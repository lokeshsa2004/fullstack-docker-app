#!/bin/bash

################################################################################
# Portfolio Manager - Rollback Script
# This script restores the database from a backup
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

# Check if backup file is provided
if [ -z "$1" ]; then
    log_info "Available backups:"
    ls -lh "$BACKUP_DIR"/backup_*.sql 2>/dev/null || log_error "No backups found"
    log_info ""
    log_info "Usage: $0 <backup_file>"
    log_info "Example: $0 backups/backup_20240101_120000.sql"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    log_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

log_warn "This will restore the database from: $BACKUP_FILE"
log_warn "All current data will be lost!"
read -p "Are you sure? (type 'yes' to confirm): " confirmation

if [ "$confirmation" != "yes" ]; then
    log_info "Rollback cancelled"
    exit 0
fi

# Check if containers are running
if ! docker-compose -f "$PROJECT_ROOT/docker-compose.yml" ps db &> /dev/null; then
    log_error "Database container is not running. Please start the application first."
    exit 1
fi

log_info "Restoring database from backup..."

# Drop and recreate database
log_info "Dropping current database..."
docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql \
    -U ${DB_USER:-postgres} \
    -c "DROP DATABASE IF EXISTS ${DB_NAME:-portfolio_db} WITH (FORCE);"

log_info "Creating new database..."
docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql \
    -U ${DB_USER:-postgres} \
    -c "CREATE DATABASE ${DB_NAME:-portfolio_db};"

# Restore from backup
log_info "Restoring data from backup..."
docker-compose -f "$PROJECT_ROOT/docker-compose.yml" exec -T db psql \
    -U ${DB_USER:-postgres} \
    ${DB_NAME:-portfolio_db} < "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    log_success "Database restored successfully from: $BACKUP_FILE"
else
    log_error "Failed to restore database"
    exit 1
fi

log_success "Rollback completed!"
log_info "To verify, check the application at http://localhost"
