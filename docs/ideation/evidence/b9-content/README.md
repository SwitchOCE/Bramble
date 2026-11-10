# Build 9 bounded content: Ooze tail and Fairy Ring

**Ooze decisions pass; Fairy Ring misses.** One content change per problem, one local confirmation apiece. No Actions runs, pushes, PRs or edits to DECISIONS/owner notes. `content/pass3/rates.json` is unchanged from `e8d2f1ab`, including every C value.

## Changes and triage

- `f97ee3ca`: cap Hedgerow own-stat reads before narrowing to Vector2i. Existing unit cap remains 1B. The 2.4B permanent-layer counterexample fails before and passes after.
- `25521d6a`: Soak/Toll bank the actual strike-Attack reduction, including borrowed-Attack reads. A capped 1.4B raw attacker loses zero displayed Attack on its first 250M debuff and 100M on its second. Regression fails before the fix. The traced 42,647×3 Soak payment itself was legal.
- `29d77d0b`: restore optional harness-only recruit traces (Ooze/Fairy seats); normal runs attach no observer. Copy offline analyzer from the read-only old worktree.
- `ea902d9a`: Mallow feeds **other** Hedgerow units. Old self-targeting was legal. This removes the lone-Mallow self-loop and cuts the pair from ×9 to ×3; normal/golden faces and bot predictions follow the new target rule.
- `de0c0a9a`: freeze passing Ooze results and per-source ledgers; record Fairy coverage/access before its change.
- `f43dbb40`: Sally Rings the nearest **unringed** slot, occupied or empty, including her own; golden Rings it twice. This fixes an enabler role gap while preserving counts/growth/clocks. The single confirmation misses 675, so it is not refit.

See [Ooze triage](mallow-triage.md), [ceiling](ceiling.md), [Soak](soak.md), and [Fairy role/journey/competition/measurement triage](fairy-triage.md).

## Same-seed confirmations

Both are `a35_run1`, B, no rates overrides, 32 seeds 2911001–2911032, eight shards and two local jobs. All 32 complete; no drops. Per-round active A+H is read before combat-start effects. Quantiles interpolate at `(n−1)q`; R15/R12 is the ratio of medians on the same seats alive at both rounds. The current arm’s surviving-seat distribution is not a fixed cohort; matched growth cohorts and all R6–15 distributions are in the JSON reports.

| Run / line | R12 p10 | Median | p90 | Alive / assigned | R15/R12 |
|---|---:|---:|---:|---:|---:|
| Ooze cut: oozes_engine | 769.2 | 1,067.0 | 2,516.0 | 20/21 | 4.317 |
| Ooze cut: oozes_tempo | 693.0 | 993.0 | 2,758.0 | 21/21 | 3.788 |
| Final Fairy change: fairies_ring | 223.8 | 471.0 | 2,070.4 | 17/22 | 17.140 |
| Final Fairy change: fairies_court | 561.6 | 973.0 | 2,976.2 | 17/22 | 6.490 |
| Final Fairy change: oozes_engine | 673.1 | 1,204.5 | 2,447.2 | 20/21 | 2.318 |
| Final Fairy change: oozes_tempo | 693.0 | 990.0 | 3,412.0 | 21/21 | 3.966 |

After the Ooze cut, engine p90/median is **2.358 ≤10**, and medians **1,067 / 993 ≥675**. The same decisions still pass in the final field (**2.032**, medians **1,204.5 / 990**). One native Soup/Aspic/Elder R12 outlier remains at 77,385, followed by 3,137 and 2,447 in the Ooze confirmation; this tail cut preserves the native high roll. Neither run has a captured active unit at the 1B ceiling; peak single stat is 14,507,712 across all rounds and seats.

Fairy Ring rises from **394** immediately before its change to **471**, below **675**. The supplied original build-8 Fairy reference was 480; the older Soup-fifth archived field reads 420. These are different field/cohort states, not a changed measure. After Sally’s change, Ring R12 post-start median is 785 (Fetch and other combat setup); the requested active-board median remains 471. Five of six R12 Cluricaun seats still lack a rainbow, and only one of seventeen survivors retains Sally. The enabler change improves coverage but does not reliably assemble the route. No further candidate is tested.

| Every other final line | R12 median |
|---|---:|
| birds_homecoming | 838.0 |
| birds_tempo | 730.0 |
| bog_court | 677.0 |
| bog_swamp | 907.0 |
| fairies_court | 973.0 |
| hedgerow_parish | 1,187.0 |
| hedgerow_supper | 592.0 |
| hunters_open_season | 669.5 |
| hunters_pack | 629.0 |
| oozes_engine | 1,204.5 |
| oozes_tempo | 990.0 |

## Evidence and reproduction

Local raw captures and all logs stay under `build/b9-content/`. Checked-in evidence contains all-line metrics (`ooze-results.json`, `fairy-results.json`), top-seat source attribution (`ooze-attribution.json`), coverage/uptime summaries, configs, and capture counts/SHA-256s (`capture-proof.json`). The raw eating/Elder ledger reports gross grants including transfers, not conserved net-new stats. `diagnose.py` also reports the pre/post-start distinction without changing the criterion.

```sh
source /opt/bramble/env.sh
export TMPDIR="$PWD/build/b9-content/tmp"
export XDG_CONFIG_HOME="$PWD/build/b9-content/config"
export XDG_DATA_HOME="$PWD/build/b9-content/data"
export XDG_STATE_HOME="$PWD/build/b9-content/state"
# At ea902d9a, one confirming run:
python3 tools/sim/sim_job.py local docs/ideation/evidence/b9-content/configs/ooze-other-mallow.json build/b9-content/ooze-other-mallow --jobs 2
# At f43dbb40, one confirming run:
python3 tools/sim/sim_job.py local docs/ideation/evidence/b9-content/configs/fairy-spread.json build/b9-content/fairy-spread --jobs 2
python3 docs/ideation/evidence/b9-content/analyze.py --baseline build/b9-content/ooze-other-mallow/result --arm fairy=build/b9-content/fairy-spread/result --out build/b9-content/fairy-results.json
python3 docs/ideation/evidence/b9-content/diagnose.py build/b9-content/fairy-spread/shards build/b9-content/fairy-after.json
GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s addons/gut/gut_cmdln.gd -gconfig=docs/ideation/evidence/b9-content/targeted.gut.json
python3 -m unittest discover -s tools/checks/tests -t .
```

## Checks

**335/335 GUT tests in 21 affected/adjacent core files pass**, including both old-fixture replay files, both overflow regressions, native/legacy Fairies, Mallow, bot rules, path and dial tests. After adding explicit Sally normal/golden face assertions, its 30-test file passes again. **193/193 Python gate tests pass**, including sim driver tests. Ruff check/format, gdlint and gdformat --check pass on all touched code; content check reports 167 files, 111 pool units, zero problems. No full Godot suite runs. Logs: `targeted.log`, `fairy-faces.log`, `python-gate.log`, `gdformat.log`, `content-check.log` under `build/b9-content`.

No B/C dial or numeric path endpoint changes were necessary, so the existing path pins remain unchanged and pass. The final evidence/face-test commit changes no gameplay relative to the confirming source.
