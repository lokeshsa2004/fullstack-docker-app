#!/bin/bash

################################################################################
# Portfolio Manager - Deployment Script for EC2
# This script deploys the application to an AWS EC2 instance
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info "Portfolio Manager EC2 Deployment Script"

# Check if GitHub Actions runner context
if [ -z "$GITHUB_ACTIONS" ]; then
    log_warn "Not running in GitHub Actions environment"
fi

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(cat "$PROJECT_ROOT/.env" | grep -v '#' | xargs)
fi

# Check required variables
if [ -z "$EC2_HOST" ]; then
    log_error "EC2_HOST is not set. Please configure in .env file or GitHub Actions secret"
    exit 1
fi

# Check for SSH key - either from GitHub Actions (EC2_KEY) or from .env (SSH_KEY_PATH)
if [ -z "$EC2_KEY" ] && [ -z "$SSH_KEY_PATH" ]; then
    log_error "EC2_KEY (GitHub Actions) or SSH_KEY_PATH (local .env) is not set"
    exit 1
fi

if [ -z "$DOCKER_REGISTRY" ] || [ -z "$DOCKER_IMAGE_NAME" ]; then
    log_error "Docker registry configuration not found"
    exit 1
fi

# SSH options
SSH_USER="${EC2_USER:-ec2-user}"
EC2_ADDR="${SSH_USER}@${EC2_HOST}"

# Determine SSH key source
if [ ! -z "$EC2_KEY" ]; then
    # GitHub Actions: write key from secret
    SSH_KEY_FILE="/tmp/ec2_key.pem"
    echo "$EC2_KEY" > "$SSH_KEY_FILE"
    chmod 600 "$SSH_KEY_FILE"
    SSH_KEY="$SSH_KEY_FILE"
else
    # Local: use SSH_KEY_PATH from .env
    SSH_KEY="$SSH_KEY_PATH"
fi

SSH_OPTS="-i ${SSH_KEY} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

log_info "Deployment configuration:"
log_info "  EC2 Host: ${EC2_HOST}"
log_info "  SSH User: ${SSH_USER}"
log_info "  Docker Image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG:-latest}"

# Step 1: Setup EC2 instance (if needed)
log_info "Step 1: Setting up EC2 instance..."
ssh ${SSH_OPTS} "${EC2_ADDR}" << 'EOF'
#!/bin/bash
set -e

# Update system
sudo yum update -y || sudo apt-get update -y

# Install curl/wget for deploy health checks and tooling (minimal AMIs often lack curl)
if command -v apt-get &> /dev/null; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget ca-certificates
elif command -v yum &> /dev/null; then
    sudo yum install -y curl wget
fi

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum install -y docker || sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Add current user to docker group
sudo usermod -aG docker $USER || true

echo "EC2 instance is ready"
EOF

log_success "EC2 instance setup completed"

# Step 2: Package compose stack and sync to EC2
log_info "Step 2: Packaging application configuration..."

DOCKER_IMAGE="${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG:-latest}"
DB_USER_VAL="${DB_USER:-postgres}"
DB_PASSWORD_VAL="${DB_PASSWORD:-postgres}"
DB_NAME_VAL="${DB_NAME:-portfolio_db}"

STAGE_DIR="$(mktemp -d)"
BUNDLE_TGZ="$(mktemp)"
ENV_FILE="$(mktemp)"
cleanup_stage() {
    rm -rf "$STAGE_DIR"
    rm -f "$BUNDLE_TGZ" "$ENV_FILE"
}
trap cleanup_stage EXIT

mkdir -p "$STAGE_DIR/nginx/ssl" "$STAGE_DIR/frontend" "$STAGE_DIR/scripts"
cp "$PROJECT_ROOT/docker-compose.yml" \
    "$PROJECT_ROOT/docker-compose.prod.yml" \
    "$PROJECT_ROOT/docker-compose.registry.yml" \
    "$STAGE_DIR/"
