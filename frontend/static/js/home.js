/* ========================================
   HOME PAGE JAVASCRIPT
   ======================================== */

onReady(() => {
    loadHomeStats();
});

async function loadHomeStats() {
    try {
        showLoading(true);

        // Fetch portfolios count
        const portfolios = await fetchAPI('/portfolios');
        const portfolioCount = portfolios.length;
        document.getElementById('stat-portfolios').textContent = portfolioCount;

        // Calculate total investments and value
        let totalInvestments = 0;
        let totalValue = 0;

        for (const portfolio of portfolios) {
            // Fetch investments for each portfolio
            const investments = await fetchAPI(`/investments/portfolio/${portfolio.id}`);
            totalInvestments += investments.length;
            totalValue += portfolio.total_value || 0;
        }

        document.getElementById('stat-investments').textContent = totalInvestments;
        document.getElementById('stat-total-value').textContent = formatCurrency(totalValue);

        showLoading(false);
    } catch (error) {
        Logger.error('Failed to load home stats', error);
        // Don't show error to user on home page, just use zero values
        showLoading(false);
    }
}
