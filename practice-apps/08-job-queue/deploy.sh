#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

: "${REDIS_HOST:?Set REDIS_HOST in .env}"

# Flask health uses 5000 and the Redis counter uses 5001 on this server.
REMOTE_PORT="${REMOTE_PORT:-5002}"
IMAGE="${REGISTRY}/docker-excercise/my-job-queue:1.0"

upload_server_compose() {
  python3 - docker-compose.yaml <<'PY' | ssh_server "cat > ~/job-queue/docker-compose.yaml"
import sys
lines = open(sys.argv[1]).read().splitlines(True)
out = []
i = 0
while i < len(lines):
    nxt = lines[i + 1] if i + 1 < len(lines) else ""
    if lines[i].strip() == "ports:" and (":6379\"" in nxt or "9181:9181" in nxt):
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

prepare_server job-queue "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env job-queue <<EOF
SERVER_IP=${SERVER_IP}
PORT=${REMOTE_PORT}
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=6379
EOF

upload_server_compose
ssh_server "cd ~/job-queue && docker compose pull && docker compose up -d"

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
