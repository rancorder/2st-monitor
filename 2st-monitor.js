#!/usr/bin/env node
/**
 * 2st-monitor.js - 2ndstreet監視システム (Node.js版)
 * 
 * 特徴:
 * ✅ Puppeteer による安定したブラウザ自動操作
 * ✅ 30秒間隔での自動監視
 * ✅ ChatWork自動通知
 * ✅ 1位商品の差分検知
 * ✅ EXE化対応（pkg）
 * 
 * 実行方法:
 * - 開発時: node 2st-monitor.js
 * - EXE化後: 2st-monitor.exe をダブルクリック
 */

const puppeteer = require('puppeteer');
const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

// ==================== 設定 ====================

const CONFIG = {
  // ChatWorkトークン
  chatworkToken: '987cf44efbf5529a09b1317a85058640',
  
  // 監視間隔（秒）
  checkInterval: 30,
  
  // スリープ時間（監視停止時間帯）
  sleepHours: {
    start: 1,  // 1時
    end: 8     // 8時
  },
  
  // ファイルパス
  snapshotFile: '2st_snapshot.json',
  statsFile: '2st_stats.json',
  
  // リトライ設定
  maxRetries: 3,
  retryDelay: 3000,
  
  // タイムアウト設定
  pageTimeout: 45000,
  selectorTimeout: 10000
};

// 監視URL設定
const URLS = [
  {
    url: 'https://www.2ndstreet.jp/search?category=121001&sortBy=arrival',
    displayName: 'セカンドストリート',
    category: 'カメラ',
    roomId: '385402385',
    urlIndex: 0
  },
  {
    url: 'https://www.2ndstreet.jp/search?category=931010&sortBy=arrival',
    displayName: 'セカンドストリート',
    category: '時計',
    roomId: '408715054',
    urlIndex: 1
  }
];

// ==================== ユーティリティ ====================

class Logger {
  static info(message) {
    console.log(`[INFO] ${new Date().toLocaleString('ja-JP')} - ${message}`);
  }
  
  static success(message) {
    console.log(`[SUCCESS] ${new Date().toLocaleString('ja-JP')} - ${message}`);
  }
  
  static warn(message) {
    console.log(`[WARN] ${new Date().toLocaleString('ja-JP')} - ${message}`);
  }
  
  static error(message) {
    console.log(`[ERROR] ${new Date().toLocaleString('ja-JP')} - ${message}`);
  }
  
  static separator() {
    console.log('='.repeat(60));
  }
}

// 日本時間（JST）でタイムスタンプを取得
function getJSTTimestamp() {
  const now = new Date();
  const jstOffset = 9 * 60; // JST = UTC+9
  const jstTime = new Date(now.getTime() + jstOffset * 60 * 1000);
  return jstTime.toISOString().replace('Z', '+09:00');
}

// ==================== スナップショット管理 ====================

class SnapshotManager {
  constructor(filePath) {
    this.filePath = filePath;
    this.snapshots = {};
  }
  
  async load() {
    try {
      const data = await fs.readFile(this.filePath, 'utf8');
      this.snapshots = JSON.parse(data);
      Logger.info(`スナップショット読み込み: ${Object.keys(this.snapshots).length}件`);
    } catch (error) {
      Logger.warn('スナップショットファイルが見つかりません（新規作成）');
      this.snapshots = {};
    }
  }
  
  async save() {
    try {
      await fs.writeFile(this.filePath, JSON.stringify(this.snapshots, null, 2), 'utf8');
    } catch (error) {
      Logger.error(`スナップショット保存失敗: ${error.message}`);
    }
  }
  
  normalizeProductKey(product) {
    const combined = `${product.name}_${product.price}`;
    return crypto.createHash('md5').update(combined).digest('hex').substring(0, 8);
  }
  
