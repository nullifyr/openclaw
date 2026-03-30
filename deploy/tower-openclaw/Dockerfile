ARG BASE_IMAGE=openclaw-nullifyr-base:latest
FROM ${BASE_IMAGE}

USER root
COPY --chown=node:node scripts/tower-openclaw-entrypoint.sh /usr/local/bin/tower-openclaw-entrypoint.sh
RUN chmod 755 /usr/local/bin/tower-openclaw-entrypoint.sh

ENV OPENCLAW_CONTAINER_HINT=openclaw-tower \
    PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright

USER node
ENTRYPOINT ["/usr/local/bin/tower-openclaw-entrypoint.sh"]
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
