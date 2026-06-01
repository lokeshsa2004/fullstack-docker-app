# CI/CD Provenance Integration & E2E Demo Setup

**Complete implementation for artifact provenance tracking, deployment verification, and end-to-end demonstrations.**

---

## 🎯 What's Implemented

### Core Changes

1. **Enhanced main.py** with provenance endpoints and startup logging
2. **Updated Dockerfile** with build arguments for commit/build-time tracking
3. **Demo Scripts** (3 variants) for different demonstration needs
4. **Logging Configuration** for Docker containers
5. **Documentation** for complete walkthrough

### Key Features

✅ Commit SHA embedded in Docker image  
✅ Build timestamp recorded  
✅ `/meta` endpoint for deployment verification  
✅ `APP_START` log marker with full provenance  
✅ Prometheus metrics for request tracking  
✅ Complete request flow documentation  
✅ Multiple demo scripts for different scenarios

---

## 🚀 Quick Start (Choose One)

### Option 1: Full Demonstration (Recommended)

```bash
chmod +x scripts/demo-e2e.sh
./scripts/demo-e2e.sh
```

**Duration**: 2 minutes  
**Shows**: Everything—from repo to running container to live requests  
**Output**: Step-by-step verification with colors and clear explanations

### Option 2: Quick Demo (5 Minutes)

```bash
chmod +x scripts/demo-quick.sh
./scripts/demo-quick.sh
```

**Duration**: ~30 seconds  
**Shows**: Build, deploy, verify endpoints  
**Output**: Concise summary

### Option 3: Verification Only

```bash
# First, ensure services running:
docker compose up -d

# Then:
chmod +x scripts/demo-verify.py
python3 scripts/demo-verify.py
```

**Duration**: 1 minute  
**Shows**: Comprehensive checks on running services  
**Output**: Detailed verification with all endpoints tested

---

## 📋 Complete File Changes

### Modified Files

#### 1. `backend/app/main.py`

**Changes**:

- Added `import os` and `import logging` and `import time`
- Added environment variables:
  ```python
  GIT_COMMIT = os.getenv("GIT_COMMIT", "dev-local")
  BUILD_TIME = os.getenv("BUILD_TIME", "dev-build")
  APP_START_TIME = int(time.time())
  ```
- Added `/meta` endpoint:
  ```python
  @app.get("/meta")
  def meta():
      return {
          "commit": GIT_COMMIT,
          "build_time": BUILD_TIME,
          "app_start_time": APP_START_TIME,
          "app_version": settings.app_version,
          "app_name": settings.app_name,
      }
  ```
- Enhanced startup logging:
  ```python
  logger.info(f"APP_START COMMIT={GIT_COMMIT} BUILD_TIME={BUILD_TIME} TS={APP_START_TIME}")
  ```

#### 2. `backend/Dockerfile`

**Changes**:

- Added build arguments:
  ```dockerfile
  ARG GIT_COMMIT=dev
  ARG BUILD_TIME=dev
  ```
- Set environment variables:
  ```dockerfile
  ENV GIT_COMMIT=$GIT_COMMIT
  ENV BUILD_TIME=$BUILD_TIME
  ```

### New Files

#### `scripts/demo-e2e.sh`

Full end-to-end demonstration showing:

- Repository status check
- Docker build with commit args
- Container deployment
- Provenance verification
- Health checks
- API request flow
- Metrics snapshot
- Complete summary

#### `scripts/demo-quick.sh`

Lightweight quick demo showing:

- Build with commit
- Start services
- Verify key endpoints

#### `scripts/demo-verify.py`

Python verification script showing:

- Repository provenance check
- Deployed commit verification
- Health checks
- Portfolio/Investment CRUD operations
- Metrics collection
- Architecture explanation

#### `docker-compose.logging.yml`

Docker Compose override for logging:

- JSON-file logging driver
- Log rotation (10m max size, 3 files)
- Container labels for identification
- Can be combined with main compose file

#### `DEMO_GUIDE.md`

Comprehensive guide with:

