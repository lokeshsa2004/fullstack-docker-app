-- Initialize database with sample data
-- This script runs automatically on first database creation

-- Create seed data for portfolios
INSERT INTO portfolios (name, owner, description, total_value, created_at, updated_at)
VALUES
    ('Tech Portfolio', 'John Doe', 'Focused on technology stocks', 50000.00, NOW(), NOW()),
    ('Dividend Portfolio', 'Jane Smith', 'High dividend yielding stocks', 35000.00, NOW(), NOW()),
    ('Growth Portfolio', 'John Doe', 'Long-term growth focused', 75000.00, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- Create seed data for investments (only if portfolios exist)
INSERT INTO investments (portfolio_id, ticker, name, quantity, purchase_price, current_price, sector, notes, created_at, updated_at)
SELECT 
    p.id,
    ticker,
    name,
    quantity,
    purchase_price,
    current_price,
    sector,
    notes,
    NOW(),
    NOW()
FROM (
    VALUES
        ('AAPL', 'Apple Inc.', 10, 150.00, 185.50, 'Technology', 'Core position'),
        ('MSFT', 'Microsoft Corporation', 8, 300.00, 370.25, 'Technology', 'Cloud growth'),
        ('GOOGL', 'Alphabet Inc.', 5, 2500.00, 2850.75, 'Technology', 'Ad tech leader'),
        ('TSLA', 'Tesla Inc.', 3, 200.00, 250.50, 'Automotive', 'EV leader'),
        ('META', 'Meta Platforms', 20, 150.00, 180.30, 'Technology', 'Social media')
) AS inv_data(ticker, name, quantity, purchase_price, current_price, sector, notes)
INNER JOIN portfolios p ON p.name = 'Tech Portfolio'
ON CONFLICT DO NOTHING;

-- Create more seed data for other portfolios
INSERT INTO investments (portfolio_id, ticker, name, quantity, purchase_price, current_price, sector, notes, created_at, updated_at)
SELECT 
    p.id,
    ticker,
    name,
    quantity,
    purchase_price,
    current_price,
    sector,
    notes,
    NOW(),
    NOW()
FROM (
    VALUES
        ('JNJ', 'Johnson & Johnson', 15, 160.00, 180.50, 'Healthcare', 'Dividend aristocrat'),
        ('KO', 'The Coca-Cola Company', 25, 60.00, 62.15, 'Consumer', 'Stable dividend'),
        ('PG', 'Procter & Gamble', 12, 145.00, 160.25, 'Consumer', 'Quality dividends')
) AS inv_data(ticker, name, quantity, purchase_price, current_price, sector, notes)
INNER JOIN portfolios p ON p.name = 'Dividend Portfolio'
ON CONFLICT DO NOTHING;

INSERT INTO investments (portfolio_id, ticker, name, quantity, purchase_price, current_price, sector, notes, created_at, updated_at)
SELECT 
    p.id,
    ticker,
    name,
    quantity,
    purchase_price,
    current_price,
    sector,
    notes,
    NOW(),
    NOW()
FROM (
    VALUES
        ('AMZN', 'Amazon.com Inc.', 7, 3000.00, 3250.80, 'Technology', 'E-commerce leader'),
        ('NVDA', 'NVIDIA Corporation', 6, 500.00, 720.50, 'Technology', 'AI chip leader'),
        ('AMD', 'Advanced Micro Devices', 12, 120.00, 165.75, 'Technology', 'Semiconductor'),
        ('CRM', 'Salesforce', 10, 250.00, 280.50, 'Software', 'CRM solution')
) AS inv_data(ticker, name, quantity, purchase_price, current_price, sector, notes)
INNER JOIN portfolios p ON p.name = 'Growth Portfolio'
ON CONFLICT DO NOTHING;
