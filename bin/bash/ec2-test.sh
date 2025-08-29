set -e

echo "🎯 最終修正版 EC2インスタンス作成開始"

# AMI ID取得
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*" \
              "Name=architecture,Values=x86_64" \
              "Name=virtualization-type,Values=hvm" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

echo "🔍 使用するAMI: $AMI_ID"

# セキュリティグループID取得
SG_ID=$(aws ec2 describe-security-groups \
    --group-names test-sg \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

echo "🆔 セキュリティグループID: $SG_ID"

# EC2インスタンス作成（t3.microを使用 - 無料枠対象）
echo "🚀 EC2インスタンス作成中..."
echo "  - インスタンスタイプ: t3.micro（無料枠対象）"
echo "  - AMI: $AMI_ID"
echo "  - セキュリティグループ: $SG_ID"

INSTANCE_RESULT=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "t3.micro" \
    --key-name "test-keypair" \
    --security-group-ids "$SG_ID" \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-instance-final},{Key=Purpose,Value=learning}]')

INSTANCE_ID=$(echo "$INSTANCE_RESULT" | jq -r '.Instances[0].InstanceId')

echo "✅ EC2インスタンス作成成功!"
echo "📊 インスタンスID: $INSTANCE_ID"

# インスタンス起動待機
echo "⏳ インスタンス起動を待機中（約30秒）..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# インスタンス情報取得
INSTANCE_INFO=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0]')

PUBLIC_IP=$(echo "$INSTANCE_INFO" | jq -r '.PublicIpAddress // "None"')
PRIVATE_IP=$(echo "$INSTANCE_INFO" | jq -r '.PrivateIpAddress // "None"')
STATE=$(echo "$INSTANCE_INFO" | jq -r '.State.Name')

echo ""
echo "🎉 === EC2インスタンス作成完了 ==="
echo "📋 インスタンス情報:"
echo "  🆔 インスタンスID: $INSTANCE_ID"
echo "  🖥️ インスタンスタイプ: t3.micro"
echo "  🌐 パブリックIP: $PUBLIC_IP"
echo "  🏠 プライベートIP: $PRIVATE_IP"
echo "  📊 状態: $STATE"
echo ""
echo "💰 料金: 無料枠範囲内（t3.micro 750時間/月）"
echo "🔗 AWS Console: https://console.aws.amazon.com/ec2/v2/home?region=ap-northeast-1#Instances:"
echo ""

if [ "$PUBLIC_IP" != "None" ] && [ "$PUBLIC_IP" != "null" ]; then
    echo "🔌 SSH接続方法:"
    echo "ssh -i test-keypair.pem ec2-user@$PUBLIC_IP"
    echo ""
fi