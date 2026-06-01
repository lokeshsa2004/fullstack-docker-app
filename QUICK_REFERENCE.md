# Quick Reference Card: E2E Demo

## 🚀 Get Started (Choose One)

```bash
# Full 2-minute demo
./scripts/demo-e2e.sh

# Quick 30-second demo
./scripts/demo-quick.sh

# Python verification
docker compose up -d && python3 scripts/demo-verify.py
```

---

## 🔗 Essential URLs

| What           | URL                  | Command                                           |
| -------------- | -------------------- | ------------------------------------------------- |
| **Commit**     | `/meta`              | `curl http://localhost:8000/meta \| jq '.commit'` |
| **Health**     | `/health`            | `curl http://localhost:8000/health`               |
| **Ready**      | `/health/ready`      | `curl http://localhost:8000/health/ready`         |
| **Metrics**    | `/metrics`           | `curl http://localhost:8000/metrics \| head -20`  |
| **Portfolios** | `/api/v1/portfolios` | `curl http://localhost:8000/api/v1/portfolios`    |
| **Dashboard**  | `/dashboard`         | Open in browser: `http://localhost/dashboard`     |
| **Docs**       | `/docs`              | Open in browser: `http://localhost:8000/docs`     |

---

## 📋 5-Minute Demo Flow

```bash
# 1. Show commit (30 sec)
git rev-parse --short HEAD
curl http://localhost:8000/meta | jq '.commit'
# They match! ✓

# 2. Show health (30 sec)
curl http://localhost:8000/health
curl http://localhost:8000/health/ready

# 3. Check metrics before (30 sec)
curl http://localhost:8000/metrics | grep portfolio_created_total

# 4. Create portfolio (1 min)
curl -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo Portfolio","description":"E2E Demo"}'

# 5. Check metrics after (30 sec)
curl http://localhost:8000/metrics | grep portfolio_created_total
# Counter increased by 1! ✓

# 6. Show logs (1 min)
docker logs portfolio_app | grep APP_START
docker logs portfolio_app | tail -5

# 7. View dashboard (30 sec)
# Open: http://localhost/dashboard
```

---

## 🔑 Key Endpoints Explained

### `/meta` - Provenance Proof

```json
{
  "commit": "abc1234",           ← Exact deployed commit
  "build_time": "2024-01-15...", ← When built
  "app_start_time": 1705318200,  ← When started
  "app_version": "1.0.0",        ← Version
  "app_name": "Portfolio Manager API"
}
```

### `/metrics` - Request Tracking

```
api_requests_total{endpoint="/api/v1/portfolios",method="POST",status="201"} 1.0
portfolio_created_total 1.0
investment_added_total 0.0
api_request_duration_seconds_sum{...} 0.025
```

### `/api/v1/portfolios` - CRUD Operations

```bash
GET  /api/v1/portfolios           # List all
POST /api/v1/portfolios           # Create new
GET  /api/v1/portfolios/1         # Get specific
PATCH /api/v1/portfolios/1        # Update
DELETE /api/v1/portfolios/1       # Delete
```

### `/api/v1/investments` - Related Data

```bash
GET  /api/v1/investments                   # List all
POST /api/v1/investments                   # Create
GET  /api/v1/investments/portfolio/1       # By portfolio
```

---

## 📊 Proof Points

| Want to Show        | Do This                                                                    |
| ------------------- | -------------------------------------------------------------------------- |
| **Code Provenance** | `curl /meta \| jq '.commit'` and compare with `git rev-parse --short HEAD` |
| **Startup Log**     | `docker logs portfolio_app \| grep APP_START`                              |
| **Health**          | `curl /health` and `curl /health/ready`                                    |
| **Request Flow**    | Create portfolio and show metrics increase                                 |
| **Database**        | Query database or view in dashboard                                        |
| **Metrics**         | `curl /metrics \| grep api_requests_total`                                 |

---

## 🛠️ Setup & Teardown

### Start

```bash
docker compose up -d
sleep 10  # Wait for startup
```

### Stop

```bash
docker compose down
```

### Reset

```bash
docker compose down -v
docker compose up -d
```

### View Logs

```bash
docker logs portfolio_app -f        # App logs (follow)
docker logs portfolio_db -f         # Database logs
docker logs portfolio_nginx -f      # Reverse proxy logs
docker compose logs -f              # All services
```

---

## 🐳 Docker Commands

```bash
# Check containers
docker ps -f "name=portfolio"

# Check image
docker inspect portfolio:abc1234

# View environment
docker inspect portfolio:abc1234 | grep -A2 "GIT_COMMIT\|BUILD_TIME"

# Exec in container
docker exec portfolio_app sh
docker exec portfolio_db psql -U postgres
```

