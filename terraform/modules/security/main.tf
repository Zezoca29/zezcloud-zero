################################################################################
# Security Module — IAM Roles, Security Groups
################################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Module      = "security"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  })
}

# ─── Security Group: EC2 ──────────────────────────────────────────────────────

resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-sg-ec2"
  description = "Security group for EC2 application server"
  vpc_id      = var.vpc_id

  # HTTP — Cloudflare IP ranges only (not open to the world)
  ingress {
    description = "HTTP from Cloudflare"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cloudflare_ip_ranges
  }

  # HTTPS — Cloudflare IP ranges only
  ingress {
    description = "HTTPS from Cloudflare"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cloudflare_ip_ranges
  }

  # SSH — restricted to operator CIDR only
  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  # All outbound allowed (needed for Docker pull, updates)
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg-ec2"
  })
}

# ─── IAM Role: EC2 Instance Profile ──────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

# CloudWatch agent permissions
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# SSM Session Manager (no SSH bastion needed for admin access)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 read access for deployments (pull compose files, configs)
resource "aws_iam_role_policy" "s3_deploy" {
  name = "${local.name_prefix}-s3-deploy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.deploy_bucket_name}",
          "arn:aws:s3:::${var.deploy_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = local.common_tags
}

# ─── IAM Role: GitHub Actions CI/CD ─────────────────────────────────────────

resource "aws_iam_role" "github_actions" {
  name = "${local.name_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = var.github_oidc_provider_arn }
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "${local.name_prefix}-github-actions-terraform"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2 — limited to Free Tier instance types
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:CreateVpc", "ec2:DeleteVpc",
          "ec2:CreateSubnet", "ec2:DeleteSubnet",
          "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
          "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
          "ec2:CreateRoute", "ec2:DeleteRoute",
          "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
          "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupEgress",
          "ec2:RunInstances", "ec2:TerminateInstances",
          "ec2:StartInstances", "ec2:StopInstances",
          "ec2:CreateTags", "ec2:DeleteTags",
          "ec2:AllocateAddress", "ec2:ReleaseAddress",
          "ec2:AssociateAddress", "ec2:DisassociateAddress",
          "ec2:ImportKeyPair", "ec2:DeleteKeyPair",
          "ec2:CreateKeyPair",
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = "*"
      },
      # IAM — scoped to project prefix
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:PassRole",
          "iam:TagRole", "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = "arn:aws:iam::*:role/${var.project}-*"
      },
      # IAM — instance profiles
      {
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile", "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = "arn:aws:iam::*:instance-profile/${var.project}-*"
      },
      # S3 — Terraform state bucket
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
          "s3:ListBucket", "s3:GetBucketVersioning",
          "s3:GetBucketAcl", "s3:GetBucketLogging",
          "s3:GetBucketPolicy", "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket_name}",
          "arn:aws:s3:::${var.state_bucket_name}/*"
        ]
      },
      # DynamoDB — state locking
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.state_lock_table_name}"
      },
      # SSM Parameter Store — parameter-level actions
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath",
          "ssm:PutParameter", "ssm:DeleteParameter",
          "ssm:AddTagsToResource", "ssm:ListTagsForResource"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.project}/*"
      },
      # SSM DescribeParameters requires resource "*" (no resource-level support)
      {
        Effect   = "Allow"
        Action   = ["ssm:DescribeParameters"]
        Resource = "*"
      },
      # SNS
      {
        Effect = "Allow"
        Action = [
          "sns:CreateTopic", "sns:DeleteTopic",
          "sns:GetTopicAttributes", "sns:SetTopicAttributes",
          "sns:Subscribe", "sns:Unsubscribe",
          "sns:ListTagsForResource", "sns:TagResource", "sns:UntagResource"
        ]
        Resource = "arn:aws:sns:*:*:${var.project}-*"
      },
      # CloudWatch
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup", "logs:DeleteLogGroup",
          "logs:DescribeLogGroups", "logs:ListTagsLogGroup",
          "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy",
          "cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms", "cloudwatch:ListTagsForResource",
          "cloudwatch:TagResource", "cloudwatch:UntagResource",
          "cloudwatch:PutDashboard", "cloudwatch:GetDashboard",
          "cloudwatch:DeleteDashboards", "cloudwatch:ListDashboards"
        ]
        Resource = "*"
      }
    ]
  })
}
