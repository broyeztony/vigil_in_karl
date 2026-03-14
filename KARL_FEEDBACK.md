# KARL FEEDBACK

## Findings from this rebuild

- Quoted object keys are rejected in object literals.
  - Example: `{ "Content-Type": "application/json" }`
  - Workaround: `map().set("Content-Type", "application/json")`.
- `_ -> ...` lambda shorthand inside object fields fails parsing in handlers.
  - Workaround: explicit param (`req -> ...`).
- Top-level blocking `signalWatch(...).recv()` can deadlock in CLI scripts.
  - Workaround: run signal recv in spawned task and keep main alive.
- Recover blocks can reject direct `[]` return in some forms.
  - Workaround: assign fallback first (`let fallback = []; fallback`).
- `match` guards using `when` are not available in current parser build.
  - Use nested `if` inside `case` branches.
