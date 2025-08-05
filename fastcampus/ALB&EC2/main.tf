terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "demo-vpc"
  cidr   = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_security_group" "demo_alb_sg" {
  name        = "demo-alb-sg"
  description = "demo-alb-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "demo_ec2_sg" {
  name        = "demo-ec2-sg"
  description = "demo-ec2-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.demo_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "demo_ec2" {
  for_each               = toset(["1", "2"])
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[tonumber(each.key) % length(module.vpc.private_subnets)]
  vpc_security_group_ids = [aws_security_group.demo_ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update
              apt install -y nginx
              systemctl start nginx
              systemctl enable nginx
            EOF

  tags = {
    Name = "demo-ec2"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }
}

resource "aws_lb_target_group" "demo_tg_80" {
  name     = "demo-tg-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "demo_alb_tg_attachment" {
  for_each         = aws_instance.demo_ec2
  target_group_arn = aws_lb_target_group.demo_tg_80.arn
  target_id        = each.value.id
  port             = 80
  depends_on       = [aws_instance.demo_ec2, aws_lb_target_group.demo_tg_80]
}

resource "aws_lb" "demo_alb" {
  name     = "demo-alb"
  internal = false

  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.demo_alb_sg.id]

  tags = {
    Name = "demo-alb"
  }
}

resource "aws_lb_listener" "demo_listener" {
  load_balancer_arn = aws_lb.demo_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = 403
    }
  }
}

resource "aws_lb_listener_rule" "demo_listener_rule" {
  listener_arn = aws_lb_listener.demo_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo_tg_80.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
