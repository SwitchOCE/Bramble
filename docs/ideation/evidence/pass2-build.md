# Pass 2 build — 9 Nov 2026

Built on `ideation/pass2`, from `bc361fb`, using `content/pass2-a.md`, `pass2-b.md` and `pass2-c.md`, with the DECISIONS entry **“Pass 2 design: review calls (the build spec)”** taking precedence. The costing and triage cuts are applied. Local commits only; nothing pushed or merged.

## Delivered

- **Rules/engine:** gap-independent, source-excluding Pass with a permanent recipient mark and source-aware previews; Mire's once-per-fight wait skips that cycle's attack; recruiting Shy ignores ambient stats and leaves only after an aimed spell, retaining that spell's other effects. Golden Shy pays 4. Early Spoils pays 1 next-turn gold on live wins in rounds 1–4, excluding ties and ghosts. Tier 1 offers four units.
- **Optional rule:** Ask for Kin is implemented as a saved setting, off by default and applied to new games. It costs 2 gold, once per turn, counts toward paid-refresh escalation, draws up to two actual matching pool copies at normal tier odds and fills normally. Nests count as Birds. It has engine, legal-action, UI and CLI actions. Bots are not redirected to use it.
- **Content:** every amended Hunter, Hedgerow, Ooze, Bog, Fairy, Bird and Lamp Moth change is built in content JSON, with schema/registry mechanics, golden rules, details, reminder text and focused tests. Mrs Stork retains the missed-fight restriction and selects by longest away, then leftmost Nest. Tom Tit no longer flies; its full-Health/full-stats Egg support agrees across home board, scout, and engine replay, including borrowed/granted support. Golden Tern's one-turn trip agrees with its sale display.
- **Timing:** combat Acorns arrive at the next Recruit Phase after once-per-turn limits reset; actual item gains and cash/feed events drive Beadle, Pym and Hayward. Passes created by End of Turn payouts drain that same End of Turn. Shy triples conserve existing combat-earned stats without being thanked. Figgy's alternating-turn pair gives a Triple Reward, as specified; dying Elder's own releases retain its buff, and returned enemies never receive it.
- **UI/docs:** Nest Eggs show fight stats and home timers; Spoils is named in results and income, without counting queued gold twice. The guide, keyword reminders, rulebook, rulebook deltas, engine documentation and affected design examples agree with the amendments. New cards use the existing explicit pending-portrait manifest and tribe art fallback; bespoke art was outside this behavior/text pass.
- **Bots:** card hints in `content/bots/cards.json` and card-specific scores were updated for the changed cards, Egg support, Lamp Moth, Soup swallowing and deliberate Shy departures. Tribe routing and strategy files are unchanged.

## Validation

**Gate:** `source /opt/bramble/env.sh; GODOT=<capped-wrapper> ./scripts/check.sh` passes every step: tools, versions, shell, Python, content, format, lint, import, compile and tests. **1,556/1,556 Godot tests pass**, 46 Python tests pass, 433 files compile with zero failures, and the strict GUT hook reports no risky or pending tests. Local logs: `build/check/` (gate transcript copied to `pass2-gate.txt`).

**Soak:** `source /opt/bramble/env.sh; GODOT=/tmp/bramble-pass2-godot tools/checks/soak.sh 200 93100` passes, exit 0: **200 games**, seeds **93100–93299**, **3,498 rounds**, **10,989 fights**, **0 violations**, in 1,058.5 seconds. End reasons: 10,984 `board_empty`, 5 accepted `no_attacks` draws; no attack-limit or trigger-limit endings. The wrapper found no Godot problem lines. [Retained full soak report](pass2-soak.txt).

The report lists only retired Barn Owl as a slice card that never fired. Synthetic trigger aliases `on_summon`, `on_home`, `on_swallow` and `on_shy_left` were not reached by the generic alias counter; the native events and directed regressions cover those paths (including 19 Shy departures and 3 Silky triggers). Keyword coverage has report-only gaps, retained in the log; this is not a claim that every keyword fired naturally.

