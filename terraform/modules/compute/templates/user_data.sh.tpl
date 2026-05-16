#!/bin/bash
# =============================================================================
# ZezCloud Zero — EC2 Bootstrap Script
# Executed once on first launch via EC2 User Data.
# =============================================================================
set -euo pipefail

LOG_FILE="/var/log/zezcloud-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== ZezCloud Bootstrap START: $(date) ==="
echo "Project:     ${project}"
echo "Environment: ${environment}"

# ─── System Update ────────────────────────────────────────────────────────────

dnf update -y
dnf install -y git curl wget unzip htop

# ─── Docker ───────────────────────────────────────────────────────────────────

dnf install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group (no sudo required)
usermod -aG docker ec2-user

# Docker Compose v2 (plugin)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL \
  "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ─── Application Directory ────────────────────────────────────────────────────

APP_DIR="/opt/zezcloud"
mkdir -p "$APP_DIR"
chown ec2-user:ec2-user "$APP_DIR"

# ─── Docker Compose File ──────────────────────────────────────────────────────

cat > "$APP_DIR/docker-compose.yml" << 'COMPOSE_EOF'
${docker_compose}
COMPOSE_EOF

# ─── Environment Variables ────────────────────────────────────────────────────

cat > "$APP_DIR/.env" << ENV_EOF
APP_DOMAIN=${app_domain}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
SPRING_PROFILES_ACTIVE=${spring_profile}
ENVIRONMENT=${environment}
ENV_EOF

chmod 600 "$APP_DIR/.env"
chown ec2-user:ec2-user "$APP_DIR/.env"

# ─── Systemd Service for Auto-Restart ────────────────────────────────────────

cat > /etc/systemd/system/zezcloud.service << 'SERVICE_EOF'
[Unit]
Description=ZezCloud Application Stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/zezcloud
ExecStart=/usr/local/lib/docker/cli-plugins/docker-compose up -d --build
ExecStop=/usr/local/lib/docker/cli-plugins/docker-compose down
User=ec2-user
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl daemon-reload
systemctl enable zezcloud

# ─── CloudWatch Agent ─────────────────────────────────────────────────────────

dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CW_EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/zezcloud-bootstrap.log",
            "log_group_name": "/zezcloud/${environment}/bootstrap",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/zezcloud/${environment}/system",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "resources": ["/"]
      }
    },
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}",
      "Environment": "${environment}"
    },
    "aggregation_dimensions": [["Environment"]]
  }
}
CW_EOF

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# ─── Start Application ────────────────────────────────────────────────────────

systemctl start zezcloud

echo "=== ZezCloud Bootstrap COMPLETE: $(date) ==="
