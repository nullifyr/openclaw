#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
REPO_ROOT=$(git -C "$ROOT" rev-parse --show-toplevel)
UPSTREAM_REMOTE=${UPSTREAM_REMOTE:-upstream}
ORIGIN_REMOTE=${ORIGIN_REMOTE:-origin}
BRANCH=${BRANCH:-main}
PUSH_ORIGIN=${PUSH_ORIGIN:-1}

cd "$REPO_ROOT"

git fetch "$UPSTREAM_REMOTE" --tags
current_branch=$(git branch --show-current)
if [[ "$current_branch" != "$BRANCH" ]]; then
  git checkout "$BRANCH"
fi

git pull --ff-only "$UPSTREAM_REMOTE" "$BRANCH"

local_head=$(git rev-parse HEAD)
if [[ "$PUSH_ORIGIN" == "1" ]]; then
  remote_head=$(git ls-remote "$ORIGIN_REMOTE" "refs/heads/$BRANCH" | awk '{print $1}')
  if [[ "$local_head" != "$remote_head" ]]; then
    GIT_TERMINAL_PROMPT=0 git push "$ORIGIN_REMOTE" "$BRANCH" --follow-tags
  fi
fi

echo "FORK_SYNC_OK $REPO_ROOT $BRANCH $local_head"
