# ---------------------------------
#  CPU‑only Ollama image (distroless)
# ---------------------------------

# Stage 1: Install Ollama on Ubuntu and pre-pull model
FROM ubuntu:22.04 AS ollama-builder

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
RUN mkdir -p /var/lib/ollama && chown root:root /var/lib/ollama

# Stage 2: Build Rust entrypoint using the official Rust image (more reliable)
FROM rust:1.82-slim AS rust-builder

WORKDIR /work

# Install small set of native deps needed by some crates (openssl etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl-dev pkg-config ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy only entrypoint crate and build
COPY cmd/entrypoint /work/cmd/entrypoint
RUN cd /work/cmd/entrypoint && \
    cargo build --manifest-path Cargo.toml --release

# -----------------------------------------------------------------------------
# Default production runtime (distroless)
# -----------------------------------------------------------------------------
FROM gcr.io/distroless/cc:latest

# Copy Ollama binary, pre-pulled model, and Rust entrypoint
COPY --from=ollama-builder /usr/local/bin/ollama /usr/local/bin/ollama
# Note: models are pulled at container start by the entrypoint. We don't copy
# pre-pulled models into the image to keep the image small and avoid fragile
# build-time server runs. If you prefer pre-pulling, re-add the copy here.
COPY --from=rust-builder /work/cmd/entrypoint/target/release/entrypoint /entrypoint

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/tmp
ENV HOME=/tmp
ENV MODEL_NAME=llama3.2:3b

VOLUME /tmp
EXPOSE 11434

ENTRYPOINT ["/entrypoint"]