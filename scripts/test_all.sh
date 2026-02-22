#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash scripts/test_unit.sh
bash scripts/test_mock_api.sh
bash scripts/test_dedupe_regression.sh
bash scripts/test_discovery_smoke.sh
bash scripts/test_user_removal_regression.sh

echo "all tests: ok"
