#!/bin/bash
set -e


# Ensure OLLAMA_HOME is set and directory exists
export OLLAMA_HOME="/tmp"
export HOME="/tmp"
mkdir -p "$OLLAMA_HOME"
mkdir -p "$HOME/.ollama"
# Try to set permissions, ignore error if not permitted
chmod 777 "$OLLAMA_HOME" 2>/dev/null || echo "Warning: Could not change permissions for $OLLAMA_HOME"


# Start Ollama server in the background
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama server to be ready
until curl -fsS http://localhost:11434/api/tags > /dev/null; do
	echo "Waiting for Ollama server to start..."
	sleep 2
done

# Pull the models
MODELS=("smollm2:1.7b" "tinyllama:1.1b" "smollm2:360m" "starcoder:1b" "deepcoder:1.5b" "deepseek-coder:1.3b" "qwen2.5-coder:1.5b")
for model in "${MODELS[@]}"; do
    ollama pull "$model"
done

# Stop background server
kill $OLLAMA_PID
wait $OLLAMA_PID 2>/dev/null || true

# Start Ollama server in the foreground
exec ollama serve