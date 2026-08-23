#!/usr/bin/env bash
set -euo pipefail

# Ensure nono state directory exists and is owned by current user
mkdir -p /var/nono
export HOME="/home/dsh"
export DSH_HOME="/home/dsh/.dsh"

# Run nono with state root in /var/nono to allow full /home/dsh workspace access
HOME=/var/nono exec nono run \
  --profile node-dev \
  --allow /workspace/project \
  --allow /home/dsh \
  --read /usr/local \
  --listen-port 8080 \
  --no-rollback-prompt \
  -- \
  env HOME=/home/dsh DSH_HOME=/home/dsh/.dsh node --expose-internals /usr/local/lib/node_modules/@deepseek-ai/dsh/lib/bin.js web "$@"
