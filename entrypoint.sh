#!/bin/bash
set -e

# Models are already pre-pulled in the Docker image during build
# Just start Ollama server directly
exec ollama serve