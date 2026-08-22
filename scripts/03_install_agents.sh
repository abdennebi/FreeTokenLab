#!/usr/bin/env bash
# ==============================================================================
# 03_install_agents.sh — Installation des 4 Agents de code
# ==============================================================================
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "========================================================"
echo "  1. Installation de OpenCode CLI"
echo "========================================================"
if ! command -v opencode &>/dev/null; then
    curl -fsSL https://opencode.ai/install | bash
else
    echo "✓ OpenCode déjà installé : $(which opencode)"
fi

echo "========================================================"
echo "  2. Installation de Pi Coding Agent"
echo "========================================================"
if ! command -v pi &>/dev/null; then
    npm install -g @earendil-works/pi-coding-agent
else
    echo "✓ Pi déjà installé : $(which pi) ($(pi --version))"
fi

echo "========================================================"
echo "  3. Installation de DeepSeek Harness (dsh)"
echo "========================================================"
if ! command -v dsh &>/dev/null; then
    npm install -g @deepseek-ai/dsh
else
    echo "✓ DeepSeek Harness déjà installé : $(which dsh) ($(dsh --version))"
fi

echo "========================================================"
echo "  4. Installation de Hermes Agent (Nous Research)"
echo "========================================================"
if ! command -v hermes &>/dev/null; then
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup --non-interactive
else
    echo "✓ Hermes Agent déjà installé : $(which hermes)"
fi

echo "✅ Étape 3 terminée : les 4 agents sont installés dans ~/.local/bin/."
