# tower-openclaw

Durable Tower/Unraid deployment tooling for a custom OpenClaw build.

Canonical home: **inside the fork repo** at `deploy/tower-openclaw/`.
Do not maintain a second standalone repo for this. The OpenClaw fork is the repo.

This deploy kit separates four concerns that were previously getting mixed together:

1. **fork sync** — fast-forward the local fork checkout from upstream and push it to our GitHub fork
2. **image build** — build a Tower-targeted OpenClaw image from the current fork checkout using upstream-supported Docker build args
3. **runtime overlay** — add only the small Tower-specific startup behavior we actually need (currently: custom workspace skill linking + stable container hint)
4. **container deployment** — recreate the Unraid/Tower container from host-mounted config, workspace, env file, and deterministic mounts

## Layout

- `Dockerfile` — tiny overlay image built on top of the fork-built base image
- `scripts/tower-openclaw-entrypoint.sh` — startup wrapper for durable Tower-specific behavior
- `scripts/sync_fork.sh` — fast-forward local fork from upstream and push to GitHub fork
- `scripts/deploy_tower.sh` — rsync fork + overlay to Tower, build images, smoke test, recreate container
- `scripts/recreate_tower_container.sh` — canonical Docker run/recreate path for Tower
- `scripts/render_unraid_template.py` — generate the Unraid XML template
- `deploy/unraid/openclaw-tower.xml` — generated template artifact
- `container.env.example` — example runtime env file shape

## Defaults

- Local fork repo: `projects/openclaw-fork`
- Tower remote repo base: `/mnt/cache/appdata/openclaw-tower/repo`
- Base image: `openclaw-nullifyr-base:latest`
- Final image: `openclaw-nullifyr:latest`
- Container name: `openclaw-tower`
- Host port: `18790` → container `18789`

## Why the overlay exists

The upstream image is already close to what we want. The overlay stays intentionally tiny.

Current durable additions:
- link custom workspace skills from `/home/node/.openclaw/workspace/skills/*` into `/app/skills/*` on container start
- set a stable `OPENCLAW_CONTAINER_HINT`
- preserve the upstream runtime/CMD path instead of replacing it with one-off shell edits in a running container

## Quick start

From the fork repo root:

```bash
cd projects/openclaw-fork/deploy/tower-openclaw
just fork-sync
just render-template
just tower-deploy
```

Single-command updater from upstream all the way to Tower recreate:

```bash
cd projects/openclaw-fork/deploy/tower-openclaw
just update-and-deploy
```

If the fork is already synced and you only changed overlay/deploy tooling:

```bash
just tower-deploy-no-sync
```

## Runtime env

Actual secrets should live on Tower in:

- `/mnt/cache/appdata/openclaw-tower/container.env`

Use `container.env.example` only as a shape reference.

## Notes

- The Unraid XML and the recreate script should stay in agreement.
- Host-mounted config/workspace/env win over container-FS edits.
- Browser support is baked into the built image via `OPENCLAW_INSTALL_BROWSER=1`.
- Docker CLI is baked into the built image via `OPENCLAW_INSTALL_DOCKER_CLI=1`.
