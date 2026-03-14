terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ------------------
# VPC Module
# ------------------
module "vpc" {
  source = "./modules/vpc"

  region             = var.region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# ------------------
# RDS Module (Private Subnet)
# ------------------
module "rds" {
  source     = "./modules/rds"

  db_name    = var.db_name
  db_user    = var.db_username
  db_pass    = var.db_password
  db_subnet1 = module.vpc.private_subnet1
  db_subnet2 = module.vpc.private_subnet2
  db_sg      = module.vpc.db_sg
}

# ------------------
# App Tier EC2 (Private Subnet)
# ------------------
module "app_ec2" {
  source         = "./modules/ec2"
  subnet_id      = module.vpc.private_subnet1
  sg_id          = module.vpc.app_sg
  key_name       = "ubuntu"
  
  ami_id         = "ami-08eb150f611ca277f"
  instance_type  = "t3.micro"

  user_data_file = "${path.module}/app.sh"
  db_endpoint    = module.rds.db_endpoint
  db_username    = var.db_username
  db_password    = var.db_password
  instance_name  = "app-ec2"
}

# ------------------
# Web Tier EC2 (Public Subnet)
# ------------------
module "web_ec2" {
  source         = "./modules/ec2"
  subnet_id      = module.vpc.public_subnet[0]
  sg_id          = module.vpc.app_sg
  key_name       = "ubuntu"

  ami_id         = "ami-08eb150f611ca277f"
  instance_type  = "t3.micro"

  user_data_file = "${path.module}/web.sh"
  app_private_ip = module.app_ec2.private_ip
  instance_name  = "web-ec2"
  depends_on     = [module.app_ec2]
}
