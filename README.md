# RAG AI-Driven Infrastructure - Terraform

このディレクトリには、RAG AI-Driven API および WebUI のAzureインフラストラクチャをTerraformで定義したファイルが含まれています。

## 🔒 セキュリティの改善点

元のBicep/ARMテンプレートから以下のセキュリティが改善されています：

### ✅ **改善された点:**
- **Managed Identity の使用**: API キーの代わりにManaged Identityを使用
- **Azure Key Vault の導入**: シークレットを安全に保存
- **権限ベースアクセス制御**: 各サービスに最小権限のRBACロールを割り当て
- **ストレージアカウントのセキュリティ強化**: 
  - `shared_key_access_enabled = false` (キーベースアクセス無効)
  - `default_to_oauth_authentication = true` (OAuth認証優先)
- **AI Search のセキュリティ**: `local_authentication_enabled = false`

### 🛡️ **環境変数からAPIキーを除去:**
以下のAPIキー関連の環境変数を削除し、Managed Identityに変更：
- `AZURE_OPENAI_API_KEY` → Managed Identity使用
- `COSMOS_DB_KEY` → Managed Identity使用
- `SEARCH_SERVICE_KEY` → Managed Identity使用
- `STORAGE_ACCOUNT_KEY` → Managed Identity使用

## 📁 ファイル構成

```
infra/
├── main.tf              # メインのTerraform設定
├── variables.tf         # 変数定義
├── outputs.tf          # アウトプット定義
├── main.tfvars.json    # 変数値（開発環境）
├── azure.yaml          # Azure Developer CLI設定
└── README.md           # このファイル
```

## 🚀 デプロイ手順

### 前提条件
- Terraform >= 1.0
- Azure CLI
- Azure Developer CLI (azd)
- 適切なAzure権限

### 1. Terraformのインストール
```bash
# Windows (winget)
winget install HashiCorp.Terraform

# macOS (Homebrew)
brew install terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Azure認証
```bash
az login
```

### 3. Terraformの初期化
```bash
cd infra
terraform init
```

### 4. 設定の検証
```bash
terraform validate
```

### 5. デプロイプランの確認
```bash
terraform plan -var-file="main.tfvars.json"
```

### 6. デプロイの実行
```bash
terraform apply -var-file="main.tfvars.json" -auto-approve
```

### 7. Azure Developer CLI を使用する場合
```bash
# プロジェクトのルートディレクトリで
azd provision --preview  # プレビュー確認
azd up                    # デプロイ実行
```

## 🔧 カスタマイズ

### 変数のカスタマイズ
`main.tfvars.json` ファイルを編集して、環境に合わせて設定を変更してください：

```json
{
  "app_name": "your-app-name",
  "resource_group_name": "your-resource-group",
  "environment_name": "dev",
  "app_service_plan_sku": "B1"
}
```

### 環境別設定
異なる環境（dev, staging, prod）用に別々の `.tfvars.json` ファイルを作成：

```bash
# 開発環境
terraform apply -var-file="dev.tfvars.json"

# ステージング環境
terraform apply -var-file="staging.tfvars.json"

# 本番環境
terraform apply -var-file="prod.tfvars.json"
```

## 📊 リソース確認

デプロイ後、以下のコマンドでリソース情報を確認できます：

```bash
# アプリケーションURL
terraform output AZURE_WEBAPP_URL
terraform output AZURE_WEBUI_URL

# リソースID
terraform output app_service_id
terraform output cosmos_db_account_name
terraform output storage_account_name
```

## 🧹 クリーンアップ

リソースを削除する場合：

```bash
terraform destroy -var-file="main.tfvars.json"
```

## ⚠️ 注意事項

1. **リソースグループ**: 既存のリソースグループを指定してください
2. **Managed Identity**: 既存のUser-Assigned Managed Identityが必要です
3. **権限**: デプロイするユーザーは適切なAzure権限が必要です
4. **コスト**: デプロイされるリソースには費用が発生します

## 🆘 トラブルシューティング

### よくある問題

1. **Resource already exists**: 既存リソースとの名前重複
   - `main.tfvars.json` の `resource_token` を変更

2. **Permission denied**: 権限不足
   - Azure管理者に適切な権限を依頼

3. **Quota exceeded**: リソース制限超過
   - 別のリージョンを試すか、制限緩和を依頼

### ログ確認
```bash
# Terraformデバッグログ
export TF_LOG=DEBUG
terraform apply -var-file="main.tfvars.json"
```
