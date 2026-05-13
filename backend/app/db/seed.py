"""Database seeding module for sample data"""
import logging
from sqlalchemy.orm import Session
from app.models.portfolio import Portfolio
from app.models.investment import Investment

logger = logging.getLogger("app")


def seed_database(db: Session) -> None:
    """Seed the database with sample data if it's empty"""
    
    # Check if data already exists
    if db.query(Portfolio).first() is not None:
        logger.info("Database already contains data, skipping seed")
        return
    
    logger.info("Seeding database with sample data...")
    
    try:
        # Create sample portfolios
        portfolio1 = Portfolio(
            name="Tech Growth Portfolio",
            owner="John Doe",
            description="A diversified portfolio focused on technology stocks with high growth potential"
        )
        
        portfolio2 = Portfolio(
            name="Conservative Income",
            owner="Jane Smith",
            description="A conservative portfolio emphasizing dividend-paying stocks and stable investments"
        )
        
        portfolio3 = Portfolio(
            name="Healthcare & Pharma",
            owner="Michael Johnson",
            description="Portfolio focused on healthcare and pharmaceutical companies for long-term growth"
        )
        
        db.add_all([portfolio1, portfolio2, portfolio3])
        db.flush()  # Get IDs without committing
        
        # Create sample investments for Portfolio 1 (Tech Growth)
        investments1 = [
            Investment(
                portfolio_id=portfolio1.id,
                ticker="AAPL",
                name="Apple Inc.",
                quantity=25,
                purchase_price=120.50,
                current_price=185.75,
                sector="Technology",
                notes="Leading consumer electronics and software company"
            ),
            Investment(
                portfolio_id=portfolio1.id,
                ticker="MSFT",
                name="Microsoft Corporation",
                quantity=15,
                purchase_price=250.00,
                current_price=380.25,
                sector="Technology",
                notes="Cloud computing and enterprise software leader"
            ),
            Investment(
                portfolio_id=portfolio1.id,
                ticker="NVDA",
                name="NVIDIA Corporation",
                quantity=10,
                purchase_price=200.00,
                current_price=875.00,
                sector="Technology",
                notes="GPU and AI chip manufacturer"
            ),
            Investment(
                portfolio_id=portfolio1.id,
                ticker="GOOGL",
                name="Alphabet Inc.",
                quantity=8,
                purchase_price=100.00,
                current_price=155.50,
                sector="Technology",
                notes="Search and advertising giant with cloud services"
            ),
        ]
        
        # Create sample investments for Portfolio 2 (Conservative Income)
        investments2 = [
            Investment(
                portfolio_id=portfolio2.id,
                ticker="JNJ",
                name="Johnson & Johnson",
                quantity=30,
                purchase_price=145.00,
                current_price=160.75,
                sector="Healthcare",
                notes="Diversified healthcare company with strong dividend history"
            ),
            Investment(
                portfolio_id=portfolio2.id,
                ticker="KO",
                name="The Coca-Cola Company",
                quantity=50,
                purchase_price=55.00,
                current_price=62.30,
                sector="Consumer Staples",
                notes="Beverage company with consistent dividend payments"
            ),
            Investment(
                portfolio_id=portfolio2.id,
                ticker="PG",
                name="Procter & Gamble",
                quantity=20,
                purchase_price=150.00,
                current_price=165.40,
                sector="Consumer Staples",
                notes="Consumer goods giant with stable cash flows"
            ),
        ]
        
        # Create sample investments for Portfolio 3 (Healthcare & Pharma)
        investments3 = [
            Investment(
                portfolio_id=portfolio3.id,
                ticker="MRNA",
                name="Moderna Inc.",
                quantity=12,
                purchase_price=95.00,
                current_price=125.80,
                sector="Healthcare",
                notes="mRNA vaccine and immunotherapy company"
            ),
            Investment(
                portfolio_id=portfolio3.id,
                ticker="BNTX",
                name="BioNTech SE",
                quantity=8,
                purchase_price=110.00,
                current_price=95.25,
                sector="Healthcare",
                notes="Biopharmaceutical company specializing in mRNA"
            ),
            Investment(
                portfolio_id=portfolio3.id,
                ticker="UNH",
                name="UnitedHealth Group",
                quantity=5,
                purchase_price=380.00,
                current_price=515.50,
                sector="Healthcare",
                notes="Healthcare and insurance company"
            ),
            Investment(
                portfolio_id=portfolio3.id,
                ticker="ABBV",
                name="AbbVie Inc.",
                quantity=10,
                purchase_price=110.00,
                current_price=168.90,
                sector="Healthcare",
                notes="Biopharmaceutical company with diversified pipeline"
            ),
        ]
        
        # Add all investments
        db.add_all(investments1 + investments2 + investments3)
        
        # Commit all changes
        db.commit()
        
        logger.info("Database seeding completed successfully")
        logger.info(f"Created 3 portfolios with 11 total investments")
        
    except Exception as e:
        logger.error(f"Error seeding database: {str(e)}")
        db.rollback()
        raise
