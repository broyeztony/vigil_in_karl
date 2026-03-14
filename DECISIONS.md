# DECISIONS

## 2026-03-14

- Rebuild starts from empty baseline after explicit legacy reset.
- Keep Karl files very small and composable (max 55 LoC).
- Keep commits local and granular; push only when explicitly requested.
- Use Docker Postgres on host port `55432` to avoid host-Postgres collisions.
- Keep mock provider stateless for email generation to avoid shared mutable state races.
- Use periodic sync loop with per-user concurrent tasks for M1 simplicity.
