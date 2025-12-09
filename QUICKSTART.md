# 🚀 2st-monitor 超簡単セットアップ（1行実行）

## たった1行で完了！

### ステップ1: PowerShellを管理者として起動

1. `Windows` キーを押す
2. 「powershell」と入力
3. 「Windows PowerShell」を右クリック
4. **「管理者として実行」**を選択

### ステップ2: 以下のコマンドを実行

```powershell
irm https://raw.githubusercontent.com/rancorder/2st-monitor/main/setup-2st-monitor.ps1 | iex
```

### ステップ3: 待つだけ（約5分）

自動的に以下を実行します：
- ✅ Node.jsのインストール
- ✅ プロジェクトフォルダ作成
- ✅ 依存パッケージインストール
- ✅ 2st-monitor.js自動ダウンロード
- ✅ 起動スクリプト作成

### 完了！

デスクトップの `2st-monitor` フォルダ内の `start.bat` をダブルクリックで起動！

---

## トラブルシューティング

### ❌ スクリプトの実行が禁止されています

**対処法：**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
実行後、再度セットアップコマンドを実行

### ❌ 管理者権限エラー

PowerShellを「管理者として実行」で起動し直してください

---

## 詳細マニュアル

- [超簡単セットアップガイド（HTML版）](./2st-monitor_超簡単セットアップ.html)
- [README（詳細版）](./README.md)

---

**🎉 これだけ！はよして完了🔥**
