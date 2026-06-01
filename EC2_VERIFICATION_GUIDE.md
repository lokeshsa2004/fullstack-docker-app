# ✅ EC2 Deployment Verification Guide

**Complete step-by-step guide to verify that your CI/CD pipeline correctly deploys artifact provenance to EC2.**

---

## 🎯 What We're Verifying

After the CI/CD pipeline deploys to EC2, confirm:

1. ✅ Docker image built with correct GIT_COMMIT (commit SHA)
2. ✅ Containers have GIT_COMMIT and BUILD_TIME environment variables
3. ✅ Startup logs show APP_START marker with commit info
4. ✅ `/meta` endpoint returns deployed commit SHA
5. ✅ All services communicate via docker network (no localhost)
6. ✅ Nginx correctly routes through service names
7. ✅ Health checks pass on all containers

---

## 📋 Pre-Deployment Checklist

### 1. GitHub Secrets Configuration

Verify all secrets are set in your GitHub repository:

```bash
# In your GitHub repo → Settings → Secrets and variables → Actions

✓ EC2_HOST          → your-ec2-ip or hostname
✓ EC2_USER          → ec2-user (Amazon Linux 2)
✓ EC2_KEY           → Your private SSH key (PEM format)
✓ DB_USER           → postgres
✓ DB_PASSWORD       → your-secure-password
✓ DB_NAME           → portfolio_db
```

**Verification**:

- SSH key is a valid PEM file (not OpenSSH format)
- EC2 security group allows SSH (port 22)
- EC2 has internet access to pull images from ghcr.io

### 2. EC2 Instance Prerequisites

```bash
# EC2 should have:
✓ Docker installed
✓ Docker Compose installed
✓ SSH key-based auth (no password required)
✓ Sufficient disk space for images and database

# Optional but recommended:
✓ CloudWatch agent
✓ Systems Manager agent
✓ Public IP or elastic IP
```

---

## 🚀 Step-by-Step Verification Process

### Phase 1: Trigger the CI/CD Pipeline

#### 1.1 Make a Commit with Your Changes

```bash
git add .
git commit -m "Deploy with artifact provenance tracking"
git push origin main
```

#### 1.2 Monitor GitHub Actions

Go to your repo → Actions → Watch the workflow:

```
Lint Job           ✓ Code quality checks pass
Test Job           ✓ Unit tests pass (across 3 Python versions)
Build Job          ✓ Docker image built with:
                     - GIT_COMMIT=${{ github.sha }}
                     - BUILD_TIME=$(timestamp)
                     - Image tagged: ghcr.io/...:main-<sha>
Deploy Job         ✓ SSH to EC2
                   ✓ Pull image
                   ✓ Start services
                   ✓ Health checks pass
```

**Key Indicators**:

- All jobs show green checkmarks
- Build job logs show `build-args: GIT_COMMIT=abc1234...`
- Deploy job logs show successful SSH connection
- No "Container exited" errors

---

### Phase 2: Verify on EC2

#### 2.1 SSH into EC2

```bash
ssh -i ~/.ssh/ec2-key.pem ec2-user@your-ec2-ip

# If successful, you should see:
# [ec2-user@ip-172-31-... ~]$
```

If this fails:

- Check security group allows port 22
- Verify EC2_KEY secret has correct permissions (400)
- Confirm EC2_HOST and EC2_USER are correct

#### 2.2 Check Running Containers

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Expected output:
# NAMES               STATUS              PORTS
# portfolio_nginx     Up X minutes        0.0.0.0:80->80/tcp, :::80->tcp
# portfolio_app      Up X minutes
# portfolio_db       Up X minutes        5432/tcp
```

**Troubleshoot**:

```bash
# If containers not running:
docker compose ps

# See errors:
docker compose logs --tail=50

# Check docker network:
docker network ls
docker network inspect portfolio_network
```

#### 2.3 Verify GIT_COMMIT in Container

```bash
# Method 1: Check environment variable
docker exec portfolio_app env | grep GIT_COMMIT

# Expected: GIT_COMMIT=abc1234567890abcdef...

# Method 2: Check /meta endpoint
docker exec portfolio_app curl -s http://127.0.0.1:8000/meta | jq '.commit'

# Expected: "abc1234567890abcdef..."

# Method 3: Get full metadata
docker exec portfolio_app curl -s http://127.0.0.1:8000/meta | jq '.'

