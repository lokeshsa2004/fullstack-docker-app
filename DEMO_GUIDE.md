# End-to-End Provenance Demo Guide

**Complete demonstration showing how code flows through CI/CD with commit tracking, artifact provenance, deployment verification, and live request handling.**

---

## 📋 Quick Start

### Option 1: Full E2E Demo (Recommended)

```bash
chmod +x scripts/demo-e2e.sh
./scripts/demo-e2e.sh
```

### Option 2: Quick Demo (5 minutes)

```bash
chmod +x scripts/demo-quick.sh
./scripts/demo-quick.sh
```

### Option 3: Verify Running Services

```bash
chmod +x scripts/demo-verify.py
python3 scripts/demo-verify.py
```

---

## 🎯 What Gets Demonstrated

### 1️⃣ **Repository Provenance**

- Shows current git commit (`git rev-parse --short HEAD`)
- Verifies repository is clean (`git status --porcelain`)
- Records build timestamp

### 2️⃣ **Artifact Provenance (Docker Image)**

- Builds image with build args: `GIT_COMMIT` and `BUILD_TIME`
- Tags image with commit SHA: `portfolio:abc1234`
- Image labels include version metadata

### 3️⃣ **Deployment Verification**

- Containers start with environment variables injected
- Services become healthy (health checks pass)
- Database seeded with sample data

### 4️⃣ **Live Verification**

- **`/meta` endpoint** returns: `commit`, `build_time`, `app_start_time`, `app_version`
- Proves deployed commit matches local repository
- Verifies build metadata embedded in container

### 5️⃣ **Request Flow**

Shows complete journey of a request:

```
Client (curl/browser)
    ↓ (nginx routing)
nginx reverse proxy :80
    ↓ (forward to app)
FastAPI Application :8000
    ↓ (metrics middleware)
[Request metrics tracked]
    ↓ (business logic)
Handler → Database Query
    ↓ (serialize response)
Response + Metrics updated
    ↓
Client receives JSON/HTML
```

### 6️⃣ **Logging & Metrics**

- **Startup marker**: `APP_START COMMIT=abc1234 BUILD_TIME=2024-01-15T10:30:00Z TS=1705318200`
- **Request tracking**: Prometheus metrics increment
- **Error tracking**: 4xx/5xx errors logged and counted
- **Performance**: Request duration recorded in histogram

### 7️⃣ **Full Callback Sequence**

#### Request 1: Health Check

```bash
curl http://localhost:8000/health
```

**Response:**

```json
{
  "status": "healthy",
  "message": "API is running"
}
```

#### Request 2: List Portfolios

```bash
curl http://localhost:8000/api/v1/portfolios
```

**Flow:**

1. nginx receives request, forwards to FastAPI
2. Metrics middleware increments `api_requests_total`
3. Handler queries database for portfolios
4. Database returns portfolio list
5. Response serialized to JSON
6. Metrics updated
7. Response sent to client

#### Request 3: Create Portfolio

```bash
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"My Portfolio","description":"Test"}'
```

**Flow:**

1. Request validation (Pydantic)
2. Database insert
3. `portfolio_created_total` counter incremented
4. Response with new portfolio ID
5. Metrics reflect success

#### Request 4: Add Investment

```bash
curl -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d '{"portfolio_id":1,"ticker":"AAPL","quantity":10,"purchase_price":150.00}'
```

**Flow:**

1. Validate investment data
2. Verify portfolio exists (DB query)
3. Insert investment record
4. `investment_added_total` counter incremented
5. Return created investment

---

## 🔍 Key Endpoints Explained

### Health & Provenance

**`GET /health`**

- Basic health check
- No dependencies
- Response: `{"status": "healthy"}`

**`GET /health/ready`**

- Readiness check
- Verifies database connectivity
- Response: `{"status": "ready"}`

**`GET /meta`** ⭐ **Key for Provenance**

```json
{
  "commit": "abc1234",
  "build_time": "2024-01-15T10:30:00Z",
  "app_start_time": 1705318200,
  "app_version": "1.0.0",
  "app_name": "Portfolio Manager API"
}
```

### Metrics

**`GET /metrics`**

- Prometheus-format metrics
- Shows all tracked counters, histograms, gauges
- Used by Prometheus scraper for monitoring

```
# HELP api_requests_total Total API Requests
# TYPE api_requests_total counter
api_requests_total{endpoint="/api/v1/portfolios",method="GET",status="200"} 5.0
api_requests_total{endpoint="/api/v1/portfolios",method="POST",status="201"} 2.0

# HELP api_request_duration_seconds API Request Duration
# TYPE api_request_duration_seconds histogram
api_request_duration_seconds_bucket{endpoint="/api/v1/portfolios",le="0.005",method="GET"} 3.0
api_request_duration_seconds_sum{endpoint="/api/v1/portfolios",method="GET"} 0.025
```

