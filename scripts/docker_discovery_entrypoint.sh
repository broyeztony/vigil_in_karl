#!/usr/bin/env bash
set -euo pipefail

echo "[vik-discovery] waiting for setup..."
for attempt in $(seq 1 60); do
  if karl run /app/cmd/setup.k; then
    echo "[vik-discovery] setup complete"
    exec karl run /app/cmd/discovery.k
  fi
  echo "[vik-discovery] setup retry ${attempt}/60"
  sleep 1
done

echo "[vik-discovery] setup failed after retries"
exit 1
