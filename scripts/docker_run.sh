#!/usr/bin/env bash
# ==============================================================================
# docker_run.sh — Lancement direct du conteneur FreeToken GPU avec options optimisées
# ==============================================================================
set -euo pipefail

MODEL="${1:-ornith-ai/Ornith-1.5-35B-A3B-NVFP4}"
PORT="${2:-1919}"
CONTAINER_NAME="freetoken-server"

echo "========================================================"
echo "  Démarrage de FreeToken (Docker GPU - Mode Optimisé)"
echo "========================================================"
echo "  • Modèle             : $MODEL"
echo "  • Port               : $PORT"
echo "  • Memory Ratio       : 0.92"
echo "  • Max Prefill Length : 1024"
echo "  • MoE Cache Size     : 800 slots"
echo "  • KV Cache Tokens    : 65536 (64k context)"
echo "  • ulimits            : memlock=unlimited, stack=64MB"
echo "========================================================"

docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Note sur --ulimit memlock=-1:-1 :
# Indispensable pour l'inférence MoE-offload. Permet à PyTorch et FreeToken
# de verrouiller (pin) les tenseurs d'experts en RAM physique hôte via DMA
# (Direct Memory Access / cudaHostRegister). Évite le fallback en mémoire
# paginée (swap) et débloque 100% de la bande passante du bus PCIe (Gen3/4 x16).

docker run -d \
  --gpus all \
  --ipc=host \
  --ulimit memlock=-1:-1 \
  --ulimit stack=67108864 \
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
