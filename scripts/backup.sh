#!/bin/bash

################################################################################
# Portfolio Manager - Backup Script
# This script backs up the database
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_ROOT/.env" ]; then
    export $(cat "$PROJECT_ROOT/.env" | grep -v '#' | xargs)
fi

BACKUP_DIR="${BACKUP_PATH:-$PROJECT_ROOT/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.sql"

log_info "Starting database backup..."
log_info "Backup directory: $BACKUP_DIR"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if containers are running
if ! docker-compose -f "$PROJECT_ROOT/docker-compose.yml" ps db &> /dev/null; then
    log_error "Database container is not running. Please start the application first."
    exit 1
fi

# Create backup
log_info "Creating backup: $BACKUP_FILE"
docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db pg_dump \
    -U ${DB_USER:-postgres} \
    ${DB_NAME:-portfolio_db} > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    log_success "Backup created successfully: $BACKUP_FILE"
    ls -lh "$BACKUP_FILE"
else
    log_error "Failed to create backup"
    exit 1
fi

# Clean up old backups
log_info "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "backup_*.sql" -type f -mtime +$RETENTION_DAYS -delete

log_success "Backup process completed!"
