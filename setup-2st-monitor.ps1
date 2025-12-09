# ============================================
# 2st-monitor 自動セットアップスクリプト
# ============================================
# 実行方法:
# irm https://raw.githubusercontent.com/rancorder/2st-monitor/main/setup-2st-monitor.ps1 | iex
# ============================================

# エラー時は即座に停止
$ErrorActionPreference = "Stop"

# 文字コードをUTF-8に設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================
# カラー出力関数
# ============================================
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Type) {
        "Success" { 
            Write-Host "[SUCCESS] $timestamp - " -NoNewline -ForegroundColor Green
            Write-Host $Message -ForegroundColor White
        }
        "Error" { 
            Write-Host "[ERROR] $timestamp - " -NoNewline -ForegroundColor Red
            Write-Host $Message -ForegroundColor White
        }
        "Warning" { 
            Write-Host "[WARN] $timestamp - " -NoNewline -ForegroundColor Yellow
            Write-Host $Message -ForegroundColor White
        }
        "Info" { 
            Write-Host "[INFO] $timestamp - " -NoNewline -ForegroundColor Cyan
            Write-Host $Message -ForegroundColor White
        }
        "Step" { 
            Write-Host "`n========================================" -ForegroundColor Magenta
            Write-Host "  $Message" -ForegroundColor Magenta
            Write-Host "========================================`n" -ForegroundColor Magenta
        }
    }
}

# ============================================
# Node.jsインストール確認・インストール
# ============================================
function Install-NodeJS {
    Write-ColorOutput "Node.jsのインストール状況を確認中..." "Step"
    
    # Node.jsが既にインストールされているか確認
    try {
        $nodeVersion = node -v 2>$null
        if ($nodeVersion) {
            Write-ColorOutput "Node.js は既にインストール済みです: $nodeVersion" "Success"
            return $true
        }
    } catch {
        Write-ColorOutput "Node.js が見つかりません。インストールを開始します..." "Info"
    }
    
    # Chocolateyのインストール確認
    Write-ColorOutput "Chocolateyのインストール状況を確認中..." "Info"
    try {
        $chocoVersion = choco -v 2>$null
        if ($chocoVersion) {
            Write-ColorOutput "Chocolatey は既にインストール済みです" "Success"
        }
    } catch {
        Write-ColorOutput "Chocolateyをインストール中..." "Info"
        
        # Chocolateyインストール
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-ColorOutput "Chocolateyのインストールが完了しました" "Success"
            
            # PATHを更新
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } catch {
            Write-ColorOutput "Chocolateyのインストールに失敗しました" "Error"
            Write-ColorOutput "手動でNode.jsをインストールしてください: https://nodejs.org/" "Warning"
            return $false
        }
    }
    
    # Node.jsをChocolatey経由でインストール
    Write-ColorOutput "Node.js LTSをインストール中... (数分かかります)" "Info"
    try {
        choco install nodejs-lts -y --no-progress
        
        # PATHを更新
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # インストール確認
        Start-Sleep -Seconds 3
        $nodeVersion = node -v 2>$null
        if ($nodeVersion) {
            Write-ColorOutput "Node.js のインストールが完了しました: $nodeVersion" "Success"
            return $true
        } else {
            Write-ColorOutput "Node.jsのインストールは完了しましたが、PATHが反映されていません" "Warning"
            Write-ColorOutput "PowerShellを再起動してから、再度このスクリプトを実行してください" "Warning"
            return $false
        }
    } catch {
        Write-ColorOutput "Node.jsのインストールに失敗しました" "Error"
        return $false
    }
}

# ============================================
# プロジェクトフォルダ作成
# ============================================
function New-ProjectFolder {
    Write-ColorOutput "プロジェクトフォルダを作成中..." "Step"
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $projectPath = Join-Path $desktopPath "2st-monitor"
    
    if (Test-Path $projectPath) {
        Write-ColorOutput "既存のフォルダが見つかりました: $projectPath" "Warning"
        $response = Read-Host "上書きしますか？ (Y/N)"
        if ($response -ne "Y" -and $response -ne "y") {
            Write-ColorOutput "セットアップを中止しました" "Warning"
            exit 0
        }
        Remove-Item -Path $projectPath -Recurse -Force
        Write-ColorOutput "既存のフォルダを削除しました" "Info"
    }
    
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    Write-ColorOutput "プロジェクトフォルダを作成しました: $projectPath" "Success"
    
    return $projectPath
}

# ============================================
# package.json作成
# ============================================
function New-PackageJson {
    param([string]$ProjectPath)
    
    Write-ColorOutput "package.jsonを作成中..." "Step"
    
    Set-Location $ProjectPath
    
    # package.jsonの内容
    $packageJson = @{
        name = "2st-monitor"
        version = "1.0.0"
        description = "2ndstreet monitoring system"
        main = "2st-monitor.js"
        scripts = @{
            start = "node 2st-monitor.js"
        }
        keywords = @("scraping", "monitoring", "chatwork")
        author = ""
        license = "ISC"
        dependencies = @{
            puppeteer = "^21.0.0"
            axios = "^1.6.0"
        }
    } | ConvertTo-Json -Depth 10
    
    $packageJson | Out-File -FilePath (Join-Path $ProjectPath "package.json") -Encoding UTF8
    Write-ColorOutput "package.jsonを作成しました" "Success"
}

