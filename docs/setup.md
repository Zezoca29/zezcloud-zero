# Setup Guide

## Prerequisites

| Tool              | Version   | Install |
|-------------------|-----------|---------|
| Terraform         | >= 1.7    | [hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| AWS CLI           | >= 2.x    | [aws.amazon.com](https://aws.amazon.com/cli/) |
| Docker            | >= 24.x   | [docker.com](https://docs.docker.com/get-docker/) |
| Java JDK          | 21        | [adoptium.net](https://adoptium.net/) |
| Git               | any       | [git-scm.com](https://git-scm.com/) |

---

## 1. AWS Account Setup

### Create IAM user for initial bootstrap

1. Go to AWS Console → IAM → Users → Create user
2. Attach policy: `AdministratorAccess` (only for bootstrap — remove after)
3. Create access key (CLI use)
4. Configure locally:

```bash
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region name: us-east-1
# Default output format: json
```

### Verify:

```bash
aws sts get-caller-identity
```

---

## 2. Bootstrap Remote State (run once)

```bash
cd terraform/shared/backend
terraform init
terraform apply
```

Outputs:
- `state_bucket_name` — add to backend configs
- `github_oidc_provider_arn` — add to GitHub Secrets

---

## 3. SSH Key Pair

Generate a dedicated key for EC2:

```bash
ssh-keygen -t ed25519 -C "zezcloud-key" -f ~/.ssh/zezcloud-key -N ""
```

Add `~/.ssh/zezcloud-key.pub` content to `ec2_public_key` in your tfvars.

---

## 4. Cloudflare Setup

1. Sign up at [cloudflare.com](https://cloudflare.com) (Free tier)
2. Add your domain
3. After Terraform apply, get the Elastic IP from output
4. Add an A record: `dev.yourdomain.com → <elastic_ip>`
5. Enable **Proxied** mode (orange cloud) for SSL

---

## 5. Configure terraform.tfvars

```bash
cp terraform/envs/dev/terraform.tfvars.example terraform/envs/dev/terraform.tfvars
```

Edit with your values. See [terraform.tfvars.example](../terraform/envs/dev/terraform.tfvars.example).

---

## 6. Deploy Infrastructure

```bash
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

Expected output:
```
Apply complete! Resources: 22 added, 0 changed, 0 destroyed.

Outputs:
  ec2_elastic_ip         = "54.x.x.x"
  github_actions_role_arn = "arn:aws:iam::..."
```

---

## 7. Configure GitHub Secrets

In your repository: **Settings → Secrets and variables → Actions**

| Secret | Value |
|--------|-------|
| `AWS_ROLE_ARN` | Output from `github_actions_role_arn` |
| `EC2_PUBLIC_KEY` | Content of `~/.ssh/zezcloud-key.pub` |
| `EC2_PRIVATE_KEY` | Content of `~/.ssh/zezcloud-key` |
| `DB_PASSWORD` | Strong random password |
| `APP_DOMAIN_DEV` | `dev.yourdomain.com` |
| `SSH_ALLOWED_CIDR` | `$(curl -s checkip.amazonaws.com)/32` |
| `GITHUB_OIDC_PROVIDER_ARN` | Backend output |

---

## 8. Deploy Application

```bash
make deploy ENV=dev
```

Or push to `main` — the CI/CD pipeline handles it automatically.

---

## Teardown

```bash
make destroy ENV=dev
```

For the backend (only when fully done with the project):

```bash
cd terraform/shared/backend
# Remove prevent_destroy lifecycle first, then:
terraform destroy
```
