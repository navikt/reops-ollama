#!/bin/sh
set -e

# Explicitly set HOME to ensure Ollama uses the correct directory
# This handles cases where NAIS might override HOME
export HOME=/home/ollama
export OLLAMA_HOME=/home/ollama/.ollama

# Ensure the directory exists and has correct permissions
mkdir -p "$OLLAMA_HOME"

# Debug: Show what user we're running as and verify directories
echo "Running as user: $(id)"
echo "HOME is set to: $HOME"
echo "OLLAMA_HOME is set to: $OLLAMA_HOME"
echo "Contents of /home/ollama:"
ls -la /home/ollama/ || true

exec ollama serve
