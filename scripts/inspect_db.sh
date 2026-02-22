#!/usr/bin/env bash
set -euo pipefail

docker ps --format '{{.Names}}' | grep -qx "vik-postgres" || {
  echo "vik-postgres is not running. Start the stack with: make up" >&2
  exit 1
}

run_query() {
  "${PSQL_CMD[@]}" -c "$1"
}

TARGET_LABEL="docker:vik-postgres"
PSQL_CMD=(docker exec -i vik-postgres psql -U vigil -d vigil)

echo "=== vigil_in_karl DB inspector ==="
echo "target: ${TARGET_LABEL}"
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
