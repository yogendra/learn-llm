terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
variable "region" {
  default = "ap-southeast-1"
}
variable "zone" {
  default = "ap-southeast-1a"
}
variable "name_prefix" {
  default = "cohr"
}

variable "private_key_filename" {
  default = "~/.ssh/id_rsa"
}
variables "tags" {
  default = {
    "yb_dept"  = "sales"
    "yb_task"  = "cohr-demo"
    "yb_owner" = "yrampuria" # Replace with the actual owner
  }
}
variable "vpc_name"{
  default = "shr-ap-southeast-1"
}
variable "subnet_name" {
  default = "shr-pub-ap-southeast-1a"
}
variable "iam_role_name" {
  default = "shr-YBAInstanceProfile"
}
variable "keypair_name"{
  default = "shr-0"
}
variable "sg_name"{
  default = "shr-default"
}
variable "hosted_zone_name"{
  default = "apj.yugabyte.com"
}

# Local Variables
locals {
  region      = var.region
  zone        = var.zone
  name_prefix = var.name_prefix
  private_key_filename = var.private_key_filename


  tags = var.tags
  vpc_name = var.vpc_name
  subnet_name = var.subnet_name
  hosted_zone_name = var.hosted_zone_name
  keypair_name = var.keypair_name
  sg_name = var.sg_name
  iam_role_name = var.iam_role_name

  dns_suffix      = "${local.name_prefix}.demo.${local.hosted_zone_name}"
  vpc_id = data.aws_vpc.selected.id
  subnet = data.aws_subnets.selected.ids[0]
  security_group_ids = [data.aws_security_group.selected.id]
  hosted_zone_id  = data.aws_route53_zone.selected.zone_id # Replace with your actual Route53 hosted zone ID
}
# AWS Provider Configuration
provider "aws" {
  region = local.region

  default_tags {
    tags = local.tags
  }
}

data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"
    values = [ local.vpc_name ]
  }
}
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  filter {
    name = "tag:Name"
    values = [local.subnet_name]

  }
}
data "aws_route53_zone" "selected" {
  name         = "${local.hosted_zone_name}."
}
data "aws_security_group" "selected"{
  tags = {
    Name = local.sg_name
  }
}
# Data Source for Ubuntu AMI (Latest 22.04 LTS)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
data "aws_iam_instance_profile" "selected" {
  name = local.iam_role_name
}

# EC2 Instance YBA (VM)
resource "aws_instance" "oracle_vm" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.xlarge"
  subnet_id     = local.subnet
  iam_instance_profile = data.aws_iam_instance_profile.selected.name
  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }
  key_name        = local.keypair_name
  user_data = <<EOF
#!/bin/bash
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu
docker pull container-registry.oracle.com/database/free:latest
EOF
  tags = {
    Name = "${local.name_prefix}-oracle"
  }
}

resource "aws_route53_record" "oracle_dns" {
  zone_id = local.hosted_zone_id
  name    = "oracle-${local.dns_suffix}"
  type    = "A"

  records = [aws_instance.oracle_vm.private_ip] # Point to the EIP's public IP address
  ttl     = 300
}

resource "local_file" "ssh_config"{
  file_permission = "0600"
  filename = "/Users/yrampuria/.ssh/configs/temp-${local.name_prefix}"
  content = <<EOF
Host ${local.name_prefix}-oracle
  HostName ${aws_route53_record.oracle_dns.fqdn}
  User ubuntu
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentityFile ${local.private_key_filename}
EOF
}

output "info" {
  value = <<EOF
ssh ${local.name_prefix}-oracle
EOF
}
