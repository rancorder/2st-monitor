# 2st-monitor 自動セットアップ

**たった1行のコマンドで、2ndstreet監視システムのセットアップが完了！**

従来の30分の手動セットアップが、**約5分の自動処理**に短縮されました。

---

## 🚀 超簡単セットアップ（3ステップ）

### ステップ1: PowerShellを管理者として起動

1. `Windows` キーを押す
2. 「powershell」と入力
3. 「Windows PowerShell」を右クリック
4. **「管理者として実行」**を選択

### ステップ2: 1行コマンドを実行

PowerShellで以下のコマンドを**コピー＆ペースト**して実行：

```powershell
irm https://raw.githubusercontent.com/rancorder/2st-monitor/main/setup-2st-monitor.ps1 | iex
```

### ステップ3: 待つだけ（約5分）

スクリプトが自動的に以下を実行します：

- ✅ Node.jsのインストール（未インストールの場合）
- ✅ プロジェクトフォルダの作成（デスクトップに `2st-monitor`）
- ✅ 依存パッケージのインストール（puppeteer, axios）
- ✅ 2st-monitor.js の自動ダウンロード
- ✅ 起動スクリプトの作成（start.bat）

**セットアップ完了！**

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
  chatworkRoomId: '123456789',       // 通知先ルームID
  checkInterval: 30,                  // チェック間隔（秒）
  sleepHours: {
    start: 1,  // 監視停止開始時刻（1時）
    end: 8     // 監視停止終了時刻（8時）
  }
};
```

---

## 📊 自動セットアップの内容

| 処理内容 | 説明 |
|---------|------|
| Node.js確認 | インストール済みならスキップ、未インストールならChocolatey経由で自動インストール |
| Chocolateyインストール | Windowsパッケージマネージャー（Node.js自動インストール用） |
| プロジェクトフォルダ作成 | デスクトップに `2st-monitor` フォルダを作成 |
| package.json生成 | npmプロジェクトとして初期化（**BOM対策済み**） |
| 依存関係インストール | `puppeteer` (Chromium含む), `axios` を自動インストール |
| 2st-monitor.js自動取得 | GitHubから最新版を自動ダウンロード |
| 起動スクリプト作成 | `start.bat`（ダブルクリック実行用）を生成 |
| README生成 | 使い方ガイドを自動生成 |

**所要時間：約5分（初回は10分程度）**

---

## 📁 生成されるファイル構成

```
📁 2st-monitor/
  ├── 📄 2st-monitor.js       ← メインプログラム（自動ダウンロード）
  ├── 📄 package.json         ← 自動生成（BOM対策済み）
  ├── 📄 start.bat           ← 起動スクリプト
  ├── 📄 README.txt          ← 使い方説明
  ├── 📁 node_modules/       ← 依存パッケージ
  │   ├── puppeteer/         ← ブラウザ自動操作（Chromium含む）
  │   └── axios/             ← HTTP通信
  └── 📄 2st_snapshot.json   ← 実行後に生成（商品データ記録）
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

---

### ❌ npm installが失敗する / BOMエラー

**エラーメッセージ：**
```
npm error Unexpected token '﻿', "﻿{  "name"... is not valid JSON
```

**原因:** package.jsonにBOM（Byte Order Mark）が付いている

**対処法（3分で解決）：**

```powershell
# デスクトップの2st-monitorフォルダで実行
cd $HOME\Desktop\2st-monitor

# package.jsonをBOMなしで再作成
@'
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
'@ | Out-File -FilePath "package.json" -Encoding utf8NoBOM

# puppeteerをインストール（axiosは成功済みの場合）
npm install puppeteer
```

**または修正パッチスクリプト使用：**

```powershell
# 修正パッチダウンロード＆実行
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rancorder/2st-monitor/main/fix-bom.ps1" -OutFile "$HOME\Desktop\fix-bom.ps1" -UseBasicParsing
& "$HOME\Desktop\fix-bom.ps1"
```

---

### ❌ Chocolateyのインストールに失敗

**対処法：**

