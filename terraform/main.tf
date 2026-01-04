locals {
  vpc_cidr = "10.20.0.0/16"

  az_a = "eu-west-2a"
  az_b = "eu-west-2b"

  public1_cidr  = "10.20.0.0/20"
  public2_cidr  = "10.20.16.0/20"
  private1_cidr = "10.20.128.0/20"
  private2_cidr = "10.20.144.0/20"
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "prod_main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_prefix}-vpc"
  }
}

# -------------------------
# Subnets
# -------------------------
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.prod_main.id
  cidr_block              = local.public1_cidr
  availability_zone       = local.az_a
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_prefix}-subnet-public1-eu-west-2a"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.prod_main.id
  cidr_block              = local.public2_cidr
  availability_zone       = local.az_b
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_prefix}-subnet-public2-eu-west-2b"
  }
}

resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.prod_main.id
  cidr_block              = local.private1_cidr
  availability_zone       = local.az_a
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_prefix}-subnet-private1-eu-west-2a"
  }
}

resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.prod_main.id
  cidr_block              = local.private2_cidr
  availability_zone       = local.az_b
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_prefix}-subnet-private2-eu-west-2b"
  }
}

# -------------------------
# Internet Gateway (public subnets only)
# -------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod_main.id

  tags = {
    Name = "${var.project_prefix}-igw"
  }
}

# -------------------------
# Route tables
# -------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.prod_main.id

  tags = {
    Name = "${var.project_prefix}-rtb-public"
  }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public1_assoc" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2_assoc" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# Private route tables (NO NAT: local-only)
resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.prod_main.id

  tags = {
    Name = "${var.project_prefix}-rtb-private1-eu-west-2a"
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.prod_main.id

  tags = {
    Name = "${var.project_prefix}-rtb-private2-eu-west-2b"
  }
}

resource "aws_route_table_association" "private1_assoc" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private2_assoc" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

# -------------------------
# Security Groups
# -------------------------
resource "aws_security_group" "sg_private_ec2" {
  name        = "prod-private-app"
  description = "Private EC2 - no inbound"
  vpc_id      = aws_vpc.prod_main.id

  egress {
    description = "Allow all outbound (recommended for now)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-prod-private-app"
  }
}

resource "aws_security_group" "sg_vpce" {
  name        = "vpce-ssm"
  description = "SG for SSM interface endpoints"
  vpc_id      = aws_vpc.prod_main.id

  ingress {
    description     = "HTTPS from private EC2 SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_private_ec2.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpce-ssm"
  }
}

# -------------------------
# Interface VPC Endpoints (SSM trio) - PRIVATE subnets
# -------------------------
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.prod_main.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ssm"
  subnet_ids          = [aws_subnet.private1.id, aws_subnet.private2.id]
  security_group_ids  = [aws_security_group.sg_vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_prefix}-vpce-ssm"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.prod_main.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  subnet_ids          = [aws_subnet.private1.id, aws_subnet.private2.id]
  security_group_ids  = [aws_security_group.sg_vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_prefix}-vpce-ec2messages"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.prod_main.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  subnet_ids          = [aws_subnet.private1.id, aws_subnet.private2.id]
  security_group_ids  = [aws_security_group.sg_vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_prefix}-vpce-ssmmessages"
  }
}

# -------------------------
# IAM Role + Instance Profile for SSM
# -------------------------
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role_ec2_ssm" {
  name               = "role-prod-ec2-ssm"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.role_ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "role-prod-ec2-ssm"
  role = aws_iam_role.role_ec2_ssm.name
}

# -------------------------
# EC2 (Private, no public IP)
# -------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "private_ec2" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private1.id
  vpc_security_group_ids      = [aws_security_group.sg_private_ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              systemctl enable --now amazon-ssm-agent
              EOF

  tags = {
    Name = "${var.project_prefix}-ec2-private-1"
  }

  depends_on = [
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ec2messages,
    aws_vpc_endpoint.ssmmessages
  ]
}
