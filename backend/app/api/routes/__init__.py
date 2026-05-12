"""API route modules"""
from app.api.routes.health import router as health_router
from app.api.routes.portfolio import router as portfolio_router
from app.api.routes.investment import router as investment_router

__all__ = ["health_router", "portfolio_router", "investment_router"]
