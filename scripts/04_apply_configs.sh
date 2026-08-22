#!/usr/bin/env bash
# ==============================================================================
# 04_apply_configs.sh — Déploiement des configurations calibrées
# ==============================================================================
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================================"
echo "  Déploiement des configurations des Agents"
echo "========================================================"

# 1. OpenCode
mkdir -p "$HOME/.config/opencode"
cp "$LAB_DIR/configs/opencode/config.json" "$HOME/.config/opencode/config.json"
echo "✓ OpenCode config déployée -> ~/.config/opencode/config.json"

# 2. Pi Coding Agent
mkdir -p "$HOME/.pi/agent"
cp "$LAB_DIR/configs/pi/models.json" "$HOME/.pi/agent/models.json"
cp "$LAB_DIR/configs/pi/settings.json" "$HOME/.pi/agent/settings.json"
echo "✓ Pi config déployée -> ~/.pi/agent/models.json & settings.json"

# 3. DeepSeek Harness
mkdir -p "$HOME/.dsh"
cp "$LAB_DIR/configs/dsh/settings.yaml" "$HOME/.dsh/settings.yaml"
cp "$LAB_DIR/configs/dsh/.credentials.yaml" "$HOME/.dsh/.credentials.yaml"
chmod 600 "$HOME/.dsh/.credentials.yaml"
echo "✓ DeepSeek Harness config déployée -> ~/.dsh/settings.yaml & .credentials.yaml"

# 4. Hermes Agent
mkdir -p "$HOME/.hermes"
cp "$LAB_DIR/configs/hermes/config.yaml" "$HOME/.hermes/config.yaml"
echo "✓ Hermes Agent config déployée -> ~/.hermes/config.yaml"

echo "✅ Toutes les configurations ont été appliquées avec succès."