### API Endpoints

**`GET /api/v1/portfolios`** - List all portfolios
**`POST /api/v1/portfolios`** - Create portfolio
**`GET /api/v1/portfolios/{id}`** - Get specific portfolio
**`PATCH /api/v1/portfolios/{id}`** - Update portfolio
**`DELETE /api/v1/portfolios/{id}`** - Delete portfolio

**`GET /api/v1/investments`** - List all investments
**`POST /api/v1/investments`** - Create investment
**`GET /api/v1/investments/{id}`** - Get specific investment
**`GET /api/v1/investments/portfolio/{id}`** - Get portfolio's investments

### Frontend

**`GET /`** - Home page
**`GET /dashboard`** - Dashboard with portfolio management UI
**`GET /about`** - About & technology information

---

## 📊 Metrics Explained

### Counters (always increase)

- **`api_requests_total`**: Total requests by method/endpoint/status
- **`api_errors_total`**: Total errors (4xx/5xx)
- **`portfolio_created_total`**: Portfolios created
- **`investment_added_total`**: Investments created

### Gauges (can go up/down)

- **`api_inprogress_requests`**: Currently processing requests

### Histograms (track distribution)

- **`api_request_duration_seconds`**: Request latency distribution by endpoint

---

## 🚀 How to Run Each Demo

### Complete E2E Demo

**Duration**: ~2 minutes

```bash
./scripts/demo-e2e.sh
```

**Shows**:

- Repository status
- Docker build with provenance args
- Container startup
- Commit verification via `/meta`
- Startup logs with `APP_START` marker
- Health checks
- Full request/response flow
- Metrics collection
- Final summary with proof

### Quick Demo

**Duration**: ~30 seconds

```bash
./scripts/demo-quick.sh
```

**Shows**:

- Build image with commit
- Deploy containers
- Verify `/meta` endpoint
- Health status
- Portfolio count
- Metrics sample

### Verification Script

**Duration**: ~1 minute

```bash
# First, ensure services are running:
docker compose up -d

# Then run verification:
python3 scripts/demo-verify.py
```

**Shows**:

- Repository provenance check
- Deployed commit verification
- Health checks
- Portfolio CRUD operations
- Metrics collection
- Architecture explanation

---

## 🔄 How the Demo Proves Everything

### Repository Provenance ✓

```bash
# Step 1: Local commit
$ git rev-parse --short HEAD
abc1234

# Step 2: Build image with this commit as arg
$ docker build --build-arg GIT_COMMIT=abc1234 ...

# Step 3: Deploy container with env var set
$ docker run -e GIT_COMMIT=abc1234 portfolio:abc1234

# Step 4: Verify deployed commit
$ curl http://localhost:8000/meta
{"commit": "abc1234", ...}

# ✓ Proof: Same commit through entire pipeline!
```

### Startup Logging ✓

```bash
# In app logs:
$ docker logs portfolio_app | grep APP_START
2024-01-15T10:30:15 APP_START COMMIT=abc1234 BUILD_TIME=2024-01-15T10:30:00Z TS=1705318200

# ✓ Proof: Startup marker shows commit/build-time
```

### Request Flow ✓

```bash
# Before:
$ curl http://localhost:8000/metrics | grep api_requests_total
api_requests_total{...} 10.0

# Make requests:
$ for i in {1..5}; do curl http://localhost:8000/api/v1/portfolios; done

# After:
$ curl http://localhost:8000/metrics | grep api_requests_total
api_requests_total{...} 15.0

# ✓ Proof: Metrics increased by 5 (one for each request)
```

### Database Flow ✓

```bash
# Create portfolio (triggers INSERT):
$ curl -X POST http://localhost:8000/api/v1/portfolios \
    -d '{"name":"Test","description":"Desc"}'
{"id": 42, "name": "Test", ...}

# Verify in database:
$ docker exec portfolio_db psql -U postgres -d portfolio_db -c \
    "SELECT name FROM portfolios WHERE id=42;"
 name
------
 Test
(1 row)

# ✓ Proof: Data persisted in database
```

### Metrics Tracking ✓

```bash
# Each request updates metrics:
$ curl http://localhost:8000/metrics | grep portfolio_created_total
portfolio_created_total 5.0  # 5 portfolios created

$ curl http://localhost:8000/metrics | grep investment_added_total
investment_added_total 12.0  # 12 investments added

# ✓ Proof: Counters reflect actual operations
```

---

## 📝 Code Changes Made

### `backend/app/main.py`

