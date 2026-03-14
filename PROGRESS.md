# PROGRESS

## Current Milestone

- M1: runnable first-principles baseline (postgres + mock + discovery)

## Done

- reset legacy codebase
- created AGENTS.md with strict coding and workflow rules
- scaffolded rebuild docs, scripts, and Make targets
- implemented first-principles Karl modules for:
  - config
  - db core/schema/users/emails
  - provider client
  - mock users/emails/http server
  - discovery cycle + app orchestration
- added runnable commands:
  - `cmd/setup.k`
  - `cmd/mock_server.k`
  - `cmd/discovery.k`
- added smoke tests:
  - `tests/mock_provider_smoke.k`
  - `tests/discovery_smoke.k`
- validated:
  - `make setup`
  - `make watch-db`
  - `make test`

## Next

- split discovery flow into smaller role-specific modules (scheduler, persistence, stats)
- add regression tests: dedupe + user rekey + user removal
- add dockerized full-stack mode (mock + discovery in compose)
