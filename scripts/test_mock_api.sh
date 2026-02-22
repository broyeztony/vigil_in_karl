#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${PORT:-18081}"
TENANT_ID="${TENANT_ID:-00000000-0000-0000-0000-000000000001}"
LOG_FILE="${LOG_FILE:-/tmp/vigil_in_karl_mock.log}"

cleanup() {
  if [[ -n "${MOCK_PID:-}" ]]; then
    kill -TERM "$MOCK_PID" 2>/dev/null || true
    wait "$MOCK_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

PORT="$PORT" MOCK_INITIAL_USERS="${MOCK_INITIAL_USERS:-50}" MOCK_EMAIL_TICK_MS="${MOCK_EMAIL_TICK_MS:-400}" \
  karl run cmd/mock_server.k >"$LOG_FILE" 2>&1 &
MOCK_PID=$!

for _ in {1..80}; do
  if curl -fsS "http://127.0.0.1:${PORT}/health" >/tmp/vigil_mock_health.json 2>/dev/null; then
    break
  fi
  sleep 0.1
done

curl -fsS "http://127.0.0.1:${PORT}/health" | grep -q '"status":"ok"'
users_json="$(curl -fsS "http://127.0.0.1:${PORT}/google/users/${TENANT_ID}")"
echo "$users_json" | grep -q '"email"'

first_user_id="$(echo "$users_json" | sed -E 's/^\[\{"id":"([^"]+)".*/\1/' | tr -d '\n')"
if [[ -n "$first_user_id" && "$first_user_id" != "$users_json" ]]; then
  curl -fsS "http://127.0.0.1:${PORT}/google/emails/${first_user_id}?orderBy=received_at" | grep -q '^\['
fi

curl -fsS -X POST "http://127.0.0.1:${PORT}/admin/users/add?numUsers=3" | grep -q '"added":3'

echo "mock-api smoke: ok"
