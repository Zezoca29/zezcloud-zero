#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Local development environment setup
# Run once to verify prerequisites and prepare for deployment.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

MIN_TF_VERSION="1.7.0"
MIN_AWS_CLI_VERSION="2.0.0"

# ─── Check Prerequisites ──────────────────────────────────────────────────────

info "Checking prerequisites..."

check_command() {
    local cmd="$1"
    local name="${2:-$1}"
    command -v "$cmd" &>/dev/null || error "$name not found. Please install it first."
    info "$name: $(${cmd} --version 2>&1 | head -1)"
}

check_command terraform Terraform
check_command aws "AWS CLI"
check_command docker Docker
check_command docker compose "Docker Compose"

# ─── Verify AWS Credentials ───────────────────────────────────────────────────

info "Verifying AWS credentials..."
IDENTITY=$(aws sts get-caller-identity --output json 2>&1) || \
    error "AWS credentials not configured. Run: aws configure"

ACCOUNT=$(echo "$IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
REGION=$(aws configure get region || echo "us-east-1")

info "AWS Account: $ACCOUNT | Region: $REGION"

# ─── Bootstrap Remote State ───────────────────────────────────────────────────

info "Bootstrapping Terraform remote state..."
cd "$(dirname "$0")/../terraform/shared/backend"

terraform init -input=false -upgrade
terraform plan -input=false
terraform apply -input=false -auto-approve

STATE_BUCKET=$(terraform output -raw state_bucket_name)
LOCK_TABLE=$(terraform output -raw lock_table_name)
OIDC_ARN=$(terraform output -raw github_oidc_provider_arn)

info "Remote state bucket: $STATE_BUCKET"
info "State lock table:    $LOCK_TABLE"
info "GitHub OIDC ARN:     $OIDC_ARN"

# ─── Generate SSH Key ──────────────────────────────────────────────────────────

cd "$(dirname "$0")/.."
KEY_DIR=".ssh"
KEY_FILE="$KEY_DIR/zezcloud-key"

if [[ ! -f "$KEY_FILE" ]]; then
    info "Generating SSH key pair..."
    mkdir -p "$KEY_DIR"
    ssh-keygen -t ed25519 -C "zezcloud-key" -f "$KEY_FILE" -N ""
    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    info "SSH key generated: $KEY_FILE"
    warn "Add the public key to your tfvars: cat $KEY_FILE.pub"
else
    info "SSH key already exists: $KEY_FILE"
fi

# ─── Create tfvars from example ───────────────────────────────────────────────

TFVARS_DEV="terraform/envs/dev/terraform.tfvars"
if [[ ! -f "$TFVARS_DEV" ]]; then
    cp "terraform/envs/dev/terraform.tfvars.example" "$TFVARS_DEV"
    warn "Created $TFVARS_DEV — fill in your values before running terraform plan"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
info "Bootstrap complete. Next steps:"
echo "  1. Edit terraform/envs/dev/terraform.tfvars with your values"
echo "  2. Run: make plan ENV=dev"
echo "  3. Run: make apply ENV=dev"
echo ""
info "GitHub Secrets to configure:"
echo "  AWS_ROLE_ARN          = $OIDC_ARN (the role ARN from security module output)"
echo "  EC2_PUBLIC_KEY        = \$(cat $KEY_FILE.pub)"
echo "  EC2_PRIVATE_KEY       = \$(cat $KEY_FILE)"
echo "  DB_PASSWORD           = <strong password>"
echo "  APP_DOMAIN_DEV        = dev.yourdomain.com"
echo "  SSH_ALLOWED_CIDR      = \$(curl -s https://checkip.amazonaws.com)/32"
echo "  AWS_OIDC_PROVIDER_ARN = $OIDC_ARN"
