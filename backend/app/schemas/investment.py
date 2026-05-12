"""Investment schemas"""
from datetime import datetime
from pydantic import BaseModel, Field


class InvestmentBase(BaseModel):
    """Base investment schema"""
    ticker: str = Field(..., min_length=1, max_length=10)
    name: str = Field(..., min_length=1, max_length=255)
    quantity: float = Field(..., gt=0)
    purchase_price: float = Field(..., gt=0)
    current_price: float = Field(..., gt=0)
    sector: str | None = None
    notes: str | None = None


class InvestmentCreate(InvestmentBase):
    """Investment creation schema"""
    portfolio_id: int = Field(..., gt=0)


class InvestmentUpdate(BaseModel):
    """Investment update schema"""
    ticker: str | None = None
    name: str | None = None
    quantity: float | None = None
    purchase_price: float | None = None
    current_price: float | None = None
    sector: str | None = None
    notes: str | None = None


class InvestmentResponse(InvestmentBase):
    """Investment response schema"""
    id: int
    portfolio_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
