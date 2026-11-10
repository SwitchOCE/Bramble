# A3 / A3.5 merge verification

Main input: `f0df66bb`. Merge resolution: `7a425eb4`.

- `card_view.gd`: kept batch 2's wordless face and removed tag system. Main's two new `RULE_TAGS` entries (Swoop aura, Extra plays) have no reader/test consumer; no tag API was restored.
- `test_burner_hint.gd`: retained current 30%/60% body-stat examples and card-local assertions through the actual Details reminder. The added legacy test opens that same reminder and verifies the original flat +3/+3 and +6/+6 examples, including burn/gold values. Worked examples remain absent from resting rules text.
- `card_detail.gd`: retained main's native percentage-example parser and native Golden explanation, together with batch 2's full reader, type links and disabled-action feedback.
- Other automatic merges preserve main's legacy-library injections after prototype retirement and batch 2's end-turn motion waits/triple cues. Replay consumers retain the reviewed presentation projection, main's A3.5 fixture lineage and the new held-release regressions. Main's approved fixture updates were kept exactly; none were re-frozen here.

The historical `frozen_replay_proof` certifies its original bc9ee571..c1394db4 presentation-only delta. It does not claim that A3/A3.5's intentional gameplay/dial changes are presentation-only.

## Checks

An explicit subset contains every merge-touched `test_*.gd` under core/UI, the requested full-game/dial/replay files, and the existing word/label/feedback checks. **63 scripts, 691/691 tests, 19,149 assertions, 312.236s**; strict hook clean and no engine errors. This was not a local full-suite run.

Ruff check/format, source/tools gdlint, tests gdlint and `gdformat --check src tools tests` passed (718 GDScript files). The merged tree projected as a single commit onto `f0df66bb` passed the history-aware docs guard; no branch/history rewrite or allowlist change was made. A final committed-tree check is retained under `build/declutter-a3-merge/`.

Raw selected-test config, import logs, native log and JUnit stay under `build/declutter-a3-merge/`. Compact reproduction metadata is in [merge-a3-results.json](merge-a3-results.json). No new screenshot packet was added.
