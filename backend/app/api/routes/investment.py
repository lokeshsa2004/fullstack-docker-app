"""Investment API routes"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.base import get_db
from app.schemas.investment import InvestmentCreate, InvestmentUpdate, InvestmentResponse
from app.services.investment_service import InvestmentService
from app.services.portfolio_service import PortfolioService
from app.core.config import logger

router = APIRouter(prefix="/api/v1/investments", tags=["investments"])


@router.post("", response_model=InvestmentResponse, status_code=201)
def create_investment(
    investment_data: InvestmentCreate,
    db: Session = Depends(get_db)
):
    """Create a new investment"""
    logger.info(f"POST /investments - Creating investment: {investment_data.ticker}")
    
    # Verify portfolio exists
    portfolio = PortfolioService.get_portfolio(db, investment_data.portfolio_id)
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    investment = InvestmentService.create_investment(db, investment_data)
    
    # Update portfolio total value
    PortfolioService.calculate_total_value(db, investment_data.portfolio_id)
    
    return investment


@router.get("/{investment_id}", response_model=InvestmentResponse)
def get_investment(
    investment_id: int,
    db: Session = Depends(get_db)
):
    """Get investment by ID"""
    logger.info(f"GET /investments/{investment_id}")
    
    investment = InvestmentService.get_investment(db, investment_id)
    if not investment:
        raise HTTPException(status_code=404, detail="Investment not found")
    
    return investment


@router.get("/portfolio/{portfolio_id}", response_model=list[InvestmentResponse])
def get_portfolio_investments(
    portfolio_id: int,
    db: Session = Depends(get_db)
):
    """Get all investments for a portfolio"""
    logger.info(f"GET /investments/portfolio/{portfolio_id}")
    
    # Verify portfolio exists
    portfolio = PortfolioService.get_portfolio(db, portfolio_id)
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    investments = InvestmentService.get_portfolio_investments(db, portfolio_id)
    return investments


@router.patch("/{investment_id}", response_model=InvestmentResponse)
def update_investment(
    investment_id: int,
    investment_data: InvestmentUpdate,
    db: Session = Depends(get_db)
):
    """Update investment"""
    logger.info(f"PATCH /investments/{investment_id}")
    
    investment = InvestmentService.get_investment(db, investment_id)
    if not investment:
        raise HTTPException(status_code=404, detail="Investment not found")
    
    updated_investment = InvestmentService.update_investment(db, investment_id, investment_data)
    
    # Update portfolio total value
    PortfolioService.calculate_total_value(db, investment.portfolio_id)
    
    return updated_investment


@router.delete("/{investment_id}", status_code=204)
def delete_investment(
    investment_id: int,
    db: Session = Depends(get_db)
):
    """Delete investment"""
    logger.info(f"DELETE /investments/{investment_id}")
    
    investment = InvestmentService.get_investment(db, investment_id)
    if not investment:
        raise HTTPException(status_code=404, detail="Investment not found")
    
    portfolio_id = investment.portfolio_id
    
    success = InvestmentService.delete_investment(db, investment_id)
    if not success:
        raise HTTPException(status_code=404, detail="Investment not found")
    
    # Update portfolio total value
    PortfolioService.calculate_total_value(db, portfolio_id)
    
    return None
