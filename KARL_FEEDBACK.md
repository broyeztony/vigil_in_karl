# KARL FEEDBACK

## Findings from this rebuild

- Quoted object keys are rejected in object literals.
  - Example: `{ "Content-Type": "application/json" }`
  - Workaround: `map().set("Content-Type", "application/json")`.
- `_ -> ...` lambda shorthand inside object fields fails parsing in handlers.
  - Workaround: explicit param (`req -> ...`).
- Top-level `signalWatch(...).recv()` deadlocked in older Karl runtime builds.
  - Fixed upstream in Karl `v0.8.6`.
  - Vigil entrypoints use `spawn(() -> signalWatch(...).recv())` + `wait` for cross-version compatibility.
- Recover blocks can reject direct `[]` return in some forms.
  - Workaround: assign fallback first (`let fallback = []; fallback`).
- `match` guards using `when` are not available in current parser build.
  - Use nested `if` inside `case` branches.
- Reconcile logic should distinguish provider failure from authoritative empty result.
  - Treating fetch error as `[]` can trigger mass user removal.
  - Correct model: log error and skip reconcile diff for that cycle.
