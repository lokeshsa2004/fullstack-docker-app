"""FastAPI Application Entry Point"""
import time
from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHTTPException
from prometheus_client import Counter, Histogram, generate_latest

from app.api.routes import health_router, portfolio_router, investment_router
from app.api.routes.html_pages import router as html_pages_router, templates as jinja_templates
from app.core.config import settings, logger
from app.db.base import Base, engine, SessionLocal
from app.db.seed import seed_database
from app.paths import frontend_dir

# Prometheus Metrics Definitions
request_count = Counter(
    'api_requests_total',
    'Total API Requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'api_request_duration_seconds',
    'API Request Duration',
    ['method', 'endpoint']
)

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI app
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
)

# Add Prometheus metrics middleware
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    """Middleware to track request metrics"""
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    # Record metrics
    request_count.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    request_duration.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    return response

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_credentials,
    allow_methods=settings.cors_methods,
    allow_headers=settings.cors_headers,
)

# Metrics endpoint
@app.get("/metrics")
def metrics():
    """Expose Prometheus metrics"""
    return Response(generate_latest(), media_type="text/plain")

# Include routers (API first, then HTML pages)
app.include_router(health_router)
app.include_router(portfolio_router)
app.include_router(investment_router)
app.include_router(html_pages_router)

# Static files
_static = frontend_dir() / "static"
if _static.is_dir():
    app.mount("/static", StaticFiles(directory=str(_static)), name="static")


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """404: HTML for browsers, JSON for API and machine clients."""
    if exc.status_code != 404:
        return JSONResponse(
            content={"detail": jsonable_encoder(exc.detail)},
            status_code=exc.status_code,
        )
    path = request.url.path
    if path.startswith("/api"):
        return JSONResponse({"detail": "Not found"}, status_code=404)
    accept = request.headers.get("accept", "")
    if "text/html" in accept:
        return jinja_templates.TemplateResponse(
            "404.html",
            {"request": request},
            status_code=404,
        )
    return JSONResponse({"detail": "Not found"}, status_code=404)


@app.on_event("startup")
async def startup_event():
    """Run on application startup"""
    logger.info("Application starting - %s v%s", settings.app_name, settings.app_version)
    
    # Seed the database with sample data if empty
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()


@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    logger.info("Application shutting down")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )
