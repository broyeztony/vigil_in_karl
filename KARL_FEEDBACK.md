# Karl Feedback from Vigil Reimplementation

Track ergonomics/performance/bugs discovered while porting Vigil.

## Entries

- `&` currently requires a call expression; spawning expression values (for loops, blocks, matches) is rejected.
  - Example hit during Vigil port: `let ticker = & for true with running = true { ... } then ()`.
  - Proposed fix: parser-level desugaring `& expr` -> `& (() -> expr)()`.
  - Impact: cleaner concurrency style, especially for background loops and expression-first Karl code.
- Quoted object keys are not accepted by the local CLI parser in object literals.
  - Example hit: `{ "from": from_email, ... }` in mock payload assembly.
  - Workaround used: create object with identifier keys, then assign reserved keys via bracket notation (`obj["from"] = ...`).
  - Impact: friction for HTTP/JSON payload code where non-identifier keys are common.
