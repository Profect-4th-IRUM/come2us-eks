#!/bin/bash

set -e

CLUSTER_NAME=$(terraform output -raw cluster_name)
ALB_ROLE_ARN=$(terraform output -raw alb_controller_irsa_role_arn)
ACM_ARN=$(terraform output -raw acm_certificate_arn)
REGION="ap-northeast-2"
PROFILE="terraform"
PREFIX="come2us"

echo "=== Istalling ALB Controller ==="

# 재설치 시 충돌 방지
kubectl delete secret aws-load-balancer-tls -n kube-system --ignore-not-found
kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook --ignore-not-found
kubectl delete mutatingwebhookconfiguration aws-load-balancer-webhook --ignore-not-found

kubectl create serviceaccount aws-load-balancer-controller \
  -n kube-system \
  --dry-run=client -o yaml | kubectl apply -f -

# IRSA annotaion
kubectl annotate serviceaccount aws-load-balancer-controller \
  -n kube-system \
  eks.amazonaws.com/role-arn=${ALB_ROLE_ARN} \
  --overwrite

# Helm 설치
helm repo add eks https://aws.github.io/eks-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set nodeSelector.node_type=infra \
  --set "tolerations[0].key=node_type" \
  --set "tolerations[0].operator=Equal" \
  --set "tolerations[0].value=infra" \
  --set "tolerations[0].effect=NoSchedule" \
  --wait

echo "=== Installing ArcoCD ==="

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install argocd argo/argo-cd \
  -n argocd \
  -f manifests/bootstrap/argocd/values.yaml \
  --set "server.ingress.annotations.alb\.ingress\.kubernetes\.io/certificate-arn=${ACM_ARN}" \
  --wait

echo "=== Registering Apps ==="

kubectl apply -f manifests/bootstrap/namespaces.yaml
kubectl apply -f manifests/bootstrap/projects.yaml
kubectl apply -f manifests/bootstarp/root-app.yaml

echo "=== Done ==="
