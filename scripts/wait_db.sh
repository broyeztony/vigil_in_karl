#!/usr/bin/env bash
set -euo pipefail

for _ in $(seq 1 60); do
  if docker exec -i vik-postgres pg_isready -U vigil -d vigil >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.5
done

echo "postgres not ready" >&2
exit 1
