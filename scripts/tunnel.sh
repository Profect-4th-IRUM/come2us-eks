#!/bin/bash
# scripts/tunnel.sh

REGION="ap-northeast-2"
CLUSTER_NAME="come2us-eks"
PROFILE="terraform"

BASTION_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=come2us-bastion" \
  --region $REGION \
  --profile $PROFILE \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

EKS_ENDPOINT=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile $PROFILE \
  --query "cluster.endpoint" \
  --output text | sed 's|https://||')

echo "Bastion: $BASTION_ID"
echo "EKS Endpoint: $EKS_ENDPOINT"
echo "Starting SSM tunnel on localhost:8443..."

aws ssm start-session \
  --target $BASTION_ID \
  --region $REGION \
  --profile $PROFILE \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{
    \"host\": [\"$EKS_ENDPOINT\"],
    \"portNumber\": [\"443\"],
    \"localPortNumber\": [\"8443\"]
  }"