cp "$PROJECT_ROOT/nginx/nginx.conf" "$STAGE_DIR/nginx/"
cp -r "$PROJECT_ROOT/frontend/static" "$STAGE_DIR/frontend/"
cp "$PROJECT_ROOT/scripts/init_db.sql" "$STAGE_DIR/scripts/"
tar -czf "$BUNDLE_TGZ" -C "$STAGE_DIR" .

printf 'DB_USER=%s\n' "$DB_USER_VAL" > "$ENV_FILE"
printf 'DB_PASSWORD=%s\n' "$DB_PASSWORD_VAL" >> "$ENV_FILE"
printf 'DB_NAME=%s\n' "$DB_NAME_VAL" >> "$ENV_FILE"
printf 'DOCKER_IMAGE=%s\n' "$DOCKER_IMAGE" >> "$ENV_FILE"

log_info "Uploading bundle to EC2..."
scp ${SSH_OPTS} "$BUNDLE_TGZ" "${EC2_ADDR}:~/deploy-bundle.tgz"
scp ${SSH_OPTS} "$ENV_FILE" "${EC2_ADDR}:~/deploy.env"

log_info "Step 2: Deploying application on EC2..."

ssh ${SSH_OPTS} "${EC2_ADDR}" << EOF
#!/bin/bash
set -e

APP_DIR="/opt/portfolio-manager"
DOCKER_IMAGE="${DOCKER_IMAGE}"

sudo mkdir -p "\$APP_DIR"
sudo tar -xzf ~/deploy-bundle.tgz -C "\$APP_DIR"
sudo mv ~/deploy.env "\$APP_DIR/.env"
sudo chmod 600 "\$APP_DIR/.env"
rm -f ~/deploy-bundle.tgz

# App dir is root-owned (sudo tar); do not cd as deploy user — use absolute compose paths.
echo "Pulling latest Docker images..."
sudo docker pull "\$DOCKER_IMAGE"
sudo docker pull postgres:15-alpine
sudo docker pull nginx:alpine

echo "Stopping existing stack and freeing host ports..."
sudo docker-compose -f "\$APP_DIR/docker-compose.yml" -f "\$APP_DIR/docker-compose.prod.yml" -f "\$APP_DIR/docker-compose.registry.yml" down --remove-orphans 2>/dev/null || true
sudo docker rm -f portfolio_nginx portfolio_app portfolio_db 2>/dev/null || true
for p in 80 443 8000 5432; do
  ids=\$(sudo docker ps -q --filter publish=\$p 2>/dev/null || true)
  if [ -n "\$ids" ]; then
    echo "Stopping container(s) using host port \$p: \$ids"
    sudo docker stop \$ids 2>/dev/null || true
    sudo docker rm \$ids 2>/dev/null || true
  fi
done

echo "Starting application..."
sudo docker-compose -f "\$APP_DIR/docker-compose.yml" -f "\$APP_DIR/docker-compose.prod.yml" -f "\$APP_DIR/docker-compose.registry.yml" up -d

sleep 25
echo "Application deployed successfully"
EOF

log_success "Application deployment completed"

# Step 3: Health check (127.0.0.1 avoids IPv6 quirks; fall back if host has no curl)
log_info "Step 3: Running health checks..."

remote_check_health() {
    ssh ${SSH_OPTS} "${EC2_ADDR}" 'bash -s' << 'REMOTE_HEALTH'
set +e
# Avoid proxy env breaking loopback checks (common on cloud / corporate images)
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy no_proxy NO_PROXY
export NO_PROXY="127.0.0.1,localhost,::1"
export no_proxy="$NO_PROXY"

URL="http://127.0.0.1/health"

# 1) Prefer checking inside the nginx container (no host proxy; BusyBox wget uses -T not --timeout)
if sudo docker exec portfolio_nginx wget -q -O /dev/null -T 10 "$URL" 2>/dev/null; then
  exit 0
fi

# 2) Published port on the host (bypass any HTTP proxy for loopback)
if command -v curl >/dev/null 2>&1; then
  curl --noproxy '*' -fsS --connect-timeout 5 --max-time 12 "$URL" >/dev/null 2>&1 && exit 0
fi

# 3) GNU wget on host (-T is network timeout in seconds)
if command -v wget >/dev/null 2>&1; then
  wget -q -O /dev/null -T 12 "$URL" 2>/dev/null && exit 0
fi

exit 1
REMOTE_HEALTH
}

