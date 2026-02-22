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
- Docker orchestration:
  - `Dockerfile`
  - `docker-compose.yml`
  - `scripts/docker_up.sh`, `scripts/docker_down.sh`, `scripts/docker_clean.sh`, `scripts/docker_logs.sh`, `scripts/docker_discovery_entrypoint.sh`
  - `Makefile` targets (`up`, `down`, `clean`, `logs`, `test`)
- Tests/scripts:
  - `tests/mock_data_test.k`
  - `tests/dedupe_regression.k`
  - `tests/user_rekey_regression.k`
  - `scripts/test_unit.sh`
  - `scripts/test_mock_api.sh`
  - `scripts/test_dedupe_regression.sh`
  - `scripts/test_user_rekey_regression.sh`
  - `scripts/test_discovery_smoke.sh`
  - `scripts/test_user_removal_regression.sh`
  - `scripts/test_all.sh`
  - `scripts/inspect_db.sh`
- Documentation:
  - `README.md`
  - `KARL_FEEDBACK.md` updated with issues found during implementation
  - `COMMAND_LOG.md` updated with executed commands

Validated:
- `karl run cmd/setup.k`
- `bash scripts/test_unit.sh`
- `bash scripts/test_mock_api.sh`
- `bash scripts/test_dedupe_regression.sh`
- `bash scripts/test_user_rekey_regression.sh`
- `bash scripts/test_discovery_smoke.sh`
- `bash scripts/test_user_removal_regression.sh`
- `bash scripts/test_all.sh`

Recent hardening:
- Fixed restart-safe user upsert to prevent `user_emails_user_id_fkey` errors when provider user IDs rotate for the same email.

## Remaining Work
- Expand toward production-level concerns:
  - actual queue transport implementation behind `lib/analysis_queue.k`
  - retry/backoff/rate-limiting policies for provider HTTP calls
  - tighter lifecycle tests around long-running shutdown timing windows
