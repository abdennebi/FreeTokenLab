#!/usr/bin/env bash
# ==============================================================================
# dsh_secure.sh — Lancement de DeepSeek Harness sous confinement noyau nono (Landlock)
# ==============================================================================
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
if ! command -v nono &>/dev/null; then
    echo "→ nono n'est pas encore installé. Installation automatique..."
    curl -fsSL https://nono.sh/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

export DEEPSEEK_BASE_URL="http://127.0.0.1:1919/v1"
export DEEPSEEK_API_KEY="dummy-key"
export FREETOKEN_API_KEY="dummy-key"
export OPENAI_API_BASE="http://127.0.0.1:1919/v1"
export OPENAI_API_KEY="dummy-key"

MODE="${1:-web}"
if [ $# -gt 0 ]; then
    shift
fi

echo "========================================================"
echo "  🔒 DeepSeek Harness (Confinement Noyau nono / Landlock)"
echo "========================================================"
echo "  • Espace de travail autorisé : $(pwd) (r+w)"
echo "  • Configuration autorisée   : $HOME/.dsh (r+w)"
echo "  • Moteur LLM FreeToken       : http://127.0.0.1:1919/v1"
echo "  • Accès système sensible    : INTERDIT (~/.ssh, ~/.aws, /etc)"
echo "  • Mode d'exécution          : dsh $MODE"
echo "========================================================"

exec nono run \
  --allow . \
  --allow "$HOME/.dsh" \
  --read "$HOME/.local/bin" \
  --read "$HOME/.local/lib" \
  --no-rollback-prompt \
  -- \
  dsh "$MODE" "$@"
