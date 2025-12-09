# ============================================
# 2st-monitor 完全自動セットアップスクリプト
# ============================================
# GitHubから自動ダウンロード → セットアップ完了まで
# BOM問題完全対応版
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   2st-monitor 自動セットアップ" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Step 1: Node.js確認・インストール
# ============================================
Write-Host "[1/6] Node.jsを確認中..." -ForegroundColor Yellow

try {
    $nodeVersion = node -v 2>$null
    if ($nodeVersion) {
        Write-Host "      ✓ Node.js インストール済み: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.jsが見つかりません"
    }
} catch {
    Write-Host "      Node.jsが見つかりません" -ForegroundColor Yellow
    Write-Host "      Chocolatey経由でインストール中..." -ForegroundColor Yellow
    
    # Chocolateyインストール
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Node.js LTSインストール
        choco install nodejs-lts -y
        
        # PATH更新
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Write-Host "      ✓ Node.js インストール完了" -ForegroundColor Green
    } catch {
        Write-Host "      ❌ Node.jsの自動インストールに失敗しました" -ForegroundColor Red
        Write-Host "      手動でインストールしてください: https://nodejs.org/" -ForegroundColor Yellow
        Read-Host "`nEnterキーを押して終了"
        exit 1
    }
}

Write-Host ""

# ============================================
# Step 2: プロジェクトフォルダ作成
# ============================================
Write-Host "[2/6] プロジェクトフォルダを作成中..." -ForegroundColor Yellow

$projectPath = "$HOME\Desktop\2st-monitor"

# 既存フォルダ削除
Remove-Item -Path $projectPath -Recurse -Force -ErrorAction SilentlyContinue

# 新規作成
New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
Set-Location $projectPath

Write-Host "      ✓ フォルダ作成完了: $projectPath" -ForegroundColor Green
Write-Host ""

# ============================================
# Step 3: package.json作成（BOM対策）
# ============================================
Write-Host "[3/6] package.json を作成中..." -ForegroundColor Yellow

$packageContent = @'
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
'@

