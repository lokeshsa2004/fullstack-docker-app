/* ========================================
   DASHBOARD PAGE JAVASCRIPT
   ======================================== */

let portfolios = [];
let currentEditingPortfolioId = null;
let currentEditingInvestmentId = null;

// DOM Elements
const addPortfolioBtnEl = document.getElementById('add-portfolio-btn');
const portfoliosContainerEl = document.getElementById('portfolios-container');
const noPortfoliosEl = document.getElementById('no-portfolios');

const portfolioModalEl = document.getElementById('portfolio-modal');
const portfolioFormEl = document.getElementById('portfolio-form');
const modalTitleEl = document.getElementById('modal-title');
const closePortfolioModalEl = portfolioModalEl?.querySelector('.close-modal');
const cancelPortfolioBtn = document.getElementById('cancel-portfolio');

const investmentModalEl = document.getElementById('investment-modal');
const investmentFormEl = document.getElementById('investment-form');
const closeInvestmentModalEl = investmentModalEl?.querySelector('.close-modal');
const cancelInvestmentBtn = document.getElementById('cancel-investment');

// Initialize
onReady(() => {
    setupEventListeners();
    loadPortfolios();
});

// Setup event listeners
function setupEventListeners() {
    // Portfolio modal
    if (addPortfolioBtnEl) {
        addPortfolioBtnEl.addEventListener('click', openPortfolioModal);
    }

    if (portfolioFormEl) {
        portfolioFormEl.addEventListener('submit', handlePortfolioSubmit);
    }

    if (closePortfolioModalEl) {
        closePortfolioModalEl.addEventListener('click', closePortfolioModal);
    }

    if (cancelPortfolioBtn) {
        cancelPortfolioBtn.addEventListener('click', closePortfolioModal);
    }

    // Investment modal
    if (investmentFormEl) {
        investmentFormEl.addEventListener('submit', handleInvestmentSubmit);
    }

    if (closeInvestmentModalEl) {
        closeInvestmentModalEl.addEventListener('click', closeInvestmentModal);
    }

    if (cancelInvestmentBtn) {
        cancelInvestmentBtn.addEventListener('click', closeInvestmentModal);
    }

    // Close modal when clicking outside
    window.addEventListener('click', (e) => {
        if (e.target === portfolioModalEl) {
            closePortfolioModal();
        }
        if (e.target === investmentModalEl) {
            closeInvestmentModal();
        }
    });
}

// Load all portfolios
async function loadPortfolios() {
    try {
        showLoading(true);
        portfolios = await fetchAPI('/portfolios');
        renderPortfolios();
        showLoading(false);
    } catch (error) {
        Logger.error('Failed to load portfolios', error);
        showError('Failed to load portfolios');
        showLoading(false);
    }
}

// Render portfolios
function renderPortfolios() {
    if (portfolios.length === 0) {
        portfoliosContainerEl.innerHTML = '';
        noPortfoliosEl.style.display = 'block';
        return;
    }

    noPortfoliosEl.style.display = 'none';
    portfoliosContainerEl.innerHTML = portfolios.map((portfolio) => createPortfolioCard(portfolio)).join('');

    // Add event listeners to dynamically created elements
    document.querySelectorAll('.portfolio-card').forEach((card) => {
        const portfolioId = parseInt(card.dataset.portfolioId);
        const editBtn = card.querySelector('.btn-edit-portfolio');
        const deleteBtn = card.querySelector('.btn-delete-portfolio');
        const addInvBtn = card.querySelector('.btn-add-investment');
        const toggleInvBtn = card.querySelector('.btn-toggle-investments');

        if (editBtn) {
            editBtn.addEventListener('click', () => editPortfolio(portfolioId));
        }
        if (deleteBtn) {
            deleteBtn.addEventListener('click', () => deletePortfolio(portfolioId));
        }
        if (addInvBtn) {
            addInvBtn.addEventListener('click', () => openInvestmentModal(portfolioId));
        }
        if (toggleInvBtn) {
            toggleInvBtn.addEventListener('click', () => toggleInvestments(portfolioId));
        }

        // Load investments
        loadPortfolioInvestments(portfolioId, card);
    });
}

