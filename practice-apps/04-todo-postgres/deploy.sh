#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

: "${POSTGRES_USER:?Set POSTGRES_USER in .env}"
: "${POSTGRES_PASSWORD:?Set POSTGRES_PASSWORD in .env}"
: "${POSTGRES_DB:?Set POSTGRES_DB in .env}"
: "${PGADMIN_DEFAULT_EMAIL:?Set PGADMIN_DEFAULT_EMAIL in .env}"
: "${PGADMIN_DEFAULT_PASSWORD:?Set PGADMIN_DEFAULT_PASSWORD in .env}"

REMOTE_PORT="${REMOTE_PORT:-8000}"
IMAGE="${REGISTRY}/docker-excercise/my-todo-api:1.0"

upload_server_compose() {
  # The local file publishes Postgres and pgAdmin for development.
  # The server copy keeps those services on the Compose network and publishes the API only.
  python3 - docker-compose.yaml <<'PY' | ssh_server "cat > ~/todo-postgres/docker-compose.yaml"
import sys
lines = open(sys.argv[1]).read().splitlines(True)
out = []
i = 0
while i < len(lines):
    nxt = lines[i + 1] if i + 1 < len(lines) else ""
    if lines[i].strip() == "ports:" and ("5432:5432" in nxt or "5050:80" in nxt):
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

prepare_server todo-postgres "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env todo-postgres <<EOF
SERVER_IP=${SERVER_IP}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
PGADMIN_DEFAULT_EMAIL=${PGADMIN_DEFAULT_EMAIL}
PGADMIN_DEFAULT_PASSWORD=${PGADMIN_DEFAULT_PASSWORD}
EOF

ssh_server "mkdir -p ~/todo-postgres/db"
upload_server_compose
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  db/init.sql "${SERVER}:~/todo-postgres/db/init.sql"
ssh_server "cd ~/todo-postgres && docker compose pull && docker compose up -d"

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
