"""Investment business logic service"""
from sqlalchemy.orm import Session
from app.models.investment import Investment
from app.schemas.investment import InvestmentCreate, InvestmentUpdate
from app.core.config import logger


class InvestmentService:
    """Service for investment operations"""
    
    @staticmethod
    def create_investment(db: Session, investment_data: InvestmentCreate) -> Investment:
        """Create a new investment"""
        logger.info(f"Creating investment: {investment_data.ticker}")
        
        investment = Investment(
            portfolio_id=investment_data.portfolio_id,
            ticker=investment_data.ticker,
            name=investment_data.name,
            quantity=investment_data.quantity,
            purchase_price=investment_data.purchase_price,
            current_price=investment_data.current_price,
            sector=investment_data.sector,
            notes=investment_data.notes,
        )
        
        db.add(investment)
        db.commit()
        db.refresh(investment)
        
        logger.info(f"Investment created with ID: {investment.id}")
        return investment
    
    @staticmethod
    def get_investment(db: Session, investment_id: int) -> Investment | None:
        """Get investment by ID"""
        return db.query(Investment).filter(Investment.id == investment_id).first()
    
    @staticmethod
    def get_portfolio_investments(db: Session, portfolio_id: int) -> list[Investment]:
        """Get all investments for a portfolio"""
        return db.query(Investment).filter(Investment.portfolio_id == portfolio_id).all()
    
    @staticmethod
    def update_investment(db: Session, investment_id: int, investment_data: InvestmentUpdate) -> Investment | None:
        """Update investment"""
        logger.info(f"Updating investment: {investment_id}")
        
        investment = db.query(Investment).filter(Investment.id == investment_id).first()
        if not investment:
            return None
        
        update_data = investment_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(investment, key, value)
        
        db.commit()
        db.refresh(investment)
        
        logger.info(f"Investment updated: {investment_id}")
        return investment
    
    @staticmethod
    def delete_investment(db: Session, investment_id: int) -> bool:
        """Delete investment"""
        logger.info(f"Deleting investment: {investment_id}")
        
        investment = db.query(Investment).filter(Investment.id == investment_id).first()
        if not investment:
            return False
        
        db.delete(investment)
        db.commit()
        
        logger.info(f"Investment deleted: {investment_id}")
        return True
