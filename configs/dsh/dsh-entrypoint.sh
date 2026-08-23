#!/usr/bin/env bash
set -euo pipefail

mkdir -p /var/nono
export HOME="/home/dsh"
export DSH_HOME="/home/dsh/.dsh"
export DEEPSEEK_BASE_URL="http://127.0.0.1:1919/v1"
export DEEPSEEK_API_KEY="dummy-key"
export FREETOKEN_API_KEY="dummy-key"
export OPENAI_API_BASE="http://127.0.0.1:1919/v1"
export OPENAI_API_KEY="dummy-key"

# Landlock LSM kernel sandboxing without HTTP MITM proxy interference
HOME=/var/nono exec nono run \
  --allow /workspace/project \
  --allow /home/dsh \
  --read /usr/local \
  --no-rollback-prompt \
  -- \
  env HOME=/home/dsh DSH_HOME=/home/dsh/.dsh \
      DEEPSEEK_BASE_URL=http://127.0.0.1:1919/v1 \
      DEEPSEEK_API_KEY=dummy-key \
      FREETOKEN_API_KEY=dummy-key \
      OPENAI_API_BASE=http://127.0.0.1:1919/v1 \
      OPENAI_API_KEY=dummy-key \
      node --expose-internals /usr/local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js web "$@"
