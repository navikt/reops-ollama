
# --------------------------
# Stage 1: Build + Model Pull
# --------------------------
FROM debian:bookworm-slim AS builder

# Install required tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl zstd ca-certificates && \
    curl -fsSL https://ollama.com/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*

# Pre-pull models to /tmp/.ollama/models
ENV OLLAMA_MODELS=/tmp/.ollama/models
RUN mkdir -p $OLLAMA_MODELS && \
    /usr/local/bin/ollama pull tinyllama:1.1b && \
    /usr/local/bin/ollama pull smollm2:360m && \
    /usr/local/bin/ollama pull smollm2:1.7b && \
    /usr/local/bin/ollama pull starcoder:1b && \
    /usr/local/bin/ollama pull deepseek-coder:1.3b && \
    /usr/local/bin/ollama pull qwen2.5-coder:1.5b

# --------------------------
# Stage 2: Runtime Image
# --------------------------
FROM debian:bookworm-slim

# Install runtime dependency
RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 && rm -rf /var/lib/apt/lists/*

# Add non-root user with GID 1069
RUN groupadd -g 1069 ollama && useradd -u 1069 -g ollama -m ollama

# Create model directory and copy pre-pulled models
RUN mkdir -p /tmp/.ollama/models
COPY --from=builder /tmp/.ollama/models /tmp/.ollama/models

# Copy binary
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=builder /usr/local/lib/ollama /usr/local/lib/ollama

# Set environment
ENV OLLAMA_MODELS=/tmp/.ollama/models \
    OLLAMA_HOST=0.0.0.0

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown -R ollama:ollama /tmp/.ollama /entrypoint.sh

USER ollama
EXPOSE 11434
ENTRYPOINT ["/entrypoint.sh"]