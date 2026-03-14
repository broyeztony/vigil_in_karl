# Architecture

```mermaid
flowchart LR
  P[Provider APIs] --> R[Reconciler]
  R --> W[Per-user workers]
  W --> Q[Bounded queue]
  Q --> C[Consumer pool]
  C --> D[(PostgreSQL)]
  R --> D
```

- Reconciler fetches current users and manages worker lifecycle.
- Workers poll emails independently; slow users do not block others.
- Queue provides backpressure boundary.
- Consumers persist and dedupe email events.
