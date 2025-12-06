############################
# ArgoCD Helm Release
############################
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm" # ✅ 공식 repo
  chart            = "argo-cd"
  version          = "5.45.0"

  namespace        = "argocd"
  create_namespace = true
  wait             = true         # 설치 완료까지 대기 (추천)

  values = [
    yamlencode({
      configs = {
        cm = {
          create = true
          # ArgoCD UI URL (외부 도메인 있으면 여기)
          url    = "https://argocd.come2us.store"
        }
      }

      server = {
        service = {
          # ArgoCD 서버를 바로 LoadBalancer 타입으로 노출
          type = "LoadBalancer"

          annotations = {
            # 인터넷에서 접근 가능하도록
            "service.beta.kubernetes.io/aws-load-balancer-scheme"   = "internet-facing"
            # NLB 사용
            "service.beta.kubernetes.io/aws-load-balancer-type"     = "nlb"
            # ACM 인증서 ARN (local.alb_acm_arn 은 바깥에서 정의되어 있어야 함)
            "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = var.alb_acm_arn
          }
        }
      }
    })
  ]
}


############################
# ArgoCD Service 정보 조회
############################
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }

  depends_on = [helm_release.argocd]
}

############################
# Output: LB Hostname
############################
output "argocd_server_hostname" {
  description = "ArgoCD server LoadBalancer hostname"
  value       = data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname
}
