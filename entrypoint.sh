#!/bin/sh
set -e

# Everything must be in /tmp (no subdirectories).
export HOME=/tmp
export OLLAMA_HOME=/tmp
export OLLAMA_MODELS=/tmp

# Debug: show identity and config
echo "Running as user: $(id)"
echo "HOME is set to: $HOME"
echo "OLLAMA_HOME is set to: $OLLAMA_HOME"
echo "OLLAMA_MODELS is set to: $OLLAMA_MODELS"

echo "Contents of /tmp (before copy):"
ls -la /tmp || true

# In Kubernetes, /tmp may be a runtime mount that hides image contents.
# If models are baked into /baked-models, copy them into /tmp at startup.
if [ -d /baked-models ]; then
  # Only copy if /tmp doesn't already contain any Ollama content
  # (we keep this generic to avoid assumptions about exact file layout)
  if [ -z "$(ls -A /tmp 2>/dev/null || true)" ]; then
    echo "/tmp is empty; copying baked models from /baked-models into /tmp..."
    cp -a /baked-models/. /tmp/
  else
    echo "/tmp is not empty; skipping baked model copy."
  fi
else
  echo "No /baked-models directory found; skipping baked model copy."
fi

echo "Contents of /tmp (after copy):"
ls -la /tmp || true

exec ollama serve