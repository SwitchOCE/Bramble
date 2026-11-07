# Ideation log

What was done, what is in flight, what is next. Newest at the bottom.

### 6 Nov 2026 — Branch created

`ideation/main` from `proto/main`, with `design/tribes-and-budget`, `design-lab/main` and `portal/main` merged in. The plan and rules are in place; the orchestrator session starts next.

### 6 Nov 2026, evening — Foundations done

Plan reviewed and reordered. Position test passed with caveats. Engine v2 merged. Woodcraft UI built on `ideation/ui`, not yet merged. Tribes designed and reviewed; slice settled in `content/SLICE.md`. Art pipeline proved. In flight: content worker, UI merge, bots and bench.

### 7 Nov 2026 — Ideation build 1

Bots at three levels, varied lobbies, sim bench and real scouting merged after two scope reviews. Build 1 exported, `latest` points at it. Bench bars not yet met: Hard among Normal (3.49 in the varied lobby, 3.73 free; bar 3.5), win spread, distinct strategies (3 of 8 by overlap); no economy line tested. Next: three fresh reviewers play it.

- 7 Nov: cloud routine trig_01MUBWuFgq4rMr3hfzhDSBHb reviews Oozes and Birds (tribes2 f51eefa).
- 7 Nov: cloud routine trig_01GVNKtoGYg1fFFU2pds8Ld9 works on placing value, branch ideation/c-placing from tribes2.
- 7 Nov, next on restart: Sol fixes freed cards in combat_screen.gd on ideation/balance (33e4406, 4 of 22 UI runs fail), then rerun the UI run, merge balance, read the two routines.
### 7 Nov 2026 — Balance step

Runaways capped, spells cheaper in rate, bodies raised, 12 units and 6 spells added with portraits, shops draw by tier odds, 40 Health. A median seat now goes out at round 14, up from 11; Dozey on 28.2% of boards, down from 82.8%; 8 of 9 builds inside 6-25% wins at 2000 games. Three bars read too close to call. Before and after: `evidence/balance-1.md`.

### 7 Nov 2026 — Balance step, after scope review

Easy plays worse, and Normal among Easy is 2.50 ±0.26. Rounds 1-2 now offer a choice of opening, level for bots at about 4.5. Mast tied to buying, Partner bounded, Chaser's finish back. Placing fails its bar: 0.14 ±0.27 at 300 games against 0.5, cause unknown; no suspect tested is shown to be it.

### 7 Nov 2026 — Oozes and Birds

Third and fourth tribes on `ideation/tribes2`: 14 units each plus Drip and the Egg, 30 portraits. Belly and Fly South in rules, fights, screens, `tools/play`, the guide, and bots at Easy, Normal and Hard, with six new builds. 200-game soak clean, every new unit seen. Spread at 120 games: the new builds win 4.9-23.1% against a fair 12.5%; none above 25%, Oozes and the Passage on the low side, and the sample is small. Not re-run: the ladder and the placing test. Numbers: `evidence/tribes2.md`.

### 7 Nov 2026 — Fight callbacks end with their cards

The build 2 gate caught a real lifetime bug: a reduced-motion death frees its card after 0.3 seconds, before the hit flash's 0.45-second callback. Godot reports the freed lambda capture before its validity guard can run. A focused regression reproduces it without added load. Flash, summon and attack tweens now belong to their cards, so freeing a card cancels its callbacks. The regression fails before the fix and passes after it; the full gate passes. No test was weakened and no log allowlist changed. A fresh deep UI run on the committed fix is required before exporting build 2.

### 7 Nov 2026 — Ideation build 2

Build 2 ships four tribes, with Oozes and Birds new, longer games, fewer runaway units and spells, an opening choice in rounds 1 and 2, and bot levels further apart. The gate on 39510b1 passes 954/954 tests. The full deep UI run at dc7d005 has 0 failed of 22; on 39510b1 nine games were clean before the detached run hit its 45-minute limit under load (exit 124). There is no full run on the fixed commit. The owner chose not to rerun and to export now; recorded in DECISIONS.md. The completed UI evidence is unchanged. The earlier 200-game soak had 0 violations. Windows, Linux and Android exports use build 1's layout under /data/bramble-builds/. No real phone tested; nobody has heard the sounds. Placing last read 0.14 ±0.27 against 0.5; the full bench on 2a12020, before the fight callback fix, is still running. Fresh reviewers are playing it; next, read their reviews and the bench and fix what they find.
- 7 Nov: playtest round 2 on 458ed0f, cloud routines A trig_01JPVRj6PM2UC9jgNeHKYDac, B trig_01NRuzaD2gCCQyndQ3TRAchR, C trig_01E6ULcbBRuEJ1QaEzx42Mt3. Tribes 5 and 6 design: trig_01AqSn8wc3i6uYQt17T5Rpuj. Placing and sticky boards: trig_01GVNKtoGYg1fFFU2pds8Ld9.
