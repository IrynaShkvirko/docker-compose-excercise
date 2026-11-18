#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

HOST_PORT="${HOST_PORT:-8080}"
IMAGE="${REGISTRY}/docker-excercise/my-static-site:1.0"

require_ssh
ensure_local_registry
login_registry local
docker build --platform linux/amd64 --push -t "$IMAGE" .

prepare_server static-site "$HOST_PORT"
login_registry remote
wait_for_nexus

write_remote_env static-site <<EOF
HOST_PORT=${HOST_PORT}
SERVER_IP=${SERVER_IP}
EOF
deploy_compose static-site

wait_for_http "http://${SERVER_IP}:${HOST_PORT}"
curl -fsSI "http://${SERVER_IP}:${HOST_PORT}" | head -n 15
