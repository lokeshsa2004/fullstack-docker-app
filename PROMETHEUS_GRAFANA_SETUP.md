# Prometheus & Grafana Setup Guide

This guide explains how to integrate Prometheus and Grafana with your Portfolio Manager application for advanced monitoring.

## Quick Overview

```
Your App (Port 8000)
    ↓ /metrics endpoint
Prometheus (Port 9090)
    ↓ scrapes metrics
Grafana (Port 3000)
    ↓ visualizes
Dashboard with custom graphs
```

## Option 1: Local Setup with Docker Compose

### Step 1: Create Prometheus Configuration

Create `prometheus.yml` in your project root:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "portfolio-app"
    scrape_interval: 5s
    static_configs:
      - targets: ["app:8000"]
    metrics_path: "/metrics"
```

### Step 2: Add to Docker Compose

Create `docker-compose.monitoring.yml`:

```yaml
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: portfolio_prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
    depends_on:
      - app
    networks:
      - portfolio_network

  grafana:
    image: grafana/grafana:latest
    container_name: portfolio_grafana
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    networks:
      - portfolio_network

volumes:
  prometheus_data:
  grafana_data:

networks:
  portfolio_network:
    external: true
```

### Step 3: Run the Stack

```bash
# Create the network
docker network create portfolio_network

# Run the main stack
docker-compose up -d

# Run monitoring in the same network
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

### Step 4: Access Services

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Your App**: http://localhost/dashboard

## Option 2: Kubernetes Deployment

### Create ServiceMonitor (if using Prometheus Operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: portfolio-monitor
spec:
  selector:
    matchLabels:
      app: portfolio-app
  endpoints:
    - port: web
      interval: 15s
      path: /metrics
```

### Deploy with Helm

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack

# Deploy your app
kubectl apply -f deployment.yaml
```

## Setting Up Grafana Dashboards

### Step 1: Add Data Source

1. Open Grafana: http://localhost:3000
2. Login with `admin/admin`
3. Go to **Configuration** > **Data Sources**
4. Click **Add data source**
5. Select **Prometheus**
6. Set URL: `http://prometheus:9090`
7. Click **Save & test**

### Step 2: Create Dashboard

1. Click **+** (Create) > **Dashboard**
2. Click **Add new panel**
3. In the query section, add:
   - `api_requests_total` - Total requests
   - `api_request_duration_seconds` - Request duration
   - `api_errors_total` - Error count
   - `api_inprogress_requests` - Active requests

### Step 3: Import Pre-built Dashboard

Use this JSON for a quick dashboard setup:

```json
{
  "dashboard": {
    "title": "Portfolio App Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(api_requests_total[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(api_errors_total[5m]) / rate(api_requests_total[5m])"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Response Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, api_request_duration_seconds)"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Portfolio Count",
        "targets": [
          {
            "expr": "portfolio_created_total"
          }
        ],
        "type": "stat"
      }
    ]
  }
}
```

## Useful Prometheus Queries

### Request Metrics

```promql
# Total requests per minute
rate(api_requests_total[1m])

# Requests by method
sum by (method) (rate(api_requests_total[5m]))

# Requests by endpoint
sum by (endpoint) (rate(api_requests_total[5m]))

# Error rate percentage
rate(api_errors_total[5m]) / rate(api_requests_total[5m]) * 100

# 95th percentile response time
histogram_quantile(0.95, api_request_duration_seconds)
```

### Business Metrics

```promql
# Portfolio creation rate
rate(portfolio_created_total[5m])

# Total portfolios ever created
portfolio_created_total

# Investment addition rate
rate(investment_added_total[5m])
```

### System Metrics

```promql
# Active requests
api_inprogress_requests

# Requests with 4xx errors
sum(rate(api_requests_total{status=~"4.."}[5m]))

# Requests with 5xx errors
sum(rate(api_requests_total{status=~"5.."}[5m]))
```

## Setting Up Alerts

### Prometheus Alert Rules

Create `alert-rules.yml`:

```yaml
groups:
  - name: portfolio_app
    rules:
      - alert: HighErrorRate
        expr: rate(api_errors_total[5m]) / rate(api_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above 5%"

      - alert: SlowResponse
        expr: histogram_quantile(0.95, api_request_duration_seconds) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Slow response times detected"
          description: "95th percentile response time is over 1 second"

      - alert: HighInProgressRequests
        expr: api_inprogress_requests > 100
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Many in-progress requests"
          description: "{{ $value }} requests are currently processing"
```

Add to Prometheus config:

```yaml
rule_files:
  - "alert-rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]
```

## Integration with Slack

### Step 1: Create Slack Webhook

1. Go to https://api.slack.com/apps
2. Create a new app
3. Enable Incoming Webhooks
4. Add webhook URL

### Step 2: Configure Alertmanager

Create `alertmanager.yml`:

```yaml
global:
  resolve_timeout: 5m

route:
  receiver: "slack"

receivers:
  - name: "slack"
    slack_configs:
      - api_url: "YOUR_SLACK_WEBHOOK_URL"
        channel: "#alerts"
        title: "Portfolio App Alert"
        text: "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
```

## Production Deployment

### Using AWS

```bash
# Upload metrics to CloudWatch
pip install watchtower

# In your code:
from watchtower import CloudWatchLogHandler
import logging

logging.basicConfig(
    level=logging.INFO,
    handlers=[
        CloudWatchLogHandler(
            log_group='portfolio-app',
            stream_name='metrics'
        )
    ]
)
```

### Using Datadog

```bash
pip install datadog

# In your code:
from datadog import initialize, api
from datadog.api import Tag

options = {
    'api_key': 'YOUR_API_KEY',
    'app_key': 'YOUR_APP_KEY'
}

initialize(**options)

# Send custom metrics
Tag.create('app:portfolio', 'env:prod')
```

### Using New Relic

```bash
pip install newrelic

# Configure in code:
import newrelic.agent
newrelic.agent.initialize('newrelic.ini')

@newrelic.agent.function_trace()
def my_function():
    pass
```

## Monitoring Checklist

- [ ] Prometheus scraping metrics from `/metrics`
- [ ] Grafana connected to Prometheus data source
- [ ] Dashboard displaying key metrics
- [ ] Alerts configured for critical thresholds
- [ ] Alert notifications (Slack/Email) working
- [ ] Historical data retention configured
- [ ] Backup strategy for Prometheus data
- [ ] Performance acceptable (<2% overhead)

## Troubleshooting

### Prometheus Can't Reach App

```bash
# Test connectivity from Prometheus container
docker exec portfolio_prometheus curl http://app:8000/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

### Grafana Can't Reach Prometheus

```bash
# Test from Grafana container
docker exec portfolio_grafana curl http://prometheus:9090

# Check data source in Grafana UI
Settings > Data Sources > Test
```

### No Data in Grafana

1. Check Prometheus is scraping: http://localhost:9090/graph
2. Run test query: `api_requests_total`
3. Verify data exists: `up{job="portfolio-app"}`
4. Check Grafana query syntax
5. Try recent time range

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AlertManager Docs](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [prometheus-client Python](https://github.com/prometheus/client_python)

## Clean Up

```bash
# Stop monitoring stack
docker-compose -f docker-compose.monitoring.yml down

# Remove volumes
docker volume rm portfolio_prometheus_data portfolio_grafana_data

# Remove network (if not used by other services)
docker network rm portfolio_network
```

---

**Your monitoring stack is now ready! Monitor your Portfolio App like a pro! 📊**
