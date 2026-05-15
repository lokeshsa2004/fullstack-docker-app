#!/bin/bash

################################################################################
# Static Files Diagnostics Script
# Tests nginx and FastAPI static file serving
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
echo "=========================================="
echo "Static Files Diagnostics"
echo "=========================================="
echo ""

# Test 1: Check if containers are running
log_info "Test 1: Checking if containers are running..."
if ! docker compose ps | grep -q portfolio_nginx; then
    log_error "nginx container not running"
    exit 1
fi
if ! docker compose ps | grep -q portfolio_app; then
    log_error "FastAPI container not running"
    exit 1
fi
log_success "All containers running"
echo ""

# Test 2: Check nginx volume mount
log_info "Test 2: Checking nginx static file volume..."
if docker compose exec -T nginx test -d /usr/share/nginx/html/static; then
    log_success "Static directory mounted in nginx"
    
    # Count files
    file_count=$(docker compose exec -T nginx find /usr/share/nginx/html/static -type f | wc -l)
    echo "  Files in nginx static: $file_count"
    
    # List main files
    echo "  Main files:"
    docker compose exec -T nginx ls -la /usr/share/nginx/html/static/ | grep -v "^total" | awk '{print "    " $NF}'
else
    log_error "Static directory NOT mounted in nginx"
fi
echo ""

# Test 3: Check FastAPI static mount
log_info "Test 3: Checking FastAPI static mount..."
docker compose exec -T app python -c "from app.paths import frontend_dir; import os; fe_dir = frontend_dir(); static_path = fe_dir / 'static'; print(f'Frontend dir: {fe_dir}'); print(f'Static dir: {static_path}'); print(f'Exists: {static_path.is_dir()}'); print(f'Files: {len(list(static_path.glob(\"**/*\"))) if static_path.is_dir() else 0}')" || log_warn "Could not verify FastAPI static mount"
echo ""

# Test 4: Test CSS file access via nginx
log_info "Test 4: Testing /static/css/style.css..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/static/css/style.css)
if [ "$http_code" = "200" ]; then
    log_success "CSS file accessible (HTTP $http_code)"
    
    # Check headers
    echo "  Response Headers:"
    curl -s -I http://localhost/static/css/style.css | grep -E "^Content-Type|^Cache-Control|^X-Served-By" | sed 's/^/    /'
    
    # Check file size
    size=$(curl -s -I http://localhost/static/css/style.css | grep -i content-length | awk '{print $2}')
    echo "  File size: $size bytes"
else
    log_error "CSS file NOT accessible (HTTP $http_code)"
fi
echo ""

# Test 5: Test CSS file access via FastAPI
log_info "Test 5: Testing /static/css/style.css via FastAPI..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/static/css/style.css)
if [ "$http_code" = "200" ]; then
    log_success "CSS file accessible via FastAPI (HTTP $http_code)"
else
    log_error "CSS file NOT accessible via FastAPI (HTTP $http_code)"
fi
echo ""

# Test 6: Test responsive CSS
log_info "Test 6: Testing /static/css/responsive.css..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/static/css/responsive.css)
if [ "$http_code" = "200" ]; then
    log_success "Responsive CSS accessible (HTTP $http_code)"
else
    log_error "Responsive CSS NOT accessible (HTTP $http_code)"
fi
echo ""

# Test 7: Test logo image
log_info "Test 7: Testing /static/images/logo.svg..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/static/images/logo.svg)
if [ "$http_code" = "200" ]; then
    log_success "Logo image accessible (HTTP $http_code)"
else
    log_error "Logo image NOT accessible (HTTP $http_code)"
fi
echo ""

# Test 8: Test JavaScript file
log_info "Test 8: Testing /static/js/main.js..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/static/js/main.js)
if [ "$http_code" = "200" ]; then
    log_success "JavaScript file accessible (HTTP $http_code)"
else
    log_error "JavaScript file NOT accessible (HTTP $http_code)"
fi
echo ""

# Test 9: Test HTML page includes static assets
log_info "Test 9: Checking HTML page for static asset references..."
html_content=$(curl -s http://localhost/)
if echo "$html_content" | grep -q "/static/css/style.css"; then
    log_success "HTML references static CSS"
    
    echo "  CSS references found:"
    echo "$html_content" | grep -o 'href="/static/[^"]*"' | sed 's/^/    /'
else
    log_error "HTML does NOT reference static CSS"
fi
echo ""

# Test 10: Test dashboard page
log_info "Test 10: Checking dashboard page..."
http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/dashboard)
if [ "$http_code" = "200" ]; then
    log_success "Dashboard page accessible (HTTP $http_code)"
else
    log_error "Dashboard page NOT accessible (HTTP $http_code)"
fi
echo ""

# Test 11: Check nginx config
log_info "Test 11: Verifying nginx configuration..."
docker compose exec -T nginx nginx -t 2>&1 | grep -q "successful" && log_success "nginx config is valid" || log_error "nginx config has errors"
echo ""

# Test 12: Check for errors in logs
log_info "Test 12: Checking logs for errors..."
nginx_errors=$(docker compose logs nginx | grep -i "error" | grep -v "error_page" | wc -l)
if [ "$nginx_errors" -eq 0 ]; then
    log_success "No errors in nginx logs"
else
    log_warn "Found $nginx_errors error(s) in nginx logs"
    docker compose logs nginx | grep -i "error" | grep -v "error_page" | head -3 | sed 's/^/    /'
fi
echo ""

# Test 13: Check cache headers
log_info "Test 13: Verifying cache headers..."
cache_control=$(curl -s -I http://localhost/static/css/style.css | grep "Cache-Control" | cut -d' ' -f2-)
if [ -n "$cache_control" ]; then
    log_success "Cache headers present: $cache_control"
else
    log_warn "No Cache-Control header"
fi
echo ""

# Summary
echo "=========================================="
echo "Diagnostics Complete"
echo "=========================================="
echo ""
echo "If all tests passed:"
echo "  ✓ Frontend should be fully visible"
echo "  ✓ All static assets should load"
echo "  ✓ Pages should render with styling"
echo ""
echo "If tests failed:"
echo "  ✗ Check docker compose logs: docker compose logs"
echo "  ✗ Check nginx config: docker compose exec nginx nginx -T"
echo "  ✗ Verify volume mounts: docker compose exec nginx ls -la /usr/share/nginx/html/static/"
echo ""
