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

# ─── Push docker-compose.yml ──────────────────────────────────────────────────

info "Syncing docker-compose.yml..."
ssh_exec "sudo mkdir -p $APP_DIR && sudo chown $SSH_USER:$SSH_USER $APP_DIR"
scp $SSH_OPTS docker/docker-compose.yml "$SSH_USER@$EC2_IP:$APP_DIR/docker-compose.yml"

# ─── Pull Latest Images ───────────────────────────────────────────────────────

info "Pulling latest images..."
ssh_exec "cd $APP_DIR && docker compose pull --quiet"

# ─── Rolling Restart (zero-downtime order: nginx → api → postgres) ────────────

info "Restarting stack [$ENVIRONMENT]..."
ssh_exec "cd $APP_DIR && \
    docker compose up -d --build --remove-orphans --wait"

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
ssh_exec "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

info "Deploy complete for [$ENVIRONMENT] at $EC2_IP"
