#!/usr/bin/env bash
# ==============================================================================
# docker_run.sh — Lancement du container FreeToken avec support NVIDIA GPU
# ==============================================================================
set -euo pipefail

MODEL="${1:-ornith-ai/Ornith-1.5-35B-A3B-NVFP4}"
PORT="${2:-1919}"

echo "========================================================"
echo "  🐳 Démarrage de FreeToken dans Docker (GPU NVIDIA)"
echo "  Modèle   : $MODEL"
echo "  Port     : $PORT"
echo "  Stockage : /mnt/storage/huggingface monté"
echo "========================================================"

docker run --rm -it \
  --gpus all \
  --ipc=host \
  --name freetoken-server \
  -p "${PORT}:1919" \
  -v /mnt/storage/huggingface:/mnt/storage/huggingface \
  -v /mnt/storage/huggingface:/root/.cache/huggingface \
  -e HF_HOME=/mnt/storage/huggingface \
  freetoken:latest \
  --model "$MODEL" \
  --moe-backend auto \
  --moe-cache-size 800 \
  --num-tokens 32768 \
  --max-prefill-length 2048 \
  --memory-ratio 0.85 \
  --host 0.0.0.0 \
  --port 1919
