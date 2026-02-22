#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DATABASE_URL="${DATABASE_URL:-postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable}"
DATABASE_URL="$DATABASE_URL" karl run tests/dedupe_regression.k | tee /tmp/vigil_in_karl_dedupe.log

grep -q '"ok"' /tmp/vigil_in_karl_dedupe.log

echo "dedupe regression: ok"
