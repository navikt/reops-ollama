# Using Chainguard's wolfi-base from their free public registry.
# Note: Chainguard's Ollama image is not free (requires paid subscription).
# Per NAV guidance: use cgr.dev/chainguard/ for images not in NAV's private registry.

# Stage 1: Model downloader
FROM cgr.dev/chainguard/wolfi-base@sha256:1c3731953120424013499309796bd0084113bad7216dd00820953c2f0f7f7e0b AS model-downloader

USER root

# Install minimal dependencies needed for downloading models
RUN apk add --no-cache \
    ca-certificates \
    curl \
    libstdc++ \
    libgcc

# Create directories for models
RUN mkdir -p /models

# Environment variables for model download
ENV OLLAMA_MODELS=/models

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Download models in parallel (using smallest model for faster builds)
RUN ollama serve & \
    OLLAMA_PID=$! && \
    # Wait for Ollama to be ready with faster polling
    timeout=30 && elapsed=0 && \
    until curl -fsS http://localhost:11434/api/tags > /dev/null 2>&1 || [ $elapsed -ge $timeout ]; do \
        sleep 0.5; elapsed=$((elapsed + 1)); \
    done && \
    # Pull the smallest model for faster builds
    ollama pull smollm2:360m && \
    # Uncomment additional models as needed:
    # ollama pull tinyllama:1.1b && \
    # ollama pull smollm2:1.7b && \
    # ollama pull starcoder:1b && \
    # ollama pull deepseek-coder:1.3b && \
    # ollama pull qwen2.5-coder:1.5b && \
    kill $OLLAMA_PID && \
    wait $OLLAMA_PID 2>/dev/null || true

# Stage 2: Final runtime image
FROM cgr.dev/chainguard/wolfi-base@sha256:1c3731953120424013499309796bd0084113bad7216dd00820953c2f0f7f7e0b

USER root

# Install runtime dependencies for Ollama
RUN apk add --no-cache \
    ca-certificates \
    curl \
    libstdc++ \
    libgcc

# Create ollama user and directories for non-root execution (required for NAIS)
RUN adduser -D -u 1000 ollama && \
    mkdir -p /home/ollama/.ollama /home/ollama/models && \
    chown -R ollama:ollama /home/ollama

# Copy entrypoint early (better layer caching - code changes won't invalidate model layers)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment variables for Ollama configuration
ENV HOME=/home/ollama
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_KEEP_ALIVE=2m
ENV OLLAMA_REQUEST_TIMEOUT=120s
ENV OLLAMA_MAX_LOADED_MODELS=4
ENV OLLAMA_MODELS=/home/ollama/models
ENV OLLAMA_HOME=/home/ollama/.ollama

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Copy pre-downloaded models from the model-downloader stage
COPY --from=model-downloader --chown=ollama:ollama /models /home/ollama/models

EXPOSE 11434

# Switch to non-root user
USER ollama
WORKDIR /home/ollama

ENTRYPOINT ["/entrypoint.sh"]
