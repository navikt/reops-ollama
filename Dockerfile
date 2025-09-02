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
ENV OLLAMA_HOME=/tmp/.ollama
ENV MODEL_NAME=llama2:7b

RUN curl -fsSL https://ollama.com/install.sh | bash

RUN mkdir -p ${OLLAMA_HOME} && \
    ollama pull ${MODEL_NAME}

VOLUME /tmp/.ollama

EXPOSE 11434
CMD ["ollama", "serve"]
