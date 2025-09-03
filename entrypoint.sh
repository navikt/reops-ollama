#!/bin/sh
set -e

echo "Starting entrypoint script"

# Ensure OLLAMA_HOME is set and directory exists
export OLLAMA_HOME="/data"
export HOME="/data"
mkdir -p "$OLLAMA_HOME"
mkdir -p "$HOME/.ollama"
# Try to set permissions, ignore error if not permitted
chmod 777 "$OLLAMA_HOME" 2>/dev/null || echo "Warning: Could not change permissions for $OLLAMA_HOME"

echo "Directories created, starting Ollama server in background"

# Start Ollama server in the background
ollama serve &
OLLAMA_PID=$!

echo "Ollama server started with PID $OLLAMA_PID"

# Wait for Ollama server to be ready
until wget -q -O /dev/null http://localhost:11434/api/tags; do
	echo "Waiting for Ollama server to start..."
	sleep 2
done

echo "Ollama server is ready, pulling model $MODEL_NAME"

# Pull the model
ollama pull "$MODEL_NAME"

echo "Model pulled successfully, stopping background server"

# Stop background server
kill $OLLAMA_PID
wait $OLLAMA_PID 2>/dev/null || true

echo "Starting Ollama server in foreground"

# Start Ollama server in the foreground
exec ollama serve
