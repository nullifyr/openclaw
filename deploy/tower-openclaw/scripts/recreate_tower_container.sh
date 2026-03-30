#!/usr/bin/env bash
set -euo pipefail

HOST=${HOST:-tower}
NAME=${NAME:-openclaw-tower}
IMAGE=${IMAGE:-openclaw-nullifyr:latest}
APPDATA_BASE=${APPDATA_BASE:-/mnt/cache/appdata/openclaw-tower}
CONFIG_DIR=${CONFIG_DIR:-$APPDATA_BASE/config}
WORKSPACE_DIR=${WORKSPACE_DIR:-$APPDATA_BASE/workspace}
ENV_FILE=${ENV_FILE:-$APPDATA_BASE/container.env}
BUDTRAK_DATA_DIR=${BUDTRAK_DATA_DIR:-/mnt/cache/data/dispensary-tracker}
BUDTRAK_BUILD_DIR=${BUDTRAK_BUILD_DIR:-/mnt/cache/tmp/budtrak-build}
HOST_PORT=${HOST_PORT:-18790}
CONTAINER_PORT=${CONTAINER_PORT:-18789}
DOCKER_SOCKET=${DOCKER_SOCKET:-/var/run/docker.sock}

# shellcheck disable=SC2087
ssh "$HOST" bash <<EOF
set -euo pipefail
mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "missing env file: $ENV_FILE" >&2
  exit 1
fi

docker rm -f "$NAME" >/dev/null 2>&1 || true

docker run -d \
  --name "$NAME" \
  --hostname "$NAME" \
  --restart unless-stopped \
  --log-opt max-size=50m \
  --log-opt max-file=1 \
  -p "$HOST_PORT:$CONTAINER_PORT" \
  --env-file "$ENV_FILE" \
  -e NODE_ENV=production \
  -e OPENCLAW_CONTAINER_HINT="$NAME" \
  -v "$CONFIG_DIR:/home/node/.openclaw" \
  -v "$WORKSPACE_DIR:/home/node/.openclaw/workspace" \
  -v "$DOCKER_SOCKET:/var/run/docker.sock" \
  -v "$BUDTRAK_DATA_DIR:$BUDTRAK_DATA_DIR" \
  -v "$BUDTRAK_BUILD_DIR:$BUDTRAK_BUILD_DIR" \
  "$IMAGE"

docker ps --filter name="^/$NAME$" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
EOF

echo "TOWER_RECREATE_OK"
