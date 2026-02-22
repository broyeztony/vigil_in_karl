#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${PORT:-18084}"
TENANT_ID="${TENANT_ID:-00000000-0000-0000-0000-000000000001}"
DATABASE_URL="${DATABASE_URL:-postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable}"

MOCK_LOG="${MOCK_LOG:-/tmp/vigil_in_karl_removal_mock.log}"
DISCOVERY_LOG="${DISCOVERY_LOG:-/tmp/vigil_in_karl_removal_discovery.log}"

cleanup() {
  if [[ -n "${DISCOVERY_PID:-}" ]]; then
    kill -TERM "$DISCOVERY_PID" 2>/dev/null || true
    wait "$DISCOVERY_PID" 2>/dev/null || true
  fi
  if [[ -n "${MOCK_PID:-}" ]]; then
    kill -TERM "$MOCK_PID" 2>/dev/null || true
    wait "$MOCK_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

DATABASE_URL="$DATABASE_URL" TENANT_ID="$TENANT_ID" karl run cmd/setup.k
psql "$DATABASE_URL" -c "TRUNCATE TABLE user_emails, emails, users;"

PORT="$PORT" TENANT_ID="$TENANT_ID" MOCK_INITIAL_USERS="${MOCK_INITIAL_USERS:-12}" MOCK_EMAIL_TICK_MS="${MOCK_EMAIL_TICK_MS:-300}" \
  karl run cmd/mock_server.k >"$MOCK_LOG" 2>&1 &
MOCK_PID=$!

for _ in {1..100}; do
  if curl -fsS "http://127.0.0.1:${PORT}/health" >/tmp/vigil_in_karl_removal_health.json 2>/dev/null; then
    break
  fi
  sleep 0.1
done

DATABASE_URL="$DATABASE_URL" \
TENANT_ID="$TENANT_ID" \
PROVIDER_API_URL="http://127.0.0.1:${PORT}" \
USER_POLL_MS="${USER_POLL_MS:-700}" \
EMAIL_POLL_MS="${EMAIL_POLL_MS:-250}" \
EMAIL_JITTER_MS="${EMAIL_JITTER_MS:-0}" \
METRICS_MS="${METRICS_MS:-500}" \
ANALYSIS_QUEUE_MODE="off" \
  karl run cmd/discovery.k >"$DISCOVERY_LOG" 2>&1 &
DISCOVERY_PID=$!

sleep 2
curl -fsS -X POST "http://127.0.0.1:${PORT}/admin/users/set?numUsers=2" | grep -q '"total":2'

sleep 3
kill -TERM "$DISCOVERY_PID"
wait "$DISCOVERY_PID" || true
DISCOVERY_PID=""

summary_line="$(grep 'stopped {' "$DISCOVERY_LOG" | tail -n 1 || true)"
[[ -n "$summary_line" ]]
echo "$summary_line"

grep -Eq 'active_workers: 0' "$DISCOVERY_LOG"
grep -Eq 'seen: [1-9][0-9]*' "$DISCOVERY_LOG"
! grep -Eq 'fatal error:|panic:' "$DISCOVERY_LOG"

echo "user-removal regression: ok"
