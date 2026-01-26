#!/bin/sh
set -e

# Everything must live directly in /tmp. No subdirectories.
# If Kubernetes/Docker sets these, keep them; otherwise default to /tmp.

if [ -z "$HOME" ]; then
  HOME="/tmp"
fi

if [ -z "$OLLAMA_HOME" ]; then
  OLLAMA_HOME="/tmp"
fi

if [ -z "$OLLAMA_MODELS" ]; then
  OLLAMA_MODELS="/tmp"
fi

export HOME
export OLLAMA_HOME
export OLLAMA_MODELS

# Do NOT mkdir anything – /tmp already exists (and is the only allowed location).

echo "Running as user: $(id)"
echo "HOME is set to: $HOME"
echo "OLLAMA_HOME is set to: $OLLAMA_HOME"
echo "OLLAMA_MODELS is set to: $OLLAMA_MODELS"

echo "Contents of /tmp:"
ls -la /tmp || true

exec ollama serve