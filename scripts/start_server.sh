#!/usr/bin/env bash
# ==============================================================================
# start_server.sh — Lancement du serveur FreeToken optimisé (RTX 3070 8GB / 32GB RAM)
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../FreeToken" 2>/dev/null && pwd || pwd)"
cd "$REPO_ROOT"

source "$HOME/Repos/FreeTokenLab/env.sh" || source .venv/bin/activate

MODEL="${1:-ornith-ai/Ornith-1.5-35B-A3B-NVFP4}"
HOST="${2:-127.0.0.1}"
PORT="${3:-1919}"

echo "========================================================"
echo "  🚀 Démarrage du serveur FreeToken"
echo "  Modèle   : $MODEL"
echo "  Endpoint : http://$HOST:$PORT"
echo "  VRAM Opt : MaxPrefill=2048, MemoryRatio=0.85, CacheSlots=800, KV=32768"
echo "========================================================"

ft serve \
  --model "$MODEL" \
  --moe-backend auto \
  --moe-cache-size 800 \
  --num-tokens 32768 \
  --max-prefill-length 2048 \
  --memory-ratio 0.85 \
  --host "$HOST" \
  --port "$PORT"
