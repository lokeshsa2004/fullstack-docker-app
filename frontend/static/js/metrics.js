/**
 * Metrics Dashboard
 * Fetches Prometheus metrics and displays them using Chart.js
 */

// Add Chart.js library dynamically
const loadChartJS = () => {
  if (window.Chart) return Promise.resolve();
  
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js';
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });
};

// Metrics API configuration
const METRICS_API = '/api/v1/metrics';
const ENDPOINTS_API = '/api/v1/metrics/endpoints';
const PORTFOLIO_API = '/api/v1/metrics/portfolio-trend';

// Chart instances storage
const charts = {};

// Refresh interval ID
let refreshIntervalId = null;

/**
 * Manually refresh metrics
 */
async function refreshMetrics() {
  const btn = document.getElementById('metrics-refresh-btn');
  if (btn) {
    btn.disabled = true;
    btn.textContent = 'Refreshing...';
  }

  try {
    const metrics = await fetchMetrics();
    if (metrics && !metrics.error) {
      updateSystemMetrics(metrics);
      createErrorRateChart(metrics);
      createRequestSummaryChart(metrics);
      createDatabaseMetricsChart(metrics);
      updateResponseTimeIndicator(metrics);
    }
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.textContent = 'Refresh Metrics';
    }
  }
}

/**
 * Fetch metrics from API
 */
async function fetchMetrics() {
  try {
    const response = await fetch(METRICS_API);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Error fetching metrics:', error);
    return null;
  }
}

/**
 * Fetch endpoint metrics
 */
async function fetchEndpointMetrics() {
  try {
    const response = await fetch(ENDPOINTS_API);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Error fetching endpoint metrics:', error);
    return null;
  }
}

/**
 * Fetch portfolio trend metrics
 */
async function fetchPortfolioTrend() {
  try {
    const response = await fetch(PORTFOLIO_API);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Error fetching portfolio trend:', error);
    return null;
  }
}

/**
 * Format bytes to human readable format
 */
function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

/**
 * Format time duration
 */
function formatDuration(seconds) {
  if (seconds < 60) return `${Math.round(seconds)}s`;
  if (seconds < 3600) return `${Math.round(seconds / 60)}m`;
  return `${Math.round(seconds / 3600)}h`;
}

/**
 * Create or update system metrics display
 */
function updateSystemMetrics(metrics) {
  const container = document.getElementById('system-metrics');
  if (!container) return;

  const db = metrics.database_metrics || {};
  const req = metrics.request_metrics || {};
  const sys = metrics.system_metrics || {};

  container.innerHTML = `
    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-label">Portfolios</div>
        <div class="metric-value">${db.portfolio_count || 0}</div>
        <div class="metric-subtext">Created: ${db.portfolios_created_total || 0}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Investments</div>
        <div class="metric-value">${db.investment_count || 0}</div>
        <div class="metric-subtext">Added: ${db.investments_added_total || 0}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Total Requests</div>
        <div class="metric-value">${req.total_requests || 0}</div>
        <div class="metric-subtext">Errors: ${req.total_errors || 0}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Error Rate</div>
        <div class="metric-value ${req.error_rate_percent > 5 ? 'error' : ''}">${req.error_rate_percent || 0}%</div>
        <div class="metric-subtext">Active requests: ${req.active_requests || 0}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Avg Response Time</div>
        <div class="metric-value">${(req.avg_response_time_seconds).toFixed(2)}s</div>
        <div class="metric-subtext">Uptime: ${formatDuration(sys.uptime_seconds || 0)}</div>
      </div>
    </div>
  `;
}

/**
 * Create error rate chart
 */
function createErrorRateChart(metrics) {
  const ctx = document.getElementById('error-rate-chart');
  if (!ctx) return;

  const errorRate = metrics.request_metrics?.error_rate_percent || 0;
  const successRate = 100 - errorRate;

  if (charts.errorRate) {
    charts.errorRate.data.datasets[0].data = [successRate, errorRate];
    charts.errorRate.update();
  } else {
    charts.errorRate = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Success', 'Errors'],
        datasets: [{
          data: [successRate, errorRate],
          backgroundColor: ['#4CAF50', '#f44336'],
          borderColor: ['#ffffff', '#ffffff'],
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                return context.label + ': ' + context.parsed + '%';
              }
            }
          }
        }
      }
    });
  }
}

