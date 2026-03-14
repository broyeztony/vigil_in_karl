#!/usr/bin/env bash
set -euo pipefail

bash scripts/test_mock_smoke.sh
bash scripts/test_discovery_smoke.sh
bash scripts/test_user_churn.sh
