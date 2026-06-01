# Portfolio Manager: URL Reference for E2E Demo

## 🎯 All Demonstration URLs

Use these URLs directly in your browser or with curl to explain every aspect of the system.

---

## ✅ Health & Provenance URLs

### Health Check

```
GET http://localhost:8000/health
```

Response:

```json
{
  "status": "healthy",
  "message": "API is running"
}
```

**Explanation**: Basic health endpoint with no dependencies.

### Readiness Check

```
GET http://localhost:8000/health/ready
```

Response:

```json
{
  "status": "ready",
  "message": "API is ready to serve requests"
}
```

**Explanation**: Verifies database connectivity; readiness for traffic.

### Meta Endpoint (⭐ Key for Provenance)

```
GET http://localhost:8000/meta
```

Response:

```json
{
  "commit": "abc1234",
  "build_time": "2024-01-15T10:30:00Z",
  "app_start_time": 1705318200,
  "app_version": "1.0.0",
  "app_name": "Portfolio Manager API"
}
```

**Explanation**: **Shows deployed commit hash**. Compare with `git rev-parse --short HEAD` to prove it's your code!

---

## 📊 Metrics URLs

### Prometheus Metrics

```
GET http://localhost:8000/metrics
```

Returns: Text-format Prometheus metrics

```
api_requests_total{endpoint="/api/v1/portfolios",method="GET",status="200"} 15.0
api_errors_total{endpoint="/api/v1/portfolios",method="GET",status="400"} 2.0
portfolio_created_total 5.0
investment_added_total 12.0
api_inprogress_requests 0.0
api_request_duration_seconds_sum{endpoint="/api/v1/portfolios",method="GET"} 0.025
```

**Explanation**: Live metrics showing request counts, errors, and timings.

---

## 🏠 Frontend URLs

### Home Page

```
GET http://localhost/
```

or

```
GET http://localhost:8000/
```

**Explanation**: Welcome page with app overview and links.

### Dashboard

```
GET http://localhost/dashboard
```

or

```
GET http://localhost:8000/dashboard
```

**Explanation**: Interactive portfolio management interface.

### About Page

```
GET http://localhost/about
```

or

```
GET http://localhost:8000/about
```

**Explanation**: Technology stack and information.

---

## 📡 API Documentation URLs

### OpenAPI/Swagger

```
GET http://localhost:8000/docs
```

**Explanation**: Interactive API documentation where you can test endpoints.

### ReDoc

```
GET http://localhost:8000/redoc
```

**Explanation**: Alternative API documentation format.

---

## 💼 Portfolio API URLs

### List All Portfolios

```
GET http://localhost:8000/api/v1/portfolios
```

Response:

```json
[
  {
    "id": 1,
    "name": "Tech Stocks",
    "description": "Growth portfolio",
    "created_at": "2024-01-15T10:00:00",
    "updated_at": "2024-01-15T10:00:00",
    "investments": []
  },
  ...
]
```

### Get Single Portfolio

```
GET http://localhost:8000/api/v1/portfolios/{id}
```

Example:

```
GET http://localhost:8000/api/v1/portfolios/1
```

### Create Portfolio

```
POST http://localhost:8000/api/v1/portfolios
Content-Type: application/json

{
  "name": "My Portfolio",
  "description": "Created during demo"
}
```

curl example:

```bash
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"My Portfolio","description":"Demo"}'
```

Response:

```json
{
  "id": 42,
  "name": "My Portfolio",
  "description": "Created during demo",
  "created_at": "2024-01-15T10:35:00",
  "updated_at": "2024-01-15T10:35:00",
  "investments": []
}
```

### Update Portfolio

```
PATCH http://localhost:8000/api/v1/portfolios/{id}
Content-Type: application/json

{
  "name": "Updated Name",
  "description": "Updated description"
}
```

### Delete Portfolio

```
DELETE http://localhost:8000/api/v1/portfolios/{id}
```

---

## 💰 Investment API URLs

### List All Investments

```
GET http://localhost:8000/api/v1/investments
```

### List Investments for a Portfolio

```
GET http://localhost:8000/api/v1/investments/portfolio/{portfolio_id}
```

Example:

```
GET http://localhost:8000/api/v1/investments/portfolio/1
```

Response:

```json
[
  {
    "id": 1,
    "portfolio_id": 1,
    "ticker": "AAPL",
    "quantity": 10,
    "purchase_price": 150.00,
    "current_price": 175.50,
    "created_at": "2024-01-15T10:00:00",
    "updated_at": "2024-01-15T10:00:00"
  },
  ...
]
```

### Get Single Investment

```
GET http://localhost:8000/api/v1/investments/{id}
```

### Create Investment

```
POST http://localhost:8000/api/v1/investments
Content-Type: application/json

{
  "portfolio_id": 1,
  "ticker": "AAPL",
  "quantity": 10,
  "purchase_price": 150.00
}
```

curl example:

```bash
curl -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d '{"portfolio_id":1,"ticker":"AAPL","quantity":10,"purchase_price":150.00}'
```

### Update Investment

```
PATCH http://localhost:8000/api/v1/investments/{id}
Content-Type: application/json

{
  "quantity": 20,
  "purchase_price": 155.00
}
```

### Delete Investment

```
DELETE http://localhost:8000/api/v1/investments/{id}
```

---

## 🔄 Complete Demonstration Flow

### 1. Verify Commit (Provenance)

```bash
# Local
git rev-parse --short HEAD
# Output: abc1234

# Deployed
curl http://localhost:8000/meta | jq '.commit'
# Output: "abc1234"

# ✓ Matches!
```

