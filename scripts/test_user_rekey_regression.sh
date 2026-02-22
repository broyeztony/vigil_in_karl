#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DATABASE_URL="${DATABASE_URL:-postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable}"
DATABASE_URL="$DATABASE_URL" karl run tests/user_rekey_regression.k | tee /tmp/vigil_in_karl_user_rekey.log

grep -q '"ok"' /tmp/vigil_in_karl_user_rekey.log

echo "user-rekey regression: ok"
