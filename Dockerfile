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
ENV OLLAMA_HOME=/data
ENV HOME=/data
ENV MODEL_NAME=llama3.2:3b

RUN curl -fsSL https://ollama.com/install.sh | bash

RUN mkdir -p /data && chmod 777 /data

VOLUME /data
EXPOSE 11434
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
