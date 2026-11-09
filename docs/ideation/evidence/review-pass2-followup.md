# Review: pass 2 follow-up (2be2397..e041091, ideation/pass2)

Fresh scope reviewer, 9 Nov 2026. Inputs: owner's words 06a, 09a, 09c; plan = DECISIONS "Pass 2 follow-up" (orchestrator's). Read nothing after e041091. Saved by the orchestrator from the reviewer's hand-back (the reviewer can't write files).

**Counts: 17 keep, 1 cut, 3 simplify, 6 ask.**

**Moves the original problem: a little.** Rules are clearer and more correct for a playtester (Bitter timing, Clover limit, Elder Drips, Pass note, shorter details). It does not touch the newest problem (stats too small and spread; fun first), and it adds two more per-card caps. Its most useful output for the rework: the +1/+1 probe (one extra +1/+1 on every unit moves fair R9 boards 22–68 points), which supports "numbers too small".

## Cut
1. The soak still counts every Bridge Toad trigger as 1 or 2 gold (`tools/checks/soak_coverage.gd:14`, `:283-296`); committed `soak.log` shows Toad "payouts 230, gold 244" though the card no longer pays gold. Fix: drop `bridge_toad` from `_mire_gold`; note in the build doc that the line was stale.

## Simplify
- Pass note timing keys on card text ("After this pricks:" in `recruit_view.gd:567`). Key it on the `urchin` mechanic or a phase flag; text will change in the rework.
- combat.gd interface comments deleted to stay at the 1,000-line lint cap. Restore them; move the Wren-Bitter arithmetic into `CombatLanes`.
- `pass2_boards.gd:7` still defaults to the unfair `pass2-boards.json`; `pass2-bog/corrected-boards.json` has stale assumptions while the build doc says "Deviations: None". Point the default at the fair file; mark both old files superseded.

## Ask
1. Toad's +3/+3 cap covers every permanent buff (Supper, Pinch, Tiddy gifts), not only its own growth; the card face reads as own growth. Keep the Dozey rule, or cap only its own growth.
2. Bot placement still gives the Toad +15 for standing across the highest-Attack enemy, the deleted gold condition (`src/core/bots/bot_lanes.gd:279-284`); live in the plain arm that measured Bog.
3. Bot keep hints changed without a plan line (Toad 4→6, Committee 14→12); hinted arm skipped.
4. Build doc omits big lobby moves since the last plain baseline (same 400 seeds): Birds first 13.5%→4.9%, mean place 4.47→5.10 (the 9 Nov "Birds bar is met" no longer holds); Hunters first 7.6%→17.6%; Fairies picked by 0.9% of seats. First-place spread widened to 4.9%–25.3% (was 7.6%–20.4%). No pass-2-only lobby run separates pass 2 from this step.
5. "Warty Nan: watched in rounds 1–4" has no output.
6. Build doc cites "an independent source review" and "a second source/data review" that aren't in the repo.

## Evidence honesty, Bog bar: honest
Recomputed from 3,200 player rows: Bog first 12.80% (95% interval up to 16.1%) vs 22% trigger; mean place 4.30 (interval from 4.09) vs 4.0. Neither fires. R9 matrix reproduces. No code change between measured c50f6c8 and e041091; hashed sources match except `project.godot` (rewritten by the release-bench build on purpose) and three generated driver files.

## Sound base for the rework: yes, once the cut is fixed
Caps are data fields; persistence code is generic; fixtures and audit script can be thrown away.

## Gaps found
- Counters into Bitter: a counter's bonus is removed after Bitter applied its loss (`combat_reactions.gd:98-102`, `board_unit.gd:119`), so a 2-Attack counter with +2 into Bitter 3 ends at 0 Attack, not 1. Old timing did the same; the test checks only the wall.
- Bitter fires before "whenever this attacks" effects, but rulebook 9.6.0 says "after the attack's own bonuses". Latent: no pool card buffs itself on attack.
- Log order: Bitter's stat event now precedes the "attack" event; combat log and replay reading not checked.
- No before-and-after on the fair bench (levels, not this step's effect).

## For the rework (not findings against this step)
combat.gd is at its line cap; flat-subtraction keywords (Bitter, Toll-Bard, Hex) need rescaling with stats; fixtures and audit hard-code 62 gold; keep the sensitivity harness.

## Item table (verdicts)
1 Bitter first: keep. 2 Wren Bitter: keep. 3 Toad growth: keep. 4 Toad cap covers all buffs: ask. 5 Prima Donna Bitter 2: keep. 6 Peat Cutter three times: keep. 7 Lifetime persistence: keep. 8 Committee 5/7: keep. 9 Clover twice a turn: keep. 10 Elder Drips: keep. 11 Spoils tie test: keep. 12 Pass note timing: simplify. 13 Details trims, golden Shy: keep. 14 Dead code removed: keep. 15 combat.gd comments deleted: simplify. 16 Bot keep hints: ask. 17 Bot Toad placement: ask. 18 Soak Toad gold: cut. 19 Fair R9 fixtures and audit: keep. 20 +1/+1 sensitivity: keep. 21 Old fixtures default: simplify. 22 400-lobby plain run and Bog verdict: keep. 23 Lobby shifts not reported: ask. 24 Nan watch: ask. 25 Unrecorded reviews: ask. 26 Test repairs: keep. 27 Evidence files: keep.
