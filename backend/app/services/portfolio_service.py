"""Portfolio business logic service"""
from sqlalchemy.orm import Session
from app.models.portfolio import Portfolio
from app.schemas.portfolio import PortfolioCreate, PortfolioUpdate
from app.core.config import logger


class PortfolioService:
    """Service for portfolio operations"""
    
    @staticmethod
    def create_portfolio(db: Session, portfolio_data: PortfolioCreate) -> Portfolio:
        """Create a new portfolio"""
        logger.info(f"Creating portfolio: {portfolio_data.name}")
        
        portfolio = Portfolio(
            name=portfolio_data.name,
            description=portfolio_data.description,
            owner=portfolio_data.owner,
        )
        
        db.add(portfolio)
        db.commit()
        db.refresh(portfolio)
        
        logger.info(f"Portfolio created with ID: {portfolio.id}")
        return portfolio
    
    @staticmethod
    def get_portfolio(db: Session, portfolio_id: int) -> Portfolio | None:
        """Get portfolio by ID"""
        return db.query(Portfolio).filter(Portfolio.id == portfolio_id).first()
    
    @staticmethod
    def get_all_portfolios(db: Session, skip: int = 0, limit: int = 100) -> list[Portfolio]:
        """Get all portfolios with pagination"""
        return db.query(Portfolio).offset(skip).limit(limit).all()
    
    @staticmethod
    def update_portfolio(db: Session, portfolio_id: int, portfolio_data: PortfolioUpdate) -> Portfolio | None:
        """Update portfolio"""
        logger.info(f"Updating portfolio: {portfolio_id}")
        
        portfolio = db.query(Portfolio).filter(Portfolio.id == portfolio_id).first()
        if not portfolio:
            return None
        
        update_data = portfolio_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(portfolio, key, value)
        
        db.commit()
        db.refresh(portfolio)
        
        logger.info(f"Portfolio updated: {portfolio_id}")
        return portfolio
    
    @staticmethod
    def delete_portfolio(db: Session, portfolio_id: int) -> bool:
        """Delete portfolio"""
        logger.info(f"Deleting portfolio: {portfolio_id}")
        
        portfolio = db.query(Portfolio).filter(Portfolio.id == portfolio_id).first()
        if not portfolio:
            return False
        
        db.delete(portfolio)
        db.commit()
        
        logger.info(f"Portfolio deleted: {portfolio_id}")
        return True
    
    @staticmethod
    def calculate_total_value(db: Session, portfolio_id: int) -> float:
        """Calculate total portfolio value"""
        portfolio = db.query(Portfolio).filter(Portfolio.id == portfolio_id).first()
        if not portfolio:
            return 0.0
        
        from app.models.investment import Investment
        investments = db.query(Investment).filter(Investment.portfolio_id == portfolio_id).all()
        
        total = sum(inv.quantity * inv.current_price for inv in investments)
        
        portfolio.total_value = total
        db.commit()
        
        return total
