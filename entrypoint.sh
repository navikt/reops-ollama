#!/bin/bash
set -e

# Pull the model if not already present
ollama pull "$MODEL_NAME"

# Start the Ollama server
exec ollama serve
