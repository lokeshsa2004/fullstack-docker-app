#!/bin/bash

################################################################################
# Portfolio Manager - Start Script
# This script starts all containers
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

log_info "Starting Portfolio Manager..."
cd "$PROJECT_ROOT"

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '#' | xargs)
else
    log_error ".env file not found. Please run './scripts/setup.sh' first."
    exit 1
fi

# Start containers
log_info "Starting Docker containers..."
docker-compose up -d

# Wait for services to be ready
log_info "Waiting for services to be ready..."
sleep 10

# Check if database is ready
log_info "Checking database connectivity..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if docker-compose exec -T db pg_isready -U ${DB_USER:-postgres} &> /dev/null; then
        log_success "Database is ready"
        break
    fi
    log_warn "Database not ready (attempt $attempt/$max_attempts)..."
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    log_error "Database failed to start"
    exit 1
fi

# Run database migrations
log_info "Running database migrations..."
docker-compose exec -T app alembic upgrade head || true

# Check API health
log_info "Checking API health..."
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
    if curl -f http://localhost:8000/health &> /dev/null; then
        log_success "API is healthy"
        break
    fi
    log_warn "API not ready (attempt $attempt/$max_attempts)..."
    sleep 2
    ((attempt++))
done

if [ $attempt -gt $max_attempts ]; then
    log_error "API failed to start"
    exit 1
fi

log_success "Portfolio Manager is running!"
log_info ""
log_info "URLs:"
log_info "  Frontend:  http://localhost"
log_info "  API:       http://localhost:8000"
log_info "  API Docs:  http://localhost:8000/docs"
log_info "  Database:  localhost:5432"
log_info ""
log_info "To view logs: docker-compose logs -f"
log_info "To stop:      ./scripts/stop.sh"
