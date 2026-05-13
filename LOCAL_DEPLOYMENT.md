# Local Development & Testing Guide

## Prerequisites

- Docker Desktop or Docker Engine
- Docker Compose
- Git
- Python 3.11+ (optional, for local development without Docker)
- curl or Postman (for API testing)

## Quick Start - Local Docker Deployment

### 1. Clone and Navigate
```bash
git clone https://github.com/lokeshsa2004/fullstack-docker-app.git
cd fullstack-docker-app
```

### 2. Create Environment File
```bash
cp backend/.env.example .env
```

Edit `.env` if needed (defaults are fine for local):
```
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=portfolio_db
DEBUG=True
LOG_LEVEL=INFO
```

### 3. Start All Services
```bash
docker compose up --build
```

Expected output:
```
portfolio_db  | database system is ready to accept connections
portfolio_app | Application starting - Portfolio Manager API v1.0.0
portfolio_nginx | [notice] master process started
```

Wait 10-15 seconds for all services to become healthy.

### 4. Test the Application

#### Test API Health
```bash
curl http://localhost:8000/health
# Response: {"status":"healthy","message":"API is running"}
```

#### Test Readiness
```bash
curl http://localhost:8000/health/ready
# Response: {"status":"ready","message":"API is ready to serve requests"}
```

#### Test Frontend
```bash
# Home page
curl http://localhost/

# Dashboard (via nginx proxy)
curl http://localhost/dashboard

# API docs
curl http://localhost/docs
```

#### Test via Browser
- Frontend Home: http://localhost/
- Dashboard: http://localhost/dashboard
- About: http://localhost/about
- API Docs: http://localhost/docs
- ReDoc: http://localhost/redoc

### 5. Test API Endpoints

#### Create a Portfolio
```bash
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Test Portfolio",
    "owner": "Test User",
    "description": "Testing the API"
  }'
```

#### List Portfolios
```bash
curl http://localhost:8000/api/v1/portfolios
```

#### Create an Investment
```bash
curl -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d '{
    "portfolio_id": 1,
    "ticker": "TEST",
    "name": "Test Company",
    "quantity": 10,
    "purchase_price": 100.00,
    "current_price": 110.00,
    "sector": "Technology"
  }'
```

#### Get Portfolio Investments
```bash
curl http://localhost:8000/api/v1/investments/portfolio/1
```

### 6. Verify All Services Are Running
```bash
docker compose ps
```

Expected:
```
NAME              STATUS
portfolio_db      Up (healthy)
portfolio_app     Up (healthy)
portfolio_nginx   Up (healthy)
```

### 7. Check Container Logs

#### Backend logs
```bash
docker compose logs app
```

#### Database logs
```bash
docker compose logs db
```

#### Nginx logs
```bash
docker compose logs nginx
```

### 8. Access Database Directly
```bash
docker compose exec db psql -U postgres -d portfolio_db

# Inside psql:
SELECT * FROM portfolios;
SELECT * FROM investments;
\q  # exit
```

## Stopping Services

### Stop all containers (keep data)
```bash
docker compose stop
```

### Stop and remove containers (keep volumes)
```bash
docker compose down
```

### Full cleanup (remove everything including database)
```bash
docker compose down -v
```

## Troubleshooting Local Deployment

### Port Already in Use
If port 80 or 8000 is already in use:

```bash
# Find what's using port 80
lsof -i :80
# or on Windows
netstat -ano | findstr :80

# Change the mapping in docker-compose.yml:
# ports:
#   - "8080:80"   # Use 8080 instead
# Then access at http://localhost:8080
```

### Container Won't Start
```bash
# Check logs
docker compose logs app

# Common issues:
# - Missing environment variables
# - Port conflicts
# - Database connection timeout (check DB is healthy first)
```

### Database Connection Failed
```bash
# Verify DB is healthy
docker compose ps db

# Check DB logs
docker compose logs db

# Restart DB
docker compose restart db
```

### Frontend Assets Not Loading
```bash
# Check nginx config
docker compose logs nginx

# Verify static files exist
docker compose exec app ls -la /app/frontend/static/

# Check nginx can read them
docker compose exec nginx ls -la /usr/share/nginx/html/static/
```

