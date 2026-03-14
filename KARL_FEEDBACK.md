# KARL FEEDBACK

## Notes from this rebuild

- keep adding findings here while implementing Vigil.

## Findings (2026-03-14)

- Quoted object keys in literals are still parser-rejected in this runtime build.
  - Example hit: `{ \"Content-Type\": \"application/json\" }`
  - Workaround: `map().set(\"Content-Type\", \"application/json\")`
- `_ -> ...` lambda shorthand in object fields failed parsing in route handlers.
  - Workaround: named parameter form (`req -> ...`).
- Top-level blocking `signalWatch(...).recv()` can trigger deadlock error in CLI scripts.
  - Workaround: receive signal in a spawned task and keep main loop alive (`sleep` loop).
- `wait task ? {}` still needs parentheses in some contexts to recover cancellation as expected.