---

## 🎯 One-Line Demos

```bash
# Complete verification in one line
curl -s http://localhost:8000/meta | jq . && \
curl -s http://localhost:8000/health | jq . && \
curl -s http://localhost:8000/api/v1/portfolios | jq '. | length' && \
echo "✓ All checks passed!"

# Create portfolio and show it in metrics
PORTFOLIO=$(curl -s -X POST http://localhost:8000/api/v1/portfolios \
  -H "Content-Type: application/json" \
  -d '{"name":"Demo","description":"Test"}' | jq '.id') && \
echo "Created portfolio $PORTFOLIO" && \
curl -s http://localhost:8000/metrics | grep portfolio_created

# Add investment
curl -s -X POST http://localhost:8000/api/v1/investments \
  -H "Content-Type: application/json" \
  -d '{"portfolio_id":1,"ticker":"AAPL","quantity":10,"purchase_price":150}' | jq '.ticker'
```

---

## 📝 Script Files

```bash
# Full E2E (2 min) - Recommended
chmod +x scripts/demo-e2e.sh
./scripts/demo-e2e.sh

# Quick demo (30 sec)
chmod +x scripts/demo-quick.sh
./scripts/demo-quick.sh

# Python verification (1 min)
chmod +x scripts/demo-verify.py
python3 scripts/demo-verify.py
```

---

## 📚 Documentation

| File                        | Purpose                                |
| --------------------------- | -------------------------------------- |
| `DEMO_GUIDE.md`             | Detailed walkthrough with explanations |
| `URL_REFERENCE.md`          | All URLs with full documentation       |
| `CI_CD_INTEGRATION.md`      | How to integrate with CI/CD pipelines  |
| `IMPLEMENTATION_SUMMARY.md` | What was implemented and why           |
| `QUICK_REFERENCE.md`        | ← This file (memorize this!)           |

---

## 🎓 What You're Demonstrating

✅ **Code Provenance**: Repo commit → Docker image → running container  
✅ **Artifact Tracking**: Image tagged by commit SHA  
✅ **Deployment Metadata**: `/meta` endpoint  
✅ **Startup Logging**: `APP_START COMMIT=...` marker  
✅ **Health Monitoring**: Multiple health endpoints  
✅ **Metrics Collection**: Prometheus-format counters  
✅ **Request Tracing**: Full request/response cycle  
✅ **Data Persistence**: Database operations  
✅ **Error Handling**: Proper status codes and logging

---

## ⚡ Pro Tips

1. **Use jq for readable JSON**

   ```bash
   curl http://localhost:8000/meta | jq '.'
   ```

2. **Compare commits**

   ```bash
   COMMIT=$(curl -s http://localhost:8000/meta | jq -r '.commit')
   LOCAL=$(git rev-parse --short HEAD)
   [ "$COMMIT" = "$LOCAL" ] && echo "✓ Match" || echo "✗ Mismatch"
   ```

3. **Monitor metrics live**

   ```bash
   watch -n 1 'curl -s http://localhost:8000/metrics | grep portfolio_created'
   ```

4. **Tail logs in parallel**

   ```bash
   docker compose logs -f
   ```

5. **Create test data quickly**
   ```bash
   for i in {1..5}; do
     curl -X POST http://localhost:8000/api/v1/portfolios \
       -H "Content-Type: application/json" \
       -d "{\"name\":\"Portfolio $i\",\"description\":\"Test\"}"
   done
   ```

---

## ❓ FAQs

**Q: Where do I run these commands?**  
A: Any terminal in the repo root, after starting `docker compose up -d`

**Q: How do I access from another machine?**  
A: Replace `localhost` with the machine's IP/hostname

**Q: What if port 8000 is in use?**  
A: Edit `docker-compose.yml` and change `8000:8000` to `8001:8000`

**Q: How do I see all metrics?**  
A: `curl http://localhost:8000/metrics | grep -E "^api_"`

**Q: How do I clear database?**  
A: `docker compose down -v && docker compose up -d`

---

## 🎬 Presentation Tips

1. **Start simple**: Show `/meta` matches repo commit
2. **Show flow**: Make request → see metrics update
3. **Explain logs**: Show `APP_START` marker
4. **Prove data**: Show database persistence
5. **End with dashboard**: Visual confirmation

**Time: 5-10 minutes total**

---

## 🚀 You're Ready!

Run this to verify everything works:

```bash
./scripts/demo-quick.sh
```

Then show your team the URLs. That's it! 🎉

---

**Bookmark this file. Come back when you need to run a demo!** ⭐
