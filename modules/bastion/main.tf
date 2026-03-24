# SSM용 IAM Role
resource "aws_iam_role" "bastion_ssm_role" {
  name = "${var.prefix}-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_ssm_instance_profile" {
  name = "${var.prefix}-bastion-ssm-instance-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.sg_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion_ssm_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              set -eux
              apt-get update -y
              apt-get install -y htop vim

              # SSM Agent 설치
              snap install amazon-ssm-agent --classic
              systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
              systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

              echo "Bastion host ready" > /etc/motd
              EOF

  tags = {
    Name = "${var.prefix}-bastion"
  }
}