  detectNewProducts(urlKey, products) {
    if (!products || products.length === 0) {
      Logger.warn(`${urlKey}: 商品リストが空です`);
      return [];
    }
    
    const isFirstRun = !this.snapshots[urlKey];
    
    if (isFirstRun) {
      // 初回実行：1位を記録
      const firstKey = this.normalizeProductKey(products[0]);
      this.snapshots[urlKey] = {
        firstProductKey: firstKey,
        firstProductName: products[0].name,
        lastCheckTime: getJSTTimestamp()
      };
      Logger.info(`${urlKey}: 初回実行 - 1位商品を記録: ${products[0].name}`);
      return [];
    }
    
    // 1位商品の変更チェック
    const currentFirstKey = this.normalizeProductKey(products[0]);
    const storedFirstKey = this.snapshots[urlKey].firstProductKey;
    
    if (currentFirstKey !== storedFirstKey) {
      Logger.success(`${urlKey}: 1位変更検知！`);
      Logger.info(`  旧: ${this.snapshots[urlKey].firstProductName}`);
      Logger.info(`  新: ${products[0].name}`);
      
      // スナップショット更新
      this.snapshots[urlKey] = {
        firstProductKey: currentFirstKey,
        firstProductName: products[0].name,
        lastCheckTime: getJSTTimestamp()
      };
      
      return [products[0]];
    } else {
      this.snapshots[urlKey].lastCheckTime = getJSTTimestamp();
      return [];
    }
  }
}

// ==================== 統計管理 ====================

class StatsManager {
  constructor(filePath) {
    this.filePath = filePath;
    this.stats = {};
  }
  
  async load() {
    try {
      const data = await fs.readFile(this.filePath, 'utf8');
      this.stats = JSON.parse(data);
    } catch (error) {
      this.stats = {
        hourlyNewItems: {},
        totalChecks: 0,
        totalNewItems: 0,
        lastNewItemTime: null,
        errorCount: 0,
        lastErrorTime: null
      };
      
      // 時間別カウンターを初期化
      for (let h = 0; h < 24; h++) {
        this.stats.hourlyNewItems[h] = 0;
      }
    }
  }
  
  async save() {
    try {
      await fs.writeFile(this.filePath, JSON.stringify(this.stats, null, 2), 'utf8');
    } catch (error) {
      Logger.error(`統計保存失敗: ${error.message}`);
    }
  }
  
  async update(newItemCount) {
    const currentHour = new Date().getHours();
    this.stats.hourlyNewItems[currentHour] = (this.stats.hourlyNewItems[currentHour] || 0) + newItemCount;
    this.stats.totalChecks += 1;
    this.stats.totalNewItems += newItemCount;
    
    if (newItemCount > 0) {
      this.stats.lastNewItemTime = getJSTTimestamp();
    }
    
    await this.save();
  }
  
  async recordError() {
    this.stats.errorCount = (this.stats.errorCount || 0) + 1;
    this.stats.lastErrorTime = getJSTTimestamp();
    await this.save();
  }
  
  getNextInterval() {
    const currentHour = new Date().getHours();
    
    // スリープ時間帯チェック
    if (currentHour >= CONFIG.sleepHours.start && currentHour < CONFIG.sleepHours.end) {
      return { interval: 60, reason: 'スリープ時間帯', shouldSkip: true };
    }
    
    // 統計ベースの動的間隔（簡易版）
    const recentActivity = this.stats.hourlyNewItems[currentHour] || 0;
    
    if (recentActivity >= 3) {
      return { interval: CONFIG.checkInterval, reason: 'アクティブ', shouldSkip: false };
    } else {
      return { interval: CONFIG.checkInterval, reason: '通常', shouldSkip: false };
    }
  }
}

// ==================== ChatWork通知 ====================

class ChatWorkNotifier {
  constructor(token) {
    this.token = token;
    this.baseUrl = 'https://api.chatwork.com/v2';
  }
  
