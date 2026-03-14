# DECISIONS

## 2026-03-14

- Restarted from zero after full `.k` deletion to avoid legacy coupling.
- Chosen topology: reconciler + per-user workers + bounded queue + consumers.
- Avoided wait-all-user barrier to prevent head-of-line blocking.
- User churn handled by lifecycle reconciliation (start/stop worker by provider snapshot).
- Docker Postgres remains on host port `55432` to avoid local host DB conflicts.
- Keep `.k` files under 55 LoC to preserve composability and reviewability.
