"""Health check endpoint"""
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.db.base import get_db

router = APIRouter()


@router.get("/health")
def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "message": "API is running"
    }


@router.get("/health/ready")
def readiness_check(db: Session = Depends(get_db)):
    """Readiness check endpoint - verifies database connectivity"""
    try:
        # Try to execute a simple query
        db.execute(text("SELECT 1"))
        return {
            "status": "ready",
            "message": "API is ready to serve requests"
        }
    except Exception as e:
        # Return 503 on database error
        from fastapi.responses import JSONResponse
        return JSONResponse(
            {
                "status": "not_ready",
                "message": f"Database connection failed: {str(e)}"
            },
            status_code=503
        )