  async send(displayName, category, url, products, roomId) {
    const message = this.formatMessage(displayName, category, url, products);
    
    try {
      await axios.post(
        `${this.baseUrl}/rooms/${roomId}/messages`,
        `body=${encodeURIComponent(message)}`,
        {
          headers: {
            'X-ChatWorkToken': this.token,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          timeout: 10000
        }
      );
      Logger.success(`ChatWork通知送信成功: ${displayName} ${category}`);
      return true;
    } catch (error) {
      Logger.error(`ChatWork通知失敗: ${error.message}`);
      return false;
    }
  }
  
  formatMessage(displayName, category, url, products) {
    let message = "[info]";
    message += "━━━━━━━━━━━━━━━━━\n";
    message += `📍 ${displayName} + ${category}\n`;
    message += "━━━━━━━━━━━━━━━━━\n";
    message += `🔗 ${url}\n`;
    message += "━━━━━━━━━━━━━━━━━\n\n";
    
    // 最大20件まで表示
    products.slice(0, 20).forEach((product) => {
      const priceText = `${product.price}円`;
      message += `■${product.name}・${priceText}\n\n`;
    });
    
    // 20件以上ある場合
    if (products.length > 20) {
      message += `...他${products.length - 20}件\n`;
    }
    
    message += "ーーーーーーーーーーー[/info]";
    return message;
  }
}

// ==================== スクレイピング ====================

class SecondStreetScraper {
  constructor() {
    this.browser = null;
  }
  
  async initialize() {
    Logger.info('Puppeteerブラウザを起動中...');
    
    this.browser = await puppeteer.launch({
      headless: false,  // ブラウザを起動するが画面外に配置
      args: [
        '--disable-blink-features=AutomationControlled',
        '--window-position=-2000,0',  // 画面外に配置（最小化相当）
        '--disable-dev-shm-usage',
        '--disable-web-security',
        '--disable-features=IsolateOrigins,site-per-process',
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-gpu',
        '--disable-features=NetworkService',
        '--disable-features=VizDisplayCompositor'
      ],
      ignoreDefaultArgs: ['--enable-automation']
    });
    
    Logger.success('ブラウザ起動完了（画面外起動モード）');
  }
  
  async close() {
    if (this.browser) {
      await this.browser.close();
      Logger.info('ブラウザを終了しました');
    }
  }
  
  async scrapeUrl(urlConfig, retries = CONFIG.maxRetries) {
    const urlKey = `${urlConfig.displayName}_${urlConfig.category}`;
    
    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        Logger.info(`${urlKey}: スクレイピング開始（試行 ${attempt}/${retries}）`);
        
        const page = await this.browser.newPage();
        
        // User-Agent設定
        await page.setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
          '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
        );
        
        // 追加ヘッダー
        await page.setExtraHTTPHeaders({
          'Accept-Language': 'ja,en-US;q=0.9,en;q=0.8',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        });
        
        // Webdriver検知回避
        await page.evaluateOnNewDocument(() => {
          Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
          window.navigator.chrome = { runtime: {} };
        });
        
        // ページ遷移
        Logger.info(`${urlKey}: ページ読み込み中...`);
        await page.goto(urlConfig.url, {
          waitUntil: 'networkidle2',
          timeout: CONFIG.pageTimeout
        });
        
        // ページタイトル確認
        const title = await page.title();
        Logger.info(`${urlKey}: ページタイトル「${title}」`);
        
        // 追加待機（Bot検知回避）
        await this.sleep(3000);
        
        // スクリーンショット保存（デバッグ用）
        const screenshotPath = `debug_${urlConfig.category}_${attempt}.png`;
        await page.screenshot({ path: screenshotPath, fullPage: false });
        Logger.info(`${urlKey}: スクリーンショット保存 → ${screenshotPath}`);
        
        // HTML保存（デバッグ用）
        const html = await page.content();
        const htmlPath = `debug_${urlConfig.category}_${attempt}.html`;
        await require('fs').promises.writeFile(htmlPath, html, 'utf8');
        Logger.info(`${urlKey}: HTML保存 → ${htmlPath}`);
        
        // 商品要素の存在確認（複数セレクタ試行）
        const selectors = [
          '.item-box',
          'div.item-box',
          '[class*="item-box"]',
          '[class*="item"]',
          'article',
          '.product',
          '[class*="product"]'
        ];
        
