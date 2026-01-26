
# --------------------------------------
# Stage 1: Download Models (Alpine-based)
# --------------------------------------
FROM alpine:3.18 AS model-downloader

# Install required tools for Ollama install
RUN apk add --no-cache curl zstd ca-certificates

# Install Ollama CLI (required for pulling models)
RUN curl -fsSL https://ollama.com/install.sh | sh

# Pre-pull models to /root/.ollama/models
RUN /usr/local/bin/ollama pull tinyllama:1.1b && \
    /usr/local/bin/ollama pull smollm2:360m && \
    /usr/local/bin/ollama pull smollm2:1.7b && \
    /usr/local/bin/ollama pull starcoder:1b && \
    /usr/local/bin/ollama pull deepseek-coder:1.3b && \
    /usr/local/bin/ollama pull qwen2.5-coder:1.5b

# --------------------------------------
# Stage 2: Build Ollama (Debian-based)
# --------------------------------------
FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl zstd ca-certificates && \
    curl -fsSL https://ollama.com/install.sh | sh && \
    apt-get purge -y curl && \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------
# Stage 3: Runtime Image
# --------------------------------------
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 && rm -rf /var/lib/apt/lists/*

# Copy Ollama binary from builder
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=builder /usr/local/lib/ollama /usr/local/lib/ollama

# Copy pre-pulled models into /tmp/.ollama
RUN mkdir -p /tmp/.ollama/models
COPY --from=model-downloader /root/.ollama/models /tmp/.ollama/models

# Create non-root user and assign GID 1069
RUN groupadd -g 1069 ollama && useradd -u 1069 -g ollama -m ollama && \
    chown -R ollama:ollama /tmp/.ollama

# Set environment
ENV OLLAMA_MODELS=/tmp/.ollama/models \
    OLLAMA_HOST=0.0.0.0

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ollama
EXPOSE 11434
ENTRYPOINT ["/entrypoint.sh"]