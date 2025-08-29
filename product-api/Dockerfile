FROM openjdk:17-jdk-slim

# 必要なパッケージのインストール（curl for health checks, sqlite3 for debugging）
RUN apt-get update && \
    apt-get install -y curl sqlite3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Maven Wrapperと設定ファイルをコピー
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# 実行権限付与と依存関係ダウンロード
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# ソースコードをコピー
COPY src src

# アプリケーションビルド
RUN ./mvnw clean package -DskipTests

# JARファイルを実行用に移動
RUN mv target/*.jar app.jar

# SQLiteデータベースファイルをコンテナにコピー
# 重要: このファイルがコンテナに埋め込まれる
COPY src/main/resources/data/products.db /app/data/products.db

# データディレクトリの作成と権限設定
RUN mkdir -p /app/data && \
    chmod 755 /app/data && \
    chmod 644 /app/data/products.db

# 不要ファイル削除（イメージサイズ最適化）
RUN rm -rf target .mvn src mvnw pom.xml

# 環境変数設定
ENV SPRING_PROFILES_ACTIVE=sqlite
ENV DB_PATH=/app/data/products.db

# ポート公開
EXPOSE 8080

# ヘルスチェック設定
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# SQLiteデータベースの存在確認（デバッグ用）
RUN echo "SQLite database check:" && \
    ls -la /app/data/ && \
    sqlite3 /app/data/products.db "SELECT COUNT(*) as product_count FROM products;"

# アプリケーション実行
ENTRYPOINT ["java", "-jar", "app.jar"]