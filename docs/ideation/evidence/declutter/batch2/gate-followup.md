# Batch 2 cloud-gate and independent-review follow-up

Input main: `bc9ee571`, merged as `6e5ce6db`. No frozen fixture file or hash was edited. Replay proof and its exact output are retained in commit `f216e973` and in `tools/checks/frozen_replay_proof.{py,json}`.

## Frozen replay proof

The same harness first reproduces the archived baseline's raw hashes/bytes, then compares every complete old/current structure. Only three added `ring_dance` presentation fields (`moved_count`, `from_ring`, `to_ring`) and the exact old/new Pass reminder in combat-unit `keyword_text` are projected. No other text, field, event order, input, result, carry, standing or log is ignored. The reminder alias is required by the requested rightmost wording; it does not change the Pass mechanic.

```text
BASELINE bc9ee571: raw frozen fidelity PASS (4 field, 8 pool, 12 legacy)
IDENTICAL: fixture input bytes and capture harness
PROJECTION: ring_dance only moved_count/from_ring/to_ring (19 snapshots)
PROJECTION: exact mandated Pass reminder alias in unit keyword_text (18 occurrences)
COMPARE: all 24 complete cases PASS; all other values/order retained
COVERAGE: 264 fights/results, 244 game inputs + 20 fixed inputs, 18763 ordered events, 332 carry entries, 32 standings rows, 4 complete game logs
FROZEN FIXTURES: unchanged; no hashes re-frozen
```

The three failing replay files now compare this proven historical contract against their unchanged fixtures. Projection boundary tests additionally verify that damage, carry, order, unknown fields and unrelated reminder text remain detectable. The wording test pins the new rightmost reminder; the geometry test retains exact related slots but rejects the removed Highlighted caption (spec §2.2 line 69).

## Review disposition

| Finding | Result |
| --- | --- |
| Disabled Play loses no-target reason | Disabled action displays the changing reason at both sizes; an unavailable aimed play shakes/flashes the selected card. Repeated tutorial hints stay removed. |
| Removed change notices have no feedback | Fresh events drive a shared-clock helper. Discover-empty and failed summons retain rare failure prose. Poach/return, kisses/transforms, Shy departure/queued acorns, Nest replacement, Pipkin use and item combining receive short moving/flash cues. Repeat renders do not replay them. Shy is one press, per §2.3. End-turn clocks run in parallel; skipping emits completion once. |
| Opponent tier knot hidden | Restored one visible numeral per living opponent, as §2.5 keeps. The orchestrator raised only overview/lobby caps to 47/46, admitting exactly seven restored tier nodes over previous counts40/39. One numeral is less to read than up to six pips per opponent. Own/out/ghost knots remain absent; every numeral counts. |
| Ring stack digits hidden | **Left for the orchestrator.** Spec §2.2 line 73 explicitly moves exact stack counts/totals to the one-tap unit/empty-slot reader, leaving a Ring frame. Existing regression checks exact 2, 36 and 12345 counts in that reader. §2.5 also keeps scout floor visuals digit-free. |
| History size bypass | Every introduced docs blob is checked across the explicit range, including later shrunk/deleted versions, index and worktree. Distinct blob IDs are counted once; exact existing exemptions remain unchanged. |
| Unsafe inferred base | No base is inferred. All gate modes require `--base`; missing/invalid bases fail. CI fetches full history and explicitly supplies PR/manual/gate review bases, rejecting an empty/synced gate range. No docs-only PR path-filter behavior was changed. |
| Click preview ask | The evidence README now states the true `bc9ee571` baseline: native pass-3 Bird multiplier forecasts only; no future homecoming-trigger forecast and no Click mechanic in that baseline. No away-tray code change. |

## Verification

Only affected files were tested. No local full suite was run:

- Five affected core files plus touched/relevant UI paths: **128/128 tests, 6,481 assertions, 122.237s**, strict hook clean, no engine errors.
- Projection-boundary tests: **3/3, 14 assertions, 0.424s**, strict hook clean.
- Size/docs-only regression tests: **27/27**, 4.254s; ShellCheck and Bash syntax passed.
- Ruff check/format, `gdlint src tools`, `(cd tests && gdlint .)`, and `gdformat --check src tools tests` pass.

After the orchestrator's numeral decision, the six affected UI files passed a further **46/46 tests, 2,087 assertions, 23.23s**, strict clean. The final tile-word/label tools count every restored numeral. Both sizes retain zero current-production tile words: overview47/47, lobby46/46, scout30/40, natural-Birds37/40 (count/cap). The open reader is reported separately at58; the ten-unit hand is68 with every stat bead retained. No other cap or label exclusion changed. Legacy non-shipped fixture names remain counted unchanged (34 recruit/28 scout raw nodes).

The repaired history scan correctly rejects this unsquashed branch's old oversized artifacts. No exemption or history rewrite was used. The intended squash-tree check is recorded below; raw captures, native logs and JUnit stay under `build/replay-proof/` and `build/declutter-b2-review/`.


## Squash-size validation

For the complete code-fix range `bc9ee571..1ab6929c`, the repaired history guard
correctly exits 1: original oversized PNG versions remain reachable, with
159,740,262 unallowlisted introduced bytes. Slimming endpoint files cannot erase
those earlier blobs.

An unreferenced one-commit squash with that exact tree and parent `bc9ee571`
(`f1ea3ad22dc561ce559ab9e1106583bcb70273f6`) passed the same guard (exit 0):

```text
docs-size: passed (2 MB per introduced blob; 30 MB total distinct introduced blobs)
```

Only an object was created to validate the planned landing shape; no branch was
moved, no existing history was rewritten, and no allowlist entry was added.
The orchestrator should land via its planned squash; gating this unsquashed
historical branch is expected to fail the new guard. Raw checks are in
`build/declutter-b2-review/size-history.log` and `size-squash.log`.
