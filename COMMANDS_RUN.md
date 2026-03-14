# COMMANDS RUN

- 2026-03-14: `git status`, `find *.k` - verified post-deletion baseline.
- 2026-03-14: `make clean && make up && make setup` - validated clean bootstrap.
- 2026-03-14: `make test` - executed smoke and churn suites repeatedly during rebuild.
- 2026-03-14: `make watch-db` - inspected DB row evolution.
- 2026-03-14: `karl run cmd/mock_server.k` - manual lifecycle/signal checks.
- 2026-03-14: `make test` - verified entrypoint signal refactor against current Karl runtime.
- 2026-03-14: `karl run cmd/mock_server.k` + `kill -TERM <pid>` and `karl run cmd/discovery.k` + `kill -TERM <pid>` - verified signal shutdown path with task-wrapped signal recv.
- 2026-03-14: `bash scripts/test_provider_users_error_no_remove.sh` - verified provider users fetch failure does not remove existing users.
