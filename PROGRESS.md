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
  - `scripts/test_unit.sh`
  - `scripts/test_mock_api.sh`
  - `scripts/test_discovery_smoke.sh`
- Documentation:
  - `README.md`
  - `KARL_FEEDBACK.md` updated with issues found during implementation

Validated:
- `karl run cmd/setup.k`
- `bash scripts/test_unit.sh`
- `bash scripts/test_mock_api.sh`
- `bash scripts/test_discovery_smoke.sh`

## Remaining Work

- Increase behavioral parity with Go service internals where useful:
  - richer metrics/top-user reporting
  - explicit queue integration stub boundaries for fraud-analysis handoff
- Add more targeted regression tests around:
  - dedupe edge cases (`message_id` collisions / fingerprint duplicates)
  - user removal path and worker teardown
