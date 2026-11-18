#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

: "${MONGO_USER:?Set MONGO_USER in .env}"
: "${MONGO_PASSWORD:?Set MONGO_PASSWORD in .env}"
: "${MONGO_DB:?Set MONGO_DB in .env}"
: "${ME_USER:?Set ME_USER in .env}"
: "${ME_PASSWORD:?Set ME_PASSWORD in .env}"

# The static site already uses 8080 on this server.
REMOTE_PORT="${REMOTE_PORT:-8082}"
IMAGE="${REGISTRY}/docker-excercise/my-notes-api:1.0"

upload_server_compose() {
  python3 - docker-compose.yaml <<'PY' | ssh_server "cat > ~/notes/docker-compose.yaml"
import sys
lines = open(sys.argv[1]).read().splitlines(True)
out = []
i = 0
while i < len(lines):
    nxt = lines[i + 1] if i + 1 < len(lines) else ""
    if lines[i].strip() == "ports:" and ("27017:27017" in nxt or "8081:8081" in nxt):
        i += 2
        continue
    out.append(lines[i])
    i += 1
sys.stdout.write("".join(out))
PY
}

require_ssh
ensure_local_registry
login_registry local
docker build --platform linux/amd64 --push -t "$IMAGE" .

prepare_server notes "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env notes <<EOF
SERVER_IP=${SERVER_IP}
PORT=${REMOTE_PORT}
MONGO_USER=${MONGO_USER}
MONGO_PASSWORD=${MONGO_PASSWORD}
MONGO_DB=${MONGO_DB}
ME_USER=${ME_USER}
ME_PASSWORD=${ME_PASSWORD}
EOF

upload_server_compose
ssh_server "cd ~/notes && docker compose pull && docker compose up -d"

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