/**
 * Create request summary chart
 */
function createRequestSummaryChart(metrics) {
  const ctx = document.getElementById('request-summary-chart');
  if (!ctx) return;

  const total = metrics.request_metrics?.total_requests || 0;
  const errors = metrics.request_metrics?.total_errors || 0;
  const success = total - errors;

  if (charts.requestSummary) {
    charts.requestSummary.data.datasets[0].data = [success, errors];
    charts.requestSummary.update();
  } else {
    charts.requestSummary = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Successful', 'Failed'],
        datasets: [{
          label: 'Requests',
          data: [success, errors],
          backgroundColor: ['#4CAF50', '#f44336'],
          borderColor: ['#4CAF50', '#f44336'],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: 'y',
        scales: {
          x: {
            beginAtZero: true
          }
        },
        plugins: {
          legend: {
            display: false
          }
        }
      }
    });
  }
}

/**
 * Create database metrics chart
 */
function createDatabaseMetricsChart(metrics) {
  const ctx = document.getElementById('database-metrics-chart');
  if (!ctx) return;

  const db = metrics.database_metrics || {};

  if (charts.database) {
    charts.database.data.datasets[0].data = [db.portfolio_count || 0, db.investment_count || 0];
    charts.database.update();
  } else {
    charts.database = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Portfolios', 'Investments'],
        datasets: [{
          label: 'Count',
          data: [db.portfolio_count || 0, db.investment_count || 0],
          backgroundColor: ['#2196F3', '#FF9800'],
          borderColor: ['#2196F3', '#FF9800'],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true
          }
        },
        plugins: {
          legend: {
            display: false
          }
        }
      }
    });
  }
}

/**
 * Create response time indicator
 */
function updateResponseTimeIndicator(metrics) {
  const indicator = document.getElementById('response-time-indicator');
  if (!indicator) return;

  const avgTime = metrics.request_metrics?.avg_response_time_seconds || 0;
  const timeMs = (avgTime * 1000).toFixed(2);
  
  let status = 'good';
  if (avgTime > 0.5) status = 'warning';
  if (avgTime > 1.0) status = 'critical';

  indicator.className = `response-time-indicator ${status}`;
  indicator.innerHTML = `
    <div class="indicator-label">Avg Response Time</div>
    <div class="indicator-value">${timeMs}ms</div>
    <div class="indicator-status">${status.toUpperCase()}</div>
  `;
}

/**
 * Initialize metrics dashboard
 */
async function initializeMetricsDashboard() {
  // Check if Chart.js container exists
  if (!document.getElementById('metrics-dashboard')) {
    return;
  }

  // Load Chart.js library
  try {
    await loadChartJS();
  } catch (error) {
    console.error('Failed to load Chart.js:', error);
    const container = document.getElementById('metrics-dashboard');
    container.innerHTML = '<div class="alert alert-error">Failed to load metrics visualization library</div>';
    return;
  }

  // Set up refresh button handler
  const refreshBtn = document.getElementById('metrics-refresh-btn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', refreshMetrics);
  }

  // Initial load
  const metrics = await fetchMetrics();
  if (metrics && !metrics.error) {
    updateSystemMetrics(metrics);
    createErrorRateChart(metrics);
    createRequestSummaryChart(metrics);
    createDatabaseMetricsChart(metrics);
    updateResponseTimeIndicator(metrics);
  }

  // Refresh metrics every 10 seconds
  refreshIntervalId = setInterval(async () => {
    const updatedMetrics = await fetchMetrics();
    if (updatedMetrics && !updatedMetrics.error) {
      updateSystemMetrics(updatedMetrics);
      createErrorRateChart(updatedMetrics);
      createRequestSummaryChart(updatedMetrics);
      createDatabaseMetricsChart(updatedMetrics);
      updateResponseTimeIndicator(updatedMetrics);
    }
  }, 10000);
}

/**
 * Cleanup on page unload
 */
window.addEventListener('beforeunload', () => {
  if (refreshIntervalId) {
    clearInterval(refreshIntervalId);
  }
});

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeMetricsDashboard);
} else {
  initializeMetricsDashboard();
}

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    fetchMetrics,
    fetchEndpointMetrics,
    fetchPortfolioTrend,
    initializeMetricsDashboard
  };
}
