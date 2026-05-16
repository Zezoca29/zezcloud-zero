# ZezCloud Zero — Infrastructure as Code Platform

[![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Free%20Tier-FF9900?logo=amazon-aws)](https://aws.amazon.com/free)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docker.com)
[![Cost](https://img.shields.io/badge/Cost-$0%2Fmonth-00C853)](.)

> A production-grade Infrastructure as Code platform demonstrating Cloud Engineering, DevOps automation, and AWS architecture — operating at **zero cost** using AWS Free Tier.

---

## Architecture Overview

```
GitHub Actions (CI/CD)
        │
        ▼
 Terraform Pipeline (fmt → validate → plan → apply)
        │
        ▼
┌──────────────────── AWS Free Tier ─────────────────────┐
│                                                         │
│                        VPC (10.0.0.0/16)                │
│                                                         │
│    ┌──────────────────┐      ┌───────────────────────┐  │
│    │   Public Subnet   │      │    Private Subnet     │  │
│    │   10.0.1.0/24    │      │    10.0.10.0/24       │  │
│    │                  │      │                       │  │
│    │  EC2 t2.micro    │      │  PostgreSQL Container │  │
│    │  Docker Runtime  │◄────►│  Spring Boot API      │  │
│    │  Nginx Proxy     │      │  Internal Services    │  │
│    └────────┬─────────┘      └───────────────────────┘  │
│             │                                           │
│      Internet Gateway                                   │
│             │                                           │
│   Terraform Remote State (S3)                           │
└─────────────┼───────────────────────────────────────────┘
              │
     Cloudflare (SSL/DNS)
              │
           Internet
```

---

## Technology Stack

| Layer          | Technology                          |
|----------------|-------------------------------------|
| Cloud          | AWS (VPC, EC2, S3, IAM)             |
| IaC            | Terraform 1.7+ (Modules)            |
| Compute        | EC2 t2.micro (Free Tier)            |
| Runtime        | Docker + Docker Compose             |
| Backend API    | Spring Boot 3.x                     |
| Database       | PostgreSQL (containerized)          |
| Reverse Proxy  | Nginx                               |
| SSL/DNS        | Cloudflare (Free)                   |
| CI/CD          | GitHub Actions                      |
| State Backend  | AWS S3 + DynamoDB (lock)            |

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml      # PR: plan on every push
│       └── terraform-apply.yml     # Main: apply on merge
│
├── terraform/
│   ├── modules/
│   │   ├── networking/             # VPC, subnets, IGW, route tables
│   │   ├── compute/                # EC2, user-data, key pair
│   │   ├── security/               # IAM roles, security groups
│   │   ├── database/               # DB config outputs (containerized)
│   │   └── monitoring/             # CloudWatch alarms
│   │
│   ├── envs/
│   │   ├── dev/                    # Development environment
│   │   └── prod/                   # Production environment
│   │
│   └── shared/
│       └── backend/                # S3 + DynamoDB bootstrap
│
├── app/
│   └── api/                        # Spring Boot REST API
│
├── docker/
│   ├── nginx/                      # Nginx reverse proxy config
│   └── docker-compose.yml          # Full stack orchestration
│
├── scripts/
│   ├── bootstrap.sh                # EC2 initialization
│   ├── deploy.sh                   # Application deploy
│   └── destroy.sh                  # Safe teardown
│
├── docs/
│   ├── architecture.md
│   ├── setup.md
│   └── cost-analysis.md
│
└── Makefile                        # Developer convenience commands
```

---

## Quick Start

### Prerequisites

- [Terraform >= 1.7](https://developer.hashicorp.com/terraform/install)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured
- [Docker + Docker Compose](https://docs.docker.com/get-docker/)
- AWS account (Free Tier eligible)
- Cloudflare account (Free)

### 1. Bootstrap Remote State

```bash
cd terraform/shared/backend
terraform init
terraform apply
```

### 2. Deploy Infrastructure

```bash
# Development environment
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

### 3. Deploy Application

```bash
make deploy ENV=dev
```

### 4. Destroy (safe teardown)

```bash
make destroy ENV=dev
```

---

## Cost Analysis

| Service             | Usage                  | Monthly Cost |
|---------------------|------------------------|--------------|
| EC2 t2.micro        | 750h/month (Free Tier) | **$0.00**    |
| S3 (state)          | < 5GB (Free Tier)      | **$0.00**    |
| DynamoDB (lock)     | < 25GB (Free Tier)     | **$0.00**    |
| Cloudflare SSL/DNS  | Free plan              | **$0.00**    |
| GitHub Actions      | Public repo            | **$0.00**    |
| **Total**           |                        | **$0.00/mo** |

**Intentionally avoided paid services:**
- ❌ NAT Gateway (~$32/mo) → ✅ Simplified subnet architecture
- ❌ ECS Fargate (CPU/mem billing) → ✅ Docker on EC2
- ❌ Application Load Balancer (~$16/mo) → ✅ Nginx reverse proxy
- ❌ RDS PostgreSQL (~$15/mo) → ✅ Containerized PostgreSQL

---

## Security Practices

- Restrictive security groups (principle of least privilege)
- IAM roles with minimal permissions (no root keys)
- Secrets via GitHub Actions Secrets + AWS SSM Parameter Store
- No credentials hardcoded anywhere
- SSH access limited to known CIDR / bastion pattern
- HTTPS enforced via Cloudflare (free SSL)
- Private subnet isolation for database and internal services
- `.tfvars` files excluded from version control

---

## CI/CD Pipeline

```
PR Open/Update:
  └── fmt check → validate → plan (output as PR comment)

Merge to main:
  └── fmt → validate → plan → [manual approval] → apply → deploy
```

---

## Competencies Demonstrated

- **Infrastructure as Code** — Modular, reusable Terraform at scale
- **Cloud Architecture** — AWS networking, compute, IAM design
- **DevOps** — GitHub Actions CI/CD with manual gates
- **Docker** — Multi-container orchestration with Docker Compose
- **Networking** — VPC design, subnets, routing, security groups
- **Security** — Least-privilege IAM, secrets management, HTTPS
- **Cost Engineering** — Strategic Free Tier usage
- **Reproducibility** — Full environment rebuild in one command

---

## Author

Built as a portfolio project demonstrating production-grade Cloud Engineering skills.

*Architecture designed to evolve toward ECS Fargate, RDS, ALB, Kubernetes, and full observability (Prometheus/Grafana) in future iterations.*
