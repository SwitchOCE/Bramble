# Batch 1 evidence: fights read by motion

Baseline source: `1ecbce6` (`ideation/main`). Implementation branch: `ideation/declutter`.
All Bramble captures are native viewport images; no third-party screenshots are committed.

## Matched stills and label counts

`before/` holds fresh captures from an isolated `git archive 1ecbce6` checkout.
The capture hook also saves the complete combat event stream, side names, bottom side,
opponent Health, exact `next_index`, full combat result, post-fight state and exact
floor marks observed at the fight-input boundary. `declutter_stills.gd` replays that saved checkpoint
through the new UI for the corresponding `after/` image. Rules and RNG are never rerun
between the two sides of a pair. The reminder pair's after image has the reader closed,
so that the resting combat state is visible; the reader interaction is tested separately.

The `*.json` beside each before image records every visible nonempty `Label`,
`RichTextLabel` and text-bearing `Button` in the combat subtree. Hidden ancestors exclude
their descendants. Canvas text below 0.05 opacity is excluded. Buttons whose semantic
text is hidden behind a `drawn_face` count only their rendered child labels, avoiding
double-counting. Numbers count as labels. Custom drawn digits are not text nodes.
The after runner prints `labels before=N after=M` for every pair and writes `after/pairs.json`.
The combat budget is 30. All eight after pairs pass the 30-node budget.

| Scenario | Original scripted source / seed | Before / after labels |
| --- | --- | --- |
| `wording2/combat_mid` | `screenshot.gd`, `20261104` plus first surviving offset, six bot rounds | 88 → 28 (both sizes) |
| `reminder/combat_reminder` | same driver and seed, first keyword reminder | 89 → 28 (both sizes) |
| `wave1/homecoming-following-combat` | `wave1_evidence.gd`, seed `109` (first mixed shop from 101–140), controlled production actions | 82 → 24 (both sizes) |
| strong-field `rival-fight` | committed seed `72`, round `8` boundary input replay | 91 → 26 (both sizes) |

## Reproduce the captures

All Godot processes run sequentially under the shared lock and 3 GiB scope.
Launch long jobs detached and inspect `build/declutter/*.log` with short commands.

```sh
source /opt/bramble/env.sh
mkdir -p build/declutter
nohup bash -c 'flock /tmp/bramble-godot.lock systemd-run --user --scope -q -p MemoryMax=3G bash tests/ui/shots/declutter_baselines.sh /tmp/bramble-declutter-baseline "$PWD/docs/ideation/evidence/declutter/batch1"' >build/declutter/baselines.log 2>&1 &
```

The baseline runner archives `1ecbce6` to `/tmp`, injects only an evidence hook into the
existing shot scripts and a passive observer into the isolated UI adapter, imports
and compiles that project, then renders both requested sizes. The observer only
records input and chains any original observer; it changes no rules or outcomes.
It does not check out, merge, rebase or push any branch. Individual process logs are in
`build/declutter/baseline-logs/`.

## Baseline capture adaptations

Scripted scenarios and seeds are unchanged. Each fight is generated once, then the
archived UI applies events synchronously with animation disabled to the saved exact
checkpoint. Two rendered frames settle layout. This captures resting presentation
without spending hundreds of software-rendered frames advancing to the checkpoint.
Both sizes and their after images reuse that same complete event stream. The
reminder snapshot opens the original card's first keyword reminder.

The wave1 driver uses the current Cluricaun growth (`ring_size > 1`) and checks the
Swallow's returned stats against its recorded preflight stats times two. Its old
literal `1.25` growth assertion no longer holds on `1ecbce6`; the `14`/`16`
return checks are also expressed from actual preflight stats instead of assumed stats. The unchanged mixed-shop search selects seed `109` on this revision.
All original gameplay actions remain; only the required homecoming image
is rendered. Unrelated reader word-count audits are omitted from this capture job.

If an earlier checkpoint lacks raw boundary metadata, `declutter_seed_input.gd`
runs the same seed and six bot rounds without rendering, requires canonical
identity of the complete event stream, then attaches the exact captured input,
floor marks and before/after hero Health. It refuses to repair a different fight.

## Baseline adaptation: strong field

The old rival-fight screenshots used a v1 field library that the current code
rejects, and no current bundled player library exists. The new baseline replays
the committed seed-72 round-8 `human_fight_inputs[7]` boundary record through
`1ecbce6`'s current combat rules, restoring both RNG states, slots, hero effects
and side rules. `field_mode_enabled` is on. This produces a real current-rules
fight from the documented field input without inventing opponents or loading
the profiling-only measurement library. Its generated event stream is saved
with the capture so the after pair can use exactly the same fight.

## Files in the baseline commit

- `tests/ui/shots/declutter_capture.gd`: visible-text counter and serialized checkpoint hook.
- `tests/ui/shots/declutter_baselines.sh`: isolated baseline export and sequential capture job.
- `tests/ui/shots/declutter_rival.gd`: current-rules replay of the recorded field fight.
- `tests/ui/shots/declutter_seed_input.gd`: canonical-event-identity metadata repair without rendering.
- `tests/ui/shots/declutter_baseline_replay.gd`: archived-UI checkpoint replay at both sizes.
- `docs/ideation/evidence/declutter/batch1/README.md`: methods, counts and adaptations.
- `docs/ideation/evidence/declutter/batch1/before/*`: fresh baseline images and event checkpoints.

All eight baseline viewport images and their serialized checkpoints are complete.
The isolated source compile passes; the final capture logs contain no script errors.
All eight after pairs also pass the label budget. Frame strips, cold-reader scoring
and the full gate remain pending.
This README will be expanded with the final inventory and validation results.
