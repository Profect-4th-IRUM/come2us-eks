resource "aws_db_subnet_group" "come2us_db_subnet" {
  name       = "${var.prefix}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.prefix}-subnet-group"
  }
}

resource "aws_db_instance" "come2us_rds" {
  identifier        = "${var.prefix}-primary"
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp2"
  username          = var.username
  password          = var.password
  db_name           = var.db_name
  port              = var.port

  skip_final_snapshot        = true
  deletion_protection        = false
  multi_az                   = true # 프리티어는 multi_az 사용 불가
  publicly_accessible        = false
  storage_encrypted          = false
  auto_minor_version_upgrade = true
  backup_retention_period    = 1 # 프리티어는 1일이 최대

  vpc_security_group_ids = [var.sg_id]
  db_subnet_group_name   = aws_db_subnet_group.come2us_db_subnet.name

  tags = {
    Name        = "${var.prefix}-primary"
    Environment = "${var.environment}"
    ManagedBy   = "Terraform"
    Role        = "primary"
  }
}

resource "aws_db_instance" "come2us_rds_replica" {
  identifier                 = "${var.prefix}-replica"
  replicate_source_db        = aws_db_instance.come2us_rds.arn
  instance_class             = var.instance_class
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  skip_final_snapshot        = true

  depends_on = [aws_db_instance.come2us_rds]

  tags = {
    Name        = "${var.prefix}-replica"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Role        = "read-replica"
  }
}