**Mire income watch:** slice-game observations of native Bridge Toad and Peat Cutter, excluding ghosts and borrowed text. Starting copies are counted once per fight, including goldens; normal payouts are 1 gold and golden payouts 2. Total gold includes native units emerging later, while the starting-copy rate uses only the starting cohort.

| Card | Starting copy-fights | Payouts | Total gold | Starting-cohort gold | Gold per starting copy-fight | Purchases | Rough gold per purchase |
|---|---:|---:|---:|---:|---:|---:|---:|
| Bridge Toad | 482 | 75 | 78 | 78 | 0.162 | 171 | 0.456 |
| Peat Cutter | 341 | 187 | 208 | 200 | 0.587 | 130 | 1.600 |

These are mixed-chaos soak observations, not lifetime balance estimates or a controlled before/after comparison. They do not select the “three times in all” fallback; that remains a follow-up option after player/free-choice evidence. The harness explicitly recognizes Tom Tit’s printed golden mode and Hedge Witch’s printed golden cap instead of treating them as unchanged thresholds. A metrics-observer preflight failed strict numeric casting before any games began; the casts were corrected, the full gate passed again, and the complete 200-game run above then passed.


All Godot invocations, including gate version/import/compile/test calls, used `systemd-run --user --scope -p MemoryMax=3G --`. This worker ran one Godot process at a time, without a shared lock. The temporary `GODOT` wrapper was `/tmp/bramble-pass2-godot`, after `source /opt/bramble/env.sh`:

```sh
#!/usr/bin/env bash
exec systemd-run --user --scope -p MemoryMax=3G -- /usr/local/bin/godot "$@"
```

The independent source review found and fixed three material issues: Tom Tit support missing from scout snapshots, Shy dropping existing buffs on triple formation, and golden Tern's stale sale timer. Directed regressions pin each. The merge review also corrected Mallow's R9 target: Burdock is smaller than the Kit. Older tests were updated where they asserted superseded rules; the portrait assertion still enforces either real art or an explicitly tracked pending portrait.

## Pool parity

Counted the pool actually shopped by `GameConfig.full_game()`: unit `set == "slice"`, `pool != false`, counted per printed tribe. Old-library units and created tokens are excluded.

| Tribe | T1 | T2 | T3 | T4 | T5 | T6 | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| Hunters | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Hedgerow folk | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Oozes | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Bog folk | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Fairies | 3 | 3 | 3 | 3 | 2 | 2 | 16 |
| Birds | 3 | 3 | 3 | 3 | 2 | 2 | 16 |

The [per-tier competition sheet](pass2-competition.md) rebuilds all three docs into the actual printed shop bodies, including neutrals. **96 tribal shop cards**, plus 13 neutral slice shop cards: 109 slice shop units total. There are 157 unit definitions across sets and tokens. Parity is also pinned by directed Group A/B/C tests.

## Round 9 merge benchmark

All twelve boards are on [one sheet](pass2-boards.md), backed by [explicit fixtures](pass2-boards.json): same income/climb assumptions for all six tribes, high and low rolls, slots, live layers, stored units, away Birds, Rings and inventory. These rebuild the draft hand estimates against the amended cards. They are plausible static compositions, not optimized boards or recorded shopping traces. No T6 is assumed at R9.

The existing `tools/sim/bench.gd` runs full-game campaigns and had no fixed-board JSON reader. The thin adapter `tools/sim/pass2_boards.gd` uses the existing RecruitRules, PlayerState, HeldUnits and Combat machinery. It reconstructs permanent layers from effective recruit totals so Rings, tribe bonuses and auras apply once, and asserts the reconstructed totals. Each fight uses a fresh deep-copied snapshot at round 9 and discards earned carry.

Reproduce after sourcing the environment:

```sh
systemd-run --user --scope -p MemoryMax=3G -- godot --headless \
  -s res://tools/sim/pass2_boards.gd -- \
  repetitions=100 seed=92100 out=build/pass2-boards
```

