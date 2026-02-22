#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker info >/dev/null 2>&1 || {
  echo "Docker daemon is not running. Nothing to stop."
  exit 1
}

docker compose down --remove-orphans

echo "vik is down (data kept)"
