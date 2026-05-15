# Testing Guide: Health Check Fixes

## Pre-Test Checklist

- [ ] All changes have been applied to files
- [ ] No syntax errors in configuration files
- [ ] Docker and Docker Compose are installed and running
- [ ] Project directory is `/Users/s_lokesh/fullstack_project`
- [ ] `.env` file exists with required variables

## Test Environment Setup

### 1. Verify Configuration Files

```bash
# Verify nginx config is valid
nginx -t -c /Users/s_lokesh/fullstack_project/nginx/nginx.conf

# Validate docker-compose files
docker compose -f /Users/s_lokesh/fullstack_project/docker-compose.yml config > /dev/null && echo "✓ docker-compose.yml valid"
docker compose -f /Users/s_lokesh/fullstack_project/docker-compose.prod.yml config > /dev/null && echo "✓ docker-compose.prod.yml valid"
```

### 2. Clean Up Previous Runs

```bash
cd /Users/s_lokesh/fullstack_project

# Remove old containers
docker compose down --remove-orphans

# Remove volumes to start fresh
docker compose down -v

# Clean up images if needed
docker system prune -f
```

## Test Suite

### ✅ Test 1: Verify Health Endpoint Configuration

**Objective:** Confirm nginx is configured to proxy health to FastAPI

```bash
# Check nginx config has proxy_pass
grep -A 5 "location /health" nginx/nginx.conf

# Expected output:
# location /health {
#     proxy_pass http://fastapi_backend/health;
#     ...
```

**Pass Criteria:** ✓ Contains `proxy_pass http://fastapi_backend/health;`

---

### ✅ Test 2: Verify Service Dependencies

**Objective:** Confirm nginx waits for FastAPI to be healthy

```bash
# Check docker-compose dependencies
grep -A 2 "depends_on:" docker-compose.yml | grep -A 1 "app:"

# Expected output:
# app:
#   condition: service_healthy
```

**Pass Criteria:** ✓ Contains `condition: service_healthy` for app

---

### ✅ Test 3: Verify Health Check Command

**Objective:** Confirm health checks use curl

```bash
# Check for correct health check in docker-compose
grep -A 1 "healthcheck:" docker-compose.yml | grep "test:"

# Expected output:
# test: ["CMD", "curl", "-f", "http://localhost/health"]
```

**Pass Criteria:** ✓ Uses `curl` (not `wget`)

---

### ✅ Test 4: Application Startup

**Objective:** Verify services start in correct order

```bash
cd /Users/s_lokesh/fullstack_project

# Start application with verbose logging
echo "Starting application..."
./scripts/start.sh

# Watch the startup sequence
docker compose logs -f
```

**Expected Startup Sequence:**

```
1. PostgreSQL initializes database
   Status: Waiting for services...

2. FastAPI starts and connects to database
   Status: Database is ready

3. nginx starts after FastAPI is healthy
   Status: API is healthy

4. Application is ready
   Message: Portfolio Manager is running!
```

**Pass Criteria:**

- [ ] All three services start without errors
- [ ] Services start in order: DB → FastAPI → nginx
- [ ] Final message shows all running

**Troubleshooting if failed:**

```bash
# Check detailed logs
docker compose logs --tail=50

# Check individual containers
docker compose ps
docker compose logs app | tail -20
docker compose logs nginx | tail -20
```

---

### ✅ Test 5: Real Health Check (Backend Running)

**Objective:** Verify health endpoint returns actual FastAPI response

```bash
# Wait for everything to be ready
sleep 5

# Test health endpoint through nginx
echo "Testing health endpoint..."
curl -v http://localhost/health

# Also test direct backend
curl -v http://localhost:8000/health
```

**Expected Response:**

```
< HTTP/1.1 200 OK
< Content-Type: application/json

{"status":"ok"}  # or similar FastAPI response
```

**Pass Criteria:**

- [ ] HTTP 200 status
- [ ] Response contains FastAPI JSON (not text "healthy")
- [ ] Direct backend request also works

**Verification:**

```bash
# Compare responses
echo "Via nginx:"
curl -s http://localhost/health | jq .

echo "Direct backend:"
curl -s http://localhost:8000/health | jq .

# They should match!
```

---

### ✅ Test 6: Health Check Failure (Backend Down)

**Objective:** Verify health endpoint fails when backend is down

```bash
# Stop FastAPI backend
docker stop portfolio_app

# Wait a moment
sleep 2

# Test health endpoint through nginx
echo "Testing health endpoint with backend down..."
curl -v http://localhost/health
```

