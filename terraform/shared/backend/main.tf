################################################################################
# Shared Backend Bootstrap — S3 + DynamoDB
# Run ONCE before any environment to create the remote state infrastructure.
# After applying: update backend configs in envs/*/main.tf with bucket name.
################################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # NOTE: Local state intentionally — this is the bootstrap, nothing to lock.
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = var.state_bucket_name
  table_name  = var.state_lock_table_name
}

# ─── S3 Bucket for Terraform State ───────────────────────────────────────────

resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = local.bucket_name
    Purpose   = "terraform-state"
    Project   = "zezcloud"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ─── DynamoDB Table for State Locking ─────────────────────────────────────────

resource "aws_dynamodb_table" "lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST" # Free Tier: 25 WCU + 25 RCU
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = local.table_name
    Purpose   = "terraform-state-lock"
    Project   = "zezcloud"
    ManagedBy = "terraform"
  }
}

# ─── GitHub OIDC Provider ─────────────────────────────────────────────────────
# Created once per AWS account. Allows GitHub Actions to assume IAM roles
# without storing long-lived AWS credentials in GitHub Secrets.

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint — rotate when GitHub rotates their cert.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name      = "github-actions-oidc"
    Project   = "zezcloud"
    ManagedBy = "terraform"
  }
}