- Step-by-step walkthrough
- All endpoints explained
- Metrics interpretation
- Callback flow sequence
- Troubleshooting tips

#### `URL_REFERENCE.md`

Quick reference of all URLs:

- Health/provenance endpoints
- Metrics endpoints
- API endpoints with examples
- Frontend URLs
- Complete curl command examples

---

## 🏗️ CI/CD Integration

### GitHub Actions Example

Add to `.github/workflows/ci-cd.yml`:

```yaml
- name: Build Docker Image with Provenance
  run: |
    COMMIT=$(git rev-parse --short HEAD)
    BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    docker build \
      --build-arg GIT_COMMIT=$COMMIT \
      --build-arg BUILD_TIME="$BUILD_TIME" \
      -t myrepo/portfolio:$COMMIT \
      -t myrepo/portfolio:latest \
      -f backend/Dockerfile .

- name: Push to Registry
  run: |
    docker push myrepo/portfolio:$COMMIT
    docker push myrepo/portfolio:latest

- name: Deploy to Production
  run: |
    COMMIT=$(git rev-parse --short HEAD)
    docker pull myrepo/portfolio:$COMMIT
    docker compose -f docker-compose.prod.yml \
      -e GIT_COMMIT=$COMMIT \
      -e BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      up -d
```

### Local Build Command

```bash
#!/bin/bash
COMMIT=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

docker build \
  --build-arg GIT_COMMIT=$COMMIT \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t portfolio:$COMMIT \
  -f backend/Dockerfile .

echo "Built: portfolio:$COMMIT"
echo "Commit: $COMMIT"
echo "Build Time: $BUILD_TIME"
```

### Deployment with Environment Variables

```bash
#!/bin/bash
COMMIT=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Export for docker-compose
export GIT_COMMIT=$COMMIT
export BUILD_TIME="$BUILD_TIME"
export IMAGE_TAG="portfolio:$COMMIT"

# Deploy
docker compose \
  -f docker-compose.yml \
  -f docker-compose.logging.yml \
  up -d
```

---

## 🔍 Verifying Everything Works

### 1. Check Commit Traceability

```bash
# Local commit
git rev-parse --short HEAD
# Output: abc1234

# Deployed commit (from /meta endpoint)
curl http://localhost:8000/meta | jq '.commit'
# Output: "abc1234"

# Match? ✓ Provenance verified!
```

### 2. Check Startup Logs

```bash
docker logs portfolio_app | grep APP_START
# Output: APP_START COMMIT=abc1234 BUILD_TIME=2024-01-15T10:30:00Z TS=1705318200
```

### 3. Test API Flow

```bash
# Create portfolio
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","description":"Test"}'

# List portfolios
curl http://localhost:8000/api/v1/portfolios

# Add investment
curl -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d '{"portfolio_id":1,"ticker":"DEMO","quantity":10,"purchase_price":50}'
```

### 4. Verify Metrics

```bash
curl http://localhost:8000/metrics | grep -E "portfolio_created_total|investment_added_total"
```

---

## 📊 Demonstration Narrative

Use this when presenting to explain the complete flow:

### Part 1: Provenance (2 minutes)

> _"This is a full-stack application with complete artifact provenance tracking. Let me show you how we track code from commit through deployment."_

```bash
# Show local commit
git rev-parse --short HEAD

# Show deployed commit matches
curl http://localhost:8000/meta | jq '.commit'

# "Notice they're the same—this proves the container is running exactly the code from this repository."
```

### Part 2: Startup Logging (1 minute)

> _"When the app starts, we log a marker with the commit and build time."_

```bash
docker logs portfolio_app | grep APP_START

# "This log line proves: (1) the app started, (2) from this commit, (3) at this exact time."
```

### Part 3: Request Flow (3 minutes)

> _"Now let's trace a real request through the entire system."_

