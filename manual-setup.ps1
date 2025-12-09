# ============================================
# 2st-monitor 完全手動セットアップ
# ============================================
# このスクリプトは自動化スクリプトを使わず、
# すべて手動でセットアップします（100%確実）
# ============================================

# エラー時は即座に停止
$ErrorActionPreference = "Stop"

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   2st-monitor 手動セットアップ" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. 既存フォルダ削除
Write-Host "[1/7] 既存フォルダをクリーンアップ中..." -ForegroundColor Yellow
Remove-Item -Path "$HOME\Desktop\2st-monitor" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "      完了" -ForegroundColor Green

# 2. フォルダ作成
Write-Host "[2/7] プロジェクトフォルダを作成中..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "$HOME\Desktop\2st-monitor" -Force | Out-Null
Set-Location "$HOME\Desktop\2st-monitor"
Write-Host "      完了: $HOME\Desktop\2st-monitor" -ForegroundColor Green

# 3. package.json作成
Write-Host "[3/7] package.json を作成中..." -ForegroundColor Yellow
$packageJson = @"
{
  "name": "2st-monitor",
  "version": "1.0.0",
  "description": "2ndstreet monitoring system",
  "main": "2st-monitor.js",
  "scripts": {
    "start": "node 2st-monitor.js"
  },
  "keywords": ["scraping", "monitoring", "chatwork"],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "puppeteer": "latest",
    "axios": "latest"
  }
}
"@

$packageJson | Out-File -FilePath "package.json" -Encoding UTF8
Write-Host "      完了" -ForegroundColor Green

# 4. npm install実行
Write-Host "[4/7] 依存パッケージをインストール中..." -ForegroundColor Yellow
Write-Host "      ※ Puppeteerのダウンロードに数分かかります" -ForegroundColor Gray

try {
    npm install --loglevel=error
    
    # インストール確認
    if ((Test-Path "node_modules\puppeteer") -and (Test-Path "node_modules\axios")) {
        Write-Host "      完了" -ForegroundColor Green
        Write-Host "        ✓ puppeteer" -ForegroundColor Green
        Write-Host "        ✓ axios" -ForegroundColor Green
    } else {
        Write-Host "      警告: 一部パッケージが見つかりません" -ForegroundColor Yellow
        Write-Host "      リトライ中..." -ForegroundColor Yellow
        npm install puppeteer axios --force
    }
} catch {
    Write-Host "      エラーが発生しました: $_" -ForegroundColor Red
    Write-Host "`n手動で以下を実行してください:" -ForegroundColor Yellow
    Write-Host "  cd $HOME\Desktop\2st-monitor" -ForegroundColor Cyan
    Write-Host "  npm install puppeteer axios" -ForegroundColor Cyan
    Read-Host "`nEnterキーを押して終了"
    exit 1
}

# 5. 2st-monitor.jsダウンロード
Write-Host "[5/7] 2st-monitor.js をダウンロード中..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rancorder/2st-monitor/main/2st-monitor.js" -OutFile "2st-monitor.js" -UseBasicParsing
    Write-Host "      完了" -ForegroundColor Green
} catch {
    Write-Host "      警告: ダウンロードに失敗しました" -ForegroundColor Yellow
    Write-Host "      手動で 2st-monitor.js をこのフォルダに配置してください" -ForegroundColor Yellow
}

# 6. 起動スクリプト作成
Write-Host "[6/7] 起動スクリプトを作成中..." -ForegroundColor Yellow

# start.bat
$batchScript = @"
@echo off
chcp 65001 > nul
title 2st-monitor
echo ================================
echo   2st-monitor 起動中...
echo ================================
echo.
echo 停止する場合: Ctrl + C を押してください
echo.
node 2st-monitor.js
echo.
echo ================================
echo   監視システムを停止しました
echo ================================
pause
"@
$batchScript | Out-File -FilePath "start.bat" -Encoding UTF8

# README.txt
$readme = @"
2st-monitor セットアップ完了

【起動方法】
  start.bat をダブルクリック

【停止方法】
  Ctrl + C を押す

【設定変更】
  2st-monitor.js をメモ帳で開いて編集
  - chatworkToken: ChatWorkトークン
  - checkInterval: チェック間隔（秒）

【生成されるファイル】
  - 2st_snapshot.json (商品データ記録)
  - 2st_stats.json (統計情報)
  - debug_*.png (スクリーンショット)

【トラブルシューティング】
  エラーが出る場合:
    1. PowerShell画面のエラーメッセージを確認
    2. debug_*.png ファイルを確認
"@
$readme | Out-File -FilePath "README.txt" -Encoding UTF8

Write-Host "      完了" -ForegroundColor Green
Write-Host "        ✓ start.bat" -ForegroundColor Green
Write-Host "        ✓ README.txt" -ForegroundColor Green

# 7. 完了
Write-Host "[7/7] セットアップ完了チェック..." -ForegroundColor Yellow

$allOK = $true

if (-not (Test-Path "package.json")) {
    Write-Host "      ✗ package.json が見つかりません" -ForegroundColor Red
    $allOK = $false
} else {
    Write-Host "      ✓ package.json" -ForegroundColor Green
}

if (-not (Test-Path "node_modules\puppeteer")) {
    Write-Host "      ✗ puppeteer がインストールされていません" -ForegroundColor Red
    $allOK = $false
} else {
    Write-Host "      ✓ puppeteer" -ForegroundColor Green
}

if (-not (Test-Path "node_modules\axios")) {
    Write-Host "      ✗ axios がインストールされていません" -ForegroundColor Red
    $allOK = $false
} else {
    Write-Host "      ✓ axios" -ForegroundColor Green
}

if (-not (Test-Path "2st-monitor.js")) {
    Write-Host "      ⚠ 2st-monitor.js が見つかりません（手動配置が必要）" -ForegroundColor Yellow
} else {
    Write-Host "      ✓ 2st-monitor.js" -ForegroundColor Green
}

if (-not (Test-Path "start.bat")) {
    Write-Host "      ✗ start.bat が見つかりません" -ForegroundColor Red
    $allOK = $false
} else {
    Write-Host "      ✓ start.bat" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   セットアップ完了！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

if ($allOK) {
    Write-Host "次のステップ:" -ForegroundColor Yellow
    Write-Host "  1. start.bat をダブルクリックで起動" -ForegroundColor White
    Write-Host "  2. ChatWorkトークンを設定済みか確認" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "⚠️ いくつか問題が見つかりました" -ForegroundColor Yellow
    Write-Host "上記のエラーを確認してください" -ForegroundColor White
    Write-Host ""
}

$openFolder = Read-Host "プロジェクトフォルダを開きますか？ (Y/N)"
if ($openFolder -eq "Y" -or $openFolder -eq "y") {
    explorer "$HOME\Desktop\2st-monitor"
}

Write-Host ""
Read-Host "Enterキーを押して終了"
