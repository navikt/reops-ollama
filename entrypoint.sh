#!/bin/sh
set -e

# Explicitly set HOME to ensure Ollama uses the correct directory
# Using /tmp which is writable in restricted environments like NAIS
export HOME=/tmp/ollama
export OLLAMA_HOME=/tmp/ollama/.ollama

# Ensure the directories exist and have correct permissions
mkdir -p "$OLLAMA_HOME" /tmp/ollama/models

# Debug: Show what user we're running as and verify directories
echo "Running as user: $(id)"
echo "HOME is set to: $HOME"
echo "OLLAMA_HOME is set to: $OLLAMA_HOME"
echo "Contents of /tmp/ollama:"
ls -la /tmp/ollama/ || true

exec ollama serve