# Expected output:
# {
#   "commit": "abc1234567890abcdef...",
#   "build_time": "2024-01-15T10:30:45Z",
#   "app_start_time": 1705322445,
#   "app_version": "0.1.0",
#   "app_name": "Portfolio Manager"
# }
```

#### 2.4 Verify BUILD_TIME in Container

```bash
# Check BUILD_TIME env var
docker exec portfolio_app env | grep BUILD_TIME

# Expected: BUILD_TIME=2024-01-15T10:30:45Z

# Verify in /meta endpoint
docker exec portfolio_app curl -s http://127.0.0.1:8000/meta | jq '.build_time'

# Expected: "2024-01-15T10:30:45Z"
```

#### 2.5 Check Startup Logs

```bash
# View app startup logs
docker logs portfolio_app | head -50

# Look for APP_START marker:
docker logs portfolio_app | grep "APP_START"

# Expected output:
# APP_START COMMIT=abc1234567890abcdef BUILD_TIME=2024-01-15T10:30:45Z TS=1705322445
```

**This proves**:

- App started with correct commit
- Build time was captured
- Container has access to metadata

#### 2.6 Verify Health Checks

```bash
# Check all containers are healthy
docker ps --filter health=healthy

# Expected: All 3 containers listed

# Test app health endpoint
docker exec portfolio_app curl -s http://127.0.0.1:8000/health

# Expected: "OK" or {"status": "healthy"}

# Test app readiness (with DB check)
docker exec portfolio_app curl -s http://127.0.0.1:8000/health/ready

# Expected: {"status": "ready", "database": "connected"}

# Test nginx health (from outside container)
docker exec portfolio_nginx curl -s http://127.0.0.1/health

# Expected: Proxied response from app
```

---

### Phase 3: Verify Service-to-Service Communication (No Localhost!)

#### 3.1 Check Docker Network

```bash
# List all networks
docker network ls

# Expected to see: portfolio_network  bridge

# Inspect the network
docker network inspect portfolio_network

# Expected to see:
# {
#   "Name": "portfolio_network",
#   "Driver": "bridge",
#   "Containers": {
#     "<id>": {
#       "Name": "portfolio_app",
#       "IPv4Address": "172.18.0.3/16"
#     },
#     "<id>": {
#       "Name": "portfolio_db",
#       "IPv4Address": "172.18.0.2/16"
#     },
#     "<id>": {
#       "Name": "portfolio_nginx",
#       "IPv4Address": "172.18.0.4/16"
#     }
#   }
# }
```

#### 3.2 Verify Nginx Configuration

```bash
# Check nginx config is loaded
docker exec portfolio_nginx nginx -T | head -50

# Look for the upstream:
docker exec portfolio_nginx nginx -T | grep -A 5 "upstream fastapi_backend"

# Expected:
# upstream fastapi_backend {
#     least_conn;
#     server app:8000 max_fails=3 fail_timeout=30s;
#     keepalive 32;
# }

# NOT "server localhost:8000" or "server 127.0.0.1:8000"
```

#### 3.3 Verify Nginx Routes to App

```bash
# Test routing from nginx to app (via service name)
docker exec portfolio_nginx curl -s http://app:8000/health

# Expected: "OK" or healthy status

# Verify static file serving
docker exec portfolio_nginx curl -s http://app:8000/static/js/main.js | head -5

# Should return JavaScript code

# Test from public port (via nginx)
curl http://your-ec2-ip/health

# Expected: Same response as direct to app
```

#### 3.4 Check Database Connection

```bash
# Verify app can reach database
docker exec portfolio_app curl -s http://127.0.0.1:8000/health/ready | jq '.database'

# Expected: "connected"

# Check database is running
docker exec portfolio_db psql -U postgres -c "SELECT version();"

# Expected: PostgreSQL version info
```

---

### Phase 4: Verify API Endpoints

#### 4.1 Test Root Endpoint

```bash
curl http://your-ec2-ip/ -v

# Expected:
# < HTTP/1.1 200 OK
# < Content-Type: text/html; charset=utf-8
# (Returns home.html)
```

#### 4.2 Test Meta Endpoint

```bash
curl http://your-ec2-ip/meta -v

# Expected:
# < HTTP/1.1 200 OK
# < Content-Type: application/json
# {
#   "commit": "abc1234567890abcdef...",
#   "build_time": "2024-01-15T10:30:45Z",
#   "app_start_time": 1705322445,
#   "app_version": "0.1.0",
#   "app_name": "Portfolio Manager"
# }
```

#### 4.3 Test API Endpoints

```bash
# Get portfolios
curl http://your-ec2-ip/api/v1/portfolios

