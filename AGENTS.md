# AGENTS.md

This repository is for rebuilding **Vigil in Karl** from scratch, using the latest Karl language/runtime.

## Mission

Deliver a production-grade Karl implementation of Vigil with:

- clear architecture
- concise idiomatic Karl code
- repeatable local/dev workflow
- strong test coverage
- explicit tracking of progress, decisions, and Karl feedback

Core principle:

- Do not over-engineer. Make things as simple as possible, but not simpler.

## Canonical References (Source of Truth)

Always follow these first:

- [Karl Standard Library](https://karl-lang.org/docs/std/)
- [Karl Idiomatic Guide](https://karl-lang.org/docs/idiomatic/)

If older code/examples conflict with these docs, prefer the docs.

## Language Rules To Apply

1. Use current naming and APIs from std docs.
2. Prefer concise, expression-first Karl style.
3. Prefer stream pipelines for real flow transformations (`|`), not ad-hoc boilerplate.
4. Use channels/tasks only for explicit concurrency topology and coordination.
5. Use recover (`?`) only at clear failure boundaries.
6. Keep code short and readable; avoid trivial wrapper functions.
7. Use idiomatic shorthand where it improves clarity (`_`, concise lambdas, inline objects).
8. Prefer `match/case` with guards instead of multi-line `if/else` chains.

## Concurrency and Process Rules

1. `spawn` / `&` for tasks, `wait` to join.
2. `race` / `!&` only when first-result semantics are needed.
3. For long-lived external commands use `proc(...)`; for blocking command wrappers use `run(...)`.
4. If a process is started and expected to complete, it must be waited or explicitly aborted.
5. Prefer stream-native composition over bridging through channels unless channel semantics are explicitly needed.

## Expected Project Structure (Create if missing)

- `cmd/` entrypoints (discovery, analysis, api, mock provider, etc.)
- `internal/` domain modules (provider, store, scheduler, workers, metrics, http)
- `db/` schema + migrations + seed data
- `scripts/` dev scripts (start/stop/reset/watch-db/test)
- `tests/` integration/e2e scenarios
- `examples/` focused runnable Karl examples
- `docs/` operational notes and architecture notes

## Required Tracking Files

Keep these updated continuously:

- `PROGRESS.md`
  - milestones completed/in-progress
  - next actions
- `KARL_FEEDBACK.md`
  - language ergonomics pain points
  - runtime/perf issues discovered while implementing Vigil
  - suggested Karl improvements
- `COMMANDS_RUN.md`
  - append all meaningful commands used for setup/run/test/debug
  - include date/time + short purpose
- `DECISIONS.md`
  - architecture decisions and tradeoffs

## Git Workflow (Required)

1. Make small, local commits frequently.
2. Keep commits granular: one focused concern per commit.
3. Commit early and often during implementation, not only at the end.
4. Do not push unless explicitly requested.
5. Do not bundle unrelated refactors with behavior changes.

## Rebuild Plan (From Scratch)

1. Bootstrapping
   - initialize repo skeleton and module boundaries
   - define env/config contract
   - add Makefile + scripts for dev lifecycle
2. Storage layer
   - add schema/migrations
   - implement repository/store APIs
   - add migration and seed flows
3. Provider integration
   - tenant/user/email fetch logic
   - deterministic fake/mock provider for tests
4. Discovery flow
   - periodic user sync
   - per-user polling and enqueue
   - idempotent persistence
5. Analysis flow
   - consume queue/messages
   - dedupe/fingerprint/update statuses
6. API and observability
   - health/metrics/status endpoints
   - structured logs
7. Graceful shutdown and lifecycle
   - signal handling
   - cancel tasks and drain safely
8. Hardening
   - integration tests + load-ish tests
   - perf and memory checks

## Coding Standards for This Repo

1. Favor small, composable functions with clear boundaries.
2. Favor small, composable `.k` files. Split by responsibility early.
3. Hard limit: no `.k` file may exceed **55 lines of code**.
4. If a file approaches the limit, extract focused helpers/modules instead of growing it.
5. No unnecessary indirection or helper wrappers.
6. Keep pipeline code readable and linear.
7. Keep error messages explicit and actionable.
8. Add concise comments only when behavior is non-obvious.
9. Do not introduce speculative abstractions.
10. Prefer the simplest design that satisfies requirements and preserves correctness.

## Formatting Style (Required, Global)

This formatting style applies to all Karl code, not only streams.

Use this as the canonical visual style reference:

```karl
merge(
  listPods()
    .map(pod ->
      proc(
        "kubectl", "logs", "-f", "-n", ns, pod, "--all-containers=true", "--tail=100",
        { stdout: PIPE, stderr: NULL, stdoutType: TEXT, }
      )
      | lines()
      | filter(_ != "")
      | map(line -> { pod, level: levelOf(line), })
    )
) | forEach(event -> {
       bump(counts, event.pod, event.level)
       if now() - last >= matrixMs {
         render(counts)
         last = now()
       }
})
```

Formatting expectations (general rule of thumb):

1. Break long expressions across multiple lines instead of horizontal sprawl.
2. Align continuation lines so expression structure is visually obvious.
3. Keep nested lambdas/blocks indented and readable; avoid dense one-liners.
4. For long calls, split arguments cleanly across lines.
5. Prefer concise inline objects with trailing commas when clarity improves.
6. Keep the same visual rhythm across all constructs: calls, lambdas, objects, `if`, `match`, streams.
7. Optimize for readability first, then brevity.

Control-flow preference:

1. Prefer:

```karl
let level = match line {
  case l when l.contains("ERROR") => "ERROR"
  case l when l.contains("WARN") => "WARN"
  case l when l.contains("INFO") => "INFO"
  case _ => "OTHER"
}
```

2. Avoid long multi-line `if/else if/else` chains when a `match` with guards expresses the same logic.

## Testing Requirements

All behavioral changes must come with tests.

Minimum test layers:

1. Unit tests for domain logic and parsers/transformers.
2. Integration tests for db + provider + discovery + analysis flows.
3. End-to-end smoke for full startup, steady-state run, and shutdown.
4. Failure-path tests (timeouts, invalid input, process failures, transient db errors).

Test focus:

- stream semantics and backpressure-sensitive behavior
- cancellation/shutdown correctness
- concurrency correctness
- idempotency and data consistency

## Makefile Expectations

If missing, add major targets early:

- `make up` (start local stack)
- `make down` (stop stack)
- `make clean` (clean stack + volumes for truly fresh state)
- `make logs` (follow relevant logs)
- `make test` (all tests)
- `make watch-db` (db inspector/watch)

## Execution Discipline

Before implementing:

1. summarize relevant spec rules from std/idiomatic docs
2. list affected files/modules
3. state assumptions and risks

After implementing:

1. explain what changed
2. explain why it matches Karl docs and repo goals
3. update `PROGRESS.md`, `KARL_FEEDBACK.md`, `COMMANDS_RUN.md`, `DECISIONS.md`
4. run tests and record outcomes

## Definition of Done (Per Milestone)

1. feature works in local run flow
2. tests pass and cover key success + failure paths
3. docs/tracking files updated
4. code remains concise and idiomatic Karl
5. all `.k` files respect the 55 LoC maximum
