#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
REPO_ROOT=$(git -C "$ROOT" rev-parse --show-toplevel)
HOST=${HOST:-tower}
SKIP_SYNC=${SKIP_SYNC:-0}
REMOTE_BASE=${REMOTE_BASE:-/mnt/cache/appdata/openclaw-tower/repo}
REMOTE_FORK=${REMOTE_FORK:-$REMOTE_BASE/openclaw-fork}
REMOTE_OVERLAY=${REMOTE_OVERLAY:-$REMOTE_BASE/tower-openclaw}
UNRAID_TEMPLATE_TARGET=${UNRAID_TEMPLATE_TARGET:-/boot/config/plugins/dockerMan/templates-user/my-openclaw-tower.xml}
BASE_IMAGE=${BASE_IMAGE:-openclaw-nullifyr-base:latest}
IMAGE=${IMAGE:-openclaw-nullifyr:latest}
OPENCLAW_INSTALL_BROWSER=${OPENCLAW_INSTALL_BROWSER:-1}
OPENCLAW_INSTALL_DOCKER_CLI=${OPENCLAW_INSTALL_DOCKER_CLI:-1}
OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES:-}
OPENCLAW_EXTENSIONS=${OPENCLAW_EXTENSIONS:-}

python3 "$ROOT/scripts/render_unraid_template.py" >/dev/null

if [[ "$SKIP_SYNC" != "1" ]]; then
  "$ROOT/scripts/sync_fork.sh"
fi

# shellcheck disable=SC2029
ssh "$HOST" "mkdir -p '$REMOTE_FORK' '$REMOTE_OVERLAY' /mnt/cache/appdata/openclaw-tower/config /mnt/cache/appdata/openclaw-tower/workspace"

rsync -avz --delete \
  --exclude .git \
  --exclude node_modules \
  --exclude dist \
  --exclude .turbo \
  "$REPO_ROOT/" "$HOST:$REMOTE_FORK/"

rsync -avz --delete \
  --exclude .git \
  "$ROOT/" "$HOST:$REMOTE_OVERLAY/"

# shellcheck disable=SC2029
ssh "$HOST" "mkdir -p '$(dirname "$UNRAID_TEMPLATE_TARGET")' && cp '$REMOTE_OVERLAY/deploy/unraid/openclaw-tower.xml' '$UNRAID_TEMPLATE_TARGET'"

# shellcheck disable=SC2029,SC2087
ssh "$HOST" bash <<EOF
set -euo pipefail
cd "$REMOTE_FORK"
docker build \
  --build-arg OPENCLAW_INSTALL_BROWSER="$OPENCLAW_INSTALL_BROWSER" \
  --build-arg OPENCLAW_INSTALL_DOCKER_CLI="$OPENCLAW_INSTALL_DOCKER_CLI" \
  $(if [[ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]]; then printf '%s' "--build-arg OPENCLAW_DOCKER_APT_PACKAGES=\"$OPENCLAW_DOCKER_APT_PACKAGES\""; fi) \
  $(if [[ -n "$OPENCLAW_EXTENSIONS" ]]; then printf '%s' "--build-arg OPENCLAW_EXTENSIONS=\"$OPENCLAW_EXTENSIONS\""; fi) \
  -t "$BASE_IMAGE" .

cd "$REMOTE_OVERLAY"
docker build --build-arg BASE_IMAGE="$BASE_IMAGE" -t "$IMAGE" .
docker run --rm "$IMAGE" openclaw --help >/dev/null
EOF

"$ROOT/scripts/recreate_tower_container.sh"

echo "TOWER_DEPLOY_OK"
