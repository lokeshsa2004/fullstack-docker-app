/* ========================================
   MAIN JAVASCRIPT - UTILITY FUNCTIONS
   ======================================== */

// API BASE URL
const API_BASE_URL = '/api/v1';

// Helper function to show loading state
function showLoading(show = true) {
    const loading = document.getElementById('loading');
    if (loading) {
        loading.style.display = show ? 'flex' : 'none';
    }
}

// Helper function to show error message
function showError(message) {
    const errorEl = document.getElementById('error-message');
    if (errorEl) {
        errorEl.textContent = message;
        errorEl.style.display = 'block';
        setTimeout(() => {
            errorEl.style.display = 'none';
        }, 5000);
    }
}

// Helper function to show success message
function showSuccess(message) {
    const successEl = document.getElementById('success-message') || createSuccessElement();
    if (successEl) {
        successEl.textContent = message;
        successEl.style.display = 'block';
        setTimeout(() => {
            successEl.style.display = 'none';
        }, 5000);
    }
}

// Create success message element if it doesn't exist
function createSuccessElement() {
    const el = document.createElement('div');
    el.id = 'success-message';
    el.className = 'success-message';
    document.body.insertBefore(el, document.body.firstChild);
    return el;
}

// Fetch API helper with error handling
async function fetchAPI(endpoint, options = {}) {
    try {
        const url = `${API_BASE_URL}${endpoint}`;
        const response = await fetch(url, {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers,
            },
            ...options,
        });

        const text = await response.text();
        let data = null;
        if (text && text.length > 0) {
            try {
                data = JSON.parse(text);
            } catch {
                if (!response.ok) {
                    throw new Error(response.statusText || 'API Error');
                }
            }
        }

        if (!response.ok) {
            const detail = data && data.detail;
            const errorMessage =
                typeof detail === 'string'
                    ? detail
                    : Array.isArray(detail)
                      ? detail.map((d) => d.msg || JSON.stringify(d)).join('; ')
                      : detail
                        ? JSON.stringify(detail)
                        : response.statusText || 'API Error';
            throw new Error(errorMessage);
        }

        return data;
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// Format currency
function formatCurrency(value) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
    }).format(value);
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
    });
}

// Calculate percentage change
function calculatePercentageChange(original, current) {
    return ((current - original) / original) * 100;
}

// Get percentage change color
function getChangeColor(percentage) {
    if (percentage > 0) return '#10b981'; // green
    if (percentage < 0) return '#ef4444'; // red
    return '#6b7280'; // gray
}

// Validate email
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Validate positive number
function validatePositiveNumber(value) {
    const num = parseFloat(value);
    return !isNaN(num) && num > 0;
}

// Format number with commas
function formatNumber(num) {
    return num.toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
    });
}

// Debounce function
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Throttle function
function throttle(func, limit) {
    let inThrottle;
    return function (...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => (inThrottle = false), limit);
        }
    };
}

// Local storage helpers
const Storage = {
    set: (key, value) => localStorage.setItem(key, JSON.stringify(value)),
    get: (key) => {
        const value = localStorage.getItem(key);
        return value ? JSON.parse(value) : null;
    },
    remove: (key) => localStorage.removeItem(key),
    clear: () => localStorage.clear(),
};

// Console logging helper
const Logger = {
    info: (message, data) => {
        console.log(`[INFO] ${message}`, data);
    },
    warn: (message, data) => {
        console.warn(`[WARN] ${message}`, data);
    },
    error: (message, error) => {
        console.error(`[ERROR] ${message}`, error);
    },
};

function onReady(callback) {
    if (document.readyState !== 'loading') {
        callback();
    } else {
        document.addEventListener('DOMContentLoaded', callback);
    }
}

function initMobileNav() {
    const toggle = document.querySelector('.nav-toggle');
    const menu = document.getElementById('nav-menu');
    if (!toggle || !menu) return;

    toggle.addEventListener('click', () => {
        const open = menu.classList.toggle('active');
        toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
        toggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    });

    menu.querySelectorAll('a').forEach((link) => {
        link.addEventListener('click', () => {
            menu.classList.remove('active');
            toggle.setAttribute('aria-expanded', 'false');
            toggle.setAttribute('aria-label', 'Open menu');
        });
    });
}

onReady(initMobileNav);

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        API_BASE_URL,
        showLoading,
        showError,
        showSuccess,
        fetchAPI,
        formatCurrency,
        formatDate,
        calculatePercentageChange,
        getChangeColor,
        validateEmail,
        validatePositiveNumber,
        formatNumber,
        debounce,
        throttle,
        Storage,
        Logger,
        onReady,
    };
}