```bash
# Before: Check current metric
curl http://localhost:8000/metrics | grep portfolio_created_total

# Create a portfolio (this triggers several things)
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo Portfolio","description":"E2E Demo"}'

# The request flow:
# 1. curl sends HTTP POST to nginx
# 2. nginx forwards to FastAPI on port 8000
# 3. Metrics middleware intercepts request
# 4. Pydantic validates JSON
# 5. Handler creates portfolio in database
# 6. portfolio_created_total counter increments
# 7. Response serialized to JSON
# 8. Sent back to client

# After: Verify metric incremented
curl http://localhost:8000/metrics | grep portfolio_created_total
# "See how the counter went up by 1? That's tracking in real-time."
```

### Part 4: Database Persistence (1 minute)

> _"The data goes straight into PostgreSQL and persists."_

```bash
# Verify in database
docker exec portfolio_db psql -U postgres -d portfolio_db -c \
  "SELECT name FROM portfolios ORDER BY id DESC LIMIT 1;"

# "There's our data in the database—not cached, actually persisted."
```

### Part 5: Full Ecosystem (1 minute)

> _"Let's see everything together:"_

- **Frontend**: http://localhost/dashboard
- **API Docs**: http://localhost:8000/docs
- **Metrics**: curl http://localhost:8000/metrics
- **Health**: curl http://localhost:8000/health

---

## 🔄 The Complete Workflow

```
Developer writes code
    ↓
git commit & push
    ↓
[CI/CD Pipeline]
├─ Get commit SHA
├─ Get build time
├─ Build Docker image with --build-arg GIT_COMMIT=... BUILD_TIME=...
├─ Tag image with commit: portfolio:abc1234
└─ Push to registry
    ↓
[Deployment]
├─ Pull image: portfolio:abc1234
├─ Run container with -e GIT_COMMIT=abc1234 BUILD_TIME=...
└─ Start services
    ↓
[Verification]
├─ curl /meta → returns commit abc1234 ✓
├─ docker logs | grep APP_START → shows commit ✓
├─ curl /health → healthy ✓
├─ Make requests → metrics update ✓
└─ Deployed code verified! ✓
```

---

## 🧪 Metrics Explained

### Counters (always increase)

- `api_requests_total` - Total requests by endpoint/method/status
- `api_errors_total` - Total errors (4xx/5xx)
- `portfolio_created_total` - Portfolios created
- `investment_added_total` - Investments created

### Gauges (can go up/down)

- `api_inprogress_requests` - Currently processing requests

### Histograms (track timing)

- `api_request_duration_seconds` - Request latency by endpoint

**Example metrics output:**

```
api_requests_total{endpoint="/api/v1/portfolios",method="POST",status="201"} 1.0
api_request_duration_seconds_sum{endpoint="/api/v1/portfolios",method="POST"} 0.025
portfolio_created_total 1.0
```

This shows: 1 portfolio created, took 0.025 seconds, returned status 201 (Created).

---

## 📚 Files Reference

| File                         | Purpose                                          |
| ---------------------------- | ------------------------------------------------ |
| `backend/app/main.py`        | Core app with /meta endpoint and startup logging |
| `backend/Dockerfile`         | Multi-stage build with provenance args           |
| `scripts/demo-e2e.sh`        | Full end-to-end demonstration (2 min)            |
| `scripts/demo-quick.sh`      | Quick 30-second demo                             |
| `scripts/demo-verify.py`     | Python verification script                       |
| `docker-compose.logging.yml` | Logging configuration override                   |
| `DEMO_GUIDE.md`              | Comprehensive guide                              |
| `URL_REFERENCE.md`           | All URLs with examples                           |
| `CI_CD_INTEGRATION.md`       | **← This file**                                  |

---

## 🎓 How to Explain Everything via URLs

You need **zero additional tools**—just URLs:

```bash
# 1. Show commit is embedded
git rev-parse --short HEAD                    # Local: abc1234
curl http://localhost:8000/meta | jq '.commit' # Deployed: abc1234

# 2. Show health
curl http://localhost:8000/health | jq '.status'

# 3. Show request creates data
curl -X POST http://localhost:8000/api/v1/portfolios \
  -d '{"name":"Demo","description":"Test"}'

# 4. Show data persists
curl http://localhost:8000/api/v1/portfolios

# 5. Show metrics track it
curl http://localhost:8000/metrics | grep portfolio_created_total

# 6. Show logs record it
docker logs portfolio_app | grep "APP_START\|portfolio"
```

