#!/usr/bin/env bash
# ==============================================================================
# 02_build_freetoken.sh — Compilation des extensions C++ et calibration matérielle
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../FreeToken" 2>/dev/null && pwd || pwd)"
cd "$REPO_ROOT"

source "$HOME/Repos/FreeTokenLab/env.sh" || source .venv/bin/activate

echo "========================================================"
echo "  1. Compilation des noyaux natifs C++ FreeToken"
echo "========================================================"
echo "→ Compilation de freetoken.kernel._pinned_tensor et _cpu_moe..."
pip install -e . --no-build-isolation

echo "========================================================"
echo "  2. Benchmark matériel (STREAM + PCIe + CPU-MoE)"
echo "========================================================"
echo "→ Calibrage du profil hybride CPU/GPU..."
ft bench hybrid || echo "Note: lancez 'ft bench hybrid' une fois le serveur au repos."

echo "✅ Étape 2 terminée avec succès : FreeToken est compilé et prêt."