### 2. Check Health

```bash
curl http://localhost:8000/health
curl http://localhost:8000/health/ready
```

### 3. Create Portfolio (Request → Metrics)

```bash
# Before: Check metrics
curl http://localhost:8000/metrics | grep portfolio_created_total

# Create portfolio (triggers metric increment)
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo Portfolio","description":"E2E Demo"}'

# After: Check metrics (count increased by 1)
curl http://localhost:8000/metrics | grep portfolio_created_total
```

### 4. Add Investment

```bash
curl -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d '{"portfolio_id":1,"ticker":"DEMO","quantity":100,"purchase_price":50.00}'
```

### 5. View Metrics Increase

```bash
curl http://localhost:8000/metrics | grep -E "api_requests_total|investment_added_total"
```

### 6. Verify in Dashboard

```
Open browser: http://localhost/dashboard
```

---

## 🐳 Docker/Service URLs

### Backend Service

- **Host**: localhost:8000
- **Container**: portfolio_app

### Frontend (via nginx)

- **Host**: localhost:80
- **Container**: portfolio_nginx

### Database

- **Host**: localhost:5432
- **Container**: portfolio_db
- **Database**: portfolio_db

---

## 📋 Example curl Commands (Copy-Paste Ready)

### Quick Demo Sequence

```bash
# 1. Check commit
curl http://localhost:8000/meta | jq '.commit'

# 2. Health
curl http://localhost:8000/health | jq '.status'

# 3. List portfolios
curl http://localhost:8000/api/v1/portfolios | jq 'length'

# 4. Create portfolio
PORTFOLIO=$(curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo Portfolio","description":"Test"}' | jq '.id')
echo "Portfolio ID: $PORTFOLIO"

# 5. Add investment
curl -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d "{\"portfolio_id\":$PORTFOLIO,\"ticker\":\"DEMO\",\"quantity\":100,\"purchase_price\":50.00}"

# 6. View metrics
curl http://localhost:8000/metrics | grep portfolio_created_total
```

---

## 🔍 Log Viewing Commands

```bash
# View app logs
docker logs portfolio_app -f

# View app startup logs
docker logs portfolio_app | grep APP_START

# View database logs
docker logs portfolio_db -f

# View nginx logs
docker logs portfolio_nginx -f

# View all logs
docker compose logs -f
```

---

## 💾 Summary Table

| What                      | URL                                                                             | Explains                        |
| ------------------------- | ------------------------------------------------------------------------------- | ------------------------------- |
| **Commit Provenance**     | `GET /meta`                                                                     | Deployed commit SHA             |
| **Health**                | `GET /health`                                                                   | App is running                  |
| **Readiness**             | `GET /health/ready`                                                             | DB is connected                 |
| **Metrics**               | `GET /metrics`                                                                  | Request counts, timing, errors  |
| **Metrics Help**          | Grep: `api_requests_total`, `portfolio_created_total`, `investment_added_total` | Request tracking                |
| **Portfolios List**       | `GET /api/v1/portfolios`                                                        | All portfolios                  |
| **Portfolio Create**      | `POST /api/v1/portfolios`                                                       | New portfolio                   |
| **Investments List**      | `GET /api/v1/investments`                                                       | All investments                 |
| **Portfolio Investments** | `GET /api/v1/investments/portfolio/1`                                           | Investments for portfolio       |
| **Investment Create**     | `POST /api/v1/investments`                                                      | New investment (creates metric) |
| **Docs**                  | `GET /docs`                                                                     | Interactive API docs            |
| **Dashboard**             | `GET /dashboard`                                                                | UI for management               |
| **Home**                  | `GET /`                                                                         | Welcome page                    |

---

## 🎓 Explanation Script

Use this narrative when demoing:

> **Step 1: Show Git Commit**
>
> ```bash
> git rev-parse --short HEAD
> # Output: abc1234
> ```
>
> _"This is our current code commit. Everything we deploy must trace back to this exact commit."_
>
> **Step 2: Show Meta Endpoint**
>
> ```bash
> curl http://localhost:8000/meta | jq '.commit'
> # Output: "abc1234"
> ```
>
> _"This container was built from that exact same commit. Proof of what code is running!"_
>
> **Step 3: Show Request Flow**
>
> ```bash
> curl http://localhost:8000/api/v1/portfolios
> # Returns JSON list of portfolios
> ```
>
> _"When we hit this endpoint, a request flows through nginx → FastAPI → Database → Metrics tracked → Response serialized and sent back."_
>
> **Step 4: Show Metrics**
>
> ```bash
> curl http://localhost:8000/metrics | grep api_requests_total
> # Shows counter incremented by 1
> ```
>
> _"Every request was tracked by our Prometheus middleware. We can see exactly how many requests hit each endpoint."_
>
> **Step 5: Show Logs**
>
> ```bash
> docker logs portfolio_app | grep APP_START
> # Shows: APP_START COMMIT=abc1234 BUILD_TIME=... TS=...
> ```
>
> _"Startup logs prove the commit was embedded at build time and is now running in production."_

---

## ✨ That's Everything!

All the URLs above completely demonstrate:

- ✅ Code provenance (repo → artifact)
- ✅ Request flow (client → nginx → app → db)
- ✅ Metrics tracking (counters, histograms, gauges)
- ✅ Logging (startup, requests, errors)
- ✅ Database persistence
- ✅ Full E2E capability

You can explain the **entire system just by hitting these URLs and showing responses**! 🚀
