resource "aws_msk_cluster" "this" {
  cluster_name           = var.cluster_name
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type = var.instance_type
    client_subnets = var.client_subnets
    storage_info {
      ebs_storage_info {
        volume_size = var.volume_size
      }
    }
    security_groups = var.security_groups
  }

  client_authentication {
    unauthenticated = true
  }


  lifecycle {
    ignore_changes = [
      # 보안 관련 속성들 – 변경이 없을 때 굳이 UpdateSecurity 안 치게 하기
      client_authentication,
      encryption_info,
      # 필요시 kafka_version_minor_version, configuration_info 등도 추가 가능
    ]
  }

    tags = {
    project = "come2us"
  }
}
