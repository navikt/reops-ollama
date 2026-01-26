#!/bin/sh
set -e

# Everything must be in /tmp (no subdirectories like /tmp/ollama).
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

# In Kubernetes, /tmp is commonly a runtime mount that hides image contents.
# Models are baked into /baked-models; copy them into /tmp if models are missing.
if [ -d /baked-models ]; then
  # Copy only if we don't already have the expected Ollama model layout in /tmp.
  if [ ! -d /tmp/manifests ] || [ ! -d /tmp/blobs ] || \
     [ -z "$(ls -A /tmp/manifests 2>/dev/null || true)" ] || \
     [ -z "$(ls -A /tmp/blobs 2>/dev/null || true)" ]; then
    echo "Models missing in /tmp; copying baked models from /baked-models into /tmp..."

    # IMPORTANT: Do NOT use `cp -a` in K8s (cannot preserve ownership/perms/times as non-root).
    # Plain recursive copy will copy content and use the runtime user's ownership.
    cp -R /baked-models/. /tmp/

    # Ensure readability/executability on directories/files we just copied (best-effort).
    chmod -R a+rX /tmp/manifests /tmp/blobs 2>/dev/null || true
  else
    echo "Models already present in /tmp; skipping baked model copy."
  fi
else
  echo "No /baked-models directory found; skipping baked model copy."
fi

echo "Contents of /tmp (after copy):"
ls -la /tmp || true

# Show top-level model dirs explicitly (helps confirm Ollama will see them)
echo "Contents of /tmp/manifests:"
ls -la /tmp/manifests 2>/dev/null || true

echo "Contents of /tmp/blobs:"
ls -la /tmp/blobs 2>/dev/null || true

exec ollama serve