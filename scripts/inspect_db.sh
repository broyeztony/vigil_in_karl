#!/usr/bin/env bash
set -euo pipefail

DATABASE_URL="${DATABASE_URL:-postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable}"

echo "=== vigil_in_karl DB inspector ==="
echo

echo "record counts:"
psql "$DATABASE_URL" -c "
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
psql "$DATABASE_URL" -c "
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
