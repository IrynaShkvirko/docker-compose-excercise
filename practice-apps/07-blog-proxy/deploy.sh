#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

REMOTE_PORT="${REMOTE_PORT:-80}"
IMAGE="${REGISTRY}/docker-excercise/my-blog-backend:1.0"

require_ssh
ensure_local_registry
login_registry local
docker build --platform linux/amd64 --push -t "$IMAGE" .

prepare_server blog "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env blog <<EOF
SERVER_IP=${SERVER_IP}
PORT=${REMOTE_PORT}
EOF

ssh_server "mkdir -p ~/blog/nginx ~/blog/frontend"
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  docker-compose.yaml "${SERVER}:~/blog/docker-compose.yaml"
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  nginx/default.conf.template "${SERVER}:~/blog/nginx/default.conf.template"
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  frontend/index.html frontend/style.css frontend/app.js "${SERVER}:~/blog/frontend/"
ssh_server "cd ~/blog && docker compose pull && docker compose up -d"

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/api/health"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/api/health"
echo
