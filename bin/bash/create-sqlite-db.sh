#!/bin/bash
# create-sqlite-db.sh - SQLiteデータベース作成

set -e

echo "🗄️ SQLiteデータベース作成開始"

# 現在のディレクトリ確認
echo "📁 現在のディレクトリ: $(pwd)"

# データディレクトリに移動
cd product-api/src/main/resources/data 2>/dev/null || {
    echo "📁 ディレクトリを作成して移動します..."
    mkdir -p product-api/src/main/resources/data
    cd product-api/src/main/resources/data
}

echo "📁 データディレクトリ: $(pwd)"

# 既存のDBファイル削除
if [ -f "products.db" ]; then
    echo "🗑️ 既存のproducts.dbを削除"
    rm products.db
fi

# SQLiteデータベース作成
echo "🔨 SQLiteデータベース作成中..."

sqlite3 products.db << 'EOF'
-- テーブル作成
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    image_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 初期データ投入
INSERT INTO products (name, description, price, image_url) VALUES
('MacBook Pro 14', 'Apple M3 Pro搭載の高性能ノートPC', 248000.00, 'https://via.placeholder.com/300x200?text=MacBook+Pro+14'),
('iPhone 15 Pro', '最新のiPhone Pro モデル', 159800.00, 'https://via.placeholder.com/300x200?text=iPhone+15+Pro'),
('AirPods Pro', 'アクティブノイズキャンセリング搭載', 39800.00, 'https://via.placeholder.com/300x200?text=AirPods+Pro'),
('iPad Air', '10.9インチの軽量タブレット', 84800.00, 'https://via.placeholder.com/300x200?text=iPad+Air'),
('Apple Watch Series 9', 'スマートウォッチの最新モデル', 59800.00, 'https://via.placeholder.com/300x200?text=Apple+Watch'),
('Magic Keyboard', 'iPad用のキーボード', 34800.00, 'https://via.placeholder.com/300x200?text=Magic+Keyboard'),
('Apple Pencil', 'iPad用のスタイラスペン', 15950.00, 'https://via.placeholder.com/300x200?text=Apple+Pencil'),
('HomePod mini', 'コンパクトなスマートスピーカー', 11800.00, 'https://via.placeholder.com/300x200?text=HomePod+mini');

-- データ確認
.headers on
.mode column
SELECT 'データ投入確認:' as status;
SELECT COUNT(*) as total_products FROM products;
SELECT id, name, price FROM products LIMIT 3;
EOF

echo "✅ SQLiteデータベース作成完了"

# ファイル情報確認
echo "📊 ファイル情報:"
ls -la products.db

# SQLiteバージョン確認
echo "📋 SQLite情報:"
sqlite3 products.db "SELECT sqlite_version() as sqlite_version;"

# データ件数確認
PRODUCT_COUNT=$(sqlite3 products.db "SELECT COUNT(*) FROM products;")
echo "📦 商品データ件数: $PRODUCT_COUNT件"

echo ""
echo "🎉 SQLiteデータベース準備完了！"
echo "📁 ファイル位置: $(pwd)/products.db"
echo ""
echo "🔄 次のステップ:"
echo "1. Spring Boot設定をSQLite用に変更"
echo "2. pom.xmlの依存関係更新"
echo "3. Dockerfile更新"