# Multi-stage production-ready Dockerfile
# Build from repository root: docker build -f backend/Dockerfile .

# ============================================================
# Builder Stage: Install Python dependencies
# ============================================================
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ============================================================
# Runtime Stage: Minimal production image
# ============================================================
FROM python:3.11-slim

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder (using global /usr/local path)
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY backend/ /app/
COPY frontend/ /app/frontend/

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check - uvicorn is in /usr/local/bin (installed globally)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -fsS http://localhost:8000/health >/dev/null || exit 1

# CMD uses uvicorn from /usr/local/bin (installed globally via pip)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
