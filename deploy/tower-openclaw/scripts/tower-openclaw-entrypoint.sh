#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_SKILLS_DIR=${WORKSPACE_SKILLS_DIR:-/home/node/.openclaw/workspace/skills}
BUNDLED_SKILLS_DIR=${BUNDLED_SKILLS_DIR:-/app/skills}

mkdir -p /home/node/.openclaw/workspace/tmp

if [[ -d "$WORKSPACE_SKILLS_DIR" && -d "$BUNDLED_SKILLS_DIR" && -w "$BUNDLED_SKILLS_DIR" ]]; then
  shopt -s nullglob
  for skill_dir in "$WORKSPACE_SKILLS_DIR"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_name=$(basename "$skill_dir")
    target="$BUNDLED_SKILLS_DIR/$skill_name"
    rm -rf "$target"
    ln -s "$skill_dir" "$target"
  done
fi

export OPENCLAW_CONTAINER_HINT=${OPENCLAW_CONTAINER_HINT:-openclaw-tower}
exec docker-entrypoint.sh "$@"
