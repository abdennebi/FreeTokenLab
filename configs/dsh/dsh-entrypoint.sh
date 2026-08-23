#!/usr/bin/env bash
set -euo pipefail

# Ensure nono state directory exists
mkdir -p /var/nono
export HOME="/home/dsh"
export DSH_HOME="/home/dsh/.dsh"
export DEEPSEEK_BASE_URL="http://127.0.0.1:1919/v1"
export DEEPSEEK_API_KEY="dummy-key"
export FREETOKEN_API_KEY="dummy-key"
export OPENAI_API_BASE="http://127.0.0.1:1919/v1"
export OPENAI_API_KEY="dummy-key"

# Ensure persistent .dsh directory is initialized with settings and credentials
mkdir -p /home/dsh/.dsh
if [ ! -f /home/dsh/.dsh/settings.yaml ] && [ -f /etc/dsh/settings.yaml ]; then
    cp /etc/dsh/settings.yaml /home/dsh/.dsh/settings.yaml
fi
if [ ! -f /home/dsh/.dsh/.credentials.yaml ] && [ -f /etc/dsh/.credentials.yaml ]; then
    cp /etc/dsh/.credentials.yaml /home/dsh/.dsh/.credentials.yaml
    chmod 600 /home/dsh/.dsh/.credentials.yaml
fi

# Run nono with Landlock kernel sandboxing and full workspace/home access
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
