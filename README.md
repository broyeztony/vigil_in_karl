# Vigil in Karl

Reimplementation of [Vigil](https://github.com/broyeztony/vigil) in Karl.

## Preview

![Vigil in Karl: DB inspector + discovery logs](assets/karl-vigil.png)

## Docker start/stop (recommended)

Requires Docker Desktop (or another running Docker daemon).

```bash
cd /Users/tonybroyez/Documents/vigil_in_karl

# start full stack (postgres + mock + discovery)
bash scripts/docker_up.sh

# follow logs
bash scripts/docker_logs.sh

# stop (keep DB data)
bash scripts/docker_down.sh

# stop + wipe DB data (clean restart)
bash scripts/docker_clean.sh
```

Equivalent Make targets:

```bash
make up
make logs
make watch-db
make down
make clean
```

## What is implemented

- `cmd/setup.k`: creates schema and seeds tenant `00000000-0000-0000-0000-000000000001`
- `cmd/mock_server.k`: mock provider API
  - `GET /health`
  - `GET /google/users/:tenantId`
  - `GET /google/emails/:userId?receivedAfter=...&orderBy=...`
  - `POST /admin/users/add?numUsers=...`
  - `POST /admin/users/set?numUsers=...`
  - `GET /admin/state`
- `cmd/discovery.k`: user discovery + per-user email polling + fingerprint dedupe + persistence + graceful shutdown
  - includes metrics with top-users and queue boundary (`ANALYSIS_QUEUE_MODE`)

## Manual local run (without Docker)

```bash
cd /Users/tonybroyez/Documents/vigil_in_karl

# 1) setup DB
karl run cmd/setup.k

# 2) run mock server
PORT=8080 karl run cmd/mock_server.k

# 3) run discovery (new terminal)
TENANT_ID=00000000-0000-0000-0000-000000000001 \
PROVIDER_API_URL=http://127.0.0.1:8080 \
karl run cmd/discovery.k
```

## Tests

```bash
# pure Karl unit check
bash scripts/test_unit.sh

# mock API smoke test
bash scripts/test_mock_api.sh

# dedupe regression (fingerprint and message_id collisions)
bash scripts/test_dedupe_regression.sh

# same-email user-id rekey regression (restart-safe upsert)
bash scripts/test_user_rekey_regression.sh

# full smoke test (setup + mock + discovery + DB assertions)
bash scripts/test_discovery_smoke.sh

# user-removal + worker-teardown regression
bash scripts/test_user_removal_regression.sh

# run all tests
bash scripts/test_all.sh

# inspect current DB state
bash scripts/inspect_db.sh
```

Notes:
- `scripts/inspect_db.sh` targets only `docker:vik-postgres`.
- If Docker DB is down, it exits and asks you to run `make up`.

## Main env vars

- `DATABASE_URL` (default `postgres://vigil:vigil@localhost:5432/vigil?sslmode=disable`)
- `TENANT_ID` (default `00000000-0000-0000-0000-000000000001`)
- `PROVIDER_TYPE` (`google` default, `microsoft` supported by client routing)
- `PROVIDER_API_URL` (default `http://localhost:8080`)
- `PORT` (mock server, default `8080`)
- `MOCK_INITIAL_USERS` (default `5000`)
- `MOCK_EMAIL_TICK_MS` (default `30000`)
- `MOCK_MAX_EMAILS_PER_TICK` (default `3`)
- `USER_POLL_MS` (default `60000`)
- `EMAIL_POLL_MS` (default `30000`)
- `EMAIL_JITTER_MS` (default `30000`)
- `METRICS_MS` (default `5000`)
- `ANALYSIS_QUEUE_MODE` (`log` default, `off` to disable queue-stub logging)