1. インターネット接続を確認
2. ファイアウォールやウイルス対策ソフトをチェック
3. 手動でNode.jsをインストール：
   - https://nodejs.org/ からLTS版をダウンロード
   - インストール後、再度セットアップスクリプトを実行

---

### ❌ 2st-monitor.jsのダウンロードに失敗

**対処法：**

手動でダウンロードして配置：

1. https://github.com/rancorder/2st-monitor/blob/main/2st-monitor.js を開く
2. 「Raw」ボタンをクリック
3. 右クリック → 「名前を付けて保存」
4. `2st-monitor` フォルダに保存

---

### 🔄 完全クリーンインストール

どうしても解決しない場合：

```powershell
# 1. 既存フォルダを削除
Remove-Item -Path "$HOME\Desktop\2st-monitor" -Recurse -Force

# 2. Node.jsをクリーンインストール（必要な場合）
choco uninstall nodejs-lts -y
choco install nodejs-lts -y

# 3. PowerShellを再起動

# 4. セットアップスクリプトを再実行
irm https://raw.githubusercontent.com/rancorder/2st-monitor/main/setup-2st-monitor.ps1 | iex
```

---

## 📝 システム要件

- **OS:** Windows 10/11
- **権限:** 管理者権限（初回セットアップ時のみ）
- **ネットワーク:** インターネット接続（パッケージダウンロード用）
- **ディスク容量:** 約500MB（Chromium含む）
- **その他:** PowerShell 5.1以上（Windows標準搭載）

---

## 🔒 セキュリティ

- スクリプトは公式のChocolateyとNode.jsを使用
- 管理者権限はNode.jsインストール時のみ必要
- インストール後は通常権限で動作
- GitHubから直接ダウンロード（改ざん防止）

---

## 🛠️ 手動セットアップ（開発者向け）

自動スクリプトを使わず、手動でセットアップする場合：

### 1. Node.jsインストール

https://nodejs.org/ からLTS版をインストール

### 2. プロジェクトフォルダ作成

```powershell
mkdir $HOME\Desktop\2st-monitor
cd $HOME\Desktop\2st-monitor
```

### 3. package.json作成

```powershell
@'
{
  "name": "2st-monitor",
  "version": "1.0.0",
  "dependencies": {
    "puppeteer": "latest",
    "axios": "latest"
  }
}
'@ | Out-File -FilePath "package.json" -Encoding utf8NoBOM
```

### 4. 依存パッケージインストール

```powershell
npm install
```

### 5. 2st-monitor.jsダウンロード

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rancorder/2st-monitor/main/2st-monitor.js" -OutFile "2st-monitor.js" -UseBasicParsing
```

### 6. 起動

```powershell
node 2st-monitor.js
```

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

## 🎯 よくある質問（FAQ）

### Q1: セットアップにどのくらい時間がかかりますか？

**A:** 初回は約10分、Node.js既にインストール済みなら約5分です。

### Q2: 管理者権限が必要なのはなぜですか？

**A:** Node.jsのシステムインストールに必要です。既にNode.jsがインストールされていれば管理者権限は不要です。

### Q3: VPSやサーバーで動作しますか？

**A:** Windows Server 2016以降で動作します。Linux版は別途対応が必要です。

### Q4: 複数のPCで使用できますか？

**A:** 各PCで個別にセットアップが必要ですが、1行コマンドで簡単にセットアップできます。

### Q5: ChatWorkトークンはどこで取得しますか？

**A:** ChatWorkの「サービス連携」→「APIトークン」から発行できます。

---

## 📄 ライセンス

ISC License

---

## 🙋 サポート

問題が発生した場合：

1. まず[トラブルシューティング](#-トラブルシューティング)を確認
2. PowerShell画面のエラーメッセージをコピー
3. [Issues](https://github.com/rancorder/2st-monitor/issues)を作成してエラー内容を報告

---

## 📚 関連ファイル

このリポジトリに含まれるファイル：

- `setup-2st-monitor.ps1` - 自動セットアップスクリプト（メイン）
- `fix-bom.ps1` - BOM問題修正パッチ
- `2st-monitor.js` - メインプログラム
- `README.md` - このファイル

---

**🎉 これで準備完了！ `start.bat` をダブルクリックして監視を開始しましょう！**