// Create portfolio card HTML
function createPortfolioCard(portfolio) {
    const totalValue = portfolio.total_value || 0;
    return `
        <div class="card portfolio-card" data-portfolio-id="${portfolio.id}">
            <div class="card-header">
                <div>
                    <h3>${escapeHtml(portfolio.name)}</h3>
                    <p style="color: var(--text-light); margin: 0;">Owner: ${escapeHtml(portfolio.owner)}</p>
                </div>
                <div class="portfolio-value" style="text-align: right;">
                    <h3 style="margin: 0;">${formatCurrency(totalValue)}</h3>
                </div>
            </div>
            <div class="card-body">
                <p>${portfolio.description ? escapeHtml(portfolio.description) : '<em>No description</em>'}</p>
                <p style="font-size: 0.9rem; color: var(--text-light); margin: 0;">
                    Created: ${formatDate(portfolio.created_at)}
                </p>
            </div>
            <div class="card-footer">
                <button class="btn btn-sm btn-primary btn-add-investment">+ Add Investment</button>
                <button class="btn btn-sm btn-outline btn-toggle-investments">View Investments</button>
                <button class="btn btn-sm btn-secondary btn-edit-portfolio">Edit</button>
                <button class="btn btn-sm btn-danger btn-delete-portfolio">Delete</button>
            </div>
            <div class="investments-section" style="display: none; margin-top: 20px; padding-top: 20px; border-top: 2px solid var(--border-color);">
                <h4>Investments</h4>
                <div class="investments-table" style="overflow-x: auto;">
                    <table>
                        <thead>
                            <tr>
                                <th>Ticker</th>
                                <th>Company</th>
                                <th>Qty</th>
                                <th>Purchase Price</th>
                                <th>Current Price</th>
                                <th>Total Value</th>
                                <th>Gain/Loss</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody class="investments-tbody">
                            <tr><td colspan="8" style="text-align: center; padding: 20px;">Loading investments...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    `;
}

// Load investments for a portfolio
async function loadPortfolioInvestments(portfolioId, cardEl) {
    try {
        const investments = await fetchAPI(`/investments/portfolio/${portfolioId}`);
        const tbody = cardEl.querySelector('.investments-tbody');
        
        if (investments.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 20px;">No investments</td></tr>';
            return;
        }

        tbody.innerHTML = investments.map((inv) => createInvestmentRow(inv, portfolioId)).join('');

        // Add event listeners to investment rows
        tbody.querySelectorAll('.btn-edit-investment, .btn-delete-investment').forEach((btn) => {
            const investmentId = parseInt(btn.dataset.investmentId);
            if (btn.classList.contains('btn-edit-investment')) {
                btn.addEventListener('click', () => editInvestment(investmentId, portfolioId));
            } else {
                btn.addEventListener('click', () => deleteInvestment(investmentId, portfolioId));
            }
        });
    } catch (error) {
        Logger.error('Failed to load investments', error);
        const tbody = cardEl.querySelector('.investments-tbody');
        tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; color: red;">Failed to load investments</td></tr>';
    }
}

// Create investment row HTML
function createInvestmentRow(investment, portfolioId) {
    const totalValue = investment.quantity * investment.current_price;
    const purchaseTotal = investment.quantity * investment.purchase_price;
    const gainLoss = totalValue - purchaseTotal;
    const gainLossPercent = (gainLoss / purchaseTotal) * 100;

    const color = gainLoss >= 0 ? '#10b981' : '#ef4444';

    return `
        <tr>
            <td><strong>${escapeHtml(investment.ticker)}</strong></td>
            <td>${escapeHtml(investment.name)}</td>
            <td>${formatNumber(investment.quantity)}</td>
            <td>${formatCurrency(investment.purchase_price)}</td>
            <td>${formatCurrency(investment.current_price)}</td>
            <td>${formatCurrency(totalValue)}</td>
            <td style="color: ${color};">
                ${formatCurrency(gainLoss)} (${gainLossPercent.toFixed(2)}%)
            </td>
            <td>
                <button class="btn btn-sm btn-secondary btn-edit-investment" data-investment-id="${investment.id}">Edit</button>
                <button class="btn btn-sm btn-danger btn-delete-investment" data-investment-id="${investment.id}">Delete</button>
            </td>
        </tr>
    `;
}

