# Vigil in Karl - Progress

## Goal
Reimplement Vigil fully in Karl with tests and runnable services.

## Current Status

Completed:
- Core modules:
  - `lib/config.k`
  - `lib/common.k`
  - `lib/db.k`
  - `lib/provider_client.k`
  - `lib/mock_data.k`
  - `lib/mock_server_app.k`
  - `lib/discovery_app.k`
- Commands:
  - `cmd/setup.k`
  - `cmd/mock_server.k`
  - `cmd/discovery.k`
- Tests/scripts:
  - `tests/mock_data_test.k`
  - `tests/dedupe_regression.k`
  - `scripts/test_unit.sh`
  - `scripts/test_mock_api.sh`
  - `scripts/test_dedupe_regression.sh`
  - `scripts/test_discovery_smoke.sh`
  - `scripts/test_user_removal_regression.sh`
  - `scripts/test_all.sh`
  - `scripts/inspect_db.sh`
- Documentation:
  - `README.md`
  - `KARL_FEEDBACK.md` updated with issues found during implementation

Validated:
- `karl run cmd/setup.k`
- `bash scripts/test_unit.sh`
- `bash scripts/test_mock_api.sh`
- `bash scripts/test_dedupe_regression.sh`
- `bash scripts/test_discovery_smoke.sh`
- `bash scripts/test_user_removal_regression.sh`
- `bash scripts/test_all.sh`

## Remaining Work
- Expand toward production-level concerns:
  - actual queue transport implementation behind `lib/analysis_queue.k`
  - retry/backoff/rate-limiting policies for provider HTTP calls
  - tighter lifecycle tests around long-running shutdown timing windows
