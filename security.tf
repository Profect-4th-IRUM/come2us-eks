# EKS Control Plane에서 Istiod webhook으로의 통신 (15017 포트)
resource "aws_security_group_rule" "allow_istiod_webhook_from_control_plane" {
  security_group_id        = module.eks.node_security_group_id
  type                     = "ingress"
  from_port                = 15017
  to_port                  = 15017
  protocol                 = "tcp"
  description              = "Allow EKS Control Plane to Istiod webhook on 15017"
  source_security_group_id = module.eks.cluster_security_group_id
}

# Envoy 사이드카 통신 (15090 포트)
resource "aws_security_group_rule" "allow_istio_envoy_metrics" {
  security_group_id        = module.eks.node_security_group_id
  type                     = "ingress"
  from_port                = 15090
  to_port                  = 15090
  protocol                 = "tcp"
  description              = "Allow Istio Envoy metrics scraping"
  source_security_group_id = module.eks.node_security_group_id
}

# mTLS 통신 (15006, 15001 포트)
resource "aws_security_group_rule" "allow_istio_mtls" {
  security_group_id        = module.eks.node_security_group_id
  type                     = "ingress"
  from_port                = 15006
  to_port                  = 15006
  protocol                 = "tcp"
  description              = "Allow Istio mTLS inbound"
  source_security_group_id = module.eks.node_security_group_id
}

resource "aws_security_group_rule" "allow_bastion_to_eks_api" {
  security_group_id        = module.eks.cluster_security_group_id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Allow Bastion to access EKS API server"
  source_security_group_id = module.sg.bastion_sg_id
}