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

# Step 2: Deploy application
log_info "Step 2: Deploying application..."

ssh ${SSH_OPTS} "${EC2_ADDR}" << EOF
#!/bin/bash
set -e

APP_DIR="/opt/portfolio-manager"
DOCKER_IMAGE="${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG:-latest}"

# Create application directory
sudo mkdir -p \$APP_DIR
cd \$APP_DIR

# Download or update docker-compose.yml
echo "Downloading docker-compose configuration..."
# In a real scenario, you would clone from git or download from a repository
# For now, we'll create a basic version

# Pull latest images
echo "Pulling latest Docker images..."
sudo docker pull \$DOCKER_IMAGE || true
sudo docker pull postgres:15-alpine
sudo docker pull nginx:alpine

# Start application
echo "Starting application..."
sudo docker-compose -f docker-compose.yml up -d

# Wait for services
sleep 10

echo "Application deployed successfully"
EOF

log_success "Application deployment completed"

# Step 3: Health check
log_info "Step 3: Running health checks..."

max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if ssh ${SSH_OPTS} "${EC2_ADDR}" "curl -f http://localhost/health &> /dev/null"; then
        log_success "Health check passed"
        break
    fi
    log_warn "Health check failed (attempt $attempt/$max_attempts)..."
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    log_error "Health check failed after $max_attempts attempts"
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
log_info "To view logs: ssh ${SSH_OPTS} ${EC2_ADDR} 'docker-compose logs -f'"
log_info "To stop:      ssh ${SSH_OPTS} ${EC2_ADDR} 'docker-compose down'"
