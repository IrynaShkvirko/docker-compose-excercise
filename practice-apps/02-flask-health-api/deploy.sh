#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

: "${APP_NAME:?Set APP_NAME in .env}"
REMOTE_PORT="${REMOTE_PORT:-5000}"
REMOTE_APP_ENV="${REMOTE_APP_ENV:-production}"
IMAGE="${REGISTRY}/docker-excercise/my-flask-health-api:1.0"

require_ssh
ensure_local_registry
login_registry local
docker build --platform linux/amd64 --push -t "$IMAGE" .

prepare_server flask-health "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env flask-health <<EOF
PORT=${REMOTE_PORT}
APP_NAME=${APP_NAME}
APP_ENV=${REMOTE_APP_ENV}
SERVER_IP=${SERVER_IP}
EOF
deploy_compose flask-health

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
