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

# Pull the model at build time so the final (distroless) image already contains it.
# Start Ollama in the background, wait for it to be ready, pull the model, then stop it.
RUN mkdir -p /var/lib/ollama && chown root:root /var/lib/ollama && \
    OLLAMA_ALLOW_ROOT=true OLLAMA_HOME=/var/lib/ollama HOME=/var/lib/ollama ollama serve & \
    OLLAMA_PID=$! && \
    until curl -fsS http://localhost:11434/api/tags > /dev/null; do sleep 1; done && \
    OLLAMA_ALLOW_ROOT=true OLLAMA_HOME=/var/lib/ollama HOME=/var/lib/ollama ollama pull "$MODEL_NAME" && \
    # Make model files writable so they can be used from a writable runtime dir (/tmp)
    chmod -R 0777 /var/lib/ollama || true && \
    kill "$OLLAMA_PID" || true && wait "$OLLAMA_PID" 2>/dev/null || true

# Build small Go entrypoint binary (static) so final distroless image can run it
RUN apt-get update && apt-get install -y --no-install-recommends golang-go && rm -rf /var/lib/apt/lists/*
WORKDIR /go/src/entrypoint
COPY cmd/entrypoint ./cmd/entrypoint
WORKDIR /go/src/entrypoint/cmd/entrypoint
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags "-s -w" -o /entrypoint ./main.go

# -----------------------------------------------------------------------------
# Default production runtime (distroless) using the Go entrypoint
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/cc:latest

# Copy Ollama binary and pre-pulled model metadata (if any) and the Go entrypoint
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