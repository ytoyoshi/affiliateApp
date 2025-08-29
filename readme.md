# 商品管理システム

Spring Boot + React + TypeScript で構築された商品管理システムです。

## プロジェクト構成

```
affiliateApp/
├── product-api/          # Spring Boot バックエンド
├── product-frontend/     # React TypeScript フロントエンド
└── README.md
```

## 必要な環境

- **Java**: 17以上
- **Node.js**: 16以上
- **npm**: 8以上

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd affiliateApp
```

### 2. バックエンド（Spring Boot）のセットアップ

```bash
cd product-api

# 依存関係の確認とビルド
./mvnw clean install

# アプリケーション起動
./mvnw spring-boot:run
```

**バックエンドが正常に起動したことを確認:**
- ブラウザで http://localhost:8080/api/products にアクセス
- JSON形式で商品一覧が表示されること

### 3. フロントエンド（React TypeScript）のセットアップ

**新しいターミナル/コマンドプロンプトで実行:**

```bash
cd product-frontend

# 依存関係のインストール
npm install

# 開発サーバー起動
npm start
```

**フロントエンドが正常に起動したことを確認:**
- ブラウザで http://localhost:3000 が自動で開く
- 商品一覧ページが表示されること

## 起動確認

### 両方のサーバーが起動している状態

- **バックエンド**: http://localhost:8080
- **フロントエンド**: http://localhost:3000

### 機能確認

1. **商品一覧表示**: 8つの商品がカード形式で表示される
2. **商品検索**: 検索バーで「iPhone」「MacBook」等で絞り込み可能
3. **検索クリア**: クリアボタンで全商品表示に戻る

## API エンドポイント

| メソッド | エンドポイント | 説明 |
|---------|-------------|------|
| GET | `/api/products` | 全商品取得 |
| GET | `/api/products/{id}` | 商品詳細取得 |
| GET | `/api/products/search?keyword={keyword}` | 商品検索 |
| POST | `/api/products` | 商品作成 |
| PUT | `/api/products/{id}` | 商品更新 |
| DELETE | `/api/products/{id}` | 商品削除 |

## データベース確認

H2データベースのコンソールにアクセス可能:
- URL: http://localhost:8080/h2-console
- JDBC URL: `jdbc:h2:mem:testdb`
- Username: `sa`
- Password: (空白)

## トラブルシューティング

### バックエンドが起動しない場合

```bash
# ポート8080が使用中の場合、プロセスを確認
lsof -i :8080

# Javaバージョン確認
java --version

# プロジェクトの再ビルド
./mvnw clean install
```

### フロントエンドが起動しない場合

```bash
# Node.jsバージョン確認
node --version
npm --version

# node_modulesの再インストール
rm -rf node_modules package-lock.json
npm install

# キャッシュクリア
npm start -- --reset-cache
```

### CORS エラーが発生する場合

Spring Bootの`ProductController.java`で以下が設定されていることを確認:

```java
@CrossOrigin(origins = "*") // 開発用設定
```

## 開発モード

### ホットリロード

- **フロントエンド**: ファイル保存時に自動更新
- **バックエンド**: DevToolsにより自動再起動

### ログ確認

```bash
# バックエンドログ
./mvnw spring-boot:run

# フロントエンドログ
npm start
```

## 本番デプロイ準備

### フロントエンドビルド

```bash
cd product-frontend
npm run build
```

### バックエンドJAR作成

```bash
cd product-api
./mvnw clean package
```

## 技術スタック

### バックエンド
- **Spring Boot 3.5.x**
- **Spring Web**
- **Spring Data JPA**
- **H2 Database**
- **Java 17**

### フロントエンド
- **React 18**
- **TypeScript**
- **Axios** (HTTP通信)
- **Bootstrap 5** (UI)

## ライセンス

MIT License