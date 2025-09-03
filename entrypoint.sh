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

# Pull the model
ollama pull "$MODEL_NAME"

# Stop background server
kill $OLLAMA_PID
wait $OLLAMA_PID 2>/dev/null || true

# Start Ollama server in the foreground
exec ollama serve