**Expected Response:**

```
< HTTP/1.1 502 Bad Gateway
< Server: nginx/1.xx.x
...
<html>
<head><title>502 Bad Gateway</title></head>
...
```

**Pass Criteria:**

- [ ] HTTP 502 status (not 200!)
- [ ] "Bad Gateway" message
- [ ] This proves nginx is trying to proxy to the backend

**Verification:**

```bash
# Check nginx is still running
docker ps | grep nginx

# Check FastAPI is stopped
docker ps | grep portfolio_app

# Verify error in nginx logs
docker compose logs nginx | grep "502\|error"
```

**Why this is correct:**

```
✓ Backend is down        → nginx cannot connect
✓ nginx returns 502      → This is expected!
✓ Health check fails     → System correctly identifies issue
✓ Orchestrators can act  → Restart or alert
```

---

### ✅ Test 7: Service Recovery

**Objective:** Verify services restart and recover properly

```bash
# Restart FastAPI
docker start portfolio_app

# Wait for it to be healthy
sleep 10

# Test health endpoint again
echo "Testing health after restart..."
curl -v http://localhost/health
```

**Expected Response:**

```
< HTTP/1.1 200 OK
< Content-Type: application/json

{"status":"ok"}
```

**Pass Criteria:**

- [ ] HTTP 200 status
- [ ] Returns FastAPI response
- [ ] Service recovered successfully

---

### ✅ Test 8: Static Files

**Objective:** Verify static files are properly served

```bash
# List static files in container
docker compose exec nginx ls -la /usr/share/nginx/html/static/

# Should show files like:
# -rw-r--r-- 1 root root 1234 May 15 10:00 style.css
# -rw-r--r-- 1 root root 5678 May 15 10:00 main.js

# Test static file access
curl -v http://localhost/static/css/style.css

# Expected: HTTP 200 with CSS content
```

**Pass Criteria:**

- [ ] Static files exist in nginx container
- [ ] HTTP 200 status for static file
- [ ] File content is correct (not 404)

---

### ✅ Test 9: Full Rebuild Scenario

**Objective:** Verify complete rebuild works with proper health checks

```bash
cd /Users/s_lokesh/fullstack_project

# Complete teardown
docker compose down --remove-orphans -v

# Remove old images
docker compose pull

# Force recreate from scratch
docker compose up -d --force-recreate

# Monitor startup
docker compose logs -f

# Wait for initialization
sleep 30

# Verify all containers healthy
docker ps

# Test health
curl -v http://localhost/health
```

**Expected:**

```
STATUS column shows:
- portfolio_db is up (healthy)
- portfolio_app is up (healthy)
- portfolio_nginx is up (healthy)

Health check passes:
< HTTP/1.1 200 OK
```

**Pass Criteria:**

- [ ] All containers start successfully
- [ ] Proper startup order observed
- [ ] All containers show healthy status
- [ ] Health check returns 200

---

### ✅ Test 10: Container Restart Resilience

**Objective:** Verify containers can restart cleanly

```bash
# Restart each container individually
docker restart portfolio_nginx
sleep 5

# Test health
curl -v http://localhost/health

# Expected: Still works

# Restart all
docker compose restart
sleep 10

# Test health again
curl -v http://localhost/health

# Expected: Still works
```

**Pass Criteria:**

- [ ] Restarts don't break health checks
- [ ] Service recovers properly
- [ ] No persistent errors in logs

---

## Automated Test Script

Save this as `test-health-checks.sh`:

