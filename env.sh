#!/usr/bin/env bash
# ==============================================================================
# FreeToken & Coding Agents — Environment Configuration
# Source this file: source env.sh
# ==============================================================================

# 1. User binaries (Node.js, npm, dsh, pi, hermes, opencode, uv)
export PATH="$HOME/.local/bin:$PATH"

# 2. Virtual environment (if located in ../FreeToken/.venv or .venv)
if [ -d "$HOME/Repos/FreeToken/.venv/bin" ]; then
    export PATH="$HOME/Repos/FreeToken/.venv/bin:$PATH"
elif [ -d "./.venv/bin" ]; then
    export PATH="$(pwd)/.venv/bin:$PATH"
fi

# 3. Hugging Face Models Cache Directory
if [ -d "/mnt/storage/huggingface" ]; then
    export HF_HOME="/mnt/storage/huggingface"
else
    export HF_HOME="${HF_HOME:-$HOME/.cache/huggingface}"
fi

# 4. PyTorch & CUDA Toolkit Runtime paths (if nvidia cu13/cu12 packages are used)
if [ -d "$HOME/Repos/FreeToken/.venv/lib/python3.12/site-packages/nvidia/cu13" ]; then
    export CUDA_HOME="$HOME/Repos/FreeToken/.venv/lib/python3.12/site-packages/nvidia/cu13"
    export LD_LIBRARY_PATH="$CUDA_HOME/lib:$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
elif [ -n "$CUDA_HOME" ] && [ -d "$CUDA_HOME" ]; then
    export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
fi

# 5. Local Server default endpoints
export FREETOKEN_BASE_URL="http://127.0.0.1:1919/v1"
export OPENAI_BASE_URL="http://127.0.0.1:1919/v1"
export OPENAI_API_KEY="freetoken-local"
export DEEPSEEK_BASE_URL="http://127.0.0.1:1919/v1"
export DEEPSEEK_API_KEY="freetoken-local"

echo "✅ Environnement FreeTokenLab chargé avec succès."
