# TEIOS AI-Driven API and WebUI Infrastructure

このディレクトリには、TEIOS AI-Driven APIとWebUIのためのAzureインフラストラクチャコードが含まれています。BicepとTerraformの両方の形式で提供されています。

## 構成

このインフラストラクチャは以下のAzureリソースを作成します：

- **App Service Plans**: API用とWebUI用の2つのプラン
- **App Services**: Python API (FastAPI) とNode.js WebUI
- **Azure OpenAI Service**: GPTモデル用
- **Cosmos DB**: ドキュメントストレージ
- **Azure AI Search**: 検索機能
- **Storage Account**: ファイルストレージ
- **SQL Database**: 構造化データ
- **Application Insights**: モニタリングと分析
- **Log Analytics Workspace**: ログ収集

## Bicepでのデプロイ

### 前提条件

- Azure CLI がインストールされていること
- Azure サブスクリプションへのアクセス権があること
- 適切なAzureロールが割り当てられていること

### デプロイ手順

1. Azureにログイン
```bash
az login
```

2. リソースグループを作成（まだ存在しない場合）
```bash
az group create --name rg-teios-ai-dev --location eastus2
```

3. Bicepテンプレートをデプロイ
```bash
az deployment group create \
  --resource-group rg-teios-ai-dev \
  --template-file main.bicep \
  --parameters @main.parameters.json
```

## Terraformでのデプロイ

### 前提条件

- Terraform >= 1.0 がインストールされていること
- Azure CLI がインストールされてログイン済みであること
- Azure サブスクリプションへのアクセス権があること

### デプロイ手順

1. Azureにログイン
```bash
az login
```

2. Terraformを初期化
```bash
terraform init
```

3. 設定を検証
```bash
terraform validate
```

4. デプロイプランを確認
```bash
terraform plan -var-file="main.tfvars.json"
```

5. リソースをデプロイ
```bash
terraform apply -var-file="main.tfvars.json" -auto-approve
```

### Terraformでのリソース削除

```bash
terraform destroy -var-file="main.tfvars.json"
```

## パラメータ設定

### Bicep パラメータ (main.parameters.json)

| パラメータ | 説明 | デフォルト値 |
|-----------|------|-------------|
| appName | アプリケーション名 | rag-ai-api |
| location | デプロイリージョン | eastus2 |
| environmentName | 環境名 | dev |
| appServicePlanSku | App Service Planのサイズ | B1 |
| pythonVersion | Python ランタイムバージョン | 3.11 |
| nodeVersion | Node.js ランタイムバージョン | 20-lts |

### Terraform 変数 (main.tfvars.json)

Terraformでは、同じパラメータに加えて以下も設定できます：

| 変数 | 説明 | デフォルト値 |
|------|------|-------------|
| resource_group_name | リソースグループ名 | rg-teios-ai-dev |
| resource_token | リソース名サフィックス | iymm4la6qt4mo |

## セキュリティ設定

- すべてのApp ServiceでHTTPS必須
- Storage AccountでHTTPSトラフィックのみ許可
- SQL DatabaseでAzure AD認証使用
- Application InsightsでIPマスキング無効化
- 最小TLSバージョン1.2

## モニタリング

- Application Insightsで包括的なモニタリング
- Log Analytics Workspaceでログ集約
- 30日間のデータ保持期間

## 接続設定

App Serviceには以下の環境変数が自動設定されます：

- `AZURE_OPENAI_ENDPOINT` / `AZURE_OPENAI_API_KEY`
- `COSMOS_DB_ENDPOINT` / `COSMOS_DB_KEY`
- `SEARCH_SERVICE_ENDPOINT` / `SEARCH_SERVICE_KEY`
- `STORAGE_ACCOUNT_NAME` / `STORAGE_ACCOUNT_KEY`
- `SQL_SERVER_NAME` / `SQL_DATABASE_NAME`

## ファイル構成

```
infra/
├── main.bicep                 # Bicep メインテンプレート
├── main.parameters.json       # Bicep パラメータファイル
├── main.tf                    # Terraform メインファイル
├── variables.tf               # Terraform 変数定義
├── outputs.tf                 # Terraform 出力定義
├── versions.tf                # Terraform バージョン要件
├── main.tfvars.json          # Terraform 変数値
└── README.md                 # このファイル
```

## トラブルシューティング

### よくある問題

1. **リソース名の競合**: `resource_token` を変更してユニークな名前を生成
2. **権限不足**: Azure RBACでContributor以上のロールが必要
3. **リージョンでのサービス利用不可**: `location` パラメータを利用可能なリージョンに変更

### ログの確認

```bash
# Azure CLI でデプロイログを確認
az deployment group list --resource-group rg-teios-ai-dev

# Terraform でステートを確認
terraform show
```
