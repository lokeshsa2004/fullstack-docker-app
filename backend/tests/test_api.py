"""Unit tests for Portfolio Manager API"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.db.base import Base, get_db

# Test database
SQLALCHEMY_TEST_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_TEST_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


class TestHealth:
    """Health check endpoint tests"""

    def test_health_check(self):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

    def test_readiness_check(self):
        response = client.get("/health/ready")
        assert response.status_code in [200, 503]


class TestPortfolios:
    """Portfolio endpoint tests"""

    def test_get_portfolios_empty(self):
        response = client.get("/api/v1/portfolios")
        assert response.status_code == 200
        assert response.json() == []

    def test_create_portfolio(self):
        portfolio_data = {
            "name": "Test Portfolio",
            "owner": "Test User",
            "description": "A test portfolio"
        }
        response = client.post("/api/v1/portfolios", json=portfolio_data)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == portfolio_data["name"]
        assert data["owner"] == portfolio_data["owner"]

    def test_create_duplicate_portfolio(self):
        portfolio_data = {
            "name": "Test Portfolio",
            "owner": "Test User",
            "description": "A test portfolio"
        }
        client.post("/api/v1/portfolios", json=portfolio_data)
        response = client.post("/api/v1/portfolios", json=portfolio_data)
        assert response.status_code == 400

    def test_get_portfolios(self):
        response = client.get("/api/v1/portfolios")
        assert response.status_code == 200
        assert len(response.json()) > 0

    def test_get_portfolio_by_id(self):
        # Create a portfolio first
        portfolio_data = {
            "name": "Get Test Portfolio",
            "owner": "Test User"
        }
        create_response = client.post("/api/v1/portfolios", json=portfolio_data)
        portfolio_id = create_response.json()["id"]

        # Get the portfolio
        response = client.get(f"/api/v1/portfolios/{portfolio_id}")
        assert response.status_code == 200
        assert response.json()["id"] == portfolio_id

    def test_update_portfolio(self):
        # Create a portfolio
        portfolio_data = {
            "name": "Update Test Portfolio",
            "owner": "Test User"
        }
        create_response = client.post("/api/v1/portfolios", json=portfolio_data)
        portfolio_id = create_response.json()["id"]

        # Update it
        update_data = {"description": "Updated description"}
        response = client.patch(f"/api/v1/portfolios/{portfolio_id}", json=update_data)
        assert response.status_code == 200
        assert response.json()["description"] == update_data["description"]

    def test_delete_portfolio(self):
        # Create a portfolio
        portfolio_data = {
            "name": "Delete Test Portfolio",
            "owner": "Test User"
        }
        create_response = client.post("/api/v1/portfolios", json=portfolio_data)
        portfolio_id = create_response.json()["id"]

        # Delete it
        response = client.delete(f"/api/v1/portfolios/{portfolio_id}")
        assert response.status_code == 204

        # Verify it's deleted
        response = client.get(f"/api/v1/portfolios/{portfolio_id}")
        assert response.status_code == 404


class TestInvestments:
    """Investment endpoint tests"""

    @pytest.fixture(autouse=True)
    def setup(self):
        """Setup test data"""
        self.portfolio_data = {
            "name": "Investment Test Portfolio",
            "owner": "Test User"
        }
        response = client.post("/api/v1/portfolios", json=self.portfolio_data)
        self.portfolio_id = response.json()["id"]

    def test_create_investment(self):
        investment_data = {
            "portfolio_id": self.portfolio_id,
            "ticker": "AAPL",
            "name": "Apple Inc.",
            "quantity": 10,
            "purchase_price": 150.0,
            "current_price": 180.0,
            "sector": "Technology"
        }
        response = client.post("/api/v1/investments", json=investment_data)
        assert response.status_code == 201
        data = response.json()
        assert data["ticker"] == investment_data["ticker"]

    def test_get_portfolio_investments(self):
        # Create investment
        investment_data = {
            "portfolio_id": self.portfolio_id,
            "ticker": "MSFT",
            "name": "Microsoft",
            "quantity": 5,
            "purchase_price": 300.0,
            "current_price": 350.0
        }
        client.post("/api/v1/investments", json=investment_data)

        # Get investments
        response = client.get(f"/api/v1/investments/portfolio/{self.portfolio_id}")
        assert response.status_code == 200
        assert len(response.json()) > 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
