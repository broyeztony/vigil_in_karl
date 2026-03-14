#!/usr/bin/env bash
set -euo pipefail

docker compose up -d postgres >/dev/null
karl run cmd/setup.k >/dev/null

PORT=18081 MOCK_INITIAL_USERS=8 karl run cmd/mock_server.k >/tmp/vik_mock.log 2>&1 &
MOCK_PID=$!
trap 'kill ${MOCK_PID} >/dev/null 2>&1 || true' EXIT
sleep 1

PROVIDER_API_URL=http://127.0.0.1:18081 USER_SYNC_MS=700 EMAIL_POLL_MS=700 METRICS_MS=8000 \
  karl run tests/discovery_smoke.k
