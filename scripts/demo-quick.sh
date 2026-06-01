#!/usr/bin/env bash
##############################################################################
# Quick Demo: Build, Deploy, and Verify
# Run this for a fast demonstration of the application
##############################################################################

set -e

COMMIT=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
IMAGE_TAG="portfolio:${COMMIT}"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Portfolio Manager: Quick Demo                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Configuration:"
echo "   Commit:      $COMMIT"
echo "   Build Time:  $BUILD_TIME"
echo "   Image Tag:   $IMAGE_TAG"
echo ""

# Build
echo "🔨 Building Docker image..."
docker build \
    --build-arg GIT_COMMIT="$COMMIT" \
    --build-arg BUILD_TIME="$BUILD_TIME" \
    -t "local/${IMAGE_TAG}" \
    -f backend/Dockerfile .
echo "✓ Build complete"
echo ""

# Deploy
echo "🚀 Starting services..."
export GIT_COMMIT=$COMMIT
export BUILD_TIME="$BUILD_TIME"
export IMAGE_TAG=$IMAGE_TAG

docker compose -f docker-compose.yml -f docker-compose.logging.yml up -d
sleep 10
echo "✓ Services started"
echo ""

# Verify
echo "✅ Verification:"
echo ""
echo "  1. Commit Provenance:"
curl -s http://localhost:8000/meta | jq '.commit' | sed 's/^/     Deployed: /'
echo "     Local:    $COMMIT"
echo ""

echo "  2. Health:"
curl -s http://localhost:8000/health | jq '.status' | sed 's/^/     /'
echo ""

echo "  3. Portfolios:"
curl -s http://localhost:8000/api/v1/portfolios | jq 'length' | sed 's/^/     Count: /'
echo ""

echo "  4. Metrics:"
curl -s http://localhost:8000/metrics | grep "api_requests_total" | head -1 | sed 's/^/     /'
echo ""

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Demo Ready!                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 Access Points:"
echo "   • Home:            http://localhost/"
echo "   • Dashboard:       http://localhost/dashboard"
echo "   • API Docs:        http://localhost/docs"
echo "   • Metrics:         http://localhost:8000/metrics"
echo "   • Meta:            http://localhost:8000/meta"
echo ""
echo "📊 View Logs:"
echo "   • App:     docker logs portfolio_app -f"
echo "   • DB:      docker logs portfolio_db -f"
echo "   • Nginx:   docker logs portfolio_nginx -f"
echo ""
echo "🧪 Run Full Demo:"
echo "   python3 scripts/demo-verify.py"
echo ""
echo "⏹️  Stop Services:"
echo "   docker compose down"
echo ""
