#!/usr/bin/env bash
# ==============================================================================
# 01_setup_host.sh — Installation des dépendances système, Node.js et Python
# ==============================================================================
set -euo pipefail

echo "========================================================"
echo "  1. Vérification des dépendances système de base"
echo "========================================================"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if command -v apt-get &>/dev/null; then
    echo "→ Installation des paquets système recommandés (build-essential, git, curl, xz)..."
    sudo apt-get update -y || true
    sudo apt-get install -y build-essential git curl wget xz-utils libopenblas-dev || true
fi

echo "========================================================"
echo "  2. Installation de Node.js LTS (v22.23.2+)"
echo "========================================================"
NODE_VERSION="v22.23.2"
if ! command -v node &>/dev/null || [[ "$(node -v)" < "v22.19.0" ]]; then
    echo "→ Téléchargement et extraction de Node.js $NODE_VERSION dans ~/.local/..."
    TMP_NODE_DIR=$(mktemp -d)
    curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" -o "${TMP_NODE_DIR}/node.tar.xz"
    tar -xJf "${TMP_NODE_DIR}/node.tar.xz" -C "${TMP_NODE_DIR}/"
    cp -rf "${TMP_NODE_DIR}/node-${NODE_VERSION}-linux-x64/"* "$HOME/.local/"
    rm -rf "${TMP_NODE_DIR}"
    echo "✓ Node.js $(node -v) et npm $(npm -v) installés avec succès."
else
    echo "✓ Node.js $(node -v) déjà présent et compatible."
fi

echo "========================================================"
echo "  3. Installation de uv (Gestionnaire d'environnement Python ultra-rapide)"
echo "========================================================"
if ! command -v uv &>/dev/null; then
    echo "→ Installation de uv..."
    curl -fsSL https://astral.sh/uv/install.sh | bash
    export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
fi
echo "✓ uv $(uv --version) prêt."

echo "========================================================"
echo "  4. Création de l'environnement virtuel Python 3.12"
echo "========================================================"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../FreeToken" 2>/dev/null && pwd || pwd)"
cd "$REPO_ROOT"

if [ ! -d ".venv" ]; then
    echo "→ Création du venv Python 3.12..."
    uv venv --python 3.12 .venv
fi

source .venv/bin/activate
echo "✓ venv activé : $(python --version)"

echo "========================================================"
echo "  5. Installation de PyTorch CUDA et dépendances"
echo "========================================================"
echo "→ Installation de PyTorch et des kernels Triton/SGLang..."
uv pip install --upgrade pip setuptools wheel ninja cmake
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 || \
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

uv pip install "sglang-kernel>=0.4.5" || true
uv pip install transformers accelerate safetensors huggingface_hub fastapi uvicorn pydantic requests rich fire

echo "✅ Étape 1 terminée avec succès."
