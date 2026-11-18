#!/bin/sh
set -eu
cd "$(dirname "$0")"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

: "${SERVER_IP:?Set SERVER_IP in .env}"
: "${SSH_USER:?Set SSH_USER in .env}"
: "${APP_NAME:?Set APP_NAME in .env}"
REMOTE_PORT="${REMOTE_PORT:-5000}"
REMOTE_APP_ENV="${REMOTE_APP_ENV:-production}"
REGISTRY="${SERVER_IP}:8081"
IMAGE="${REGISTRY}/docker-excercise/my-flask-health-api:1.0"
SERVER="${SSH_USER}@${SERVER_IP}"

registry_configured() {
  docker info 2>/dev/null | grep -F -- "$REGISTRY" >/dev/null 2>&1
}

wait_for_nexus() {
  i=0
  while ! curl -s -o /dev/null --max-time 2 "http://${REGISTRY}/"; do
    i=$((i + 1))
    if [ "$i" -gt 30 ]; then
      echo "Nexus at ${REGISTRY} did not respond." >&2
      exit 1
    fi
    sleep 2
  done
}

ensure_local_registry() {
  if registry_configured; then
    return 0
  fi

  config="${HOME}/.orbstack/config/docker.json"
  if [ ! -d "${HOME}/.orbstack" ]; then
    echo "Add ${REGISTRY} to this machine's Docker insecure registries, then restart Docker." >&2
    exit 1
  fi

  mkdir -p "${HOME}/.orbstack/config"
  set +e
  python3 - "$config" "$REGISTRY" <<'PY'
import json, sys
path, registry = sys.argv[1], sys.argv[2]
try:
    with open(path) as fh:
        data = json.load(fh)
except FileNotFoundError:
    data = {}
regs = list(data.get("insecure-registries") or [])
if registry in regs:
    sys.exit(0)
regs.append(registry)
data["insecure-registries"] = regs
with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
sys.exit(10)
PY
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    echo "Restart OrbStack so it loads ${REGISTRY}, then run this script again." >&2
    exit 1
  fi
  if [ "$status" -ne 10 ]; then
    exit "$status"
  fi

  osascript -e 'quit app "OrbStack"' >/dev/null 2>&1 || true
  open -a OrbStack
  i=0
  while ! registry_configured; do
    i=$((i + 1))
    if [ "$i" -gt 45 ]; then
      echo "OrbStack did not load ${REGISTRY}." >&2
      exit 1
    fi
    sleep 2
  done
}

login_registry() {
  target="$1"
  if [ -z "${NEXUS_USER:-}" ] || [ -z "${NEXUS_PASSWORD:-}" ]; then
    return 0
  fi
  if [ "$target" = "local" ]; then
    printf '%s' "$NEXUS_PASSWORD" | docker login "$REGISTRY" -u "$NEXUS_USER" --password-stdin
    return 0
  fi
  printf '%s' "$NEXUS_PASSWORD" | ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$SERVER" \
    "docker login '${REGISTRY}' -u '${NEXUS_USER}' --password-stdin"
}

prepare_server() {
  # shellcheck disable=SC2029
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$SERVER" \
    "REGISTRY=${REGISTRY} HOST_PORT=${REMOTE_PORT} bash -s" <<'REMOTE'
set -eu
mkdir -p "$HOME/flask-health"

if ! command -v docker >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
fi

if ! docker compose version >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update
  if ! sudo apt-get install -y docker-compose-plugin; then
    sudo apt-get install -y docker-compose-v2
  fi
fi

changed=0
if command -v python3 >/dev/null 2>&1; then
  tmp=$(mktemp)
  set +e
  python3 - "$REGISTRY" >"$tmp" <<'PY'
import json, sys
registry = sys.argv[1]
path = "/etc/docker/daemon.json"
try:
    with open(path) as fh:
        data = json.load(fh)
except FileNotFoundError:
    data = {}
regs = list(data.get("insecure-registries") or [])
if registry in regs:
    sys.exit(0)
regs.append(registry)
data["insecure-registries"] = regs
json.dump(data, sys.stdout, indent=2)
sys.stdout.write("\n")
sys.exit(10)
PY
  status=$?
  set -e
  if [ "$status" -eq 10 ]; then
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <"$tmp" >/dev/null
    changed=1
  elif [ "$status" -ne 0 ]; then
    rm -f "$tmp"
    exit "$status"
  fi
  rm -f "$tmp"
elif [ ! -f /etc/docker/daemon.json ]; then
  sudo mkdir -p /etc/docker
  printf '{ "insecure-registries": ["%s"] }\n' "$REGISTRY" | sudo tee /etc/docker/daemon.json >/dev/null
  changed=1
elif ! grep -F "$REGISTRY" /etc/docker/daemon.json >/dev/null 2>&1; then
  echo "python3 is required to update /etc/docker/daemon.json." >&2
  exit 1
fi

if [ "$changed" -eq 1 ]; then
  echo "Restarting Docker so it accepts ${REGISTRY}."
  sudo systemctl restart docker
  i=0
  while ! docker info >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -gt 30 ]; then
      echo "Docker did not come back after the restart." >&2
      exit 1
    fi
    sleep 2
  done
fi

if command -v ufw >/dev/null 2>&1; then
  ufw_status=$(sudo ufw status 2>/dev/null || true)
  case "$ufw_status" in
    *"Status: active"*)
      sudo ufw allow OpenSSH >/dev/null
      sudo ufw allow "${HOST_PORT}/tcp" >/dev/null
      ;;
  esac
fi
REMOTE
}

if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$SERVER" true; then
  echo "SSH key login to ${SERVER} has to work before this script can run." >&2
  exit 1
fi

ensure_local_registry
login_registry local
docker build --platform linux/amd64 --push -t "$IMAGE" .

prepare_server
login_registry remote
wait_for_nexus

ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$SERVER" "cat > ~/flask-health/.env" <<EOF
PORT=${REMOTE_PORT}
APP_NAME=${APP_NAME}
APP_ENV=${REMOTE_APP_ENV}
SERVER_IP=${SERVER_IP}
EOF
scp -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
  docker-compose.yaml "${SERVER}:~/flask-health/docker-compose.yaml"
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$SERVER" \
  'cd ~/flask-health && docker compose pull && docker compose up -d'

echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/"
echo
curl -fsS "http://${SERVER_IP}:${REMOTE_PORT}/health"
echo
