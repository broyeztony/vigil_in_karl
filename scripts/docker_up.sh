#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker info >/dev/null 2>&1 || {
  echo "Docker daemon is not running. Start Docker Desktop, then retry."
  exit 1
}

docker compose up -d --build

echo "vik is up"
echo "- mock API: http://127.0.0.1:8080/health"
echo "- logs: bash scripts/docker_logs.sh"
