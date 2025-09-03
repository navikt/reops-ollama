# ---------------------------------
#  CPU‑only Ollama image (distroless)
# ---------------------------------

FROM ubuntu:22.04 AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://ollama.com/install.sh | bash

FROM gcr.io/distroless/base:debug

ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434
ENV OLLAMA_HOME=/data
ENV HOME=/data
ENV MODEL_NAME=llama3.2:3b

COPY --from=builder /usr/local/bin/ollama /usr/local/bin/ollama
COPY --from=builder /usr/local/lib/ollama /usr/local/lib/ollama
COPY entrypoint.sh /entrypoint.sh

VOLUME /data
EXPOSE 11434
ENTRYPOINT ["/entrypoint.sh"]