# ============================================
# npm依存関係インストール
# ============================================
function Install-Dependencies {
    param([string]$ProjectPath)
    
    Write-ColorOutput "依存パッケージをインストール中..." "Step"
    Write-ColorOutput "Puppeteerのインストールには数分かかります（Chromiumのダウンロード）" "Info"
    
    Set-Location $ProjectPath
    
    try {
        # npm install実行
        $npmOutput = npm install 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "依存パッケージのインストールが完了しました" "Success"
            Write-ColorOutput "  ✓ puppeteer (Chromium含む)" "Success"
            Write-ColorOutput "  ✓ axios" "Success"
            return $true
        } else {
            Write-ColorOutput "依存パッケージのインストールに失敗しました" "Error"
            Write-ColorOutput $npmOutput "Error"
            return $false
        }
    } catch {
        Write-ColorOutput "npm installの実行中にエラーが発生しました: $_" "Error"
        return $false
    }
}

# ============================================
# 2st-monitor.jsダウンロード
# ============================================
function Get-MonitorScript {
    param([string]$ProjectPath)
    
    Write-ColorOutput "監視スクリプトをダウンロード中..." "Step"
    
    # GitHub上の2st-monitor.jsのURL
    $scriptUrl = "https://raw.githubusercontent.com/rancorder/2st-monitor/main/2st-monitor.js"
    $scriptPath = Join-Path $ProjectPath "2st-monitor.js"
    
    # ファイルが既に存在する場合
    if (Test-Path $scriptPath) {
        Write-ColorOutput "2st-monitor.js は既に配置されています" "Success"
        $response = Read-Host "上書きダウンロードしますか？ (Y/N)"
        if ($response -ne "Y" -and $response -ne "y") {
            return $true
        }
    }
    
    # GitHubからダウンロード
    try {
        Write-ColorOutput "GitHubから2st-monitor.jsをダウンロード中..." "Info"
        Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing
        Write-ColorOutput "2st-monitor.jsのダウンロードが完了しました" "Success"
        return $true
    } catch {
        Write-ColorOutput "2st-monitor.jsのダウンロードに失敗しました: $_" "Error"
        Write-ColorOutput "手動で配置してください: $scriptPath" "Warning"
        return $false
    }
}

# ============================================
# 起動スクリプト作成
# ============================================
function New-StartScript {
    param([string]$ProjectPath)
    
    Write-ColorOutput "起動スクリプトを作成中..." "Step"
    
    # PowerShell起動スクリプト
    $startScript = @"
# 2st-monitor 起動スクリプト
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  2st-monitor 起動中..." -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "停止する場合: Ctrl + C を押してください" -ForegroundColor Yellow
Write-Host ""

Set-Location "$ProjectPath"
node 2st-monitor.js

Write-Host ""
Write-Host "================================" -ForegroundColor Green
Write-Host "  監視システムを停止しました" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

Read-Host "Enterキーを押して終了"
"@
    
    $startScriptPath = Join-Path $ProjectPath "start.ps1"
    $startScript | Out-File -FilePath $startScriptPath -Encoding UTF8
    
    # バッチファイル（PowerShell実行用）
    $batchScript = @"
@echo off
chcp 65001 > nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
pause
"@
    
    $batchScriptPath = Join-Path $ProjectPath "start.bat"
    $batchScript | Out-File -FilePath $batchScriptPath -Encoding UTF8
    
    Write-ColorOutput "起動スクリプトを作成しました" "Success"
    Write-ColorOutput "  ✓ start.ps1 (PowerShell版)" "Info"
    Write-ColorOutput "  ✓ start.bat (ダブルクリック実行用)" "Info"
}

