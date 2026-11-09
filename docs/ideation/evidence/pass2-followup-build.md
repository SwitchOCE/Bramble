# Pass 2 follow-up build — 9 Nov 2026

Status: complete. Implementation, gate, soak, parity, fair R9 measurement and the required 400-lobby plain bar are complete; the Bog threshold verdict is recorded below.

Built on `ideation/pass2` after fetching origin and merging `origin/ideation/main` (`eebef0e`), then `origin/ideation/c-pass2-bog-review` (`2be2397`). Both merges were clean. The incoming main already includes the fixture correction for the plain Hedge Witch's tier cap. The DECISIONS entry **“Pass 2 follow-up: review calls, the Bog fix and the Committee”** controls the build.

## Delivered

- Bitter reduces the leading attacker's Attack before damage, after its own attack bonuses. Pack joiners keep their Attack. The floor is 1; Prima Donna's per-enemy allowance is spent at declaration, including a cancelled attack. Counter, pounce, multi-strike and borrowed-Attack regressions cover the timing. The rulebook and reminder explain the rule.
- Bridge Toad grows permanently by +1/+1 to a +3/+3 ceiling (golden +2/+2 to +6/+6), without a once-per-fight limit. Prima Donna has Bitter 2 (golden 4). Peat Cutter pays once a fight, three times in all; lifetime payment counters survive combat snapshots and carry back. Tiddy Mun and Beadle retain their approved pass 2 behavior. Mire's wait remains.
- Standing Committee is 5/7 (golden 10/14), with partial and full-line gifts as decided. Clover's two buffs are shared across recruiting and the following fight, then reset for the next turn.
- Elder Ooze buffs its own Wobbly Drips without replaying Belly-release effects. Live Early Spoils ties pay neither side. Combat Pass notes resolve immediately, while recruiting Pass notes say End of Turn. Redundant Details, duplicate golden Shy wording, stale Pass comments and obsolete shop-soaking code are removed.
- Bot edits are the Bridge Toad and Committee card hints only. Tribe routing is unchanged.

An independent source review found no material issue. Its fixture clarification was applied: Hedgerow high's Kit received Clover's recruiting gift on a prior turn, so Clover starts R9 with no uses spent.

## Validation

**Gate: passed**, with `PARITY_STRICT=1`: tools, versions, shell, Python, content, format, lint, import, compile, parity and tests. **1,608/1,608 Godot tests pass**, with 24,384 assertions and no risky/pending tests; 50 Python tests pass. All 447 scripts/resources compile. [Full gate transcript](pass2-followup/gate.log).

**Strict parity: passed**, using the game's actual full-game shop pool, excluding tokens and other sets. [Loader output](pass2-followup/parity.log).

| Tribe | T1 | T2 | T3 | T4 | T5 | T6 | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| Hunters | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Hedgerow folk | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Oozes | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Bog folk | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Fairies | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Birds | 3 | 3 | 3 | 3 | 2 | 2 | 16 |

There are 96 tribal and 13 neutral shop cards (109 total).

**Soak: passed**, `tools/checks/soak.sh 200 94100`, exit 0: **200 games**, seeds **94100–94299**, **3,475 rounds**, **10,951 fights**, **0 violations** in 1,055.8 seconds. End reasons were 10,949 `board_empty` and two accepted `no_attacks` draws. **Attack-limit stops: 0. Trigger-limit stops: 0.** Maximum fight length was 258 events. The wrapper found no Godot problem lines. [Full soak report](pass2-followup/soak.log).

The existing mixed-rules harness exercises legacy, real slice and synthetic-coverage games; it is a rules soak, not the free-choice balance estimate. Bitter fired 1,701 times, Mire 4,072, Bridge Toad 233, Tiddy 272, Elder 1,746 and Clover 273. Coverage gaps remain report-only and are retained in the full log; directed regressions cover the amended paths as well.

Every Godot process is run sequentially by this worker inside `systemd-run --user --scope -p MemoryMax=3G --`, after `source /opt/bramble/env.sh`; no shared lock is used.

The measured code is frozen at `c50f6c8` (rules/cards `3469742`, reminders/cleanup `b4d547e`, fair fixtures/tooling `845f8c3`, isolated Tiddy fixtures `c50f6c8`). Fixture history was clarified in `b86c11d` before the R9 run, with no stat or cost changes: Ooze high's carried gold funds its R8 Elder purchase, and its exact R1–R9 banks and two Aspic feeding turns are listed. Measurement output is retained in `pass2-followup/`; large intermediate campaign CSVs remain under `build/sim/pass2-followup/`.

Reproduction, after sourcing the environment and exporting `GODOT` as the capped wrapper:

```sh
PARITY_STRICT=1 ./scripts/check.sh
tools/checks/soak.sh 200 94100
"$GODOT" --headless -s res://tools/sim/pass2_boards.gd -- \
  input=res://docs/ideation/evidence/pass2-followup-boards.json \
  repetitions=100 seed=92100 sensitivity=1 out=build/pass2-followup-boards
tools/sim/bench.sh --cores 1 --seed 1 --timeout 86400 \
  --out /absolute/path/to/run --report /absolute/path/to/report.md free_choice_plain=400
```

