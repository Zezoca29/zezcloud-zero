################################################################################
# Compute Module — EC2, Key Pair, User Data
################################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Module      = "compute"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  })
}

# ─── AMI Data Source ──────────────────────────────────────────────────────────
# Latest Amazon Linux 2023 — optimized for AWS, no license cost.

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────

resource "aws_key_pair" "main" {
  key_name   = "${local.name_prefix}-keypair"
  public_key = var.public_key

  tags = local.common_tags
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "main" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = aws_key_pair.main.key_name
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    project         = var.project
    environment     = var.environment
    docker_compose  = var.docker_compose_content
    app_domain      = var.app_domain
    db_name         = var.db_name
    db_user         = var.db_user
    db_password     = var.db_password
    spring_profile  = var.environment
  }))

  lifecycle {
    # Prevent accidental replacement on AMI updates — use rolling deploy instead
    ignore_changes = [ami, user_data]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2"
  })
}

# ─── Elastic IP ───────────────────────────────────────────────────────────────
# Keeps the IP stable across stop/start cycles.

resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eip"
  })

  depends_on = [aws_instance.main]
}