- Added `os` import for environment variables
- Added `GIT_COMMIT` and `BUILD_TIME` from environment
- Added `APP_START_TIME` timestamp
- Added `/meta` endpoint returning provenance
- Enhanced startup log with `APP_START COMMIT=... BUILD_TIME=... TS=...`

### `backend/Dockerfile`

- Added `ARG GIT_COMMIT=dev`
- Added `ARG BUILD_TIME=dev`
- Set environment variables: `ENV GIT_COMMIT=$GIT_COMMIT` and `ENV BUILD_TIME=$BUILD_TIME`

### New Files

- `scripts/demo-e2e.sh` - Full end-to-end demo
- `scripts/demo-quick.sh` - Quick 30-second demo
- `scripts/demo-verify.py` - Python verification script
- `docker-compose.logging.yml` - Logging configuration override
- `DEMO_GUIDE.md` - This guide

---

## 🧪 Live Demonstration Walkthrough

### Scenario: Explaining Everything Through URLs

You can demo **everything by just hitting URLs and showing the responses**:

#### 1. Show Commit Tracking

```bash
# Show local commit
git rev-parse --short HEAD

# Show deployed commit
curl http://localhost:8000/meta | jq '.commit'

# They match! ✓
```

#### 2. Show Startup Logs

```bash
docker logs portfolio_app | grep APP_START
# Output: APP_START COMMIT=abc1234 BUILD_TIME=... TS=...
```

#### 3. Show Health

```bash
curl http://localhost:8000/health
curl http://localhost:8000/health/ready
```

#### 4. Show API Working

```bash
# Create portfolio
curl -X POST http://localhost:8000/api/v1/portfolios -d '{"name":"Test","description":"Test"}'

# List portfolios
curl http://localhost:8000/api/v1/portfolios

# Add investment
curl -X POST http://localhost:8000/api/v1/investments -d '{"portfolio_id":1,"ticker":"AAPL","quantity":10,"purchase_price":150}'

# List investments for portfolio
curl http://localhost:8000/api/v1/investments/portfolio/1
```

#### 5. Show Metrics

```bash
curl http://localhost:8000/metrics | grep -E "api_requests_total|portfolio_created_total|investment_added_total"
```

#### 6. Show Architecture

```bash
# View page to understand frontend
curl http://localhost/dashboard

# View API docs
curl http://localhost/docs
```

---

## ✅ Demo Checklist

Before presenting:

- [ ] Docker installed and running
- [ ] Git repository initialized
- [ ] Source code committed (clean status)
- [ ] Network interface accessible (localhost or DNS)

During demo:

- [ ] Show git commit locally
- [ ] Run build with commit arg
- [ ] Show image tagged with commit
- [ ] Start containers
- [ ] Hit `/meta` and show commit matches
- [ ] Make API requests
- [ ] Show metrics increasing
- [ ] Show logs with `APP_START` marker

After demo:

- [ ] Clean up: `docker compose down`
- [ ] Show how to restart: `./scripts/demo-quick.sh`

---

## 🛠️ Troubleshooting

### Services not starting

```bash
# Check logs
docker compose logs

# Verify services
docker ps

# Rebuild and restart
docker compose down -v
./scripts/demo-quick.sh
```

### Port already in use

```bash
# Find what's using port 8000
lsof -i :8000

# Or change docker-compose ports temporarily
sed -i 's/8000:8000/8001:8000/g' docker-compose.yml
```

### Cannot connect to localhost

```bash
# Check if services are actually running
docker ps -f "name=portfolio"

# Check container IP
docker inspect portfolio_app | grep IPAddress
```

### Metrics not updating

```bash
# Verify app is processing requests
docker logs portfolio_app | tail -20

# Check metrics endpoint
curl -v http://localhost:8000/metrics
```

---

## 📚 Additional Resources

- **OpenAPI Docs**: http://localhost:8000/docs
- **ReDoc Docs**: http://localhost:8000/redoc
- **Dashboard**: http://localhost/dashboard
- **About Page**: http://localhost/about

## 🔗 Related Files

- Main app: `backend/app/main.py`
- Dockerfile: `backend/Dockerfile`
- Config: `backend/app/core/config.py`
- Compose: `docker-compose.yml`
- Demo scripts: `scripts/demo-*.sh` and `scripts/demo-verify.py`

---

## 💡 Key Takeaways

1. **Code → Docker Image**: Build args embed commit SHA
2. **Image → Container**: Environment variables preserve metadata
3. **Container → /meta Endpoint**: Proves deployed code version
4. **Request → Logs**: Every operation logged with context
5. **Metrics → Observability**: Count and duration tracked
6. **Full Traceability**: From repo commit to running container to live metrics

This demo proves **complete artifact provenance** and **full request traceability** through your entire stack! 🎉
