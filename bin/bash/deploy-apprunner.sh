# deploy-apprunner.sh - App Runner構成でのデプロイスクリプト
set -e

echo "🐳 === App Runner + コンテナ構成デプロイ開始 ==="

# 変数設定
APP_NAME="product-management-app"
SERVICE_NAME="product-api-service"
REGION="ap-northeast-1"
S3_BUCKET="product-management-frontend-$(date +%s)"
ECR_REPO="product-api"

# AWSアカウントID取得
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO"

echo "📋 設定情報:"
echo "  Account ID: $ACCOUNT_ID"
echo "  Region: $REGION"
echo "  ECR URI: $ECR_URI"

# Phase 1: RDS作成
echo "🗄️ Phase 1: RDS データベース作成..."
if ! aws rds describe-db-instances --db-instance-identifier product-db --region $REGION > /dev/null 2>&1; then
    echo "RDS インスタンスを作成中..."
    aws rds create-db-instance \
        --db-instance-identifier product-db \
        --db-instance-class db.t3.micro \
        --engine mysql \
        --engine-version 8.0.35 \
        --master-username admin \
        --master-user-password ProductDB123! \
        --allocated-storage 20 \
        --publicly-accessible \
        --storage-encrypted \
        --backup-retention-period 7 \
        --region $REGION \
        --tags Key=Project,Value=ProductManagement
    
    echo "⏳ RDS作成完了を待機中（約10分）..."
    aws rds wait db-instance-available --db-instance-identifier product-db --region $REGION
    echo "✅ RDS作成完了"
else
    echo "✅ RDS インスタンスは既に存在します"
fi

# RDS エンドポイント取得
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier product-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text --region $REGION)
echo "📍 RDS Endpoint: $RDS_ENDPOINT"

# Phase 2: ECR リポジトリ作成
echo "🏗️ Phase 2: ECR リポジトリ作成..."
if ! aws ecr describe-repositories --repository-names $ECR_REPO --region $REGION > /dev/null 2>&1; then
    echo "ECR リポジトリを作成中..."
    aws ecr create-repository \
        --repository-name $ECR_REPO \
        --region $REGION \
        --tags Key=Project,Value=ProductManagement
    echo "✅ ECR リポジトリ作成完了"
else
    echo "✅ ECR リポジトリは既に存在します"
fi

# Phase 3: Docker イメージビルドとプッシュ
echo "🐳 Phase 3: Docker イメージビルドとプッシュ..."
cd product-api

# ECR ログイン
echo "ECR にログイン中..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

# Docker イメージビルド
echo "Docker イメージをビルド中..."
docker build -t $ECR_REPO .

# タグ付け
docker tag $ECR_REPO:latest $ECR_URI:latest

# ECR にプッシュ
echo "ECR にプッシュ中..."
docker push $ECR_URI:latest

echo "✅ Docker イメージプッシュ完了"
echo "📦 Image URI: $ECR_URI:latest"

cd ..

# Phase 4: App Runner サービス作成
echo "🚀 Phase 4: App Runner サービス作成..."

# IAM ロール作成（App Runner用）
if ! aws iam get-role --role-name AppRunnerECRAccessRole > /dev/null 2>&1; then
    echo "App Runner用IAMロールを作成中..."
    
    # Trust policy
    cat > apprunner-trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "build.apprunner.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

    aws iam create-role \
        --role-name AppRunnerECRAccessRole \
        --assume-role-policy-document file://apprunner-trust-policy.json

    aws iam attach-role-policy \
        --role-name AppRunnerECRAccessRole \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess

    rm apprunner-trust-policy.json
    echo "✅ IAMロール作成完了"
fi

