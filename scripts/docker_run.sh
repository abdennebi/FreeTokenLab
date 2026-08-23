#!/usr/bin/env bash
set -euo pipefail

MODEL="${1:-ornith-ai/Ornith-1.5-35B-A3B-NVFP4}"
PORT="${2:-1919}"
CONTAINER_NAME="freetoken-server"

echo "========================================================"
echo "  Démarrage de FreeToken (Docker GPU - 64k Context 65536)"
echo "========================================================"
echo "  • Modèle             : $MODEL"
echo "  • Port               : $PORT"
echo "  • Memory Ratio       : 0.92"
echo "  • Max Prefill Length : 1024"
echo "  • MoE Cache Size     : 800 slots"
echo "  • KV Cache Tokens    : 65536 (64k context)"
echo "========================================================"

docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

docker run -d \
  --gpus all \
  --ipc=host \
  --name "$CONTAINER_NAME" \
  -p "${PORT}:1919" \
  -v /mnt/storage/huggingface:/mnt/storage/huggingface \
  -v /mnt/storage/huggingface:/root/.cache/huggingface \
  -e HF_HOME=/mnt/storage/huggingface \
  ghcr.io/abdennebi/freetoken:v0.1.2 \
  --model "$MODEL" \
  --moe-backend auto \
  --moe-cache-size 800 \
  --num-tokens 65536 \
  --max-prefill-length 1024 \
  --memory-ratio 0.92 \
  --host 0.0.0.0 \
  --port 1919

echo "✓ Conteneur $CONTAINER_NAME démarré en arrière-plan."
echo "→ Pour suivre les logs : docker logs -f $CONTAINER_NAME"