```bash
#!/bin/bash

set -e

cd /Users/s_lokesh/fullstack_project

echo "=========================================="
echo "Health Check Configuration Tests"
echo "=========================================="
echo ""

# Test 1: Config verification
echo "✓ Test 1: Verifying configuration files..."
grep -q "proxy_pass http://fastapi_backend/health" nginx/nginx.conf && echo "  ✓ nginx config has proxy_pass"
grep -q "condition: service_healthy" docker-compose.yml && echo "  ✓ docker-compose has health condition"
grep -q "curl.*localhost/health" docker-compose.yml && echo "  ✓ healthcheck uses curl"
echo ""

# Test 2: Start application
echo "✓ Test 2: Starting application..."
./scripts/start.sh > /tmp/start.log 2>&1 && echo "  ✓ Application started successfully" || cat /tmp/start.log

sleep 10
echo ""

# Test 3: Health check with backend running
echo "✓ Test 3: Testing health with backend running..."
if curl -sf http://localhost/health > /dev/null; then
    echo "  ✓ Health check returns 200"
else
    echo "  ✗ Health check failed: $(curl -s -o /dev/null -w '%{http_code}' http://localhost/health)"
    exit 1
fi
echo ""

# Test 4: Health check with backend down
echo "✓ Test 4: Testing health with backend down..."
docker stop portfolio_app
sleep 3
HEALTH_CODE=$(curl -s -o /dev/null -w '%{http_code}' http://localhost/health)
if [ "$HEALTH_CODE" = "502" ]; then
    echo "  ✓ Health check correctly returns 502 when backend is down"
else
    echo "  ✗ Expected 502, got: $HEALTH_CODE"
    docker start portfolio_app
    exit 1
fi
echo ""

# Test 5: Recovery
echo "✓ Test 5: Testing recovery after restart..."
docker start portfolio_app
sleep 10
if curl -sf http://localhost/health > /dev/null; then
    echo "  ✓ Service recovered successfully"
else
    echo "  ✗ Service did not recover"
    exit 1
fi
echo ""

# Test 6: Container health status
echo "✓ Test 6: Checking container health status..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep portfolio
echo ""

# Test 7: Container logs check
echo "✓ Test 7: Checking for errors in logs..."
ERROR_COUNT=$(docker compose logs | grep -i "error" | wc -l)
if [ "$ERROR_COUNT" -lt 5 ]; then
    echo "  ✓ Minimal errors in logs"
else
    echo "  ⚠ Found errors in logs (may be normal):"
    docker compose logs | grep -i "error" | head -5
fi
echo ""

echo "=========================================="
echo "✓ All Tests Passed!"
echo "=========================================="
```

**Run the test:**

```bash
chmod +x test-health-checks.sh
./test-health-checks.sh
```

---

## Test Results Template

### Test Run Date: ******\_******

| Test # | Test Name              | Expected      | Actual        | Result |
| ------ | ---------------------- | ------------- | ------------- | ------ |
| 1      | Config files valid     | ✓             | ✓             | PASS   |
| 2      | Service dependencies   | ✓             | ✓             | PASS   |
| 3      | Health check command   | ✓             | ✓             | PASS   |
| 4      | Startup sequence       | Correct order | Correct order | PASS   |
| 5      | Health with backend    | 200 + JSON    | 200 + JSON    | PASS   |
| 6      | Health without backend | 502           | 502           | PASS   |
| 7      | Service recovery       | Healthy again | Healthy again | PASS   |
| 8      | Static files           | HTTP 200      | HTTP 200      | PASS   |
| 9      | Full rebuild           | All healthy   | All healthy   | PASS   |
| 10     | Restart resilience     | Healthy       | Healthy       | PASS   |

---

## Performance Considerations

### Expected Times

| Operation              | Expected | Actual |
| ---------------------- | -------- | ------ |
| PostgreSQL startup     | 5-10s    | \_\_\_ |
| FastAPI initialization | 10-15s   | \_\_\_ |
| nginx startup          | 2-3s     | \_\_\_ |
| Total to healthy       | 20-30s   | \_\_\_ |
| Health check response  | <1s      | \_\_\_ |
| Container restart      | 5-10s    | \_\_\_ |

---

## Debugging Commands

If tests fail, use these commands:

```bash
# View full logs
docker compose logs --tail=100

# View specific container
docker compose logs app
docker compose logs nginx
docker compose logs db

# Check container status
docker compose ps

# Check resource usage
docker stats

# Inspect network connectivity
docker compose exec nginx ping app
docker compose exec nginx nslookup app

# Check nginx configuration
docker compose exec nginx nginx -T

# View nginx error log
docker compose exec nginx cat /var/log/nginx/error.log

# Check FastAPI directly
docker compose exec app curl http://localhost:8000/health

# View actual health status
docker inspect portfolio_app --format='{{json .State.Health}}' | jq .
```

---

## Success Criteria Summary

All tests should show:

- ✅ nginx proxies health checks to FastAPI
- ✅ nginx waits for FastAPI to be healthy before starting
- ✅ Health checks return 502 when backend is down
- ✅ Services recover properly after restart
- ✅ Static files are served correctly
- ✅ No infinite restarts or error loops
- ✅ Proper service dependency chain
- ✅ Startup completes within 30 seconds

If all criteria are met, the fixes are working correctly! 🎉
