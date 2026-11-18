#!/bin/sh
set -eu
cd "$(dirname "$0")"
# shellcheck disable=SC1091
. ../lib/deploy-common.sh

load_dotenv
init_targets

: "${GF_ADMIN_PASSWORD:?Set GF_ADMIN_PASSWORD in .env}"

# The URL shortener already uses 3000 on this server.
REMOTE_PORT="${REMOTE_PORT:-3001}"
IMAGE="${REGISTRY}/docker-excercise/my-metrics-app:1.0"

upload_server_compose() {
  python3 - docker-compose.yaml <<'PY' | ssh_server "cat > ~/metrics/docker-compose.yaml"
import sys
lines = open(sys.argv[1]).read().splitlines(True)
out = []
i = 0
while i < len(lines):
    nxt = lines[i + 1] if i + 1 < len(lines) else ""
    if lines[i].strip() == "ports:" and ("9090:9090" in nxt or ":5000\"" in nxt):
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

prepare_server metrics "$REMOTE_PORT"
login_registry remote
wait_for_nexus

write_remote_env metrics <<EOF
SERVER_IP=${SERVER_IP}
APP_PORT=5000
GRAFANA_PORT=${REMOTE_PORT}
GF_ADMIN_PASSWORD=${GF_ADMIN_PASSWORD}
EOF

ssh_server "mkdir -p ~/metrics/grafana/provisioning/datasources"
upload_server_compose
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  prometheus.yml "${SERVER}:~/metrics/prometheus.yml"
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  grafana/provisioning/datasources/datasource.yml \
  "${SERVER}:~/metrics/grafana/provisioning/datasources/datasource.yml"
ssh_server "cd ~/metrics && docker compose pull && docker compose up -d"

wait_for_http "http://${SERVER_IP}:${REMOTE_PORT}/login"
echo
curl -fsS -o /dev/null -w "%{http_code}\n" "http://${SERVER_IP}:${REMOTE_PORT}/login"
