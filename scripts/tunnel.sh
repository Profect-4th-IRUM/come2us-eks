#!/bin/bash
# scripts/tunnel.sh

REGION="ap-northeast-2"
CLUSTER_NAME="come2us-eks"
PROFILE="terraform"
LOCAL_PORT="8443"

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
  }" &

TUNNEL_PID=$!
echo "Tunnel PID: $TUNNEL_PID"

# 터널 대기
echo "Waiting for tunnel to be ready..."
for i in $(seq 1 15); do
  if nc -z localhost $LOCAL_PORT 2>/dev/null; then
    echo "Tunnel is ready"
    break
  fi
  if [ $i -eq 15 ]; then
    echo "Tunnel failed to open"
    kill $TUNNEL_PID
    exit 1
  fi
  sleep 1
done

# kubeconfig 설정
echo "Configuring kubeconfig..."
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $REGION \
  --profile $PROFILE

CLUSTER_ARN="arn:aws:eks:${REGION}:$(aws sts get-caller-identity \
  --profile $PROFILE \
  --query Account \
  --output text):cluster/${CLUSTER_NAME}"

kubectl config set-cluster $CLUSTER_ARN \
  --server=https://localhost:${LOCAL_PORT} \
  --tls-server-name=$EKS_ENDPOINT

echo "Done. kubectl is ready."
echo "To close tunnel: kill $TUNNEL_PID"
