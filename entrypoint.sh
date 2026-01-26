#!/bin/sh
set -e

# Use /tmp directly, avoid creating extra top-level directories
# Everything lives under /tmp/.ollama
export HOME=/tmp
export OLLAMA_HOME=/tmp/.ollama
export OLLAMA_MODELS=/tmp/.ollama/models

# Ensure the directories exist and have correct permissions
mkdir -p "$OLLAMA_HOME" "$OLLAMA_MODELS"

# Debug: Show what user we're running as and verify directories
echo "Running as user: $(id)"
echo "HOME is set to: $HOME"
echo "OLLAMA_HOME is set to: $OLLAMA_HOME"
echo "OLLAMA_MODELS is set to: $OLLAMA_MODELS"
echo "Contents of /tmp:"
ls -la /tmp/ || true
echo "Contents of $OLLAMA_HOME:"
ls -la "$OLLAMA_HOME" || true

exec ollama serve