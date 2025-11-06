#!/bin/bash
set -e

# Models are already pre-pulled in the Docker image during build at /root/.ollama/models
# OLLAMA_HOME is set to /tmp/.ollama for runtime data (logs, state, etc.)
# Create the tmp directory (needed because /tmp is mounted as emptyDir in nais.yaml)
mkdir -p /tmp/.ollama

# Start Ollama server
exec ollama serve