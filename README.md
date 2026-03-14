# Vigil in Karl

Rebuild of Vigil from first principles in Karl, optimized for high-throughput email ingestion.

## Problem We Are Solving

For each tenant:

1. retrieve users from provider APIs
2. retrieve user emails incrementally
3. persist/dedupe reliably
4. keep up under churn and spikes

Reference: `REQUIREMENTS.md`.

## How This Implementation Addresses It

### Efficient runtime topology

```mermaid
flowchart LR
  P[Provider APIs] --> R[Reconciler]
  R --> W[Per-user workers]
  W --> Q[Bounded queue]
  Q --> C[Consumer pool]
  C --> D[(PostgreSQL)]
  R --> D
```

- Reconciler updates worker set from provider snapshot.
- One long-lived worker per active user.
- Workers enqueue email events into a bounded channel.
- Consumer pool writes to PostgreSQL with dedupe.
- Slow users do not block fast users.

### Why this is efficient

- No global "wait all users" barrier.
- Work is parallelized per user and per consumer.
- Queue provides backpressure boundary.
- User churn handled by worker start/stop reconciliation.

### Failure handling

- Provider errors are contained per loop and logged.
- Unknown-user email fetches during churn are tolerated.
- Process shutdown is signal-driven and cancel-safe.
- DB writes use idempotent upsert/link semantics.
- Analysis enqueue occurs only after successful store of a new unique email.

## Current Commands

```bash
make up
make setup
make mock        # terminal A
make discovery   # terminal B
make watch-db
make test
make down
make clean
```

Default DB DSN:
`postgres://vigil:vigil@127.0.0.1:55432/vigil?sslmode=disable`

## Tests

- `tests/mock_provider_smoke.k`
- `tests/discovery_smoke.k`
- `tests/discovery_analysis_queue_smoke.k`
- `tests/discovery_user_churn.k`
- `tests/discovery_provider_users_error_no_remove.k`

Run all:

```bash
make test
```

## Fraud Flagging Pipeline Ideas

The current build focuses on ingestion and persistence. Next step is fraud scoring.

Candidate features to compute per email:

1. Sender/domain mismatch with historical sender profile.
2. Urgency/financial-action language patterns.
3. Thread impersonation indicators (name spoofing, lookalike domains).
4. Abnormal sending time or geo deviations.
5. Novel attachment/link signatures and reputation checks.

Suggested pipeline:

1. ingest + dedupe
2. normalize features
3. score with rules/model
4. persist score and reasons
5. expose review queue/API for analysts

## Notes

- Architecture notes: `docs/ARCHITECTURE.md`
  - includes topology + full runtime activity diagram
- Progress and design logs:
  - `PROGRESS.md`
  - `DECISIONS.md`
  - `KARL_FEEDBACK.md`
  - `COMMANDS_RUN.md`
