#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${PORT:-18082}"
TENANT_ID="${TENANT_ID:-00000000-0000-0000-0000-000000000001}"
DATABASE_URL="${DATABASE_URL:-postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable}"
RUN_SECONDS="${RUN_SECONDS:-8}"

MOCK_LOG="${MOCK_LOG:-/tmp/vigil_in_karl_mock_smoke.log}"
DISCOVERY_LOG="${DISCOVERY_LOG:-/tmp/vigil_in_karl_discovery_smoke.log}"

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

PORT="$PORT" TENANT_ID="$TENANT_ID" MOCK_INITIAL_USERS="${MOCK_INITIAL_USERS:-100}" MOCK_EMAIL_TICK_MS="${MOCK_EMAIL_TICK_MS:-500}" \
  karl run cmd/mock_server.k >"$MOCK_LOG" 2>&1 &
MOCK_PID=$!

for _ in {1..80}; do
  if curl -fsS "http://127.0.0.1:${PORT}/health" >/tmp/vigil_discovery_health.json 2>/dev/null; then
    break
  fi
  sleep 0.1
done

DATABASE_URL="$DATABASE_URL" \
TENANT_ID="$TENANT_ID" \
PROVIDER_API_URL="http://127.0.0.1:${PORT}" \
USER_POLL_MS="${USER_POLL_MS:-2000}" \
EMAIL_POLL_MS="${EMAIL_POLL_MS:-500}" \
EMAIL_JITTER_MS="${EMAIL_JITTER_MS:-0}" \
METRICS_MS="${METRICS_MS:-1000}" \
  karl run cmd/discovery.k >"$DISCOVERY_LOG" 2>&1 &
DISCOVERY_PID=$!

sleep "$RUN_SECONDS"

users_count="$(psql "$DATABASE_URL" -t -A -c 'SELECT COUNT(*) FROM users;' | tr -d '[:space:]')"
emails_count="$(psql "$DATABASE_URL" -t -A -c 'SELECT COUNT(*) FROM emails;' | tr -d '[:space:]')"
links_count="$(psql "$DATABASE_URL" -t -A -c 'SELECT COUNT(*) FROM user_emails;' | tr -d '[:space:]')"

echo "users=$users_count emails=$emails_count user_emails=$links_count"

[[ "${users_count:-0}" -ge 1 ]]
[[ "${emails_count:-0}" -ge 1 ]]
[[ "${links_count:-0}" -ge 1 ]]

echo "discovery smoke: ok"
