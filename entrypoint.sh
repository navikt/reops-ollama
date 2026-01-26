#!/bin/sh
set -e

# If these are already set (for example from Dockerfile or Kubernetes),
# we keep them. Otherwise we assign our defaults.

if [ -z "$HOME" ]; then
  HOME="/tmp/ollama"
fi

if [ -z "$OLLAMA_HOME" ]; then
  OLLAMA_HOME="/tmp/ollama/.ollama"
fi

if [ -z "$OLLAMA_MODELS" ]; then
  OLLAMA_MODELS="/tmp/ollama/models"
fi

export HOME
export OLLAMA_HOME
export OLLAMA_MODELS

# Ensure the directories exist
mkdir -p "$OLLAMA_HOME" "$OLLAMA_MODELS"

# Debug output to verify paths and contents
echo "Running as user: $(id)"
echo "HOME is set to: $HOME"
echo "OLLAMA_HOME is set to: $OLLAMA_HOME"
echo "OLLAMA_MODELS is set to: $OLLAMA_MODELS"

echo "Contents of /tmp:"
ls -la /tmp/ || true

echo "Contents of $OLLAMA_HOME:"
ls -la "$OLLAMA_HOME" || true

echo "Contents of $OLLAMA_MODELS:"
ls -la "$OLLAMA_MODELS" || true

# Start Ollama
exec ollama serve