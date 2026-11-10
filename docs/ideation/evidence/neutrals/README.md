# A3 neutral evidence

`role-summary.json` contains the compact constructed role results: 32 paired
seeds per normal/golden combat case (384 fights), alternating orientation, plus
actual recruit actions for Burner, Click and scaled Echo. Combat controls remove
only the target neutral's native mechanic, retaining its body and every other
card. The recruit reference values without support are calculated, not simulated
control arms. These cases show the stated roles; their win counts are not field
strength estimates.

Reproduce with `tools/sim/neutral_roles.gd`; fixed recipes are in
`tools/sim/recipes/neutral-roles.json`. Raw captures and per-seed reports stay local:

- `build/neutrals/neutral-roles.fights.jsonl` — 384 FightCapture records.
- `build/neutrals/neutral-roles.report.json` — paired samples and recruit event logs.
- `build/neutrals/roles.log` — detached harness run.
- `build/neutrals/final.*` — explicitly selected compatibility tests.

`checkpoint-tests.json` records the earlier failing nested recall counterexample,
before FIFO landing completion was implemented. It is historical, not the final
validation result. No frozen replay fixture was changed for A3.

Review follow-up: `review-validation.json` records the affected 35-script checks
(387 passing tests), the frozen replay preserved by the native-Ooze guard, and
four report tests. `stone-soup-confirm.json` is the compact original-32-seed B
confirmation on `a2504fee`: early arrival fails at 17/32; survival and R12 presence
pass. Full per-seat shopping telemetry and captures remain under
`build/neutrals/soup-confirm.*`; the job log is
`build/neutrals/review-fixes/confirm.log`. No raw captures are tracked.