# App Runner サービス設定
cat > apprunner-service-config.json << EOF
{
    "ServiceName": "$SERVICE_NAME",
    "SourceConfiguration": {
        "ImageRepository": {
            "ImageIdentifier": "$ECR_URI:latest",
            "ImageConfiguration": {
                "Port": "8080",
                "RuntimeEnvironmentVariables": {
                    "SPRING_PROFILES_ACTIVE": "prod",
                    "RDS_HOSTNAME": "$RDS_ENDPOINT",
                    "RDS_PORT": "3306",
                    "RDS_DB_NAME": "productdb",
                    "RDS_USERNAME": "admin",
                    "RDS_PASSWORD": "ProductDB123!",
                    "CORS_ALLOWED_ORIGINS": "https://*.amazonaws.com,https://*.cloudfront.net"
                }
            },
            "ImageRepositoryType": "ECR"
        },
        "AccessRoleArn": "arn:aws:iam::$ACCOUNT_ID:role/AppRunnerECRAccessRole"
    },
    "InstanceConfiguration": {
        "Cpu": "0.25 vCPU",
        "Memory": "0.5 GB"
    },
    "Tags": [
        {
            "Key": "Project",
            "Value": "ProductManagement"
        }
    ]
}
EOF

# App Runner サービス作成または更新
if aws apprunner describe-service --service-arn "arn:aws:apprunner:$REGION:$ACCOUNT_ID:service/$SERVICE_NAME" > /dev/null 2>&1; then
    echo "既存のApp Runnerサービスを更新中..."
    aws apprunner start-deployment \
        --service-arn "arn:aws:apprunner:$REGION:$ACCOUNT_ID:service/$SERVICE_NAME" \
        --region $REGION
else
    echo "App Runner サービスを作成中..."
    aws apprunner create-service \
        --cli-input-json file://apprunner-service-config.json \
        --region $REGION
fi

rm apprunner-service-config.json

echo "⏳ App Runner サービス起動を待機中..."
sleep 60  # 初期起動時間

# サービスURL取得
SERVICE_URL=$(aws apprunner describe-service \
    --service-arn "arn:aws:apprunner:$REGION:$ACCOUNT_ID:service/$SERVICE_NAME" \
    --query 'Service.ServiceUrl' \
    --output text --region $REGION)

echo "✅ App Runner サービス作成完了"
echo "🌐 Service URL: https://$SERVICE_URL"

# Phase 5: React アプリケーションのビルドとS3デプロイ
echo "⚛️ Phase 5: React アプリケーションのデプロイ..."
cd product-frontend

# API URLを環境変数に設定
export REACT_APP_API_URL="https://$SERVICE_URL/api"
echo "📡 React API URL: $REACT_APP_API_URL"

# プロダクションビルド
echo "React アプリケーションをビルド中..."
npm run build

# S3バケット作成
echo "S3バケットを作成中..."
aws s3 mb s3://$S3_BUCKET --region $REGION

# S3バケットをウェブサイトとして設定
aws s3 website s3://$S3_BUCKET \
    --index-document index.html \
    --error-document index.html

# バケットポリシー設定
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$S3_BUCKET/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket $S3_BUCKET --policy file://bucket-policy.json
rm bucket-policy.json

# ファイルアップロード
echo "S3にファイルをアップロード中..."
aws s3 sync build/ s3://$S3_BUCKET --delete

S3_WEBSITE_URL="http://$S3_BUCKET.s3-website-$REGION.amazonaws.com"

echo "✅ React アプリケーションデプロイ完了"
echo "🌐 Frontend URL: $S3_WEBSITE_URL"

cd ..

echo ""
echo "🎉 === App Runner デプロイ完了 ==="
echo "📊 構成情報:"
echo "  🔧 Architecture: App Runner + RDS + S3"
echo "  💰 月額費用: 約 $26.49"
echo "  🌐 Backend API: https://$SERVICE_URL/api"
echo "  🌐 Frontend: $S3_WEBSITE_URL"
echo "  🗄️ Database: $RDS_ENDPOINT"
echo ""
echo "🔗 確認URL:"
echo "  ✅ Health Check: https://$SERVICE_URL/actuator/health"
echo "  📦 Products API: https://$SERVICE_URL/api/products"
echo ""
echo "📝 次のステップ (オプション):"
echo "  1. CloudFront設定でHTTPS化とキャッシュ最適化"
echo "  2. Route 53でカスタムドメイン設定"
echo "  3. App Runnerのカスタムドメイン設定"
echo "  4. RDSセキュリティグループの最適化"