The lobby run uses the official Godot 4.7.2 Linux release template and an immutable PCK produced by `tools/sim/build_release_bench.py`, through a capped wrapper as well. Core/content scripts are copied unchanged; only the driver's SceneTree lifecycle is adapted to a Node entry point. The editor/release seed-1 equivalence check passed before the 400-lobby run. Its source/runtime hashes and provenance are retained with the results.

## Fair R9 benchmark

The [one-sheet boards](pass2-followup-boards.md) and [fixtures](pass2-followup-boards.json) replace the historical fixture assumptions for this measurement. Every board has an itemized net spend of 62–65 gold, high rolls have two Suppers each and low rolls none, and each board has a named non-Supper growth layer. Low boards include eight paid Pinches; Bog low's Toad receives none and is capped at 4/6. Held bodies, temporary purchases and sales, spells, upgrades and paid refreshes all appear in the ledgers. Explicit extra-income assumptions fund Ooze high's 65 and Fairy high's 63 gold. These are constructed boards, not recorded shop traces or estimates of composition probability.

`python3 tools/sim/audit_pass2_followup.py` passes all twelve inventories, gold ledgers, stat receipts, Supper parity, Belly layers, Shy immunity and the Toad cap.

**Completed: 25,200 engine fights.** The baseline plays all 66 unordered pairs of twelve boards, 100 seeds (92100–92199), with sides swapped: **13,200 fights**, 200 per pair. Sensitivity adds **12,000 fights**, 1,000 for each boosted board against its five same-roll opponents. **0 attack-limit stops, 0 trigger-limit stops, 0 ties** across both runs; every fight ended `board_empty`. Cells below are strict win percentages; same-roll totals each use 1,000 fights per board. [Full twelve-board matrix and sensitivity](pass2-followup/r9-results.md), [raw counts and reconstructed snapshots](pass2-followup/r9-results.json), [run log](pass2-followup/r9.log).

**High roll**

| Board | hunters_high | hedgerow_high | oozes_high | bog_high | fairies_high | birds_high | Win % | Tie % | Score % |
|--- |---: |---: |---: |---: |---: |---: |---:|---:|---:|
| hunters_high | — | 89.0 | 24.0 | 41.5 | 15.0 | 76.0 | 49.1 | 0.0 | 49.1 |
| hedgerow_high | 11.0 | — | 48.0 | 87.5 | 29.5 | 48.5 | 44.9 | 0.0 | 44.9 |
| oozes_high | 76.0 | 52.0 | — | 75.5 | 64.5 | 63.0 | 66.2 | 0.0 | 66.2 |
| bog_high | 58.5 | 12.5 | 24.5 | — | 0.5 | 45.5 | 28.3 | 0.0 | 28.3 |
| fairies_high | 85.0 | 70.5 | 35.5 | 99.5 | — | 94.5 | 77.0 | 0.0 | 77.0 |
| birds_high | 24.0 | 51.5 | 37.0 | 54.5 | 5.5 | — | 34.5 | 0.0 | 34.5 |

**Low roll**

| Board | hunters_low | hedgerow_low | oozes_low | bog_low | fairies_low | birds_low | Win % | Tie % | Score % |
|--- |---: |---: |---: |---: |---: |---: |---:|---:|---:|
| hunters_low | — | 0.0 | 39.5 | 5.0 | 88.0 | 0.0 | 26.5 | 0.0 | 26.5 |
| hedgerow_low | 100.0 | — | 98.0 | 100.0 | 100.0 | 100.0 | 99.6 | 0.0 | 99.6 |
| oozes_low | 60.5 | 2.0 | — | 10.5 | 100.0 | 25.5 | 39.7 | 0.0 | 39.7 |
| bog_low | 95.0 | 0.0 | 89.5 | — | 100.0 | 25.0 | 61.9 | 0.0 | 61.9 |
| fairies_low | 12.0 | 0.0 | 0.0 | 0.0 | — | 39.0 | 10.2 | 0.0 | 10.2 |
| birds_low | 100.0 | 0.0 | 74.5 | 75.0 | 61.0 | — | 62.1 | 0.0 | 62.1 |

**+1/+1 sensitivity (same roll)**

One board at a time receives combat-only +1/+1 on every starting fighter, recursively including held bodies and Eggs. Away Bird source stats stay fixed; no direct gift is applied to later summons. Five same-roll baseline opponents, identical seed pairs and swapped sides; carry discarded. No recruiting buff or economic spend is claimed.

| Board | Base win % | +1/+1 win % | Change (pp) |
|---|---:|---:|---:|
| hunters_high | 49.1 | 99.1 | +50.0 |
| hunters_low | 26.5 | 87.6 | +61.1 |
| hedgerow_high | 44.9 | 94.1 | +49.2 |
| hedgerow_low | 99.6 | 100.0 | +0.4 |
| oozes_high | 66.2 | 99.8 | +33.6 |
| oozes_low | 39.7 | 97.4 | +57.7 |
| bog_high | 28.3 | 96.4 | +68.1 |
| bog_low | 61.9 | 93.0 | +31.1 |
| fairies_high | 77.0 | 99.2 | +22.2 |
| fairies_low | 10.2 | 33.1 | +22.9 |
| birds_high | 34.5 | 90.2 | +55.7 |
| birds_low | 62.1 | 91.9 | +29.8 |

