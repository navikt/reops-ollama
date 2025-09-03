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

# Stage 2: Copy to Distroless
FROM gcr.io/distroless/cc:latest

# Copy Ollama binaries and necessary files
COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama
# Copy pre-pulled model files into the runtime-writable folder (/tmp).
# Copy the .ollama directory explicitly to ensure dotfiles/directories are preserved.
COPY --from=builder /var/lib/ollama/.ollama /tmp/.ollama
# We do NOT copy the shell entrypoint into the Distroless image because
# Distroless does not include a shell (bash/sh). Instead we run the
# Ollama binary directly as the container's entrypoint.

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/tmp
ENV HOME=/tmp
ENV MODEL_NAME=llama3.2:3b

VOLUME /tmp
EXPOSE 11434

ENTRYPOINT ["/usr/local/bin/ollama","serve"]

## Optional dev final image (includes bash and entrypoint for runtime pulls)
FROM ubuntu:22.04 AS dev

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl bash && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=builder /var/lib/ollama/.ollama /tmp/.ollama
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/tmp
ENV HOME=/tmp

VOLUME /tmp
EXPOSE 11434

ENTRYPOINT ["/entrypoint.sh"]