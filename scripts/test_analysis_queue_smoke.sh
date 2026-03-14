#!/usr/bin/env bash
set -euo pipefail

docker compose up -d postgres >/dev/null
bash scripts/wait_db.sh
karl run cmd/setup.k >/dev/null

karl run tests/discovery_analysis_queue_smoke.k
