# 🔧 npm install エラー対処法

## よくあるエラーと解決方法

### ❌ エラー: puppeteer deprecated warning

**表示メッセージ:**
```
npm warn deprecated puppeteer@21.11.0: < 24.15.0 is no longer supported
```

**✅ 解決策:**

これは**警告**であり、エラーではありません。インストールは正常に完了しています。

最新版を使いたい場合：
```powershell
cd $HOME\Desktop\2st-monitor
npm install puppeteer@latest axios@latest
```

---

### ❌ エラー: npm ERR! network request failed

**原因:** インターネット接続の問題

**✅ 解決策:**

1. インターネット接続を確認
2. プロキシ設定を確認（企業環境の場合）
3. ファイアウォール設定を確認

**手動インストール:**
```powershell
cd $HOME\Desktop\2st-monitor

# キャッシュクリア
npm cache clean --force

# 再インストール
npm install puppeteer axios --force
```

---

### ❌ エラー: EACCES permission denied

**原因:** 管理者権限の不足

**✅ 解決策:**

PowerShellを**管理者として実行**で起動し直す

または：
```powershell
# npmのグローバルディレクトリを変更
npm config set prefix "$HOME\AppData\Roaming\npm"

# 再インストール
npm install puppeteer axios
```

---

### ❌ エラー: Chromiumのダウンロードに失敗

**表示メッセージ:**
```
ERROR: Failed to set up Chromium
```

**✅ 解決策1: 手動でChromiumをスキップ**

```powershell
# 環境変数を設定
$env:PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "true"

# Puppeteerをインストール
npm install puppeteer-core axios

# システムのChromeを使用する設定に変更が必要
```

**✅ 解決策2: プロキシ経由でダウンロード**

```powershell
# プロキシ設定（企業環境の場合）
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080

# 再インストール
npm install puppeteer axios
```

**✅ 解決策3: 手動でChromiumをダウンロード**

1. https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html
2. 適切なバージョンをダウンロード
3. `node_modules/puppeteer/.local-chromium/` に配置

---

### ❌ エラー: node-gyp rebuild failed

**原因:** ビルドツールの不足（Windowsの場合）

**✅ 解決策:**

```powershell
# Windows Build Tools をインストール
npm install --global windows-build-tools

# 再度セットアップスクリプトを実行
irm https://raw.githubusercontent.com/rancorder/2st-monitor/main/setup-2st-monitor.ps1 | iex
```

---

### ❌ エラー: package.json not found

**原因:** カレントディレクトリが間違っている

**✅ 解決策:**

```powershell
# プロジェクトフォルダに移動
cd $HOME\Desktop\2st-monitor

# package.jsonが存在するか確認
ls package.json

# なければ作成
npm init -y

# 依存関係をインストール
npm install puppeteer axios
```

---

## 🚀 完全クリーンインストール

どうしても解決しない場合：

```powershell
# 1. 既存フォルダを削除
Remove-Item -Path "$HOME\Desktop\2st-monitor" -Recurse -Force

# 2. Node.jsをクリーンインストール
choco uninstall nodejs-lts -y
choco install nodejs-lts -y

# 3. PowerShellを再起動

# 4. セットアップスクリプトを再実行
irm https://raw.githubusercontent.com/rancorder/2st-monitor/main/setup-2st-monitor.ps1 | iex
```

---

## 📞 それでも解決しない場合

以下の情報を収集してサポートに連絡：

1. **Node.jsバージョン:**
   ```powershell
   node -v
   npm -v
   ```

2. **エラーログ全文:**
   ```powershell
   npm install puppeteer axios --verbose 2>&1 | Out-File -FilePath error.log
   ```

3. **環境情報:**
   ```powershell
   # Windows バージョン
   systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
   
   # プロキシ設定
   npm config get proxy
   npm config get https-proxy
   ```

4. **ディスク容量:**
   ```powershell
   Get-PSDrive C | Select-Object Used,Free
   ```

---

## ✅ 正常にインストールされたか確認

```powershell
cd $HOME\Desktop\2st-monitor

# node_modulesフォルダ確認
ls node_modules

# puppeteer が存在するか確認
Test-Path node_modules\puppeteer

# 簡易テスト実行
node -e "const puppeteer = require('puppeteer'); console.log('Puppeteer OK!');"
```

**期待される出力:**
```
Puppeteer OK!
```

---

**🔥 これで解決しなければ、エラーログを共有してください！**
