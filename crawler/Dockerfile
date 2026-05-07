# syntax=docker/dockerfile:1.7
# Crawler — APScheduler + crawl4ai (Playwright Chromium) + Redis publisher
# Story 5.2: BuildKit multi-stage with registry cache mode=max.

FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# OS deps for Playwright Chromium runtime + curl/pgrep for healthcheck.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl procps tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# `-e ../shared` in crawler/requirements.txt expects /app/shared next to /app/crawler.
COPY shared /app/shared
COPY crawler/requirements.txt /app/crawler/requirements.txt

WORKDIR /app/crawler
RUN pip install --upgrade pip setuptools && \
    pip install -r requirements.txt

# Install Chromium + system deps via Playwright's apt installer.
RUN python -m playwright install --with-deps chromium

# Copy source AFTER deps for cache reuse on code-only changes.
COPY crawler /app/crawler

# /run/secrets/<name> → upper-case env var; AC #12 (secrets mount, no direct env injection).
COPY infra/docker-secret-shim.sh /usr/local/bin/secret-shim
RUN chmod +x /usr/local/bin/secret-shim

# Healthcheck: scheduler process must be running.
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD pgrep -f "crawler.src.scheduler" >/dev/null || exit 1

ENV PYTHONPATH=/app
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/secret-shim"]
CMD ["python", "-m", "crawler.src.scheduler.crawl_scheduler"]
