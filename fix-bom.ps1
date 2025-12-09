# ============================================
# 2st-monitor BOM問題 緊急修正パッチ
# ============================================
# package.jsonのBOMを削除してpuppeteerを再インストール
# ============================================

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   2st-monitor BOM修正パッチ" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# プロジェクトフォルダに移動
Set-Location "$HOME\Desktop\2st-monitor"

Write-Host "[1/3] package.json を修正中（BOM削除）..." -ForegroundColor Yellow

# BOMなしUTF8で再作成
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

# PowerShell 5.1対応（utf8NoBOMがない場合）
try {
    $packageContent | Out-File -FilePath "package.json" -Encoding utf8NoBOM -NoNewline
    Write-Host "      ✓ BOMなしUTF8で保存完了" -ForegroundColor Green
} catch {
    # PowerShell 5.1の場合は.NETを使用
    [System.IO.File]::WriteAllText("$PWD\package.json", $packageContent, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "      ✓ .NETメソッドでBOMなし保存完了" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/3] node_modules/puppeteerを削除中..." -ForegroundColor Yellow

# 既存のpuppeteerフォルダ削除（エラー無視）
Remove-Item -Path "node_modules\puppeteer" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "      ✓ 削除完了" -ForegroundColor Green

Write-Host ""
Write-Host "[3/3] puppeteerを再インストール中..." -ForegroundColor Yellow
Write-Host "      ※ Chromiumダウンロードに数分かかります" -ForegroundColor Gray
Write-Host ""

# puppeteerのみインストール
npm install puppeteer

Write-Host ""

# 成功確認
if (Test-Path "node_modules\puppeteer") {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   修正完了！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ✓ package.json (BOM削除)" -ForegroundColor Green
    Write-Host "  ✓ puppeteer インストール済み" -ForegroundColor Green
    Write-Host "  ✓ axios インストール済み" -ForegroundColor Green
    Write-Host ""
    Write-Host "次のステップ:" -ForegroundColor Yellow
    Write-Host "  start.bat をダブルクリックで起動" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "   修正失敗" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "手動で以下を実行してください:" -ForegroundColor Yellow
    Write-Host "  npm cache clean --force" -ForegroundColor Cyan
    Write-Host "  npm install puppeteer" -ForegroundColor Cyan
    Write-Host ""
}

Read-Host "Enterキーを押して終了"