# BOMなしUTF8で保存（PowerShell 5.1/7両対応）
try {
    $packageContent | Out-File -FilePath "package.json" -Encoding utf8NoBOM -NoNewline
    Write-Host "      ✓ BOMなしUTF8で保存完了" -ForegroundColor Green
} catch {
    # PowerShell 5.1の場合は.NETを使用
    [System.IO.File]::WriteAllText("$projectPath\package.json", $packageContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "      ✓ .NETメソッドでBOMなし保存完了" -ForegroundColor Green
}

Write-Host ""

# ============================================
# Step 4: 依存パッケージインストール
# ============================================
Write-Host "[4/6] 依存パッケージをインストール中..." -ForegroundColor Yellow
Write-Host "      ※ Puppeteerのダウンロードに数分かかります" -ForegroundColor Gray
Write-Host ""

try {
    # npm install実行
    npm install --loglevel=error
    
    # インストール確認
    $puppeteerOK = Test-Path "node_modules\puppeteer"
    $axiosOK = Test-Path "node_modules\axios"
    
    if ($puppeteerOK -and $axiosOK) {
        Write-Host "      ✓ 依存パッケージインストール完了" -ForegroundColor Green
        Write-Host "        ✓ puppeteer (Chromium含む)" -ForegroundColor Green
        Write-Host "        ✓ axios" -ForegroundColor Green
    } else {
        throw "一部パッケージのインストールに失敗"
    }
} catch {
    Write-Host "      ⚠ 初回インストールに失敗、リトライ中..." -ForegroundColor Yellow
    
    # キャッシュクリア後に再試行
    npm cache clean --force 2>&1 | Out-Null
    npm install puppeteer axios --force
    
    if ((Test-Path "node_modules\puppeteer") -and (Test-Path "node_modules\axios")) {
        Write-Host "      ✓ リトライ成功！" -ForegroundColor Green
    } else {
        Write-Host "      ❌ インストールに失敗しました" -ForegroundColor Red
        Write-Host "      手動で実行: npm install puppeteer axios" -ForegroundColor Yellow
        Read-Host "`nEnterキーを押して終了"
        exit 1
    }
}

Write-Host ""

# ============================================
# Step 5: 2st-monitor.js自動ダウンロード
# ============================================
Write-Host "[5/6] 2st-monitor.js をダウンロード中..." -ForegroundColor Yellow

try {
    $url = "https://raw.githubusercontent.com/rancorder/2st-monitor/main/2st-monitor.js"
    Invoke-WebRequest -Uri $url -OutFile "2st-monitor.js" -UseBasicParsing
    Write-Host "      ✓ ダウンロード完了" -ForegroundColor Green
} catch {
    Write-Host "      ⚠ 自動ダウンロードに失敗しました" -ForegroundColor Yellow
    Write-Host "      手動で 2st-monitor.js をこのフォルダに配置してください" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# Step 6: 起動スクリプト作成
# ============================================
Write-Host "[6/6] 起動スクリプトを作成中..." -ForegroundColor Yellow

# start.bat
$batchScript = @'
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
'@

try {
    $batchScript | Out-File -FilePath "start.bat" -Encoding utf8NoBOM
} catch {
    [System.IO.File]::WriteAllText("$projectPath\start.bat", $batchScript, (New-Object System.Text.UTF8Encoding $false))
}

# README.txt
$readme = @'
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
'@

try {
    $readme | Out-File -FilePath "README.txt" -Encoding utf8NoBOM
} catch {
    [System.IO.File]::WriteAllText("$projectPath\README.txt", $readme, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "      ✓ 起動スクリプト作成完了" -ForegroundColor Green
Write-Host "        ✓ start.bat" -ForegroundColor Green
Write-Host "        ✓ README.txt" -ForegroundColor Green

Write-Host ""

# ============================================
# 完了確認
# ============================================
Write-Host "============================================" -ForegroundColor Green
Write-Host "   セットアップ完了！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# ファイル確認
$allOK = $true

Write-Host "【インストール確認】" -ForegroundColor Cyan

if (Test-Path "package.json") {
    Write-Host "  ✓ package.json" -ForegroundColor Green
} else {
    Write-Host "  ✗ package.json が見つかりません" -ForegroundColor Red
    $allOK = $false
}

if (Test-Path "node_modules\puppeteer") {
    Write-Host "  ✓ puppeteer (Chromium含む)" -ForegroundColor Green
} else {
    Write-Host "  ✗ puppeteer がインストールされていません" -ForegroundColor Red
    $allOK = $false
}

if (Test-Path "node_modules\axios") {
    Write-Host "  ✓ axios" -ForegroundColor Green
} else {
    Write-Host "  ✗ axios がインストールされていません" -ForegroundColor Red
    $allOK = $false
}

if (Test-Path "2st-monitor.js") {
    Write-Host "  ✓ 2st-monitor.js" -ForegroundColor Green
} else {
    Write-Host "  ⚠ 2st-monitor.js （手動配置が必要）" -ForegroundColor Yellow
}

if (Test-Path "start.bat") {
    Write-Host "  ✓ start.bat" -ForegroundColor Green
} else {
    Write-Host "  ✗ start.bat が見つかりません" -ForegroundColor Red
    $allOK = $false
}

Write-Host ""

if ($allOK) {
    Write-Host "【次のステップ】" -ForegroundColor Yellow
    Write-Host "  1. 2st-monitor.js でChatWorkトークンを設定" -ForegroundColor White
    Write-Host "  2. start.bat をダブルクリックで起動" -ForegroundColor White
    Write-Host ""
    
    $openFolder = Read-Host "プロジェクトフォルダを開きますか？ (Y/N)"
    if ($openFolder -match "^[Yy]$") {
        explorer $projectPath
    }
} else {
    Write-Host "【⚠ 問題が見つかりました】" -ForegroundColor Yellow
    Write-Host "上記のエラーを確認してください" -ForegroundColor White
    Write-Host ""
}

Read-Host "`nEnterキーを押して終了"