Sensitivity fights: 12000. Terminations: {"board_empty":12000}.

Bog now wins 28.3% high and 61.9% low on these fair same-roll boards; its high board beats Hedgerow high 12.5%. Birds low is 62.1%, while Hedgerow low's assumed Dozey growth produces 99.6%. The +1/+1 shifts are large (22.2–68.1 percentage points except the already dominant Hedgerow low), showing strong sensitivity to starting stats. Combat breakpoints are a plausible explanation, not an isolated causal finding. A second source/data review verified winner orientation, swapped legs, fresh copies, exactly one boost per starting body, all per-pair totals and the reported percentages. This is a threshold probe of the listed boards, not a tribe ranking or a reason to retune cards. The completed plain lobby rates appear beside both R9 rolls below.


## Plain free-choice lobby bar

**Completed: 400 lobbies, 3,200 seats**, seeds **1–400**, in **4904.2 seconds (81.7 minutes)**. The original run finished without being restarted. All 400 seeds have exactly eight unique seats and places 1–8; no runtime errors were logged.

The immutable Godot 4.7.2 release pack uses the gated code at `c50f6c8`. The editor/release seed-1 pilot matches players, rounds, cards, turns excluding timing, and profile rows. [Provenance and runtime hashes](pass2-followup/provenance.json), [full lobby report](pass2-followup/free-choice.md), [compressed player rows](pass2-followup/free_choice_plain.players.csv.gz), [machine-readable rates](pass2-followup/free_choice_plain.summary.csv), [completion log](pass2-followup/free-choice.log).

Each seat uses free choice with zero tribe priors and no routes; buy/keep hints and text_value are bypassed, while other live mechanic evaluation remains. Pick rate is the fraction of all 3,200 seats ending with that tribe as a strict majority of non-token starting-board units. Neutral non-token units count in the majority denominator; away Birds and Belly contents do not add slots. Mean place and first rate condition on that final label. The mixed/no-majority row remains in the pick denominator. Brackets are 95% lobby-clustered ratio intervals from the existing summarizer (exploratory, without a multiple-comparison correction). R9 columns show the same-roll baseline win rate followed by that board with +1/+1, against unchanged opponents.

| Tribe | Seats | R9 high base → +1/+1 (%) | R9 low base → +1/+1 (%) | Pick rate (95%) | Mean place (95%) | First rate (95%) |
|---|---:|---:|---:|---:|---:|---:|
| Hunters | 705 | 49.1 → 99.1 | 26.5 → 87.6 | 22.03% [20.45%, 23.62%] | 3.89 [3.75, 4.03] | 17.59% [15.30%, 19.87%] |
| Hedgerow folk | 281 | 44.9 → 94.1 | 99.6 → 100.0 | 8.78% [7.76%, 9.81%] | 3.75 [3.51, 3.99] | 25.27% [20.56%, 29.98%] |
| Oozes | 283 | 66.2 → 99.8 | 39.7 → 97.4 | 8.84% [7.73%, 9.96%] | 4.76 [4.52, 5.01] | 9.19% [6.01%, 12.37%] |
| Bog folk | 336 | 28.3 → 96.4 | 61.9 → 93.0 | 10.50% [9.35%, 11.65%] | 4.30 [4.09, 4.51] | 12.80% [9.49%, 16.11%] |
| Fairies | 29 | 77.0 → 99.2 | 10.2 → 33.1 | 0.91% [0.58%, 1.24%] | 3.79 [2.94, 4.65] | 31.03% [14.72%, 47.35%] |
| Birds | 371 | 34.5 → 90.2 | 62.1 → 91.9 | 11.59% [10.42%, 12.77%] | 5.10 [4.91, 5.29] | 4.85% [2.74%, 6.97%] |
| Mixed / no majority | 1195 | — | — | 37.34% [35.69%, 39.00%] | 4.86 [4.76, 4.97] | 9.12% [7.76%, 10.49%] |

**Bog threshold verdict: NEITHER TRIGGER FIRES.**

- First-rate trigger (>22%): **no**; 12.80% versus 22%, with 95% interval [9.49%, 16.11%].
- Mean-place trigger (<4.0): **no**; 4.2976 versus 4.0, with 95% interval [4.09, 4.51].

The decision uses point estimates for these triggers; the intervals show their precision. No cards are retuned in this evidence stage.

The optional hinted arm is omitted as expensive: this plain run took 81.7 minutes, and the [previous hinted 400](baseline-step2/after-birds-pass1/free-choice.log) took about 82 minutes. The required plain bar is complete.

## Deviations

None in the implementation. The optional hinted arm is omitted for the runtime reason above. The required plain bar and Bog verdict are complete. Nothing has been pushed.
