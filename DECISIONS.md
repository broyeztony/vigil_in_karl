# DECISIONS

## 2026-03-14

- Restarted from zero after full `.k` deletion to avoid legacy coupling.
- Chosen topology: reconciler + per-user workers + bounded queue + consumers.
- Avoided wait-all-user barrier to prevent head-of-line blocking.
- User churn handled by lifecycle reconciliation (start/stop worker by provider snapshot).
- Docker Postgres remains on host port `55432` to avoid local host DB conflicts.
- Keep `.k` files under 55 LoC to preserve composability and reviewability.
- Entrypoints use `spawn(signal recv) + wait` for signal lifecycle handling:
  - cleaner than spawn + infinite sleep loop
  - works across current local runtime and newer runtime fixes
- Provider users fetch failure must not be interpreted as empty snapshot.
  - Reconciler now skips removal/addition diff when provider users request fails.
  - Matches original Vigil behavior (log and retry on next tick).
- Removed explicit module export objects (`{ ... }`) from `lib/*.k`.
  - Karl imports already expose all top-level `let` bindings via module object.
- Entrypoints now use direct top-level `signalWatch(...).recv()`.
