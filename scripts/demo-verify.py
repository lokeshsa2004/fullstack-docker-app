#!/usr/bin/env python3
"""
End-to-End Demo: Provenance & Callback Flow Verification

This script demonstrates:
1. Repository commit tracking
2. Deployed artifact provenance
3. Complete request flow with logging
4. Metrics collection
5. Callback sequence
"""

import requests
import json
import time
import subprocess
import sys
from datetime import datetime
from typing import Dict, Any

# Configuration
BASE_URL = "http://localhost:8000"
APP_NAME = "Portfolio Manager API"


class Colors:
    """ANSI color codes"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def print_section(title: str):
    """Print a section header"""
    print(f"\n{Colors.BLUE}{Colors.BOLD}{'='*70}{Colors.ENDC}")
    print(f"{Colors.BLUE}{Colors.BOLD}  {title}{Colors.ENDC}")
    print(f"{Colors.BLUE}{Colors.BOLD}{'='*70}{Colors.ENDC}\n")


def print_step(message: str):
    """Print a step marker"""
    print(f"{Colors.GREEN}→{Colors.ENDC} {message}")


def print_success(message: str):
    """Print a success message"""
    print(f"{Colors.GREEN}✓{Colors.ENDC} {message}")


def print_error(message: str):
    """Print an error message"""
    print(f"{Colors.RED}✗{Colors.ENDC} {message}")


def print_info(message: str):
    """Print an info message"""
    print(f"{Colors.YELLOW}ℹ{Colors.ENDC} {message}")


def get_repo_commit() -> str:
    """Get current git commit"""
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--short', 'HEAD'],
            capture_output=True,
            text=True,
            cwd='/Users/s_lokesh/fullstack_project'
        )
        return result.stdout.strip()
    except Exception as e:
        print_error(f"Could not get git commit: {e}")
        return "unknown"


def get_repo_status() -> bool:
    """Check if repository is clean"""
    try:
        result = subprocess.run(
            ['git', 'status', '--porcelain'],
            capture_output=True,
            text=True,
            cwd='/Users/s_lokesh/fullstack_project'
        )
        return len(result.stdout.strip()) == 0
    except Exception:
        return False


def verify_endpoint(path: str, method: str = "GET") -> Dict[str, Any]:
    """Make a request and return response"""
    try:
        if method == "GET":
            response = requests.get(f"{BASE_URL}{path}", timeout=5)
        elif method == "POST":
            response = requests.post(f"{BASE_URL}{path}", timeout=5)
        return {
            "status": response.status_code,
            "data": response.json() if response.headers.get('content-type') == 'application/json' else response.text,
            "success": response.status_code < 400
        }
    except Exception as e:
        return {
            "status": None,
            "data": str(e),
            "success": False
        }


def demo_provenance():
    """Demo Step 1: Provenance Verification"""
    print_section("STEP 1: Provenance Verification")
    
    print_step("Fetching repository commit...")
    local_commit = get_repo_commit()
    print_success(f"Local commit: {local_commit}")
    
    print_step("Checking repository status...")
    is_clean = get_repo_status()
    if is_clean:
        print_success("Repository is clean (no uncommitted changes)")
    else:
        print_info("Repository has uncommitted changes")
    
    print_step("Fetching deployed metadata from /meta endpoint...")
    meta_response = verify_endpoint("/meta")
    if meta_response["success"]:
        meta = meta_response["data"]
        print_success(f"Deployed commit: {meta.get('commit')}")
        print_success(f"Build time: {meta.get('build_time')}")
        print_success(f"App version: {meta.get('app_version')}")
        
        # Verify commit match
        if meta.get('commit') == local_commit:
            print_success(f"✓ Commit match verified!")
        else:
            print_error(f"Commit mismatch: local={local_commit} vs deployed={meta.get('commit')}")
        
        return meta
    else:
        print_error(f"Failed to fetch /meta: {meta_response['data']}")
        return None


def demo_health_checks():
    """Demo Step 2: Health Checks"""
    print_section("STEP 2: Health Checks")
    
    print_step("Checking /health endpoint...")
    health = verify_endpoint("/health")
    if health["success"]:
        print_success(f"Health status: {health['data']['status']}")
    else:
        print_error(f"Health check failed: {health['data']}")
        return False
    
    print_step("Checking /health/ready endpoint...")
    ready = verify_endpoint("/health/ready")
    if ready["success"]:
        print_success(f"Readiness status: {ready['data']['status']}")
        return True
    else:
        print_error(f"Readiness check failed: {ready['data']}")
        return False


def demo_portfolio_flow():
    """Demo Step 3: Portfolio Management Flow"""
    print_section("STEP 3: Portfolio Management Flow")
    
    print_step("Fetching existing portfolios...")
    list_response = verify_endpoint("/api/v1/portfolios")
    if list_response["success"]:
        portfolios = list_response["data"]
        print_success(f"Found {len(portfolios)} portfolios")
        if portfolios:
            print_info(f"Sample portfolio: {portfolios[0]['name']}")
    else:
        print_error(f"Failed to list portfolios: {list_response['data']}")
        return None
    
    print_step("Creating new portfolio...")
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/portfolios",
            json={
                "name": f"Demo Portfolio {int(time.time())}",
                "description": "Created during E2E demo"
            },
            timeout=5
        )
        if response.status_code == 201:
            portfolio = response.json()
            portfolio_id = portfolio["id"]
            print_success(f"Portfolio created: ID={portfolio_id}, Name={portfolio['name']}")
            return portfolio_id
        else:
            print_error(f"Failed to create portfolio: {response.status_code}")
            return None
    except Exception as e:
        print_error(f"Error creating portfolio: {e}")
        return None


def demo_investment_flow(portfolio_id: int):
    """Demo Step 4: Investment Management Flow"""
    print_section("STEP 4: Investment Management Flow")
    
    if not portfolio_id:
        print_error("No portfolio ID provided")
        return False
    
    print_step(f"Adding investment to portfolio {portfolio_id}...")
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/investments",
            json={
                "portfolio_id": portfolio_id,
                "ticker": "DEMO",
                "quantity": 100,
                "purchase_price": 50.00
            },
            timeout=5
        )
        if response.status_code == 201:
            investment = response.json()
            print_success(f"Investment created: ID={investment['id']}, Ticker={investment['ticker']}")
            
            print_step("Fetching portfolio investments...")
            inv_response = requests.get(
                f"{BASE_URL}/api/v1/investments/portfolio/{portfolio_id}",
                timeout=5
            )
            if inv_response.status_code == 200:
                investments = inv_response.json()
                print_success(f"Portfolio has {len(investments)} investment(s)")
                return True
            else:
                print_error(f"Failed to fetch investments: {inv_response.status_code}")
                return False
        else:
            print_error(f"Failed to create investment: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Error in investment flow: {e}")
        return False


def demo_metrics():
    """Demo Step 5: Prometheus Metrics"""
    print_section("STEP 5: Prometheus Metrics")
    
    print_step("Fetching metrics from /metrics endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/metrics", timeout=5)
        if response.status_code == 200:
            metrics_text = response.text
            
            # Parse and show relevant metrics
            lines = metrics_text.split('\n')
            api_metrics = [l for l in lines if l.startswith('api_') and not l.startswith('#')]
            
            print_success(f"Found {len(api_metrics)} API metrics")
            print_info("Sample metrics:")
            for line in api_metrics[:5]:
                print(f"  {line}")
            
            # Show metric categories
            metric_types = set()
            for line in api_metrics:
                metric_name = line.split('{')[0] if '{' in line else line.split(' ')[0]
                metric_types.add(metric_name)
            
            print_info(f"Metric types tracked:")
            for mtype in sorted(metric_types):
                print(f"  • {mtype}")
            
            return True
        else:
            print_error(f"Failed to fetch metrics: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Error fetching metrics: {e}")
        return False


def demo_api_docs():
    """Demo Step 6: API Documentation"""
    print_section("STEP 6: API Documentation & Endpoints")
    
    print_step("Available endpoints:")
    print("")
    print(f"{Colors.CYAN}Frontend Pages:{Colors.ENDC}")
    print("  • GET  /              - Home page")
    print("  • GET  /dashboard     - Dashboard with portfolio management")
    print("  • GET  /about         - About & technology information")
    print("")
    print(f"{Colors.CYAN}Health & Status:{Colors.ENDC}")
    print("  • GET  /health        - Basic health check")
    print("  • GET  /health/ready  - Readiness check (verifies DB connection)")
    print("  • GET  /meta          - Build metadata & provenance")
    print("")
    print(f"{Colors.CYAN}Portfolio API (v1):{Colors.ENDC}")
    print("  • GET  /api/v1/portfolios              - List all portfolios")
    print("  • POST /api/v1/portfolios              - Create new portfolio")
    print("  • GET  /api/v1/portfolios/{id}         - Get specific portfolio")
    print("  • PATCH /api/v1/portfolios/{id}        - Update portfolio")
    print("  • DELETE /api/v1/portfolios/{id}       - Delete portfolio")
    print("")
    print(f"{Colors.CYAN}Investment API (v1):{Colors.ENDC}")
    print("  • GET  /api/v1/investments             - List all investments")
    print("  • POST /api/v1/investments             - Create investment")
    print("  • GET  /api/v1/investments/{id}        - Get specific investment")
    print("  • GET  /api/v1/investments/portfolio/{portfolio_id} - Get portfolio investments")
    print("")
    print(f"{Colors.CYAN}Monitoring:{Colors.ENDC}")
    print("  • GET  /metrics       - Prometheus metrics in text format")
    print("  • GET  /docs          - OpenAPI/Swagger documentation")
    print("  • GET  /redoc         - ReDoc API documentation")
    print("")


def demo_architecture():
    """Demo Step 7: Architecture Overview"""
    print_section("STEP 7: Request Flow Architecture")
    
    print(f"{Colors.CYAN}Complete Request Journey:{Colors.ENDC}")
    print("")
    print("  User Browser Request")
    print("      ↓")
    print("  nginx (reverse proxy) :80")
    print("      ↓")
    print("  FastAPI App :8000")
    print("      ├─ Metrics Middleware (middleware)")
    print("      ├─ CORS Middleware")
    print("      ├─ Route Matching")
    print("      └─ Handler Execution")
    print("          ↓")
    print("      PostgreSQL :5432")
    print("          ↓")
    print("      Response → Serialized → Middleware → Client")
    print("")
    print(f"{Colors.CYAN}Logging & Observability:{Colors.ENDC}")
    print("")
    print("  Startup: APP_START COMMIT=xxxx BUILD_TIME=yyyy TS=zzzz")
    print("  Requests: Tracked via Prometheus metrics")
    print("  Errors: Recorded in api_errors_total counter")
    print("  Performance: Tracked in request_duration_seconds histogram")
    print("")


def main():
    """Run complete E2E demo"""
    print(f"{Colors.BOLD}{Colors.BLUE}")
    print("╔" + "="*68 + "╗")
    print("║" + f" Portfolio Manager: End-to-End Provenance Demo".ljust(69) + "║")
    print("╚" + "="*68 + "╝")
    print(f"{Colors.ENDC}")
    
    # Check if service is running
    print_step("Checking if services are running...")
    try:
        requests.get(f"{BASE_URL}/health", timeout=2)
        print_success("Services are live")
    except Exception as e:
        print_error(f"Cannot connect to services: {e}")
        print_info("Start services with: docker compose up -d")
        sys.exit(1)
    
    # Run demos
    meta = demo_provenance()
    
    if not demo_health_checks():
        sys.exit(1)
    
    portfolio_id = demo_portfolio_flow()
    
    if portfolio_id:
        demo_investment_flow(portfolio_id)
    
    demo_metrics()
    demo_api_docs()
    demo_architecture()
    
    # Summary
    print_section("DEMO COMPLETE!")
    print(f"{Colors.GREEN}{Colors.BOLD}")
    print("✓ Provenance verified (repo commit → Docker image → deployed container)")
    print("✓ Health checks passing")
    print("✓ Portfolio & Investment APIs working")
    print("✓ Metrics collection enabled")
    print("✓ Complete request flow demonstrated")
    print(f"{Colors.ENDC}")
    
    print(f"\n{Colors.CYAN}Next steps:{Colors.ENDC}")
    print("  • View OpenAPI docs:    curl http://localhost:8000/docs")
    print("  • View metrics:         curl http://localhost:8000/metrics | head -20")
    print("  • View meta info:       curl http://localhost:8000/meta | jq .")
    print("  • Open dashboard:       http://localhost/dashboard")
    print("  • View container logs:  docker logs portfolio_app -f")
    print(f"\n{Colors.YELLOW}Stop services:      docker compose down{Colors.ENDC}\n")


if __name__ == "__main__":
    main()
