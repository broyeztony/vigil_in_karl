#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker info >/dev/null 2>&1 || {
  echo "Docker daemon is not running. Nothing to clean."
  exit 1
}

docker compose down -v --remove-orphans

echo "vik is down (data wiped)"
