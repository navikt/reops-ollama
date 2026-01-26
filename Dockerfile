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

# Download models with proper wait and error handling
RUN ollama serve > /tmp/ollama.log 2>&1 & \
    OLLAMA_PID=$! && \
    echo "Waiting for Ollama to start (PID: $OLLAMA_PID)..." && \
    # Wait for Ollama to be ready (up to 2 minutes)
    for i in $(seq 1 120); do \
        if curl -fsS http://localhost:11434/api/tags > /dev/null 2>&1; then \
            echo "Ollama is ready!"; \
            break; \
        fi; \
        if [ $i -eq 120 ]; then \
            echo "Timeout waiting for Ollama"; \
            cat /tmp/ollama.log; \
            exit 1; \
        fi; \
        sleep 1; \
    done && \
    # Pull models sequentially with better error handling
    echo "Pulling tinyllama:1.1b..." && \
    ollama pull tinyllama:1.1b && \
    echo "Pulling smollm2:360m..." && \
    ollama pull smollm2:360m && \
    echo "Pulling smollm2:1.7b..." && \
    ollama pull smollm2:1.7b && \
    echo "Pulling starcoder:1b..." && \
    ollama pull starcoder:1b && \
    echo "Pulling deepseek-coder:1.3b..." && \
    ollama pull deepseek-coder:1.3b && \
    echo "Pulling qwen2.5-coder:1.5b..." && \
    ollama pull qwen2.5-coder:1.5b && \
    echo "All models downloaded successfully!" && \
    # List downloaded models for verification
    ollama list && \
    # Clean shutdown
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

# Environment variables for Ollama configuration (using /tmp which is writable)
ENV HOME=/tmp/ollama
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_KEEP_ALIVE=2m
ENV OLLAMA_REQUEST_TIMEOUT=120s
ENV OLLAMA_MAX_LOADED_MODELS=4
ENV OLLAMA_MODELS=/tmp/ollama/models
ENV OLLAMA_HOME=/tmp/ollama/.ollama

# Create directories with proper permissions in /tmp
# World-writable (777) to ensure NAIS's default user can write
RUN mkdir -p /tmp/ollama/.ollama /tmp/ollama/models && \
    chmod -R 777 /tmp/ollama

# Copy entrypoint early (better layer caching - code changes won't invalidate model layers)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Install Ollama
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl zstd ca-certificates && \
    curl -fsSL https://ollama.com/install.sh | sh && \
    apt-get purge -y curl && \
    rm -rf /var/lib/apt/lists/*

# Copy pre-downloaded models from the model-downloader stage
COPY --from=model-downloader /models /tmp/ollama/models
RUN chmod -R 777 /tmp/ollama/models

EXPOSE 11434

# Don't switch user - let NAIS handle user switching with its default user
WORKDIR /tmp/ollama

ENTRYPOINT ["/entrypoint.sh"]