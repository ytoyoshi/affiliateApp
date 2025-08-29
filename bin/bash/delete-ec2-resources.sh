#!/bin/bash
# delete-ec2-resources.sh - EC2リソース削除スクリプト

set -e

echo "🗑️ EC2リソース削除開始"

# 1. 現在のインスタンス確認
echo "📋 現在のテストインスタンスを確認中..."
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=test-instance-final" \
              "Name=instance-state-name,Values=running,pending,stopping,stopped" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress]' \
    --output table

# インスタンスIDを取得
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=test-instance-final" \
              "Name=instance-state-name,Values=running,pending,stopping,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text)

if [ -z "$INSTANCE_IDS" ] || [ "$INSTANCE_IDS" = "None" ]; then
    echo "ℹ️ 削除対象のインスタンスはありません"
else
    echo "🔍 削除対象インスタンス: $INSTANCE_IDS"
    
    # 2. インスタンス削除実行
    echo "🗑️ インスタンス削除を実行中..."
    for INSTANCE_ID in $INSTANCE_IDS; do
        echo "  - 削除中: $INSTANCE_ID"
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID
    done
    
    # 3. 削除完了待機
    echo "⏳ インスタンス削除完了を待機中（最大5分）..."
    for INSTANCE_ID in $INSTANCE_IDS; do
        echo "  - 待機中: $INSTANCE_ID"
        aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
    done
    echo "✅ インスタンス削除完了"
fi

# 4. セキュリティグループ削除
echo "🛡️ セキュリティグループ削除中..."
if aws ec2 describe-security-groups --group-names test-sg >/dev/null 2>&1; then
    SG_ID=$(aws ec2 describe-security-groups \
        --group-names test-sg \
        --query 'SecurityGroups[0].GroupId' \
        --output text)
    
    echo "🗑️ セキュリティグループ削除: $SG_ID"
    aws ec2 delete-security-group --group-id $SG_ID
    echo "✅ セキュリティグループ削除完了"
else
    echo "ℹ️ 削除対象のセキュリティグループはありません"
fi

# 5. キーペア削除
echo "🔑 キーペア削除中..."
if aws ec2 describe-key-pairs --key-names test-keypair >/dev/null 2>&1; then
    echo "🗑️ AWS側キーペア削除中..."
    aws ec2 delete-key-pair --key-name test-keypair
    echo "✅ AWS側キーペア削除完了"
else
    echo "ℹ️ 削除対象のキーペアはありません"
fi

# ローカルキーファイル削除
if [ -f "test-keypair.pem" ]; then
    echo "🗑️ ローカルキーファイル削除中..."
    rm test-keypair.pem
    echo "✅ ローカルキーファイル削除完了"
else
    echo "ℹ️ ローカルキーファイルは存在しません"
fi

# 6. 削除確認
echo ""
echo "🔍 削除確認中..."
echo "📊 残存インスタンス:"
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=test-instance-final" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
    --output table