# ============================================
# README作成
# ============================================
function New-ReadmeFile {
    param([string]$ProjectPath)
    
    Write-ColorOutput "READMEファイルを作成中..." "Step"
    
    $readme = @"
# 2st-monitor - 2ndstreet監視システム

## 使い方

### 起動方法
\`start.bat\` をダブルクリックで起動

または

PowerShellで以下を実行:
\`\`\`powershell
node 2st-monitor.js
\`\`\`

### 停止方法
\`Ctrl + C\` を押す

## 設定変更

\`2st-monitor.js\` をメモ帳で開いて編集:

\`\`\`javascript
const CONFIG = {
  chatworkToken: 'YOUR_TOKEN_HERE',  // ChatWorkトークン
  checkInterval: 30,                  // チェック間隔（秒）
  sleepHours: {
    start: 1,  // 監視停止開始時刻
    end: 8     // 監視停止終了時刻
  }
};
\`\`\`

## 生成されるファイル

- \`2st_snapshot.json\` - 商品データの記録
- \`2st_stats.json\` - 統計情報
- \`debug_*.png\` - スクリーンショット（デバッグ用）
- \`debug_*.html\` - HTMLソース（デバッグ用）

## トラブルシューティング

### エラー: 商品が取得できない
- \`debug_*.png\` を確認してページが正しく表示されているか確認
- Bot検知の可能性があるため、待機時間を増やす

### ChatWork通知が届かない
- トークンが正しいか確認
- ルームIDが正しいか確認

### その他のエラー
PowerShell画面のエラーメッセージを確認してください

## サポート

問題が発生した場合:
1. PowerShell画面のエラーメッセージをコピー
2. \`debug_*.png\` ファイルを確認
3. 管理者に連絡
"@
    
    $readmePath = Join-Path $ProjectPath "README.md"
    $readme | Out-File -FilePath $readmePath -Encoding UTF8
    
    Write-ColorOutput "READMEファイルを作成しました" "Success"
}

# ============================================
# メイン処理
# ============================================
function Main {
    Clear-Host
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "   2st-monitor 自動セットアップ" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "このスクリプトは以下を自動で実行します:" -ForegroundColor White
    Write-Host "  1. Node.jsのインストール（未インストールの場合）" -ForegroundColor Gray
    Write-Host "  2. プロジェクトフォルダの作成" -ForegroundColor Gray
    Write-Host "  3. 依存パッケージのインストール" -ForegroundColor Gray
    Write-Host "  4. 起動スクリプトの作成" -ForegroundColor Gray
    Write-Host ""
    Write-Host "所要時間: 約5〜10分" -ForegroundColor Yellow
    Write-Host ""
    
    $response = Read-Host "セットアップを開始しますか？ (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-ColorOutput "セットアップを中止しました" "Warning"
        exit 0
    }
    
    Write-Host ""
    
    # Node.jsインストール
    $nodeInstalled = Install-NodeJS
    if (-not $nodeInstalled) {
        Write-ColorOutput "Node.jsのセットアップに失敗しました" "Error"
        Write-ColorOutput "PowerShellを再起動してから、再度このスクリプトを実行してください" "Warning"
        Read-Host "Enterキーを押して終了"
        exit 1
    }
    
    # プロジェクトフォルダ作成
    $projectPath = New-ProjectFolder
    
    # package.json作成
    New-PackageJson -ProjectPath $projectPath
    
    # 依存関係インストール
    $depsInstalled = Install-Dependencies -ProjectPath $projectPath
    if (-not $depsInstalled) {
        Write-ColorOutput "依存パッケージのインストールに失敗しました" "Error"
        Read-Host "Enterキーを押して終了"
        exit 1
    }
    
    # 監視スクリプトダウンロード（またはプレースホルダー）
    Get-MonitorScript -ProjectPath $projectPath
    
    # 起動スクリプト作成
    New-StartScript -ProjectPath $projectPath
    
    # README作成
    New-ReadmeFile -ProjectPath $projectPath
    
    # 完了メッセージ
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   セットアップ完了！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-ColorOutput "プロジェクトフォルダ: $projectPath" "Success"
    Write-Host ""
    
    # 2st-monitor.jsの配置確認
    $scriptExists = Test-Path (Join-Path $projectPath "2st-monitor.js")
    
    if ($scriptExists) {
        Write-Host "次のステップ:" -ForegroundColor Yellow
        Write-Host "  1. ChatWorkトークンを設定（2st-monitor.jsを編集）" -ForegroundColor White
        Write-Host ""
        Write-Host "  2. start.bat をダブルクリックで起動" -ForegroundColor White
        Write-Host ""
        Write-Host "  または PowerShell で以下を実行:" -ForegroundColor White
        Write-Host "     cd $projectPath" -ForegroundColor Cyan
        Write-Host "     node 2st-monitor.js" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  注意:" -ForegroundColor Yellow
        Write-Host "  2st-monitor.js のダウンロードに失敗しました" -ForegroundColor White
        Write-Host "  手動で以下のフォルダに配置してください:" -ForegroundColor White
        Write-Host "     $projectPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  配置後、start.bat をダブルクリックで起動" -ForegroundColor White
    }
    Write-Host ""
    
    # フォルダを開く
    $openFolder = Read-Host "プロジェクトフォルダを開きますか？ (Y/N)"
    if ($openFolder -eq "Y" -or $openFolder -eq "y") {
        Invoke-Item $projectPath
    }
    
    Write-Host ""
    Read-Host "Enterキーを押して終了"
}

# ============================================
# 実行
# ============================================
try {
    Main
} catch {
    Write-ColorOutput "予期しないエラーが発生しました: $_" "Error"
    Write-ColorOutput $_.ScriptStackTrace "Error"
    Read-Host "Enterキーを押して終了"
    exit 1
}
