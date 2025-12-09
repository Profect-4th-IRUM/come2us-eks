output "bastion_sg_id" { value = aws_security_group.bastion_sg.id }
output "backend_sg_id" { value = aws_security_group.backend_sg.id }
output "alb_sg_id" { value = aws_security_group.alb_sg.id }
output "rds_sg_id" { value = aws_security_group.rds_sg.id }
output "redis_sg_id" { value = aws_security_group.redis_sg.id }
output "kafka_sg_id" { value = aws_security_group.kafka_sg.id  }