        let foundSelector = null;
        for (const selector of selectors) {
          try {
            const elements = await page.$$(selector);
            if (elements.length > 0) {
              foundSelector = selector;
              Logger.success(`${urlKey}: セレクタ「${selector}」で${elements.length}個の要素発見`);
              break;
            }
          } catch (e) {
            // 次のセレクタを試行
          }
        }
        
        if (!foundSelector) {
          Logger.warn(`${urlKey}: 商品要素が見つかりません（試行 ${attempt}/${retries}）`);
          Logger.warn(`${urlKey}: HTMLとスクリーンショットを確認してください`);
          await page.close();
          
          if (attempt < retries) {
            await this.sleep(CONFIG.retryDelay);
            continue;
          }
          return [];
        }
        
        // 商品情報抽出（改良版）
        const products = await page.evaluate((selector) => {
          const items = [];
          const boxes = document.querySelectorAll(selector);
          
          boxes.forEach(box => {
            try {
              // 商品名を探す（複数パターン）
              const nameSelectors = [
                '.item-name', 
                '[class*="item-name"]',
                '[class*="name"]',
                'h2', 'h3', 'h4',
                '.title',
                '[class*="title"]'
              ];
              
              let nameElem = null;
              for (const sel of nameSelectors) {
                nameElem = box.querySelector(sel);
                if (nameElem && nameElem.textContent.trim()) break;
              }
              
              // 価格を探す（複数パターン）
              const priceSelectors = [
                '.item-price',
                '[class*="item-price"]',
                '[class*="price"]',
                '.price'
              ];
              
              let priceElem = null;
              for (const sel of priceSelectors) {
                priceElem = box.querySelector(sel);
                if (priceElem && priceElem.textContent.trim()) break;
              }
              
              // リンクを探す
              const linkElem = box.querySelector('a');
              
              if (nameElem && priceElem && linkElem) {
                const name = nameElem.textContent.trim();
                const price = priceElem.textContent.trim();
                let url = linkElem.getAttribute('href') || '';
                
                if (url && !url.startsWith('http')) {
                  url = 'https://www.2ndstreet.jp' + url;
                }
                
                if (name && price && url) {
                  items.push({ name, price, url });
                }
              }
            } catch (e) {
              // スキップ
            }
          });
          
          return items.slice(0, 20);
        }, foundSelector);
        
        Logger.info(`${urlKey}: 抽出結果 ${products.length}件`);
        
        // 最初の3件を表示（デバッグ）
        if (products.length > 0) {
          Logger.info(`${urlKey}: 商品サンプル:`);
          products.slice(0, 3).forEach((p, i) => {
            Logger.info(`  ${i+1}. ${p.name} - ${p.price}`);
          });
        }
        
        await page.close();
        
        if (products.length >= 3) {
          Logger.success(`${urlKey}: ${products.length}件取得成功`);
          return products;
        } else {
          Logger.warn(`${urlKey}: 商品数不足（${products.length}件）`);
          
          if (attempt < retries) {
            await this.sleep(CONFIG.retryDelay);
            continue;
          }
        }
        
      } catch (error) {
        Logger.error(`${urlKey}: エラー（試行 ${attempt}/${retries}）: ${error.message}`);
        
        if (attempt < retries) {
          await this.sleep(CONFIG.retryDelay);
          continue;
        }
      }
    }
    
    Logger.error(`${urlKey}: 全試行失敗`);
    return [];
  }
  
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ==================== メインループ ====================

class MonitoringSystem {
  constructor() {
    this.scraper = new SecondStreetScraper();
    this.snapshotManager = new SnapshotManager(CONFIG.snapshotFile);
    this.statsManager = new StatsManager(CONFIG.statsFile);
    this.notifier = new ChatWorkNotifier(CONFIG.chatworkToken);
    this.isRunning = false;
  }
  
