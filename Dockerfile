# ---------------------------------
#  CPU‑only Ollama image (Alpine-based)
# ---------------------------------

FROM alpine:latest

USER root

RUN apk add --no-cache \
        ca-certificates \
        curl \
        bash \
        libstdc++ \
        libc6-compat

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/tmp
ENV HOME=/tmp
ENV MODEL_NAME=llama3.2:3b

# Download pre-built Ollama binary for Linux
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) ARCH="amd64" ;; \
        aarch64|arm64) ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    OLLAMA_VERSION=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -fsSL "https://github.com/ollama/ollama/releases/download/${OLLAMA_VERSION}/ollama-linux-${ARCH}.tgz" | tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/ollama

RUN mkdir -p /tmp && chmod 777 /tmp

VOLUME /tmp
EXPOSE 11434
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]