# One-shot debug after first failed check (printed to CI log)
remote_health_debug() {
    ssh ${SSH_OPTS} "${EC2_ADDR}" 'bash -s' << 'REMOTE_DBG' || true
set +x
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy
echo "--- docker ps (nginx/app) ---"
sudo docker ps -a --filter "name=portfolio_nginx" --filter "name=portfolio_app" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>&1
echo "--- wget from inside nginx (stderr) ---"
sudo docker exec portfolio_nginx wget -S -O - -T 5 http://127.0.0.1/health 2>&1 | tail -20
echo "--- curl on host with noproxy (verbose tail) ---"
command -v curl >/dev/null && curl --noproxy '*' -v --max-time 8 http://127.0.0.1/health 2>&1 | tail -25
REMOTE_DBG
}

log_remote_diag() {
    log_warn "Remote diagnostics (docker ps / recent logs):"
    ssh ${SSH_OPTS} "${EC2_ADDR}" 'bash -s' << 'REMOTE_DIAG' || true
APP_DIR="/opt/portfolio-manager"
sudo docker ps -a 2>/dev/null || true
echo "--- nginx (last 60 lines) ---"
sudo docker logs --tail 60 portfolio_nginx 2>&1 || true
echo "--- app (last 80 lines) ---"
sudo docker logs --tail 80 portfolio_app 2>&1 || true
echo "--- db (last 40 lines) ---"
sudo docker logs --tail 40 portfolio_db 2>&1 || true
if [ -d "$APP_DIR" ]; then
  echo "--- compose ps ---"
  sudo docker-compose -f "$APP_DIR/docker-compose.yml" -f "$APP_DIR/docker-compose.prod.yml" -f "$APP_DIR/docker-compose.registry.yml" ps 2>&1 || true
fi
REMOTE_DIAG
}

max_attempts=45
attempt=1
while [ "$attempt" -le "$max_attempts" ]; do
    if remote_check_health; then
        log_success "Health check passed"
        break
    fi
    log_warn "Health check failed (attempt $attempt/$max_attempts)..."
    if [ "$attempt" -eq 1 ]; then
        log_info "First health check failed; printing one-shot connectivity debug..."
        remote_health_debug
    fi
    sleep 3
    attempt=$((attempt + 1))
done

if [ "$attempt" -gt "$max_attempts" ]; then
    log_error "Health check failed after $max_attempts attempts"
    log_remote_diag
    exit 1
fi

# Step 4: Cleanup
log_info "Step 4: Cleaning up..."

ssh ${SSH_OPTS} "${EC2_ADDR}" << EOF
#!/bin/bash
set -e
sudo docker system prune -f
echo "Cleanup completed"
EOF

log_success "Cleanup completed"

log_success "Deployment completed successfully!"
log_info ""
log_info "Application is running at: http://${EC2_HOST}"
log_info "To view logs: ssh ${SSH_OPTS} ${EC2_ADDR} 'sudo docker-compose -f /opt/portfolio-manager/docker-compose.yml -f /opt/portfolio-manager/docker-compose.prod.yml -f /opt/portfolio-manager/docker-compose.registry.yml logs -f'"
log_info "To stop:      ssh ${SSH_OPTS} ${EC2_ADDR} 'sudo docker-compose -f /opt/portfolio-manager/docker-compose.yml -f /opt/portfolio-manager/docker-compose.prod.yml -f /opt/portfolio-manager/docker-compose.registry.yml down'"
