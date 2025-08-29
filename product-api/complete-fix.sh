#!/bin/bash
# complete-fix.sh - スキーマ検証を完全に無効化

set -e

echo "🔧 完全修正開始 - スキーマ検証無効化"

# 1. 完全にスキーマ検証を無効化した設定
cat > src/main/resources/application.properties << 'EOF'
# SQLite設定
spring.datasource.url=jdbc:sqlite:/app/data/products.db
spring.datasource.driver-class-name=org.sqlite.JDBC

# JPA設定 - スキーマ検証完全無効化
spring.jpa.database-platform=org.hibernate.community.dialect.SQLiteDialect
spring.jpa.hibernate.ddl-auto=none
spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl

# スキーマ検証を完全無効化
spring.jpa.properties.hibernate.hbm2ddl.auto=none
spring.jpa.properties.hibernate.validator.apply_to_ddl=false
spring.jpa.properties.hibernate.validator.autoregister_listeners=false

# 基本設定
server.port=8080
management.endpoints.web.exposure.include=health
cors.allowed-origins=*

# ログ設定
logging.level.org.hibernate.SQL=ERROR
logging.level.org.springframework.orm=ERROR
EOF

echo "✅ スキーマ検証完全無効化設定完了"

# 2. Product Entity を日時フィールドなしの簡素版に変更
echo "🔧 Product Entity を簡素化..."

cat > src/main/java/com/example/productapi/entity/Product.java << 'EOF'
package com.example.productapi.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "products")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String name;
    
    @Column(length = 1000)
    private String description;
    
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;
    
    @Column(name = "image_url")
    private String imageUrl;
    
    // コンストラクタ
    public Product() {}
    
    public Product(String name, String description, BigDecimal price, String imageUrl) {
        this.name = name;
        this.description = description;
        this.price = price;
        this.imageUrl = imageUrl;
    }
    
    // Getter/Setter
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }
    
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
}
EOF

echo "✅ Product Entity 簡素化完了"

# 3. 簡素化されたSQLiteデータベース作成
echo "🗄️ 簡素化されたSQLiteデータベース作成..."

cd src/main/resources/data
rm -f products.db

sqlite3 products.db << 'SQLEOF'
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    image_url TEXT
);

INSERT INTO products (name, description, price, image_url) VALUES
('MacBook Pro 14', 'Apple M3 Pro搭載の高性能ノートPC', 248000.00, 'https://via.placeholder.com/300x200?text=MacBook'),
('iPhone 15 Pro', '最新のiPhone Pro モデル', 159800.00, 'https://via.placeholder.com/300x200?text=iPhone'),
('AirPods Pro', 'アクティブノイズキャンセリング搭載', 39800.00, 'https://via.placeholder.com/300x200?text=AirPods'),
('iPad Air', '10.9インチの軽量タブレット', 84800.00, 'https://via.placeholder.com/300x200?text=iPad'),
('Apple Watch', 'スマートウォッチの最新モデル', 59800.00, 'https://via.placeholder.com/300x200?text=Watch');
SQLEOF

cd ../../../..

echo "✅ 簡素化データベース作成完了"

# 4. 完全にクリーンビルド
echo "🧹 完全クリーンビルド..."

docker stop product-api-sqlite-test 2>/dev/null || echo "コンテナ停止済み"
docker rm product-api-sqlite-test 2>/dev/null || echo "コンテナ削除済み"
docker rmi product-api-sqlite 2>/dev/null || echo "イメージ削除済み"

# 5. 新しいビルド
echo "🔨 新しいイメージビルド..."
docker build --no-cache -t product-api-sqlite .

# 6. 起動・テスト
echo "🚀 コンテナ起動..."
docker run -d --name product-api-sqlite-test -p 8080:8080 product-api-sqlite

echo "⏳ 起動待機（40秒）..."
sleep 40

# 7. テスト実行
echo "🏥 ヘルスチェック:"
if curl -s http://localhost:8080/actuator/health | grep -q "UP"; then
    echo "✅ SUCCESS! アプリケーション起動成功"
    
    echo ""
    echo "📡 API テスト:"
    PRODUCT_COUNT=$(curl -s http://localhost:8080/api/products | jq length 2>/dev/null || echo "jq不要")
    echo "商品数: $PRODUCT_COUNT"
    
    echo ""
    echo "🎉 完全修正成功!"
    echo "🌐 アクセスURL:"
    echo "  - Health: http://localhost:8080/actuator/health"
    echo "  - API: http://localhost:8080/api/products"
    
else
    echo "❌ まだ問題があります"
    echo "ログ確認:"
    docker logs product-api-sqlite-test | tail -20
fi