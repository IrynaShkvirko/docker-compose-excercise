#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

: "${LOG_LEVEL:?Set LOG_LEVEL in .env}"
: "${GREETING:?Set GREETING in .env}"

# 5000, 5001, and 5002 are already used on this server.
REMOTE_PORT="${REMOTE_PORT:-5003}"
IMAGE="${REGISTRY}/docker-excercise/my-dev-vs-prod:1.0"

require_ssh
ensure_local_registry
login_registry local
docker build --platform linux/amd64 --push -t "$IMAGE" .

prepare_server dev-vs-prod "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env dev-vs-prod <<EOF
SERVER_IP=${SERVER_IP}
PORT=${REMOTE_PORT}
LOG_LEVEL=${LOG_LEVEL}
GREETING=${GREETING}
EOF

scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  docker-compose.yaml "${SERVER}:~/dev-vs-prod/docker-compose.yaml"
ssh_server "cd ~/dev-vs-prod && docker compose -f docker-compose.yaml pull && docker compose -f docker-compose.yaml up -d"

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/config"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/config"
echo
