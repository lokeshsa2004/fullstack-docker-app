#!/bin/bash

################################################################################
# Portfolio Manager - Stop Script
# This script stops all containers
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info "Stopping Portfolio Manager..."
cd "$PROJECT_ROOT"

# Stop containers
docker-compose down

log_success "Portfolio Manager stopped successfully!"
log_info "To start again, run: ./scripts/start.sh"