**That's the entire system in 6 commands!** 🎉

---

## ✅ Demo Checklist

Before presenting:

- [ ] Repository is clean (`git status`)
- [ ] Docker is running
- [ ] Port 8000/80 available
- [ ] Run one of the demo scripts once to ensure everything works

During presentation:

- [ ] Show git commit locally
- [ ] Show /meta endpoint matches
- [ ] Show health checks pass
- [ ] Create/read/update operations
- [ ] Show metrics increase
- [ ] Show logs with APP_START marker

---

## 🆘 Troubleshooting

### Services won't start

```bash
# Check what's running
docker ps -a

# View errors
docker compose logs

# Clean restart
docker compose down -v
./scripts/demo-quick.sh
```

### Ports already in use

```bash
# Find what's using port 8000
lsof -i :8000
# Kill it or use different port

# Temporary: modify docker-compose
sed -i 's/8000:8000/8001:8000/g' docker-compose.yml
```

### Commit doesn't match in /meta

```bash
# Verify build args were passed
docker inspect portfolio:abc1234 | grep -A5 GIT_COMMIT

# Rebuild without cache
docker compose build --no-cache
```

---

## 🚀 Production Deployment

### Environment-Based Deployment

```bash
#!/bin/bash
set -e

# Get current commit and build time
COMMIT=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REGISTRY="docker.io/yourrepo"

# Build for production
docker build \
  --build-arg GIT_COMMIT=$COMMIT \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t ${REGISTRY}/portfolio:${COMMIT} \
  -t ${REGISTRY}/portfolio:latest \
  -f backend/Dockerfile .

# Push to registry
docker push ${REGISTRY}/portfolio:${COMMIT}
docker push ${REGISTRY}/portfolio:latest

# Deploy
export GIT_COMMIT=$COMMIT
export BUILD_TIME="$BUILD_TIME"
export REGISTRY=$REGISTRY

docker compose -f docker-compose.prod.yml up -d
```

### Kubernetes Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portfolio-app
spec:
  containers:
    - name: app
      image: myrepo/portfolio:abc1234
      env:
        - name: GIT_COMMIT
          value: "abc1234"
        - name: BUILD_TIME
          value: "2024-01-15T10:30:00Z"
      livenessProbe:
        httpGet:
          path: /health
          port: 8000
        initialDelaySeconds: 10
      readinessProbe:
        httpGet:
          path: /health/ready
          port: 8000
        initialDelaySeconds: 5
```

---

## 💡 Key Learnings

1. **Immutable Artifacts**: Image tag = commit SHA (example: `portfolio:abc1234`)
2. **Provenance in Code**: Environment variables passed at build/runtime
3. **Verification Endpoint**: `/meta` proves deployed code version
4. **Log Markers**: `APP_START COMMIT=...` in logs for CloudWatch/ELK parsing
5. **Metrics Tracking**: Prometheus counters for operational observability
6. **Full Traceability**: repo → image → container → running → logs → metrics

---

## 📞 Questions?

Every aspect of this system demonstrates:

- ✅ Where the code came from (commit)
- ✅ When it was built (timestamp)
- ✅ What version is running (via /meta)
- ✅ How requests flow (logs + metrics)
- ✅ Where data lives (database)
- ✅ Why it matters (complete audit trail)

**Present it all through URLs!** 🎉

---

## Next Steps

1. **Try the demo**: `./scripts/demo-quick.sh`
2. **Read the guide**: `DEMO_GUIDE.md`
3. **Reference URLs**: `URL_REFERENCE.md`
4. **Run verification**: `python3 scripts/demo-verify.py`
5. **Show the team**: Present the flow they understand

Good luck! 🚀
