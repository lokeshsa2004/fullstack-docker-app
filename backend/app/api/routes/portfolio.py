"""Portfolio API routes"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.db.base import get_db
from app.models.portfolio import Portfolio
from app.schemas.portfolio import PortfolioCreate, PortfolioUpdate, PortfolioResponse
from app.services.portfolio_service import PortfolioService
from app.core.config import logger

router = APIRouter(prefix="/api/v1/portfolios", tags=["portfolios"])


@router.post("", response_model=PortfolioResponse, status_code=201)
def create_portfolio(
    portfolio_data: PortfolioCreate,
    db: Session = Depends(get_db)
):
    """Create a new portfolio"""
    logger.info(f"POST /portfolios - Creating portfolio: {portfolio_data.name}")
    
    # Check if portfolio already exists
    existing = db.query(Portfolio).filter(Portfolio.name == portfolio_data.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Portfolio name already exists")
    
    portfolio = PortfolioService.create_portfolio(db, portfolio_data)
    return portfolio


@router.get("", response_model=list[PortfolioResponse])
def get_portfolios(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db)
):
    """Get all portfolios"""
    logger.info(f"GET /portfolios - Skip: {skip}, Limit: {limit}")
    
    portfolios = PortfolioService.get_all_portfolios(db, skip=skip, limit=limit)
    for p in portfolios:
        PortfolioService.calculate_total_value(db, p.id)
        db.refresh(p)
    return portfolios


@router.get("/{portfolio_id}", response_model=PortfolioResponse)
def get_portfolio(
    portfolio_id: int,
    db: Session = Depends(get_db)
):
    """Get portfolio by ID"""
    logger.info(f"GET /portfolios/{portfolio_id}")
    
    portfolio = PortfolioService.get_portfolio(db, portfolio_id)
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    return portfolio


@router.patch("/{portfolio_id}", response_model=PortfolioResponse)
def update_portfolio(
    portfolio_id: int,
    portfolio_data: PortfolioUpdate,
    db: Session = Depends(get_db)
):
    """Update portfolio"""
    logger.info(f"PATCH /portfolios/{portfolio_id}")
    
    portfolio = PortfolioService.update_portfolio(db, portfolio_id, portfolio_data)
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    return portfolio


@router.delete("/{portfolio_id}", status_code=204)
def delete_portfolio(
    portfolio_id: int,
    db: Session = Depends(get_db)
):
    """Delete portfolio"""
    logger.info(f"DELETE /portfolios/{portfolio_id}")
    
    success = PortfolioService.delete_portfolio(db, portfolio_id)
    if not success:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    return None


@router.get("/{portfolio_id}/total-value", response_model=dict)
def get_portfolio_total_value(
    portfolio_id: int,
    db: Session = Depends(get_db)
):
    """Get portfolio total value"""
    logger.info(f"GET /portfolios/{portfolio_id}/total-value")
    
    portfolio = PortfolioService.get_portfolio(db, portfolio_id)
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    total_value = PortfolioService.calculate_total_value(db, portfolio_id)
    return {
        "portfolio_id": portfolio_id,
        "total_value": total_value
    }
