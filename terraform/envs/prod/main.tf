################################################################################
# Prod Environment — Root Configuration
# Same modules as dev; tuned for reliability over dev iteration speed.
################################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "zezcloud-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "zezcloud-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = "prod"
      ManagedBy   = "terraform"
      Repository  = "zezcloud-zero"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  environment        = "prod"
  availability_zones = [data.aws_availability_zones.available.names[0]]

  docker_compose_content = templatefile("${path.module}/../../docker/docker-compose.yml", {
    db_name        = var.db_name
    db_user        = var.db_user
    db_password    = var.db_password
    app_domain     = var.app_domain
    spring_profile = local.environment
  })
}

module "networking" {
  source = "../../modules/networking"

  project              = var.project
  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = local.availability_zones
  enable_flow_logs     = true # Enabled in prod for audit trail
}

module "security" {
  source = "../../modules/security"

  project                  = var.project
  environment              = local.environment
  vpc_id                   = module.networking.vpc_id
  ssh_allowed_cidrs        = var.ssh_allowed_cidrs
  deploy_bucket_name       = var.state_bucket_name
  state_bucket_name        = var.state_bucket_name
  state_lock_table_name    = var.state_lock_table_name
  github_oidc_provider_arn = var.github_oidc_provider_arn
  github_repo              = var.github_repo
}

module "database" {
  source = "../../modules/database"

  project     = var.project
  environment = local.environment
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
}

module "compute" {
  source = "../../modules/compute"

  project                = var.project
  environment            = local.environment
  instance_type          = "t2.micro" # Free Tier
  public_key             = var.ec2_public_key
  public_subnet_id       = module.networking.public_subnet_ids[0]
  security_group_ids     = [module.security.ec2_security_group_id]
  iam_instance_profile   = module.security.ec2_instance_profile_name
  app_domain             = var.app_domain
  db_name                = var.db_name
  db_user                = var.db_user
  db_password            = var.db_password
  docker_compose_content = local.docker_compose_content

  depends_on = [module.database]
}

module "monitoring" {
  source = "../../modules/monitoring"

  project     = var.project
  environment = local.environment
  instance_id = module.compute.instance_id
  alert_email = var.alert_email
}
