#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

start_users="${START_USERS:-32}"
target_users="${TARGET_USERS:-5000}"
step_users="${STEP_USERS:-32}"
ramp_interval_sec="${RAMP_INTERVAL_SEC:-1}"
host="${HOST:-127.0.0.1}"
port="${PORT:-8080}"
base_url="http://${host}:${port}"

if (( start_users < 0 || target_users < start_users || step_users <= 0 )); then
  echo "invalid ramp params: START_USERS>=0, TARGET_USERS>=START_USERS, STEP_USERS>0"
  exit 1
fi

cleanup() {
  if [[ -n "${mock_pid:-}" ]]; then
    kill -TERM "${mock_pid}" 2>/dev/null || true
    wait "${mock_pid}" 2>/dev/null || true
  fi
}
trap cleanup INT TERM EXIT

echo "starting mock server on :${port} with ${start_users} users"
MOCK_INITIAL_USERS="${start_users}" PORT="${port}" karl run cmd/mock_server.k &
mock_pid=$!

for _ in $(seq 1 120); do
  if curl -fsS "${base_url}/health" >/dev/null 2>&1; then break; fi
  sleep 0.25
done
curl -fsS "${base_url}/health" >/dev/null

users="${start_users}"
echo "ramp start: users=${users}, target=${target_users}, step=${step_users}"
while (( users < target_users )); do
  inc="${step_users}"
  remaining=$((target_users - users))
  if (( inc > remaining )); then inc="${remaining}"; fi
  curl -fsS -X POST "${base_url}/admin/users/add?num_users=${inc}" >/dev/null
  users=$((users + inc))
  echo "users=${users}/${target_users}"
  if (( users < target_users )); then sleep "${ramp_interval_sec}"; fi
done

echo "ramp complete: users=${users}. mock server stays running."
wait "${mock_pid}"