  async initialize() {
    Logger.separator();
    Logger.info('🚀 2ndstreet監視システム起動');
    Logger.separator();
    
    await this.snapshotManager.load();
    await this.statsManager.load();
    await this.scraper.initialize();
    
    Logger.info(`監視対象: ${URLS.length}サイト`);
    URLS.forEach(url => {
      Logger.info(`  - ${url.displayName} ${url.category} → ルーム ${url.roomId}`);
    });
    Logger.info(`監視間隔: ${CONFIG.checkInterval}秒`);
    Logger.info(`スリープ時間: ${CONFIG.sleepHours.start}時 〜 ${CONFIG.sleepHours.end}時`);
    Logger.separator();
    Logger.info('Ctrl+C で停止');
    Logger.separator();
  }
  
  async checkAllUrls() {
    Logger.separator();
    Logger.info('📡 監視チェック開始');
    Logger.separator();
    
    let totalNewProducts = 0;
    
    // シーケンシャル実行（Bot検知回避）
    for (const urlConfig of URLS) {
      const urlKey = `${urlConfig.displayName}_${urlConfig.category}`;
      
      try {
        const products = await this.scraper.scrapeUrl(urlConfig);
        
        if (products.length > 0) {
          const newProducts = this.snapshotManager.detectNewProducts(urlKey, products);
          
          if (newProducts.length > 0) {
            Logger.success(`🎉 ${urlKey}: 新商品 ${newProducts.length}件検知！`);
            
            await this.notifier.send(
              urlConfig.displayName,
              urlConfig.category,
              urlConfig.url,
              newProducts,
              urlConfig.roomId
            );
            
            totalNewProducts += newProducts.length;
          } else {
            Logger.info(`${urlKey}: 変更なし`);
          }
        } else {
          Logger.warn(`${urlKey}: 商品取得失敗`);
        }
        
        // URL間に遅延（Bot検知回避）
        if (URLS.indexOf(urlConfig) < URLS.length - 1) {
          await this.sleep(2000);
        }
        
      } catch (error) {
        Logger.error(`${urlKey}: 処理エラー: ${error.message}`);
        await this.statsManager.recordError();
      }
    }
    
    await this.snapshotManager.save();
    await this.statsManager.update(totalNewProducts);
    
    Logger.separator();
    Logger.success(`✅ 監視チェック完了: 新商品 ${totalNewProducts}件`);
    Logger.separator();
  }
  
  async start() {
    this.isRunning = true;
    
    while (this.isRunning) {
      try {
        const { interval, reason, shouldSkip } = this.statsManager.getNextInterval();
        
        if (shouldSkip) {
          const currentHour = new Date().getHours();
          Logger.info(`😴 スリープ時間帯 (${currentHour}時) - ${interval}秒待機`);
        } else {
          await this.checkAllUrls();
          
          // 統計情報表示（10回に1回）
          if (this.statsManager.stats.totalChecks % 10 === 0) {
            Logger.info(`📊 統計: チェック${this.statsManager.stats.totalChecks}回 / 新着${this.statsManager.stats.totalNewItems}件`);
          }
        }
        
        const nextTime = new Date(Date.now() + interval * 1000);
        Logger.info(`⏳ 次回実行: ${nextTime.toLocaleString('ja-JP')} (${interval}秒後・${reason})`);
        
        await this.sleep(interval * 1000);
        
      } catch (error) {
        Logger.error(`システムエラー: ${error.message}`);
        await this.statsManager.recordError();
        Logger.info('60秒後に再試行...');
        await this.sleep(60000);
      }
    }
  }
  
  async stop() {
    Logger.info('監視システムを停止中...');
    this.isRunning = false;
    await this.scraper.close();
    Logger.success('✅ 監視システム終了');
  }
  
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ==================== エントリーポイント ====================

async function main() {
  const system = new MonitoringSystem();
  
  // シグナルハンドリング
  process.on('SIGINT', async () => {
    console.log('\n');
    Logger.warn('⚠️  停止シグナル受信');
    await system.stop();
    process.exit(0);
  });
  
  process.on('SIGTERM', async () => {
    await system.stop();
    process.exit(0);
  });
  
  try {
    await system.initialize();
    await system.start();
  } catch (error) {
    Logger.error(`致命的エラー: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  }
}

// 実行
if (require.main === module) {
  main();
}

module.exports = { MonitoringSystem };
