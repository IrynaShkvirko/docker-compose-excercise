#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

: "${RATE_LIMIT:?Set RATE_LIMIT in .env}"
: "${RATE_WINDOW_SECONDS:?Set RATE_WINDOW_SECONDS in .env}"

# The Flask health API already uses 5000 on this server.
REMOTE_PORT="${REMOTE_PORT:-5001}"
IMAGE="${REGISTRY}/docker-excercise/my-redis-counter:1.0"

upload_server_compose() {
  python3 - docker-compose.yaml <<'PY' | ssh_server "cat > ~/redis-counter/docker-compose.yaml"
import sys
lines = open(sys.argv[1]).read().splitlines(True)
out = []
i = 0
while i < len(lines):
    nxt = lines[i + 1] if i + 1 < len(lines) else ""
    if lines[i].strip() == "ports:" and (":6379\"" in nxt or "5540:5540" in nxt):
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

prepare_server redis-counter "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env redis-counter <<EOF
SERVER_IP=${SERVER_IP}
PORT=${REMOTE_PORT}
REDIS_PORT=6379
RATE_LIMIT=${RATE_LIMIT}
RATE_WINDOW_SECONDS=${RATE_WINDOW_SECONDS}
EOF

upload_server_compose
ssh_server "cd ~/redis-counter && docker compose pull && docker compose up -d"

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