# Expected: JSON array of portfolios

# Get investments
curl http://your-ec2-ip/api/v1/investments

# Expected: JSON array of investments
```

#### 4.4 Test Health Endpoints

```bash
# Basic health
curl http://your-ec2-ip/health

# Expected: "OK"

# Readiness (with DB check)
curl http://your-ec2-ip/health/ready

# Expected: {"status": "ready"}
```

---

### Phase 5: Monitor Logs Across Services

#### 5.1 View Application Logs

```bash
# Last 50 lines
docker logs portfolio_app --tail=50

# Follow logs in real-time
docker logs portfolio_app -f

# Search for APP_START
docker logs portfolio_app | grep "APP_START"

# Search for specific requests
docker logs portfolio_app | grep "GET /health"
```

#### 5.2 View Nginx Logs

```bash
# Access logs
docker logs portfolio_nginx --tail=50

# Look for request routing
docker exec portfolio_nginx tail -f /var/log/nginx/access.log

# Check for errors
docker exec portfolio_nginx tail -f /var/log/nginx/error.log
```

#### 5.3 View Database Logs

```bash
# Database logs
docker logs portfolio_db --tail=50

# Check for connection issues
docker logs portfolio_db | grep -i error
```

#### 5.4 Aggregate Logs

```bash
# All services logs together
docker compose logs --tail=100

# Follow all logs
docker compose logs -f

# Logs from specific service
docker compose logs app
docker compose logs nginx
docker compose logs db
```

---

### Phase 6: Trace a Complete Request

#### 6.1 Make a Request and Trace It

```bash
# Terminal 1: Follow app logs
docker logs portfolio_app -f

# Terminal 2: Follow nginx logs
docker exec portfolio_nginx tail -f /var/log/nginx/access.log

# Terminal 3: Make a request
curl -v http://your-ec2-ip/api/v1/portfolios

# Observe in Terminal 1 (app logs):
# 2024-01-15 10:45:30 INFO GET /api/v1/portfolios [200 OK]

# Observe in Terminal 2 (nginx logs):
# 172.18.0.1 - - [15/Jan/2024:10:45:30 +0000] "GET /api/v1/portfolios HTTP/1.1" 200 150
```

#### 6.2 Verify Commit Metadata in Response

```bash
# Make request to /meta
curl http://your-ec2-ip/meta | jq '.'

# Shows:
{
  "commit": "abc1234567890abcdef",    # ← Commit SHA from GitHub
  "build_time": "2024-01-15T10:30:45Z", # ← Build timestamp
  "app_start_time": 1705322445,        # ← Unix timestamp when container started
  "app_version": "0.1.0",               # ← App version
  "app_name": "Portfolio Manager"       # ← App name
}
```

---

## ✅ Complete Verification Checklist

### Build & Deployment

- [ ] GitHub Actions workflow completed successfully
- [ ] All 4 jobs passed (lint, test, build, deploy)
- [ ] Build job shows GIT_COMMIT build argument
- [ ] Deploy job shows successful SSH to EC2

### Container Status

- [ ] All 3 containers running: `docker ps | grep portfolio`
- [ ] All containers healthy: `docker ps --filter health=healthy`
- [ ] No crashed containers in logs

### Environment Variables

- [ ] `docker exec portfolio_app env | grep GIT_COMMIT` returns commit SHA
- [ ] `docker exec portfolio_app env | grep BUILD_TIME` returns timestamp

### Endpoints & API

- [ ] `/meta` returns JSON with correct commit SHA
- [ ] `/health` returns "OK"
- [ ] `/health/ready` returns `{"status": "ready"}`
- [ ] `/api/v1/portfolios` returns JSON array
- [ ] `/api/v1/investments` returns JSON array

### Service Communication

- [ ] Nginx upstream shows `server app:8000` (not localhost)
- [ ] Nginx can reach app: `docker exec portfolio_nginx curl app:8000/health`
- [ ] App can reach database: curl `/health/ready` shows database connected
- [ ] No localhost references in running configs

### Logs

- [ ] App startup logs show: `APP_START COMMIT=... BUILD_TIME=...`
- [ ] Nginx access logs show successful routing
- [ ] No error logs in any service

### Public Access

- [ ] Web browser: `http://your-ec2-ip` shows home page
- [ ] API: `curl http://your-ec2-ip/api/v1/portfolios` returns data
- [ ] Metadata: `curl http://your-ec2-ip/meta` shows deployment info

---

