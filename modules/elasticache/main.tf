resource "aws_elasticache_subnet_group" "come2us_cache_subnet" {
  name       = "${var.prefix}-cache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name    = "${var.prefix}-cache-subnet-group"
    Purpose = "cache"
  }
}


resource "aws_elasticache_cluster" "come2us_cache_redis" {
  cluster_id        = "${var.prefix}-cache-redis"
  engine            = "redis"
  engine_version    = var.engine_version
  node_type         = var.node_type
  num_cache_nodes   = 1
  port              = 6379
  availability_zone = var.azs[0]

  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.come2us_cache_subnet.name
  security_group_ids   = [var.sg_id]

  tags = {
    Name        = "${var.prefix}-cache"
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
    Purpose     = "cache"
  }
}

resource "aws_elasticache_subnet_group" "come2us_session_subnet" {
  name       = "${var.prefix}-session-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name    = "${var.prefix}-session-subnet-group"
    Purpose = "session/transient"
  }
}

resource "aws_elasticache_replication_group" "come2us_session_redis" {
  replication_group_id       = "${var.prefix}-session-redis"
  description                = "Session Redis for transient & session data"
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  replicas_per_node_group    = 1
  port                       = 6379
  multi_az_enabled           = true
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token

  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.come2us_session_subnet.name
  security_group_ids   = [var.sg_id]

  tags = {
    Name        = "${var.prefix}-session-redis"
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
    Purpose     = "session/transient"
  }
}
