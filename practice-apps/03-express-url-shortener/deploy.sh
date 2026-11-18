#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

REMOTE_PORT="${REMOTE_PORT:-3000}"
REMOTE_NODE_ENV="${REMOTE_NODE_ENV:-production}"
IMAGE="${REGISTRY}/docker-excercise/my-url-shortener:1.0"
BASE_URL="http://${SERVER_IP}:${REMOTE_PORT}"

require_ssh
ensure_local_registry
login_registry local
docker build --platform linux/amd64 --build-arg NODE_VERSION=20 --push -t "$IMAGE" .

prepare_server url-shortener "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env url-shortener <<EOF
PORT=${REMOTE_PORT}
BASE_URL=${BASE_URL}
NODE_ENV=${REMOTE_NODE_ENV}
SERVER_IP=${SERVER_IP}
EOF
deploy_compose url-shortener

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
