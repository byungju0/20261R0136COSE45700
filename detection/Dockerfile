# syntax=docker/dockerfile:1.7
# Detection — Redis queue consumer + VARCO Translation/LLM classifier
# Story 5.2: BuildKit multi-stage with registry cache mode=max.

FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl procps tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY shared /app/shared
COPY detection/requirements.txt /app/detection/requirements.txt

WORKDIR /app/detection
RUN pip install --upgrade pip setuptools && \
    pip install -r requirements.txt

COPY detection /app/detection

# /run/secrets/<name> → upper-case env var; AC #12 (secrets mount, no direct env injection).
COPY infra/docker-secret-shim.sh /usr/local/bin/secret-shim
RUN chmod +x /usr/local/bin/secret-shim

# Healthcheck: queue consumer process must be running.
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -f "detection.src.main" >/dev/null || exit 1

ENV PYTHONPATH=/app
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/secret-shim"]
CMD ["python", "-m", "detection.src.main"]
