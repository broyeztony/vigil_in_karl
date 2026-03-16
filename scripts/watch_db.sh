#!/usr/bin/env bash
set -euo pipefail

docker compose up -d postgres >/dev/null
bash scripts/wait_db.sh

interval="${WATCH_DB_INTERVAL:-2}"

render() {
  if [[ -t 1 ]]; then clear; fi
  echo "=== vigil_in_karl DB inspector ==="
  echo "target: docker:vik-postgres"
  echo "updated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo

  has_schema="$(docker exec -i vik-postgres psql -U vigil -d vigil -tAc "SELECT to_regclass('public.tenant') IS NOT NULL;" | tr -d '[:space:]')"
  if [[ "${has_schema}" != "t" ]]; then
    echo "schema not initialized; run: make setup"
    return
  fi

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
}

while true; do
  render
  sleep "${interval}"
done
