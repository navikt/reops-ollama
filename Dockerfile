# Using Chainguard's wolfi-base from their free public registry.
# Note: Chainguard's Ollama image is not free (requires paid subscription).
# Per NAV guidance: use cgr.dev/chainguard/ for images not in NAV's private registry.

FROM cgr.dev/chainguard/wolfi-base@sha256:1c3731953120424013499309796bd0084113bad7216dd00820953c2f0f7f7e0b

USER root

# Install runtime dependencies for Ollama
# libstdc++ and libgcc are required for Ollama's C++ dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    libstdc++ \
    libgcc

# Create ollama user and directories for non-root execution (required for NAIS)
RUN adduser -D -u 1000 ollama && \
    mkdir -p /home/ollama/.ollama /home/ollama/models && \
    chown -R ollama:ollama /home/ollama

# Environment variables for Ollama configuration
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_KEEP_ALIVE=2m
ENV OLLAMA_REQUEST_TIMEOUT=120s
ENV OLLAMA_MAX_LOADED_MODELS=4
ENV OLLAMA_MODELS=/home/ollama/models

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Pre-pull models during build (as root, then fix ownership)
RUN OLLAMA_MODELS=/home/ollama/models ollama serve & \
    OLLAMA_PID=$! && \
    until curl -fsS http://localhost:11434/api/tags > /dev/null 2>&1; do sleep 1; done && \
    OLLAMA_MODELS=/home/ollama/models ollama pull tinyllama:1.1b && \
    # ollama pull smollm2:1.7b && \
    # ollama pull smollm2:360m && \
    # ollama pull starcoder:1b && \
    # ollama pull deepcoder:1.5b && \
    # ollama pull deepseek-coder:1.3b && \
    # ollama pull qwen2.5-coder:1.5b && \
    kill $OLLAMA_PID && \
    wait $OLLAMA_PID 2>/dev/null || true && \
    chown -R ollama:ollama /home/ollama

EXPOSE 11434

# Copy entrypoint and switch to non-root user
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ollama
WORKDIR /home/ollama

ENTRYPOINT ["/entrypoint.sh"]
