#!/bin/bash
# debug-ec2.sh - EC2作成問題の診断と修正

set -e

echo "🔍 EC2作成問題を診断中..."

# 1. 現在のリージョン確認
echo "📍 現在のリージョン:"
aws configure get region

# 2. 無料枠対象インスタンスタイプを正確に確認
echo ""
echo "💰 無料枠対象インスタンスタイプの詳細:"
aws ec2 describe-instance-types \
    --filters "Name=free-tier-eligible,Values=true" \
    --query 'InstanceTypes[*].[InstanceType,FreeTierEligible]' \
    --output table

# 3. t2.microが利用可能か確認
echo ""
echo "🔍 t2.microの詳細確認:"
aws ec2 describe-instance-types \
    --instance-types t2.micro \
    --query 'InstanceTypes[*].[InstanceType,FreeTierEligible,CurrentGeneration]' \
    --output table

# 4. 利用可能なアベイラビリティゾーン確認
echo ""
echo "🌏 利用可能なアベイラビリティゾーン:"
aws ec2 describe-availability-zones \
    --query 'AvailabilityZones[*].[ZoneName,State]' \
    --output table

# 5. デフォルトVPC確認
echo ""
echo "🌐 デフォルトVPC確認:"
DEFAULT_VPC=$(aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query 'Vpcs[0].VpcId' \
    --output text)

if [ "$DEFAULT_VPC" != "None" ] && [ "$DEFAULT_VPC" != "null" ]; then
    echo "✅ デフォルトVPC: $DEFAULT_VPC"
else
    echo "⚠️ デフォルトVPCが見つかりません"
fi

# 6. 修正版EC2作成（明示的にt2.microを指定）
echo ""
echo "🚀 修正版EC2インスタンス作成開始..."

# AMI ID再取得
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

# EC2インスタンス作成（詳細なパラメータ指定）
echo "🚀 EC2インスタンス作成実行中..."
echo "Instance Type: t2.micro"
echo "AMI: $AMI_ID"
echo "Security Group: $SG_ID"

INSTANCE_RESULT=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "t2.micro" \
    --key-name "test-keypair" \
    --security-group-ids "$SG_ID" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-instance-v2},{Key=Purpose,Value=learning}]' \
    --no-associate-public-ip-address false)

INSTANCE_ID=$(echo "$INSTANCE_RESULT" | jq -r '.Instances[0].InstanceId')

echo "✅ EC2インスタンス作成成功!"
echo "📊 インスタンスID: $INSTANCE_ID"

# インスタンス起動待機
echo "⏳ インスタンス起動を待機中..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# 最終確認
echo ""
echo "📋 作成されたインスタンス情報:"
aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,InstanceType,PublicIpAddress]' \
    --output table

echo ""
echo "🎉 === EC2インスタンス作成成功 ==="
echo "💰 料金: 無料枠範囲内（t2.micro）"
echo "🔗 AWS Console: https://console.aws.amazon.com/ec2/"