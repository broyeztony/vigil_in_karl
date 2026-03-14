#!/usr/bin/env bash
set -euo pipefail

docker compose up -d postgres >/dev/null

echo "=== vigil_in_karl DB inspector ==="
echo "target: docker:vik-postgres"

docker exec -i vik-postgres psql -U vigil -d vigil <<'SQL'
\pset pager off
\timing off

SELECT 'tenant' AS table_name, COUNT(*) AS count FROM tenant
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'emails', COUNT(*) FROM emails
UNION ALL
SELECT 'user_emails', COUNT(*) FROM user_emails;
SQL
