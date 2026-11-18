#!/usr/bin/env bash
# End-to-end smoke test:
#   build jar -> build image -> docker compose up --wait -> call the API -> tear down.
# Needs: Java 17, Gradle, Docker (with Compose v2), curl.
# Warning: runs `docker compose down -v`, which deletes the mysql-data volume.
set -euo pipefail
cd "$(dirname "$0")/.."

export DB_USER="${DB_USER:-appuser}"
export DB_PWD="${DB_PWD:-apppassword}"
export DB_SERVER="${DB_SERVER:-mysql}"
export DB_NAME="${DB_NAME:-appdb}"
BASE_URL="${BASE_URL:-http://localhost:8080}"
EXPECTED_MEMBERS=5

cleanup() {
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "==> FAILED (exit $status), container state and logs:" >&2
    docker compose ps >&2 || true
    docker compose logs --tail=100 >&2 || true
  fi
  docker compose down -v >/dev/null 2>&1 || true
  exit "$status"
}
trap cleanup EXIT

echo "==> Building jar"
gradle bootJar --no-daemon -q

echo "==> Building image java-mysql-app:1.0"
docker build -t java-mysql-app:1.0 .

echo "==> Starting stack (waits for healthchecks)"
docker compose down -v >/dev/null 2>&1 || true
docker compose up -d --wait --wait-timeout 180

echo "==> Waiting for the app to answer"
for i in $(seq 1 30); do
  if curl -fsS "$BASE_URL/get-data" -o /tmp/get-data.json 2>/dev/null; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "App did not respond on $BASE_URL/get-data" >&2
    exit 1
  fi
  sleep 2
done

echo "==> Checking /get-data"
body=$(cat /tmp/get-data.json)
count=$(printf '%s' "$body" | grep -o '"name"' | wc -l | tr -d ' ')
if [ "$count" -ne "$EXPECTED_MEMBERS" ]; then
  echo "Expected $EXPECTED_MEMBERS team members, got $count: $body" >&2
  exit 1
fi
printf '%s' "$body" | grep -q '"Sarah"' || { echo "Seed member 'Sarah' missing: $body" >&2; exit 1; }

echo "==> Checking front page"
curl -fsS "$BASE_URL/" -o /dev/null

echo "==> Checking phpMyAdmin"
curl -fsS "http://localhost:8083/" -o /dev/null

echo "==> Smoke test PASSED"
