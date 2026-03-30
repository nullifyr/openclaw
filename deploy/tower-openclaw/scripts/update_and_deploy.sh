#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BRANCH=${BRANCH:-main}
PUSH_ORIGIN=${PUSH_ORIGIN:-1}

BRANCH="$BRANCH" PUSH_ORIGIN="$PUSH_ORIGIN" "$ROOT/scripts/sync_fork.sh"
SKIP_SYNC=1 "$ROOT/scripts/deploy_tower.sh"

echo "TOWER_UPDATE_AND_DEPLOY_OK"