## Testing from Host Machine

### Test Backend API
```bash
# From any terminal on your machine
curl http://localhost:8000/api/v1/portfolios
```

### Test Frontend
Open browser: http://localhost

### Test via Docker Compose Network
```bash
# From inside app container
docker compose exec app curl http://db:5432  # Should timeout (DB port, not HTTP)
docker compose exec app curl http://localhost:8000/health  # Should work
```

## Development Workflow

### Making Backend Changes
```bash
# Edit Python files in backend/

# Option 1: Restart container (applies changes)
docker compose restart app

# Option 2: Rebuild container
docker compose up --build app
```

### Making Frontend Changes
```bash
# Edit files in frontend/templates or frontend/static/

# Changes appear immediately (mounted volume)
# Just refresh browser
```

### Running Backend Tests
```bash
# Install test dependencies
pip install pytest pytest-asyncio

# Run tests locally
cd backend
pytest tests/

# Or run tests in container
docker compose exec app pytest tests/
```

## Performance Monitoring

### Check Resource Usage
```bash
docker stats
```

### View Network Activity
```bash
docker compose logs -f --tail=20
```

### Monitor Database Connections
```bash
docker compose exec db psql -U postgres -d portfolio_db -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

## Database Backups

### Create Backup
```bash
docker compose exec db pg_dump -U postgres portfolio_db > backup.sql
```

### Restore from Backup
```bash
docker compose exec db psql -U postgres portfolio_db < backup.sql
```

## Cleanup and Reset

### Remove Old Containers/Images
```bash
docker system prune -a
```

### Reset Database to Initial State
```bash
docker compose down -v
docker compose up
# Database will be re-initialized with seed data
```

## Next Steps

Once local testing is successful:

1. Set GitHub Secrets (see GITHUB_SECRETS.md)
2. Set up EC2 instance (see EC2 setup below)
3. Push to main branch to trigger deployment
4. Monitor GitHub Actions

## EC2 Setup

### Prerequisites
- AWS EC2 instance running Ubuntu 20.04+ or Amazon Linux 2
- Security group allows:
  - Port 22 (SSH) from your IP
  - Port 80 (HTTP) from internet
  - Port 443 (HTTPS) from internet (if using SSL)

### Initial Setup
```bash
# SSH into your EC2 instance
ssh -i your-key.pem ec2-user@your-instance-ip

# Run setup script (from repo)
curl https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/fullstack-docker-app/main/scripts/setup-ec2.sh | bash

# Or manually:
sudo apt-get update && sudo apt-get upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
sudo apt-get install -y docker-compose-plugin
sudo mkdir -p /opt/portfolio-app
sudo chown $USER:$USER /opt/portfolio-app
```

### Verify EC2 Setup
```bash
docker --version
docker compose version
ls -la /opt/portfolio-app
```

## GitHub Actions Deployment

Once EC2 is ready and secrets are set:

1. Make a commit to main branch
2. Go to GitHub Actions tab
3. Monitor the workflow:
   - Test job: Runs tests
   - Build and push: Builds Docker image
   - Deploy: Deploys to EC2
   - Health check: Verifies deployment

## Monitoring Production

### Check EC2 Deployment Status
```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@your-instance-ip

# Check containers
docker compose ps

# Check logs
docker compose logs --tail=50 app
docker compose logs --tail=50 db
docker compose logs --tail=50 nginx
```

### Monitor Nginx
```bash
# View access logs
docker compose logs nginx

# Check upstream backend health
curl http://localhost/health
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| 502 Bad Gateway | App container not ready. Check `docker compose ps` and logs |
| 503 Service Unavailable | DB not healthy. Wait 30s and retry |
| Empty Dashboard | Check DB has data. Run `psql` and verify `SELECT COUNT(*) FROM portfolios;` |
| Slow API Response | Check container logs, verify DB is not overloaded |
| API docs not loading | Verify all routes are registered in main.py |
| Static files 404 | Check frontend/static/ path and nginx config |

