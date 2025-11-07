# ---------------------------------
#  CPU‑only Ollama image (plain)
# ---------------------------------

FROM ubuntu:22.04

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/root/.ollama
ENV HOME=/root
ENV OLLAMA_KEEP_ALIVE=2m
ENV OLLAMA_REQUEST_TIMEOUT=120s
ENV OLLAMA_MAX_LOADED_MODELS=4
# Point models to the pre-built location (read-only)
ENV OLLAMA_MODELS=/root/.ollama/models

RUN curl -fsSL https://ollama.com/install.sh | bash

# Pre-pull models during build
RUN ollama serve & \
    OLLAMA_PID=$! && \
    until curl -fsS http://localhost:11434/api/tags > /dev/null 2>&1; do sleep 1; done && \
    ollama pull smollm2:1.7b && \
    ollama pull tinyllama:1.1b && \
    ollama pull smollm2:360m && \
    ollama pull starcoder:1b && \
    ollama pull deepcoder:1.5b && \
    ollama pull deepseek-coder:1.3b && \
    ollama pull qwen2.5-coder:1.5b && \
    kill $OLLAMA_PID && \
    wait $OLLAMA_PID 2>/dev/null || true

# Copy models to a location we can reference, then point OLLAMA_MODELS there
# Keep OLLAMA_HOME separate for runtime data
ENV OLLAMA_MODELS=/root/.ollama/models
ENV OLLAMA_HOME=/tmp/.ollama

EXPOSE 11434
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
