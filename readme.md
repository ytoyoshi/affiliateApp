# Affiliate Product Management System

商品管理機能付きアフィリエイトアプリケーション

## 🏗️ アーキテクチャ

```
┌─────────────────┐    ┌──────────────────┐
│   Frontend      │    │    Backend       │
│   (Next.js)     │◄──►│  (Spring Boot)   │
│   Port: 3000    │    │   Port: 8080     │
└─────────────────┘    └──────────────────┘
                                │
                       ┌────────▼────────┐
                       │   SQLite DB     │
                       │ (Embedded File) │
                       └─────────────────┘
```

## 🛠️ 技術スタック

### バックエンド
- **Framework**: Spring Boot
- **Java Version**: 17
- **Database**: SQLite (コンテナ内蔵)
- **Build Tool**: Maven

### フロントエンド
- **Framework**: Next.js
- **Node Version**: 18

### インフラ（AWS）
- **Container Orchestration**: AWS App Runner × 2
- **CDN**: CloudFront
- **Container Registry**: Amazon ECR

## 📁 プロジェクト構成

```
affiliateApp/
├── product-api/                 # バックエンド
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   └── resources/
│   │   │       └── data/
│   │   │           └── products.db
│   │   └── test/
│   ├── Dockerfile
│   ├── pom.xml
│   └── mvnw
│
├── product-frontend-nextjs/     # フロントエンド
│   ├── src/
│   ├── public/
│   ├── Dockerfile
│   ├── package.json
│   └── package-lock.json
│
├── docker-compose.yml           # ローカル開発用
└── README.md
```

## 🚀 開発環境セットアップ

### 前提条件
- Docker Desktop (28.x+)
- Git

### 1. プロジェクトクローン
```bash
git clone <repository-url>
cd affiliateApp
```

### 2. Docker Compose で起動
```bash
# バックグラウンドで起動
docker compose up -d

# ログ確認
docker compose logs -f

# 停止
docker compose down
```

### 3. 個別起動（オプション）

#### バックエンドのみ
```bash
cd product-api
docker build -t product-api:latest .
docker run -d \
  --name product-api-container \
  -p 8080:8080 \
  product-api:latest
```

#### フロントエンドのみ
```bash
cd product-frontend-nextjs
docker build -t product-frontend:latest .
docker run -d \
  --name product-frontend-container \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL=http://localhost:8080/api \
  product-frontend:latest
```

## 🌐 アクセス

| サービス | URL | 説明 |
|---------|-----|------|
| フロントエンド | http://localhost:3000 | Next.jsアプリケーション |
| バックエンドAPI | http://localhost:8080/api | REST API |
| ヘルスチェック | http://localhost:8080/actuator/health | アプリケーション状態確認 |

## 🔧 環境変数

### バックエンド
```env
SPRING_PROFILES_ACTIVE=sqlite
DB_PATH=/app/data/products.db
```

### フロントエンド
```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
NODE_ENV=production
PORT=3000
HOSTNAME=0.0.0.0
```

## 📊 データベース

### SQLite設定
- データベースファイル: `/app/data/products.db`
- コンテナに埋め込み型（永続化なし）
- 開発・テスト環境向け

### データベース確認
```bash
# コンテナ内でSQLite接続
docker exec -it product-api-container sqlite3 /app/data/products.db

# 商品数確認
docker exec -it product-api-container sqlite3 /app/data/products.db "SELECT COUNT(*) FROM products;"
```

## 🚢 デプロイ

### AWS App Runner構成

#### 1. ECRにイメージプッシュ
```bash
# AWS ECRログイン
aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com

# バックエンド
docker tag product-api:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/product-api:latest
docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/product-api:latest

# フロントエンド  
docker tag product-frontend:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/product-frontend:latest
docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/product-frontend:latest
```

#### 2. App Runner設定

**バックエンド (apprunner-backend.yaml)**
```yaml
version: 1.0
runtime: docker
run:
  runtime-version: latest
  command: java -jar app.jar
  network:
    port: 8080
  env:
    - name: SPRING_PROFILES_ACTIVE
      value: sqlite
    - name: DB_PATH
      value: /app/data/products.db
```

**フロントエンド (apprunner-frontend.yaml)**
```yaml
version: 1.0
runtime: docker
run:
  runtime-version: latest  
  command: node server.js
  network:
    port: 3000
  env:
    - name: NEXT_PUBLIC_API_URL
      value: https://your-backend-apprunner-url.ap-northeast-1.awsapprunner.com/api
```

#### 3. CloudFront設定
- Origin: App Runner フロントエンドURL
- キャッシュ設定: SSR対応
- SEO最適化

## 🔍 トラブルシューティング

### よくある問題

#### コンテナが起動しない
```bash
# ログ確認
docker compose logs <service-name>

# 詳細情報
docker inspect <container-name>
```

#### API接続エラー
```bash
# ネットワーク確認
docker network ls
docker network inspect <network-name>

# 環境変数確認
docker exec -it <container-name> printenv
```

#### SQLiteデータベースエラー
```bash
# ファイル存在確認
docker exec -it product-api-container ls -la /app/data/

# 権限確認
docker exec -it product-api-container stat /app/data/products.db
```

### ログ確認
```bash
# 全サービスログ
docker compose logs -f

# 特定サービスのログ
docker compose logs -f product-api
docker compose logs -f product-frontend
```

## 📈 パフォーマンス最適化

### Dockerイメージ最適化
- マルチステージビルド使用
- 不要ファイル削除実装済み
- Alpine Linuxベースイメージ使用

### Next.js最適化
- サーバーサイドレンダリング (SSR)
- 静的最適化
- イメージ最適化

## 🔒 セキュリティ

### コンテナセキュリティ
- 非rootユーザー実行（フロントエンド）
- 最小権限ファイルシステム
- ヘルスチェック実装

### API セキュリティ
- CORS設定
- 入力値検証
- SQLインジェクション対策

## 🧪 テスト

```bash
# ヘルスチェック
curl http://localhost:8080/actuator/health

# API エンドポイントテスト
curl http://localhost:8080/api/products

# フロントエンド確認
curl http://localhost:3000
```

## 💰 コスト見積もり（AWS）

| リソース | 月額概算 |
|---------|----------|
| App Runner × 2 | $15-30 |
| CloudFront | $1-5 |
| ECR | $1-3 |
| **合計** | **$17-38** |

## 🤝 貢献

1. Forkしてください
2. 機能ブランチを作成 (`git checkout -b feature/AmazingFeature`)
3. 変更をコミット (`git commit -m 'Add some AmazingFeature'`)
4. ブランチにプッシュ (`git push origin feature/AmazingFeature`)
5. Pull Requestを作成

## 📝 ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 📞 サポート

問題や質問がある場合は、[Issues](../../issues) を作成してください。