## 🐛 Troubleshooting

### Problem: Cannot SSH to EC2

**Symptoms**: `ssh: connect to host ... port 22: Connection refused`

**Solutions**:

```bash
# 1. Check EC2_KEY is correct
ls -la ~/.ssh/ec2-key.pem
chmod 400 ~/.ssh/ec2-key.pem

# 2. Check security group (port 22 open)
# In AWS Console: EC2 → Security Groups → Inbound Rules

# 3. Try with verbose output
ssh -vvv -i ~/.ssh/ec2-key.pem ec2-user@your-ec2-ip

# 4. Verify EC2_HOST is correct
# Should be public IP or elastic IP
```

### Problem: Containers Won't Start

**Symptoms**: `docker ps` shows no containers or "Exited"

**Solutions**:

```bash
# 1. Check logs
docker compose logs

# 2. Check docker-compose.yml syntax
docker compose config

# 3. Pull images manually
docker pull ghcr.io/your-repo/portfolio:latest

# 4. Start with verbose output
docker compose up --verbose

# 5. Check disk space
df -h
```

### Problem: App Container Crashes

**Symptoms**: `docker logs portfolio_app` shows errors

**Common causes**:

```bash
# Database connection failed
docker logs portfolio_app | grep -i database

# Missing environment variables
docker exec portfolio_app env | grep GIT_COMMIT

# Port already in use
docker ps | grep 8000
```

**Fix**:

```bash
# Remove and restart
docker compose down
docker compose up -d

# Check health
docker ps --filter name=portfolio
```

### Problem: Health Checks Failing

**Symptoms**: `docker ps` shows `(unhealthy)` status

**Solutions**:

```bash
# 1. Check health logs
docker inspect portfolio_app | grep -i health

# 2. Manual health check
docker exec portfolio_app curl http://127.0.0.1:8000/health

# 3. Check logs for startup errors
docker logs portfolio_app | grep -i error

# 4. Increase start_period if starting slow
# Edit docker-compose.yml, increase start_period: 30s
```

### Problem: Nginx Cannot Route to App

**Symptoms**: `curl http://localhost` returns error or timeout

**Solutions**:

```bash
# 1. Check nginx config
docker exec portfolio_nginx nginx -T | grep upstream

# 2. Test from nginx container
docker exec portfolio_nginx curl app:8000/health

# 3. Check network
docker network inspect portfolio_network | grep portfolio_app

# 4. Check nginx logs
docker logs portfolio_nginx | grep error
```

### Problem: Database Connection Failed

**Symptoms**: `/health/ready` returns `{"database": "disconnected"}`

**Solutions**:

```bash
# 1. Check database is running
docker ps | grep portfolio_db

# 2. Check database logs
docker logs portfolio_db

# 3. Test connection manually
docker exec portfolio_app psql postgresql://postgres:password@db:5432/portfolio_db -c "SELECT 1;"

# 4. Verify DATABASE_URL environment variable
docker exec portfolio_app env | grep DATABASE_URL
```

---

## 📊 Success Indicators

When everything is working correctly, you should see:

```bash
# Terminal 1: Check containers
$ docker ps
CONTAINER ID   IMAGE                    NAMES              STATUS
abc123...      postgres:15-alpine       portfolio_db       Up 2m (healthy)
def456...      ghcr.io/you/portfolio:.. portfolio_app      Up 2m (healthy)
ghi789...      nginx:alpine             portfolio_nginx    Up 2m (healthy)

# Terminal 2: Check commit
$ docker exec portfolio_app curl -s http://127.0.0.1:8000/meta | jq '.commit'
"abc1234567890abcdef1234567890abcdef1234"

# Terminal 3: Check public access
$ curl http://your-ec2-ip/meta | jq '.commit'
"abc1234567890abcdef1234567890abcdef1234"

# Terminal 4: Check logs
$ docker logs portfolio_app | grep APP_START
APP_START COMMIT=abc1234567890abcdef BUILD_TIME=2024-01-15T10:30:45Z TS=1705322445
```

---

## 🎉 Verification Complete!

If all checks pass, you have successfully:

✅ Built Docker image with commit SHA embedded  
✅ Deployed to EC2 with artifact provenance  
✅ Verified metadata is accessible via `/meta` endpoint  
✅ Confirmed startup logs show commit information  
✅ Ensured all services communicate via docker network (no localhost)  
✅ Validated complete request traceability from nginx → app → db

**Your deployment now proves: "This exact code at commit abc123... is running on EC2!"** 🚀
