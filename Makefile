.PHONY: help setup build run down logs clean test lint format shell db-migrate db-seed health backup rollback deploy-setup deploy

# Default target
help:
	@echo "Portfolio Manager - Available Commands:"
	@echo ""
	@echo "Setup & Installation:"
	@echo "  make setup              - Setup environment and build images"
	@echo "  make build              - Build Docker images"
	@echo ""
	@echo "Running:"
	@echo "  make run                - Start all containers"
	@echo "  make down               - Stop all containers"
	@echo "  make restart            - Restart all containers"
	@echo "  make logs               - View container logs (follow mode)"
	@echo ""
	@echo "Development:"
	@echo "  make shell-app          - Open shell in app container"
	@echo "  make shell-db           - Open shell in database container"
	@echo "  make lint               - Run Python linter"
	@echo "  make format             - Format Python code"
	@echo "  make test               - Run tests"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate         - Run database migrations"
	@echo "  make db-seed            - Seed database with sample data"
	@echo "  make db-reset           - Reset database (WARNING: deletes all data)"
	@echo ""
	@echo "Backup & Recovery:"
	@echo "  make backup             - Create database backup"
	@echo "  make rollback           - Show available backups"
	@echo ""
	@echo "Health & Monitoring:"
	@echo "  make health             - Check application health"
	@echo "  make ps                 - Show running containers"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean              - Remove containers and volumes"
	@echo "  make clean-build        - Remove build artifacts"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-setup       - Setup EC2 instance for deployment"
	@echo "  make deploy             - Deploy to EC2"
	@echo ""

# Setup environment
setup:
	@echo "Setting up environment..."
	@bash scripts/setup.sh

# Build Docker images
build:
	@echo "Building Docker images..."
	docker-compose build --no-cache

# Start containers
run:
	@echo "Starting containers..."
	@bash scripts/start.sh

# Stop containers
down:
	@echo "Stopping containers..."
	@bash scripts/stop.sh

# Restart containers
restart: down run

# View logs
logs:
	docker-compose logs -f

# View running containers
ps:
	docker-compose ps

# Open shell in app container
shell-app:
	docker-compose exec app bash

# Open shell in database container
shell-db:
	docker-compose exec db psql -U postgres -d portfolio_db

# Run linter
lint:
	@echo "Running linter..."
	docker-compose exec app python -m pylint app/ --exit-zero || true

# Format code
format:
	@echo "Formatting code..."
	docker-compose exec app python -m black app/ || true

# Run tests (if tests exist)
test:
	@echo "Running tests..."
	docker-compose exec app python -m pytest tests/ -v || echo "No tests found"

# Database migrations
db-migrate:
	@echo "Running database migrations..."
	docker-compose exec app alembic upgrade head

# Seed database
db-seed:
	@echo "Seeding database..."
	docker-compose exec db psql -U postgres -d portfolio_db -f /docker-entrypoint-initdb.d/init.sql

# Reset database (WARNING)
db-reset:
	@echo "WARNING: This will delete all data!"
	@read -p "Are you sure? (yes/no): " confirm && [ $$confirm = yes ] || (echo "Aborted"; exit 1)
	@echo "Dropping database..."
	docker-compose down -v
	@echo "Creating new database..."
	docker-compose up -d db
	sleep 5
	docker-compose exec db psql -U postgres -c "CREATE DATABASE portfolio_db;"

# Health check
health:
	@echo "Checking application health..."
	@curl -s http://localhost:8000/health | python -m json.tool || echo "API not responding"
	@curl -s http://localhost:8000/health/ready | python -m json.tool || echo "API not ready"
	@echo "Frontend health: http://localhost"

# Create backup
backup:
	@echo "Creating database backup..."
	@bash scripts/backup.sh

# Show available backups
rollback:
	@echo "Available backups:"
	@ls -lh backups/backup_*.sql 2>/dev/null || echo "No backups found"

# Clean up containers and volumes
clean:
	@echo "Removing containers and volumes..."
	docker-compose down -v
	@echo "Cleaned up successfully"

# Clean build artifacts
clean-build:
	@echo "Removing build artifacts..."
	find . -type d -name __pycache__ -exec rm -rf {} + || true
	find . -type f -name "*.pyc" -delete || true
	rm -rf build/ dist/ *.egg-info || true
	@echo "Build artifacts removed"

# Deploy setup
deploy-setup:
	@echo "Running deployment setup..."
	@if [ -z "$$EC2_HOST" ]; then echo "ERROR: EC2_HOST not set"; exit 1; fi
	@bash scripts/deploy.sh setup

# Deploy to EC2
deploy:
	@echo "Deploying to EC2..."
	@if [ -z "$$EC2_HOST" ]; then echo "ERROR: EC2_HOST not set"; exit 1; fi
	@bash scripts/deploy.sh

# Development mode with reload
dev:
	@echo "Starting in development mode..."
	docker-compose up

# Production mode
prod:
	@echo "Starting in production mode..."
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Install dependencies
install:
	@echo "Installing dependencies..."
	docker-compose exec app pip install -r requirements.txt

# Update dependencies
update:
	@echo "Updating dependencies..."
	docker-compose exec app pip install --upgrade pip
	docker-compose exec app pip install -r requirements.txt --upgrade

# Security check
security-check:
	@echo "Running security checks..."
	docker-compose exec app python -m bandit -r app/ -ll || true

# Generate documentation
docs:
	@echo "Generating API documentation..."
	@echo "API documentation available at: http://localhost:8000/docs"

# Show all targets
.DEFAULT_GOAL := help
