#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash scripts/test_unit.sh
bash scripts/test_mock_api.sh
bash scripts/test_discovery_smoke.sh

echo "all tests: ok"