**13,200 engine fights**: every unordered pair of the twelve boards, 100 seeds (92100–92199), each seed played with sides swapped. That is 200 fights per pair and 1,000 fights per board against its five same-roll opponents. **0 trigger-limit stops, 0 attack-limit stops, 0 ties.** Cells below are strict wins as a percentage of all fights; the diagonal is omitted.

**High roll**

| Board | hunters_high | hedgerow_high | oozes_high | bog_high | fairies_high | birds_high | Win % | Tie % | Score % |
|--- |---: |---: |---: |---: |---: |---: |---:|---:|---:|
| hunters_high | — | 41.0 | 17.5 | 100.0 | 15.0 | 76.0 | 49.9 | 0.0 | 49.9 |
| hedgerow_high | 59.0 | — | 2.0 | 100.0 | 5.0 | 41.0 | 41.4 | 0.0 | 41.4 |
| oozes_high | 82.5 | 98.0 | — | 100.0 | 76.5 | 76.0 | 86.6 | 0.0 | 86.6 |
| bog_high | 0.0 | 0.0 | 0.0 | — | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| fairies_high | 85.0 | 95.0 | 23.5 | 100.0 | — | 94.5 | 79.6 | 0.0 | 79.6 |
| birds_high | 24.0 | 59.0 | 24.0 | 100.0 | 5.5 | — | 42.5 | 0.0 | 42.5 |

**Low roll**

| Board | hunters_low | hedgerow_low | oozes_low | bog_low | fairies_low | birds_low | Win % | Tie % | Score % |
|--- |---: |---: |---: |---: |---: |---: |---:|---:|---:|
| hunters_low | — | 19.0 | 96.5 | 100.0 | 70.0 | 0.0 | 57.1 | 0.0 | 57.1 |
| hedgerow_low | 81.0 | — | 98.0 | 100.0 | 100.0 | 9.0 | 77.6 | 0.0 | 77.6 |
| oozes_low | 3.5 | 2.0 | — | 100.0 | 95.0 | 0.0 | 40.1 | 0.0 | 40.1 |
| bog_low | 0.0 | 0.0 | 0.0 | — | 1.5 | 0.0 | 0.3 | 0.0 | 0.3 |
| fairies_low | 30.0 | 0.0 | 5.0 | 98.5 | — | 22.0 | 31.1 | 0.0 | 31.1 |
| birds_low | 100.0 | 91.0 | 100.0 | 100.0 | 78.0 | — | 93.8 | 0.0 | 93.8 |


[Full twelve-board matrix](pass2-benchmark-results.md) and [raw wins/ties/losses and engine snapshots](pass2-benchmark-results.json) retain cross-roll fights as well.

On these fixed compositions, Oozes lead the high rolls (86.6%) and Fairies follow (79.6%); Birds lead the low rolls (93.8%). Bog's high board loses every same-roll pairing and its low board wins 0.3%. This is evidence to carry into the next balance/player pass, not a reason to silently change the approved numbers. Rates describe these boards and fixed placements, not tribe lobby win rates or the free-choice bot bench.

## Deviations and limits

No gameplay deviation from the amended build spec. Ask for Kin remains off and was not enabled for the baseline benchmark or soak. Its opt-in behavior is covered by directed engine/UI tests; it is not yet a balance trial. **Tooling adaptation:** no existing fixed-board JSON round-robin reader was available; the new thin adapter uses the existing engine rather than the full-game campaign CLI. New bespoke portraits remain explicitly pending under the established convention.

The soak mixes baseline, slice and synthetic-chaos games by the existing seed schedule; it is a rules-invariant check, not 200 ordinary slice lobbies. The fixtures retain each designer’s finds: Bog high has one Supper while the other highs have two; Bird low has one Supper while most lows have none. These are composition comparisons, not matched shopping traces or controlled tribe-strength estimates. The static board bench cannot establish pick rates, player decisions, the frequency of rolls, or overall balance. No out-of-scope balance retuning, tribe bot routing, push or merge was performed.
