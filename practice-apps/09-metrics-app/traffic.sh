#!/usr/bin/env bash
# Generates traffic so Grafana has something to show. Usage: ./traffic.sh [base_url]
BASE=${1:-http://localhost:5000}
while true; do
  curl -s "$BASE/work" >/dev/null
  curl -s "$BASE/error" >/dev/null
  sleep 0.5
done
