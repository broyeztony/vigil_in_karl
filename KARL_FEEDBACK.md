# Karl Feedback from Vigil Reimplementation

Track ergonomics/performance/bugs discovered while porting Vigil.

## Entries

- `? { ... }` is recoverable-error handling only; it does not act as null-coalescing fallback.
  - Example pitfall hit during port: `env(\"X\") ? { \"fallback\" }` does not apply when env is `null`.
  - Impact: easy to misread while writing concise code; explicit `null` checks are required.
