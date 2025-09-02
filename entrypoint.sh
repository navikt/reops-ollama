#!/bin/bash
set -e

# Start Ollama server in the background
ollama serve &
OLLAMA_PID=$!

# Wait for server to be ready
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
