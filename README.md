# 2st-monitor 自動セットアップスクリプト

**たった1行のコマンドで、2ndstreet監視システムのセットアップが完了！**

従来の30分の手動セットアップが、**約5分の自動処理**に短縮されました。

---

## 🚀 超簡単セットアップ（推奨）

### ステップ1: PowerShellを管理者として起動

1. `Windows` キーを押す
2. 「powershell」と入力
3. 「Windows PowerShell」を右クリック
4. **「管理者として実行」**を選択

### ステップ2: 1行コマンドを実行

PowerShellで以下のコマンドを実行：

```powershell
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

```

### ステップ3: 待つだけ

スクリプトが自動的に以下を実行します：

- ✅ Node.jsのインストール（未インストールの場合）
- ✅ プロジェクトフォルダの作成（デスクトップに `2st-monitor`）
- ✅ 依存パッケージのインストール（puppeteer, axios）
- ✅ 起動スクリプトの作成（start.bat）

**所要時間：約5分（初回は10分程度）**

---

## 📋 自動セットアップの内容

| 処理内容 | 説明 |
|---------|------|
| Node.js確認 | インストール済みならスキップ、未インストールならChocolatey経由で自動インストール |
| Chocolateyインストール | Windowsパッケージマネージャー（Node.js自動インストール用） |
| プロジェクトフォルダ作成 | デスクトップに `2st-monitor` フォルダを作成 |
| package.json生成 | npmプロジェクトとして初期化 |
| 依存関係インストール | `puppeteer`, `axios` を自動インストール |
| 起動スクリプト作成 | `start.bat`（ダブルクリック実行用）を生成 |
| README生成 | 使い方ガイドを自動生成 |

---

## 🎮 使い方

### 起動方法

**方法1: ダブルクリック（簡単）**

1. デスクトップの `2st-monitor` フォルダを開く
2. `start.bat` をダブルクリック

**方法2: PowerShellから実行**

```powershell
cd $HOME\Desktop\2st-monitor
node 2st-monitor.js
```

### 停止方法

PowerShell画面で `Ctrl + C` を押す

---

## 🔧 設定のカスタマイズ

`2st-monitor.js` をメモ帳で開いて編集：

```javascript
const CONFIG = {
  chatworkToken: 'YOUR_TOKEN_HERE',  // ChatWorkトークン
  checkInterval: 30,                  // チェック間隔（秒）
  sleepHours: {
    start: 1,  // 監視停止開始時刻
    end: 8     // 監視停止終了時刻
  }
};
```

---

## 📊 生成されるファイル構成

```
📁 2st-monitor/
  ├── 📄 2st-monitor.js       ← メインプログラム（手動配置）
  ├── 📄 package.json         ← 自動生成
  ├── 📄 start.bat           ← 起動スクリプト
  ├── 📄 start.ps1           ← PowerShell起動スクリプト
  ├── 📄 README.md           ← 使い方説明
  ├── 📁 node_modules/       ← 依存パッケージ
  │   ├── puppeteer/
  │   └── axios/
  └── 📄 2st_snapshot.json   ← 実行後に生成
```

---

## 🔍 トラブルシューティング

### ❌ スクリプトの実行が禁止されています

**エラーメッセージ：**
```
このシステムではスクリプトの実行が無効になっているため、
ファイル setup-2st-monitor.ps1 を読み込むことができません。
```

**対処法：**

1. PowerShellを**管理者として実行**で起動し直す
2. 以下のコマンドを実行：
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   ```
3. 再度セットアップコマンドを実行

### ❌ Chocolateyのインストールに失敗

**対処法：**

1. インターネット接続を確認
2. ファイアウォールやウイルス対策ソフトをチェック
3. 手動でNode.jsをインストール：
   - https://nodejs.org/ からLTS版をダウンロード
   - インストール後、再度セットアップスクリプトを実行

### ❌ npm installが失敗する

**対処法：**

```powershell
cd $HOME\Desktop\2st-monitor
npm cache clean --force
npm install
```

---

## 📝 システム要件

- **OS:** Windows 10/11
- **権限:** 管理者権限（初回セットアップ時のみ）
- **ネットワーク:** インターネット接続（パッケージダウンロード用）
- **ディスク容量:** 約500MB（Chromium含む）

---

## 🔒 セキュリティ

- スクリプトは公式のChocolateyとNode.jsを使用
- 管理者権限はNode.jsインストール時のみ必要
- インストール後は通常権限で動作

---

## 🛠️ 開発者向け情報

### ローカルでのスクリプト実行

```powershell
# スクリプトをダウンロード
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rancorder/2st-monitor/main/setup-2st-monitor.ps1" -OutFile "setup-2st-monitor.ps1"

# 実行
.\setup-2st-monitor.ps1
```

### スクリプトのカスタマイズ

`setup-2st-monitor.ps1` を編集して、以下をカスタマイズ可能：

- プロジェクトフォルダのパス
- インストールするNode.jsバージョン
- 依存パッケージのバージョン
- ChatWorkトークンのデフォルト値

---

## 📦 アンインストール

### 2st-monitorのみ削除

デスクトップの `2st-monitor` フォルダを削除

### Node.jsも削除する場合

```powershell
# PowerShell（管理者として実行）で実行
choco uninstall nodejs-lts -y
```

---

## 📄 ライセンス

ISC License

---

## 🙋 サポート

問題が発生した場合：

1. PowerShell画面のエラーメッセージをコピー
2. `debug_*.png` ファイルを確認
3. Issueを作成してエラー内容を報告

---

## 📚 関連ドキュメント

- [詳細セットアップガイド（HTML版）](./2st-monitor_超簡単セットアップ.html)
- [従来のセットアップ手順](./2stスクレイピングツール_セットアップ手順.html)
- [2st-monitor.js 仕様書](./2st-monitor.js)

---

**🎉 これで準備完了！ `start.bat` をダブルクリックして監視を開始しましょう！**
