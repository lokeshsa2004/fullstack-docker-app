"""Metrics endpoint for Prometheus metrics collection and visualization"""
import time
from typing import Dict, Any
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from prometheus_client import REGISTRY
from app.db.base import get_db
from app.models.portfolio import Portfolio
from app.models.investment import Investment

router = APIRouter(prefix="/api/v1", tags=["metrics"])


@router.get("/metrics", response_model=Dict[str, Any])
def get_metrics_json(db: Session = Depends(get_db)):
    """
    Get Prometheus metrics in JSON format for dashboard visualization.
    
    Returns:
        - portfolio_count: Total number of portfolios
        - investment_count: Total number of investments
        - api_request_metrics: Request count, duration, errors
        - error_rate: Percentage of requests that resulted in errors
        - active_requests: Currently in-progress requests
        - system_metrics: Uptime, memory usage
    """
    from app.main import (
        request_count,
        request_duration,
        error_count,
        inprogress_requests,
        portfolio_created_total,
        investment_added_total,
        APP_START_TIME
    )
    import time
    
    try:
        # Database metrics
        portfolio_count = db.query(Portfolio).count()
        investment_count = db.query(Investment).count()
        
        # Extract Prometheus metrics
        registry = REGISTRY
        metrics_data = {}
        
        for metric in registry.collect():
            for sample in metric.samples:
                metric_name = sample.name
                metric_value = sample.value
                metric_labels = sample.labels
                
                if metric_name not in metrics_data:
                    metrics_data[metric_name] = []
                
                metrics_data[metric_name].append({
                    "value": metric_value,
                    "labels": metric_labels
                })
        
        # Calculate request statistics
        total_requests = 0
        total_errors = 0
        request_durations = []
        
        if 'api_requests_total' in metrics_data:
            for item in metrics_data['api_requests_total']:
                total_requests += item['value']
        
        if 'api_errors_total' in metrics_data:
            for item in metrics_data['api_errors_total']:
                total_errors += item['value']
        
        if 'api_request_duration_seconds_bucket' in metrics_data:
            # Extract meaningful duration data
            for item in metrics_data['api_request_duration_seconds_bucket']:
                if item['labels'].get('le') not in ['inf', '+Inf']:
                    try:
                        request_durations.append(float(item['labels'].get('le', 0)))
                    except (ValueError, TypeError):
                        pass
        
        error_rate = (total_errors / total_requests * 100) if total_requests > 0 else 0
        avg_response_time = sum(request_durations) / len(request_durations) if request_durations else 0
        
        # System metrics
        uptime_seconds = int(time.time()) - APP_START_TIME
        
        return {
            "timestamp": int(time.time()),
            "database_metrics": {
                "portfolio_count": portfolio_count,
                "investment_count": investment_count,
                "portfolios_created_total": int(portfolio_created_total._value.get()),
                "investments_added_total": int(investment_added_total._value.get())
            },
            "request_metrics": {
                "total_requests": int(total_requests),
                "total_errors": int(total_errors),
                "error_rate_percent": round(error_rate, 2),
                "active_requests": int(inprogress_requests._value.get()),
                "avg_response_time_seconds": round(avg_response_time, 4)
            },
            "system_metrics": {
                "uptime_seconds": uptime_seconds,
                "uptime_minutes": round(uptime_seconds / 60, 2),
                "uptime_hours": round(uptime_seconds / 3600, 2)
            },
            "raw_prometheus_metrics": metrics_data
        }
    
    except Exception as e:
        return {
            "error": str(e),
            "timestamp": int(time.time()),
            "database_metrics": {
                "portfolio_count": 0,
                "investment_count": 0,
                "portfolios_created_total": 0,
                "investments_added_total": 0
            },
            "request_metrics": {
                "total_requests": 0,
                "total_errors": 0,
                "error_rate_percent": 0,
                "active_requests": 0,
                "avg_response_time_seconds": 0
            },
            "system_metrics": {
                "uptime_seconds": 0,
                "uptime_minutes": 0,
                "uptime_hours": 0
            }
        }


@router.get("/metrics/endpoints", response_model=Dict[str, Any])
def get_endpoint_metrics(db: Session = Depends(get_db)):
    """
    Get metrics grouped by endpoint for detailed analysis.
    Useful for understanding which endpoints are most used and have highest errors.
    """
    from app.main import request_count, request_duration, error_count
    
    try:
        endpoints_data = {}
        
        # Aggregate request count by endpoint
        for sample in request_count.collect()[0].samples:
            if sample.name == 'api_requests_total':
                endpoint = sample.labels.get('endpoint', 'unknown')
                method = sample.labels.get('method', 'unknown')
                status = sample.labels.get('status', 'unknown')
                
                if endpoint not in endpoints_data:
                    endpoints_data[endpoint] = {
                        "methods": {},
                        "total_requests": 0,
                        "error_count": 0,
                        "by_status": {}
                    }
                
                if method not in endpoints_data[endpoint]['methods']:
                    endpoints_data[endpoint]['methods'][method] = 0
                
                count = int(sample.value)
                endpoints_data[endpoint]['methods'][method] += count
                endpoints_data[endpoint]['total_requests'] += count
                
                if int(status) >= 400:
                    endpoints_data[endpoint]['error_count'] += count
                
                if status not in endpoints_data[endpoint]['by_status']:
                    endpoints_data[endpoint]['by_status'][status] = 0
                endpoints_data[endpoint]['by_status'][status] += count
        
        return {
            "timestamp": int(time.time()),
            "endpoints": endpoints_data
        }
    
    except Exception as e:
        return {
            "error": str(e),
            "timestamp": int(time.time()),
            "endpoints": {}
        }


@router.get("/metrics/portfolio-trend", response_model=Dict[str, Any])
def get_portfolio_trend(db: Session = Depends(get_db)):
    """
    Get portfolio creation trend data.
    In a real application, this would track creation timestamps.
    For now, returns total counts.
    """
    from app.main import portfolio_created_total
    
    try:
        portfolio_count = db.query(Portfolio).count()
        
        return {
            "timestamp": int(time.time()),
            "portfolio_metrics": {
                "total_portfolios": portfolio_count,
                "total_created": int(portfolio_created_total._value.get())
            },
            "message": "Portfolio trend data (consider adding created_at timestamps to Portfolio model for detailed trends)"
        }
    
    except Exception as e:
        return {
            "error": str(e),
            "timestamp": int(time.time()),
            "portfolio_metrics": {
                "total_portfolios": 0,
                "total_created": 0
            }
        }

