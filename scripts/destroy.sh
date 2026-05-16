#!/usr/bin/env bash
# =============================================================================
# destroy.sh — Safely teardown an environment
# Usage: ./scripts/destroy.sh <environment>
# Requires double confirmation for prod.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

ENVIRONMENT="${1:-dev}"
TF_DIR="terraform/envs/$ENVIRONMENT"

[[ ! -d "$TF_DIR" ]] && error "Environment not found: $TF_DIR"

warn "=========================================="
warn "  DESTROYING ENVIRONMENT: $ENVIRONMENT"
warn "=========================================="
warn "This will delete ALL infrastructure in the '$ENVIRONMENT' environment."
warn "This action is IRREVERSIBLE."
echo ""

# Double confirmation for prod
if [[ "$ENVIRONMENT" == "prod" ]]; then
    read -rp "Type the environment name to confirm: " CONFIRM_ENV
    [[ "$CONFIRM_ENV" != "prod" ]] && error "Confirmation failed. Aborting."
    read -rp "Are you absolutely sure? (yes/no): " CONFIRM_FINAL
    [[ "$CONFIRM_FINAL" != "yes" ]] && error "Cancelled."
else
    read -rp "Confirm destruction of '$ENVIRONMENT'? (yes/no): " CONFIRM
    [[ "$CONFIRM" != "yes" ]] && { info "Cancelled."; exit 0; }
fi

info "Initializing Terraform..."
terraform -chdir="$TF_DIR" init -input=false

info "Planning destroy..."
terraform -chdir="$TF_DIR" plan -destroy -out=destroy.tfplan

info "Applying destroy..."
terraform -chdir="$TF_DIR" apply destroy.tfplan

rm -f "$TF_DIR/destroy.tfplan"

info "Environment '$ENVIRONMENT' destroyed successfully."
