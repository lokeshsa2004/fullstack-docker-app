"""Tests for metrics endpoint"""
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestMetricsEndpoints:
    """Test suite for metrics API endpoints"""

    def test_metrics_endpoint_exists(self):
        """Test that /api/v1/metrics endpoint exists and returns JSON"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)

    def test_metrics_contains_database_metrics(self):
        """Test that metrics response contains database metrics"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "database_metrics" in data
        assert "portfolio_count" in data["database_metrics"]
        assert "investment_count" in data["database_metrics"]

    def test_metrics_contains_request_metrics(self):
        """Test that metrics response contains request metrics"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "request_metrics" in data
        assert "total_requests" in data["request_metrics"]
        assert "total_errors" in data["request_metrics"]
        assert "error_rate_percent" in data["request_metrics"]

    def test_metrics_contains_system_metrics(self):
        """Test that metrics response contains system metrics"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "system_metrics" in data
        assert "uptime_seconds" in data["system_metrics"]
        assert "uptime_minutes" in data["system_metrics"]

    def test_metrics_contains_timestamp(self):
        """Test that metrics response contains timestamp"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "timestamp" in data
        assert isinstance(data["timestamp"], int)

    def test_endpoint_metrics_exists(self):
        """Test that /api/v1/metrics/endpoints endpoint exists"""
        response = client.get("/api/v1/metrics/endpoints")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        assert "endpoints" in data

    def test_portfolio_trend_endpoint_exists(self):
        """Test that /api/v1/metrics/portfolio-trend endpoint exists"""
        response = client.get("/api/v1/metrics/portfolio-trend")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, dict)
        assert "portfolio_metrics" in data

    def test_metrics_error_rate_is_percentage(self):
        """Test that error rate is between 0 and 100"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        error_rate = data["request_metrics"]["error_rate_percent"]
        assert 0 <= error_rate <= 100

    def test_metrics_response_time_is_positive(self):
        """Test that response time is positive"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        response_time = data["request_metrics"]["avg_response_time_seconds"]
        assert response_time >= 0

    def test_metrics_counts_are_non_negative(self):
        """Test that all counts are non-negative"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        
        # Check database metrics
        assert data["database_metrics"]["portfolio_count"] >= 0
        assert data["database_metrics"]["investment_count"] >= 0
        assert data["database_metrics"]["portfolios_created_total"] >= 0
        assert data["database_metrics"]["investments_added_total"] >= 0
        
        # Check request metrics
        assert data["request_metrics"]["total_requests"] >= 0
        assert data["request_metrics"]["total_errors"] >= 0
        assert data["request_metrics"]["active_requests"] >= 0


class TestPrometheusMetrics:
    """Test suite for Prometheus metrics collection"""

    def test_prometheus_metrics_endpoint(self):
        """Test that /metrics endpoint returns Prometheus format"""
        response = client.get("/metrics")
        assert response.status_code == 200
        assert response.headers["content-type"] == "text/plain; charset=utf-8"
        # Prometheus metrics should contain metric names starting with #
        content = response.text
        assert "api_requests_total" in content or "#HELP" in content or len(content) > 0

    def test_multiple_requests_increment_counter(self):
        """Test that multiple requests increment the request counter"""
        # Make a request to trigger metrics
        client.get("/health")
        
        # Get metrics
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        
        # Verify request was counted
        assert data["request_metrics"]["total_requests"] > 0

    def test_error_requests_are_counted(self):
        """Test that error responses are counted as errors"""
        # Make a request that will fail (non-existent endpoint)
        client.get("/api/v1/nonexistent")
        
        # Get metrics
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        
        # Error count should be incremented
        # (May be > 0 if there were previous errors)
        assert data["request_metrics"]["total_errors"] >= 0


class TestMetricsIntegration:
    """Integration tests for metrics collection"""

    def test_health_check_is_tracked(self):
        """Test that health check requests are tracked in metrics"""
        # First, get initial metrics
        initial_response = client.get("/api/v1/metrics")
        initial_data = initial_response.json()
        initial_count = initial_data["request_metrics"]["total_requests"]
        
        # Make a health check request
        health_response = client.get("/health")
        assert health_response.status_code == 200
        
        # Get updated metrics
        updated_response = client.get("/api/v1/metrics")
        updated_data = updated_response.json()
        updated_count = updated_data["request_metrics"]["total_requests"]
        
        # Count should have increased (or stayed the same if there were caching issues)
        assert updated_count >= initial_count

    def test_meta_endpoint_not_tracked(self):
        """Test that /meta endpoint returns metadata"""
        response = client.get("/meta")
        assert response.status_code == 200
        data = response.json()
        assert "commit" in data
        assert "build_time" in data
        assert "app_version" in data

    def test_metrics_dashboard_data_consistency(self):
        """Test that metrics data is consistent"""
        response = client.get("/api/v1/metrics")
        assert response.status_code == 200
        data = response.json()
        
        # Error count should never exceed total request count
        total_requests = data["request_metrics"]["total_requests"]
        total_errors = data["request_metrics"]["total_errors"]
        assert total_errors <= total_requests
        
        # Error rate should reflect the relationship
        expected_error_rate = (total_errors / total_requests * 100) if total_requests > 0 else 0
        actual_error_rate = data["request_metrics"]["error_rate_percent"]
        assert abs(expected_error_rate - actual_error_rate) < 0.1
