#!/usr/bin/env bash
set -euo pipefail

HOST=${HOST:-tower}
NAME=${NAME:-openclaw-tower}
JOB_ID=${JOB_ID:-e267984b-b705-4f1f-8958-8bacf4aabc95}
UNRAID_TEMPLATE_TARGET=${UNRAID_TEMPLATE_TARGET:-/boot/config/plugins/dockerMan/templates-user/my-openclaw-tower.xml}
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-180}

start_ts=$(date +%s)
while true; do
  # shellcheck disable=SC2029
  status=$(ssh "$HOST" "docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}} {{.State.Status}}' '$NAME' 2>/dev/null" || true)
  case "$status" in
    "healthy running"|"starting running"|"no-healthcheck running")
      break
      ;;
    "unhealthy running")
      echo "SMOKE_CHECK_FAIL unhealthy container: $status" >&2
      exit 1
      ;;
  esac
  now_ts=$(date +%s)
  if (( now_ts - start_ts >= TIMEOUT_SECONDS )); then
    echo "SMOKE_CHECK_FAIL timeout waiting for container: ${status:-unknown}" >&2
    exit 1
  fi
  sleep 5
done

# shellcheck disable=SC2029
# shellcheck disable=SC2029
ssh "$HOST" "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | grep '^${NAME}[[:space:]]'"
# shellcheck disable=SC2029
ssh "$HOST" "test -r '$UNRAID_TEMPLATE_TARGET' && echo template-ok"
# shellcheck disable=SC2029
ssh "$HOST" "docker exec -u node '$NAME' sh -lc 'openclaw cron list | sed -n \"1,20p\"'"
# shellcheck disable=SC2029
ssh "$HOST" "docker exec -u node '$NAME' sh -lc 'test -r /app/skills/budtrak-review/SKILL.md && echo skill-ok; command -v docker >/dev/null && docker --version | sed -n \"1p\"'"
if [[ -n "$JOB_ID" ]]; then
  # shellcheck disable=SC2029
  ssh "$HOST" "docker exec -u node '$NAME' sh -lc 'openclaw cron runs --id \"$JOB_ID\" | tail -n 20'"
fi

echo "SMOKE_CHECK_OK"
