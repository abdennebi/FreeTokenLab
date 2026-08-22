#!/usr/bin/env bash
# ==============================================================================
# test_agents.sh — Validation rapide du fonctionnement des 4 agents
# ==============================================================================
set -euo pipefail

source "$HOME/Repos/FreeTokenLab/env.sh"

echo "========================================================"
echo "  🧪 Test 1: Pi Coding Agent (Non-interactif)"
echo "========================================================"
pi -p "Réponds uniquement par: 'PI OK'"

echo "========================================================"
echo "  🧪 Test 2: DeepSeek Harness (Headless)"
echo "========================================================"
dsh --profile headless "Réponds uniquement par: 'DSH OK'"

echo "========================================================"
echo "  🧪 Test 3: Hermes Agent (One-shot)"
echo "========================================================"
hermes -z "Réponds uniquement par: 'HERMES OK'"

echo "========================================================"
echo "  🧪 Test 4: OpenCode CLI (Dry-Run / Verify)"
echo "========================================================"
ft launch opencode --dry-run

echo "========================================================"
echo "  ✅ Tous les tests ont été exécutés avec succès !"
echo "========================================================"
