#!/bin/bash

################################################################################
# Portfolio Manager - Setup Script
# This script prepares the environment for running the application locally
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_info "Setting up Portfolio Manager..."
log_info "Project root: $PROJECT_ROOT"

# Check dependencies
log_info "Checking system dependencies..."

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi
log_success "Docker is installed"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
log_success "Docker Compose is installed"

# Check if .env file exists
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    log_warn ".env file not found. Creating from .env.example..."
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    log_success "Created .env file. Please update it with your configuration."
else
    log_success ".env file already exists"
fi

# Create necessary directories
log_info "Creating necessary directories..."
mkdir -p "$PROJECT_ROOT/backups"
mkdir -p "$PROJECT_ROOT/nginx/ssl"
mkdir -p "$PROJECT_ROOT/frontend/static/uploads"
log_success "Directories created"

# Build images
log_info "Building Docker images..."
cd "$PROJECT_ROOT"
docker-compose build --no-cache

log_success "Setup completed successfully!"
log_info "To start the application, run: ./scripts/start.sh"
