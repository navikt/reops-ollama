# ────────────────────────────────────────────────────────────────────────
#  CPU‑only Ollama image that writes everything into /tmp
# ────────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04

# --------------------------------------------------------------------
# 1️⃣  Install minimal dependencies
# --------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------
# 2️⃣  Environment – run as root, listen on port 1880
# --------------------------------------------------------------------
ENV OLLAMA_ALLOW_ROOT=true
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=1880

# --------------------------------------------------------------------
# 3️⃣  Tell Ollama to use /tmp as its home directory
# --------------------------------------------------------------------
#    * The models will be stored in /tmp/.ollama
#    * The server will keep all temporary files here as well
ENV OLLAMA_HOME=/tmp/.ollama

# --------------------------------------------------------------------
# 4️⃣  Install the Ollama binary
# --------------------------------------------------------------------
RUN curl -fsSL https://ollama.com/install.sh | bash

# --------------------------------------------------------------------
# 5️⃣  Create the directory & pull a small model during build
# --------------------------------------------------------------------
#    * Pick one from https://ollama.com/library
#    * Replace MODEL_NAME if you want something else
ENV MODEL_NAME=llama2:7b
RUN mkdir -p ${OLLAMA_HOME} && \
    # cache the pull so that the image build is faster on rebuilds
    --mount=type=cache,target=${OLLAMA_HOME} \
    ollama pull ${MODEL_NAME}

# --------------------------------------------------------------------
# 6️⃣  Persist the /tmp/.ollama directory as a volume
# --------------------------------------------------------------------
#    * This volume will be the only writable location in the container
VOLUME /tmp/.ollama

# --------------------------------------------------------------------
# 7️⃣  Expose the chosen port
# --------------------------------------------------------------------
EXPOSE 1880

# --------------------------------------------------------------------
# 8️⃣  Start the server
# --------------------------------------------------------------------
CMD ["ollama", "serve"]
