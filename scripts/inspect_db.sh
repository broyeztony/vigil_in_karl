#!/usr/bin/env bash
set -euo pipefail

choose_psql_target() {
  TARGET_WARNING=""
  if [[ -n "${DATABASE_URL:-}" ]]; then
    local url="${DATABASE_URL}"
    TARGET_LABEL="$url"
    PSQL_CMD=(psql "$url")
    return
  fi
  if docker ps --format '{{.Names}}' | grep -qx "vik-postgres"; then
    TARGET_LABEL="docker:vik-postgres"
    PSQL_CMD=(docker exec -i vik-postgres psql -U vigil -d vigil)
    return
  fi
  local url="postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable"
  TARGET_LABEL="$url"
  TARGET_WARNING="vik-postgres is not running; inspecting host Postgres on localhost:5432."
  PSQL_CMD=(psql "$url")
}

run_query() {
  "${PSQL_CMD[@]}" -c "$1"
}

choose_psql_target

echo "=== vigil_in_karl DB inspector ==="
echo "target: ${TARGET_LABEL}"
if [[ -n "${TARGET_WARNING}" ]]; then
  echo "warning: ${TARGET_WARNING}"
fi
echo

echo "record counts:"
run_query "
SELECT 'tenant' AS table_name, COUNT(*) AS count FROM tenant
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'emails', COUNT(*) FROM emails
UNION ALL
SELECT 'user_emails', COUNT(*) FROM user_emails;
"

echo
echo "top users by linked emails:"
run_query "
SELECT
  u.email,
  COUNT(ue.email_id) AS email_count,
  u.last_email_check,
  u.last_email_received
FROM users u
LEFT JOIN user_emails ue ON ue.user_id = u.id
GROUP BY u.id, u.email, u.last_email_check, u.last_email_received
ORDER BY email_count DESC
LIMIT 10;
"
