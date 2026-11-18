#!/usr/bin/env bash
# Static checks: no containers are started.
#   1. docker compose config  -> YAML / schema validation of docker-compose.yaml
#   2. hadolint               -> Dockerfile lint (skipped with a warning if unavailable)
set -euo pipefail
cd "$(dirname "$0")/.."

# Dummy values so ${VAR} interpolation doesn't warn about unset variables.
export DB_USER="${DB_USER:-appuser}"
export DB_PWD="${DB_PWD:-apppassword}"
export DB_SERVER="${DB_SERVER:-mysql}"
export DB_NAME="${DB_NAME:-appdb}"

echo "==> Validating docker-compose.yaml"
docker compose config -q
echo "OK"

echo "==> Linting Dockerfile"
if command -v hadolint >/dev/null 2>&1; then
  hadolint Dockerfile
elif command -v docker >/dev/null 2>&1; then
  docker run --rm -i hadolint/hadolint < Dockerfile
else
  echo "WARNING: hadolint and docker not found, skipping Dockerfile lint" >&2
fi
echo "OK"
