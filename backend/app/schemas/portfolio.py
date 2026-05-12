"""Portfolio schemas"""
from datetime import datetime
from pydantic import BaseModel, Field


class PortfolioBase(BaseModel):
    """Base portfolio schema"""
    name: str = Field(..., min_length=1, max_length=255)
    description: str | None = None
    owner: str = Field(..., min_length=1, max_length=255)


class PortfolioCreate(PortfolioBase):
    """Portfolio creation schema"""
    pass


class PortfolioUpdate(BaseModel):
    """Portfolio update schema"""
    name: str | None = None
    description: str | None = None
    owner: str | None = None


class PortfolioResponse(PortfolioBase):
    """Portfolio response schema"""
    id: int
    total_value: float
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
