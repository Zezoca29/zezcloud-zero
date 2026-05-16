#!/usr/bin/env bash
# =============================================================================
# deploy.sh — Deploy the application to EC2
# Usage: ./scripts/deploy.sh <environment> <ec2-ip> <key-file>
# =============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

ENVIRONMENT="${1:-dev}"
EC2_IP="${2:-}"
KEY_FILE="${3:-}"

[[ -z "$EC2_IP"   ]] && error "EC2_IP is required. Usage: $0 <env> <ip> <key>"
[[ -z "$KEY_FILE" ]] && error "KEY_FILE is required. Usage: $0 <env> <ip> <key>"
[[ ! -f "$KEY_FILE" ]] && error "Key file not found: $KEY_FILE"

SSH_USER="ec2-user"
APP_DIR="/opt/zezcloud"
SSH_OPTS="-i $KEY_FILE -o StrictHostKeyChecking=no -o ConnectTimeout=30"

ssh_exec() {
    ssh $SSH_OPTS "$SSH_USER@$EC2_IP" "$@"
}

# ─── Wait for Instance Ready ──────────────────────────────────────────────────

info "Waiting for EC2 instance to be ready..."
RETRIES=12
for i in $(seq 1 $RETRIES); do
    if ssh $SSH_OPTS "$SSH_USER@$EC2_IP" "echo ok" &>/dev/null; then
        info "SSH connection established."
        break
    fi
    [[ $i -eq $RETRIES ]] && error "Could not connect after $RETRIES attempts"
    warn "Attempt $i/$RETRIES — retrying in 15s..."
    sleep 15
done

# ─── Ensure Docker is installed ──────────────────────────────────────────────

info "Checking Docker installation..."
ssh_exec 'bash -s' <<'ENDSSH'
  if ! command -v docker &>/dev/null; then
    echo "[INSTALL] Docker not found — installing..."
    sudo dnf install -y docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker ec2-user
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -fsSL \
      "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  else
    sudo systemctl start docker 2>/dev/null || true
  fi
ENDSSH

# ─── Push docker-compose.yml ──────────────────────────────────────────────────

info "Syncing docker-compose.yml..."
ssh_exec "sudo mkdir -p $APP_DIR && sudo chown $SSH_USER:$SSH_USER $APP_DIR"
scp $SSH_OPTS docker/docker-compose.yml "$SSH_USER@$EC2_IP:$APP_DIR/docker-compose.yml"

# ─── Create .env from SSM ─────────────────────────────────────────────────────

info "Fetching secrets from SSM and writing .env..."
SSM_PREFIX="/${ENVIRONMENT:-dev}"
get_ssm() {
    aws ssm get-parameter --name "$1" --with-decryption \
        --query Parameter.Value --output text 2>/dev/null || echo ""
}

DB_NAME=$(get_ssm "/zezcloud/${ENVIRONMENT}/db/name")
DB_USER=$(get_ssm "/zezcloud/${ENVIRONMENT}/db/user")
DB_PASS=$(get_ssm "/zezcloud/${ENVIRONMENT}/db/password")

ssh $SSH_OPTS "$SSH_USER@$EC2_IP" "cat > $APP_DIR/.env" <<EOF
db_name=${DB_NAME}
db_user=${DB_USER}
db_password=${DB_PASS}
spring_profile=${ENVIRONMENT}
app_domain=localhost
EOF

# ─── Authenticate EC2 with GHCR ──────────────────────────────────────────────

info "Authenticating EC2 with GHCR..."
echo "${GHCR_TOKEN}" | ssh $SSH_OPTS "$SSH_USER@$EC2_IP" \
    "sudo docker login ghcr.io -u ${GHCR_USER} --password-stdin"

# ─── Pull Latest Images ───────────────────────────────────────────────────────

info "Pulling latest images..."
ssh_exec "cd $APP_DIR && sudo docker compose pull --quiet"

# ─── Rolling Restart ──────────────────────────────────────────────────────────

info "Restarting stack [$ENVIRONMENT]..."
ssh_exec "cd $APP_DIR && sudo docker compose up -d --remove-orphans --wait"

# ─── Health Check ─────────────────────────────────────────────────────────────

info "Running health check..."
HEALTH_URL="http://$EC2_IP/actuator/health"
RETRIES=6
for i in $(seq 1 $RETRIES); do
    STATUS=$(curl -sf --max-time 10 "$HEALTH_URL" | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || true)
    if [[ "$STATUS" == "UP" ]]; then
        info "Health check passed. Application is UP."
        break
    fi
    [[ $i -eq $RETRIES ]] && error "Health check failed after $RETRIES attempts"
    warn "Attempt $i/$RETRIES — waiting 10s..."
    sleep 10
done

# ─── Show Running Containers ──────────────────────────────────────────────────

info "Running containers:"
ssh_exec "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

info "Deploy complete for [$ENVIRONMENT] at $EC2_IP"
