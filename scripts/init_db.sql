-- Initialize database with sample data (runs on first PostgreSQL volume init only)

INSERT INTO portfolios (name, owner, description, total_value, created_at, updated_at)
VALUES
    ('Tech Portfolio', 'John Doe', 'Focused on technology stocks', 50000.00, NOW(), NOW()),
    ('Dividend Portfolio', 'Jane Smith', 'High dividend yielding stocks', 35000.00, NOW(), NOW()),
    ('Growth Portfolio', 'John Doe', 'Long-term growth focused', 75000.00, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- Tech Portfolio investments
INSERT INTO investments (portfolio_id, ticker, name, quantity, purchase_price, current_price, sector, notes, created_at, updated_at)
SELECT p.id, v.ticker, v.name, v.quantity, v.purchase_price, v.current_price, v.sector, v.notes, NOW(), NOW()
FROM portfolios p
CROSS JOIN (
    VALUES
        ('AAPL', 'Apple Inc.', 10, 150.00, 185.50, 'Technology', 'Core position'),
        ('MSFT', 'Microsoft Corporation', 8, 300.00, 370.25, 'Technology', 'Cloud growth'),
        ('GOOGL', 'Alphabet Inc.', 5, 2500.00, 2850.75, 'Technology', 'Ad tech leader'),
        ('TSLA', 'Tesla Inc.', 3, 200.00, 250.50, 'Automotive', 'EV leader'),
        ('META', 'Meta Platforms', 20, 150.00, 180.30, 'Technology', 'Social media')
) AS v(ticker, name, quantity, purchase_price, current_price, sector, notes)
WHERE p.name = 'Tech Portfolio'
  AND NOT EXISTS (
      SELECT 1 FROM investments i WHERE i.portfolio_id = p.id AND i.ticker = v.ticker
  );

-- Dividend Portfolio investments
INSERT INTO investments (portfolio_id, ticker, name, quantity, purchase_price, current_price, sector, notes, created_at, updated_at)
SELECT p.id, v.ticker, v.name, v.quantity, v.purchase_price, v.current_price, v.sector, v.notes, NOW(), NOW()
FROM portfolios p
CROSS JOIN (
    VALUES
        ('JNJ', 'Johnson & Johnson', 15, 160.00, 180.50, 'Healthcare', 'Dividend aristocrat'),
        ('KO', 'The Coca-Cola Company', 25, 60.00, 62.15, 'Consumer', 'Stable dividend'),
        ('PG', 'Procter & Gamble', 12, 145.00, 160.25, 'Consumer', 'Quality dividends')
) AS v(ticker, name, quantity, purchase_price, current_price, sector, notes)
WHERE p.name = 'Dividend Portfolio'
  AND NOT EXISTS (
      SELECT 1 FROM investments i WHERE i.portfolio_id = p.id AND i.ticker = v.ticker
  );

-- Growth Portfolio investments
INSERT INTO investments (portfolio_id, ticker, name, quantity, purchase_price, current_price, sector, notes, created_at, updated_at)
SELECT p.id, v.ticker, v.name, v.quantity, v.purchase_price, v.current_price, v.sector, v.notes, NOW(), NOW()
FROM portfolios p
CROSS JOIN (
    VALUES
        ('AMZN', 'Amazon.com Inc.', 7, 3000.00, 3250.80, 'Technology', 'E-commerce leader'),
        ('NVDA', 'NVIDIA Corporation', 6, 500.00, 720.50, 'Technology', 'AI chip leader'),
        ('AMD', 'Advanced Micro Devices', 12, 120.00, 165.75, 'Technology', 'Semiconductor'),
        ('CRM', 'Salesforce', 10, 250.00, 280.50, 'Software', 'CRM solution')
) AS v(ticker, name, quantity, purchase_price, current_price, sector, notes)
WHERE p.name = 'Growth Portfolio'
  AND NOT EXISTS (
      SELECT 1 FROM investments i WHERE i.portfolio_id = p.id AND i.ticker = v.ticker
  );