// Toggle investments view
function toggleInvestments(portfolioId) {
    const cardEl = document.querySelector(`[data-portfolio-id="${portfolioId}"]`);
    const investmentsSection = cardEl?.querySelector('.investments-section');
    
    if (investmentsSection) {
        if (investmentsSection.style.display === 'none') {
            investmentsSection.style.display = 'block';
            loadPortfolioInvestments(portfolioId, cardEl);
        } else {
            investmentsSection.style.display = 'none';
        }
    }
}

// Open portfolio modal for creation
function openPortfolioModal() {
    currentEditingPortfolioId = null;
    modalTitleEl.textContent = 'Create New Portfolio';
    portfolioFormEl.reset();
    portfolioModalEl.classList.add('active');
}

// Open portfolio modal for editing
async function editPortfolio(portfolioId) {
    try {
        const portfolio = await fetchAPI(`/portfolios/${portfolioId}`);
        currentEditingPortfolioId = portfolioId;
        
        document.getElementById('portfolio-name').value = portfolio.name;
        document.getElementById('portfolio-owner').value = portfolio.owner;
        document.getElementById('portfolio-description').value = portfolio.description || '';
        
        modalTitleEl.textContent = 'Edit Portfolio';
        portfolioModalEl.classList.add('active');
    } catch (error) {
        Logger.error('Failed to load portfolio', error);
        showError('Failed to load portfolio');
    }
}

// Close portfolio modal
function closePortfolioModal() {
    portfolioModalEl.classList.remove('active');
    portfolioFormEl.reset();
    currentEditingPortfolioId = null;
}

// Handle portfolio form submission
async function handlePortfolioSubmit(e) {
    e.preventDefault();

    const name = document.getElementById('portfolio-name').value.trim();
    const owner = document.getElementById('portfolio-owner').value.trim();
    const description = document.getElementById('portfolio-description').value.trim();

    if (!name || !owner) {
        showError('Please fill in all required fields');
        return;
    }

    try {
        showLoading(true);

        if (currentEditingPortfolioId) {
            // Update portfolio
            await fetchAPI(`/portfolios/${currentEditingPortfolioId}`, {
                method: 'PATCH',
                body: JSON.stringify({ name, owner, description: description || null }),
            });
            showSuccess('Portfolio updated successfully!');
        } else {
            // Create portfolio
            await fetchAPI('/portfolios', {
                method: 'POST',
                body: JSON.stringify({ name, owner, description: description || null }),
            });
            showSuccess('Portfolio created successfully!');
        }

        closePortfolioModal();
        loadPortfolios();
        showLoading(false);
    } catch (error) {
        Logger.error('Failed to save portfolio', error);
        showError(error.message || 'Failed to save portfolio');
        showLoading(false);
    }
}

// Delete portfolio
async function deletePortfolio(portfolioId) {
    if (!confirm('Are you sure you want to delete this portfolio? This action cannot be undone.')) {
        return;
    }

    try {
        showLoading(true);
        await fetchAPI(`/portfolios/${portfolioId}`, { method: 'DELETE' });
        showSuccess('Portfolio deleted successfully!');
        loadPortfolios();
        showLoading(false);
    } catch (error) {
        Logger.error('Failed to delete portfolio', error);
        showError('Failed to delete portfolio');
        showLoading(false);
    }
}

