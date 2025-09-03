# ---------------------------------
#  CPU‑only Ollama image (distroless)
# ---------------------------------

# Stage 1: Install Ollama on Ubuntu
FROM ubuntu:22.04 AS builder

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/var/lib/ollama
ENV HOME=/var/lib/ollama
ENV MODEL_NAME=llama3.2:3b

RUN curl -fsSL https://ollama.com/install.sh | bash

# Pull the model at build time and ensure it's in /var/lib/ollama/.ollama
RUN mkdir -p /var/lib/ollama && chown root:root /var/lib/ollama && \
    OLLAMA_ALLOW_ROOT=true OLLAMA_HOME=/var/lib/ollama HOME=/var/lib/ollama ollama serve & \
    OLLAMA_PID=$! && \
    until curl -fsS http://localhost:11434/api/tags > /dev/null; do sleep 1; done && \
    OLLAMA_ALLOW_ROOT=true OLLAMA_HOME=/var/lib/ollama HOME=/var/lib/ollama ollama pull "$MODEL_NAME" && \
    kill "$OLLAMA_PID" || true && wait "$OLLAMA_PID" 2>/dev/null || true

# Build Rust entrypoint binary
RUN apt-get update && apt-get install -y --no-install-recommends rustc cargo && rm -rf /var/lib/apt/lists/*
COPY cmd/entrypoint ./cmd/entrypoint
RUN cd cmd/entrypoint && cargo build --release
RUN cp cmd/entrypoint/target/release/entrypoint /entrypoint

# -----------------------------------------------------------------------------
# Default production runtime (distroless)
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/cc:latest

# Copy Ollama binary, pre-pulled model, and Rust entrypoint
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=builder /var/lib/ollama/.ollama /tmp/.ollama
COPY --from=builder /entrypoint /entrypoint

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/tmp
ENV HOME=/tmp
ENV MODEL_NAME=llama3.2:3b

VOLUME /tmp
EXPOSE 11434

ENTRYPOINT ["/entrypoint"]