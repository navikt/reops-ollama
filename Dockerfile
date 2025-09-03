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
ENV OLLAMA_HOME=/tmp
ENV HOME=/tmp
ENV MODEL_NAME=llama3.2:3b

RUN curl -fsSL https://ollama.com/install.sh | bash

# Stage 2: Copy to Distroless
FROM gcr.io/distroless/cc:latest

# Copy Ollama binaries and necessary files
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=builder /tmp /tmp
COPY --from=builder /entrypoint.sh /entrypoint.sh

# Set permissions (if needed, but Distroless has limited tools)
# Note: Distroless lacks chmod; ensure entrypoint.sh is executable in builder stage

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/tmp
ENV HOME=/tmp
ENV MODEL_NAME=llama3.2:3b

VOLUME /tmp
EXPOSE 11434

ENTRYPOINT ["/entrypoint.sh"]