// Open investment modal
function openInvestmentModal(portfolioId) {
    currentEditingInvestmentId = null;
    document.getElementById('investment-portfolio-id').value = portfolioId;
    document.getElementById('investment-id').value = '';
    investmentFormEl.reset();
    investmentModalEl.classList.add('active');
}

// Edit investment
async function editInvestment(investmentId, portfolioId) {
    try {
        const investment = await fetchAPI(`/investments/${investmentId}`);
        currentEditingInvestmentId = investmentId;
        
        document.getElementById('investment-portfolio-id').value = portfolioId;
        document.getElementById('investment-id').value = investmentId;
        document.getElementById('investment-ticker').value = investment.ticker;
        document.getElementById('investment-name').value = investment.name;
        document.getElementById('investment-sector').value = investment.sector || '';
        document.getElementById('investment-quantity').value = investment.quantity;
        document.getElementById('investment-purchase-price').value = investment.purchase_price;
        document.getElementById('investment-current-price').value = investment.current_price;
        document.getElementById('investment-notes').value = investment.notes || '';
        
        investmentModalEl.classList.add('active');
    } catch (error) {
        Logger.error('Failed to load investment', error);
        showError('Failed to load investment');
    }
}

// Close investment modal
function closeInvestmentModal() {
    investmentModalEl.classList.remove('active');
    investmentFormEl.reset();
    currentEditingInvestmentId = null;
}

// Handle investment form submission
async function handleInvestmentSubmit(e) {
    e.preventDefault();

    const portfolioId = parseInt(document.getElementById('investment-portfolio-id').value);
    const ticker = document.getElementById('investment-ticker').value.trim().toUpperCase();
    const name = document.getElementById('investment-name').value.trim();
    const sector = document.getElementById('investment-sector').value.trim();
    const quantity = parseFloat(document.getElementById('investment-quantity').value);
    const purchasePrice = parseFloat(document.getElementById('investment-purchase-price').value);
    const currentPrice = parseFloat(document.getElementById('investment-current-price').value);
    const notes = document.getElementById('investment-notes').value.trim();

    if (!ticker || !name || !validatePositiveNumber(quantity) || !validatePositiveNumber(purchasePrice) || !validatePositiveNumber(currentPrice)) {
        showError('Please fill in all required fields with valid values');
        return;
    }

    try {
        showLoading(true);

        const investmentData = {
            portfolio_id: portfolioId,
            ticker,
            name,
            sector: sector || null,
            quantity,
            purchase_price: purchasePrice,
            current_price: currentPrice,
            notes: notes || null,
        };

        if (currentEditingInvestmentId) {
            // Update investment
            await fetchAPI(`/investments/${currentEditingInvestmentId}`, {
                method: 'PATCH',
                body: JSON.stringify(investmentData),
            });
            showSuccess('Investment updated successfully!');
        } else {
            // Create investment
            await fetchAPI('/investments', {
                method: 'POST',
                body: JSON.stringify(investmentData),
            });
            showSuccess('Investment added successfully!');
        }

        closeInvestmentModal();
        loadPortfolios();
        showLoading(false);
    } catch (error) {
        Logger.error('Failed to save investment', error);
        showError(error.message || 'Failed to save investment');
        showLoading(false);
    }
}

// Delete investment
async function deleteInvestment(investmentId, portfolioId) {
    if (!confirm('Are you sure you want to delete this investment?')) {
        return;
    }

    try {
        showLoading(true);
        await fetchAPI(`/investments/${investmentId}`, { method: 'DELETE' });
        showSuccess('Investment deleted successfully!');
        
        const cardEl = document.querySelector(`[data-portfolio-id="${portfolioId}"]`);
        if (cardEl) {
            loadPortfolioInvestments(portfolioId, cardEl);
        }
        
        showLoading(false);
    } catch (error) {
        Logger.error('Failed to delete investment', error);
        showError('Failed to delete investment');
        showLoading(false);
    }
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;',
    };
    return text?.replace(/[&<>"']/g, (m) => map[m]) || '';
}
