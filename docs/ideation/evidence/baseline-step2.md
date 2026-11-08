# Step 2 baseline: measure before designing

8–9 November 2026. Measurement code `4965d3e`, based on merged `a29c19d`: arm B default and feedback5. No additional game rules or content changes. Reproduce with [these commands](../../../tools/sim/STEP2.md).

The full-game slice pool has 98 shop cards before lobby rotation. Every tribe misses 16 at 3/3/3/3/2/2. Neutrals have no target. The gate warns; `PARITY_STRICT=1` fails.

| Tribe | Total | T1/T2/T3/T4/T5/T6 |
|---|---:|---|
| Birds | 16 | 4/4/2/3/1/2 |
| Bog folk | 14 | 3/3/3/2/2/1 |
| Fairies | 14 | 3/3/2/2/2/2 |
| Hedgerow folk | 11 | 3/1/3/2/1/1 |
| Hunters | 14 | 3/3/3/2/2/1 |
| Oozes | 16 | 3/3/3/2/1/4 |
| Neutrals | 13 | 3/4/2/2/1/1 |

Benchmark: 72 supplied boards, 180 cross-tribe pairs, seeds 1–200 in both orientations: 72,000 real-engine fights, 2,000 per board. Cells show **strict win % (guessed→measured rank)**; ranks use wins plus half draws. Only four fights drew.

| Tribe | Round | Average | High | Low |
|---|---:|---:|---:|---:|
| Birds | 3 | 0.7% (6→6) | 0.0% (6→6) | 80.0% (1→1) |
| Birds | 6 | 0.0% (6→6) | 5.1% (6→6) | 19.9% (6→5) |
| Birds | 9 | 1.4% (6→6) | 0.0% (6→6) | 17.6% (6→6) |
| Birds | 12 | 0.4% (6→6) | 0.0% (6→6) | 1.1% (6→6) |
| Bog folk | 3 | 41.1% (5→5) | 25.7% (3→5) | 15.2% (4→6) |
| Bog folk | 6 | 49.2% (4→4) | 40.2% (5→4) | 2.5% (5→6) |
| Bog folk | 9 | 46.1% (5→4) | 28.1% (5→5) | 21.1% (5→5) |
| Bog folk | 12 | 23.1% (5→5) | 20.0% (5→5) | 35.5% (3→5) |
| Fairies | 3 | 65.1% (1→2) | 98.7% (1→1) | 70.0% (3→2) |
| Fairies | 6 | 98.1% (1→1) | 94.1% (1→1) | 100.0% (1→1) |
| Fairies | 9 | 93.8% (1→1) | 86.2% (1→1) | 60.1% (2→3) |
| Fairies | 12 | 45.1% (1→4) | 68.1% (1→3) | 44.2% (4→4) |
| Hedgerow folk | 3 | 90.4% (3→1) | 50.2% (4→3) | 35.1% (6→5) |
| Hedgerow folk | 6 | 22.4% (5→5) | 60.7% (3→3) | 56.3% (3→3) |
| Hedgerow folk | 9 | 75.6% (3→2) | 82.9% (4→2) | 65.4% (3→2) |
| Hedgerow folk | 12 | 85.9% (2→2) | 91.4% (2→1) | 70.3% (5→2) |
| Hunters | 3 | 54.5% (2→3) | 45.9% (5→4) | 44.2% (2→4) |
| Hunters | 6 | 52.0% (3→3) | 18.6% (4→5) | 51.4% (4→4) |
| Hunters | 9 | 30.3% (2→5) | 61.6% (2→3) | 80.3% (1→1) |
| Hunters | 12 | 54.4% (3→3) | 50.4% (3→4) | 83.4% (1→1) |
| Oozes | 3 | 48.1% (4→4) | 79.5% (2→2) | 55.5% (5→3) |
| Oozes | 6 | 78.2% (2→2) | 81.2% (2→2) | 69.9% (2→2) |
| Oozes | 9 | 52.8% (4→3) | 41.1% (3→4) | 55.5% (4→4) |
| Oozes | 12 | 91.0% (4→1) | 70.0% (4→2) | 65.5% (2→3) |

Supplied slots, stat totals, goldens, Bellies and supported counters are preserved. Tests check all 72 starting boards and aura removal. Missing state affects 27 boards: all 12 Fairies, 8 of 12 Birds, 4 Bog folk and 3 Hedgerow folk boards. Hunters and Oozes have none. Missing state includes: full Ring amounts/layouts, Nest identities/away buffs/goldens, paint identities, prior kisses and Conkers ammunition. Known prose values load; uncertain state is itemized in [limitations](baseline-step2/benchmark.limitations.json). Snapshots ignore heroes and economy; bots retain card hints, heroes and ordinary five-tribe rotation.

Free choice: 400 lobbies, seeds 1–400 (3,200 seats), using the seed-validated official release pack. Equal zero tribe priors; no named routes. Labels require a strict majority of occupied final fight-start slots; Eggs occupy neutral slots, away Birds/Bellies add none. Mixed/tied/empty boards are `no_tribe`. Pick uses all 3,200 seats; placement and first rate condition on the label. The pick column reflects hand-written buy/keep card hints as well as card strength; it measures this policy.

| Final tribe | Seats | Pick | Mean place | First |
|---|---:|---:|---:|---:|
| Birds | 1 | 0.03% | 3.00 | 0.0% |
| Bog folk | 612 | 19.1% | 4.47 | 14.9% |
| Fairies | 103 | 3.2% | 3.51 | 21.4% |
| Hedgerow folk | 123 | 3.8% | 3.85 | 25.2% |
| Hunters | 833 | 26.0% | 4.73 | 10.6% |
| Oozes | 210 | 6.6% | 4.64 | 8.6% |
| no_tribe | 1318 | 41.2% | 4.49 | 11.4% |

Birds are last in 10/12 cells. The four clean Birds boards are R3 high, R3 low, R9 low and R12 low, ranked 6, 1, 6 and 6 respectively: the weak result survives on those clean snapshots. R6 low improves to fifth on a limited board; neutral-assisted R3 low wins.
Oozes R12 average win 91.0%, first versus guessed fourth: the audit’s weak-top claim is unsupported by this Belly snapshot.
Hedgerow R12 low wins 70.3%, second versus guessed fifth, on a limited board with missing Acorn/Conkers state; this is not a full-mechanics claim.
Fairies R12 average fall to fourth versus guessed first on limited boards, as do all Fairies results here; missing Ring/paint state limits that late-game claim.
Only one final board has a Birds majority; its placement average rests on one seat. Another 41.2% have no strict tribe majority, covering several different board types.

Gate: all steps pass, including 1,472 Godot tests. [Raw fights and summaries](baseline-step2/benchmark.summary.json) retain rates, draws, guesses and per-pair results; [gate log](baseline-step2/gate.log).

## After Birds pass 1

*Measured on `8895189`, before the pass 1 fixes (`c1864d2`) and pass 2. It is the step 3 checkpoint, not the pass 2 baseline; pass 2 is re-measured on its own tree.*

9 November 2026. Merged `origin/ideation/main` (`8895189`) in `07fbdb0`. Birds now meet 16 cards at 3/3/3/3/2/2; the full pool remains 98. The other five tribes still warn. Strict parity remains opt-in until pass 2 merges.

Both arms ran seeds 1–400 (400 lobbies, 3,200 seats each) on the merged tree. Each arm matched editor and official release player/round/card CSVs byte for byte at seed 1. `free_choice` retains buy/keep hints, so its pick column reflects those hints. `free_choice_plain` bypasses them, including `text_value`; generic text falls back to 1.5 × tier, with stats and live mechanic evaluation retained. The plain arm still runs four hand-written per-card valuators: Barn Owl and Redwing (`BotContent5`), Charcoal Burner (`BotBurner`) and `BotCommitment.future_bonus`. Other hints (flight/larder/spells/heroes/placement) remain in both.

Labels exclude all tokens, including Eggs, from numerator and denominator; ordinary neutral slots remain. Plurality and its share, offered lobby tribes and no-majority reasons are recorded per seat. Pick uses all seats; lobby pick conditions on the tribe being offered. Outcomes condition on the majority label. Brackets are exploratory 95% intervals from lobby-clustered ratio residuals; boundary rates use a conservative Wilson bound per informative lobby. Fewer than two informative lobbies have no interval; rare results need more data.

**free_choice**

| Tribe | Seats | Pick (95%) | Lobby pick (95%) | Mean place (95%) | First (95%) |
|---|---:|---:|---:|---:|---:|
| Birds | 41 | 1.28% [0.87%, 1.69%] | 1.52% [1.04%, 2.01%] | 4.56 [3.86, 5.27] | 9.76% [0.54%, 18.97%] |
| Bog folk | 608 | 19.00% [17.46%, 20.54%] | 23.10% [21.55%, 24.65%] | 4.31 [4.15, 4.47] | 17.11% [14.47%, 19.74%] |
| Fairies | 89 | 2.78% [2.19%, 3.37%] | 3.45% [2.74%, 4.17%] | 3.67 [3.25, 4.10] | 17.98% [10.30%, 25.65%] |
| Hedgerow folk | 94 | 2.94% [2.35%, 3.52%] | 3.50% [2.82%, 4.17%] | 4.36 [3.93, 4.79] | 10.64% [4.31%, 16.97%] |
| Hunters | 728 | 22.75% [21.07%, 24.43%] | 26.38% [24.73%, 28.03%] | 4.70 [4.55, 4.84] | 10.58% [8.56%, 12.60%] |
| Oozes | 192 | 6.00% [5.20%, 6.80%] | 7.25% [6.34%, 8.16%] | 4.64 [4.33, 4.95] | 11.46% [7.02%, 15.90%] |
| no_tribe | 1448 | 45.25% [43.55%, 46.95%] | — | 4.52 [4.44, 4.61] | 11.53% [10.26%, 12.81%] |

`no_tribe`: 937 mixed, 511 tied_plurality. [Full reason/plurality breakdown](baseline-step2/after-birds-pass1/free_choice.no_tribe.csv).

**free_choice_plain**

| Tribe | Seats | Pick (95%) | Lobby pick (95%) | Mean place (95%) | First (95%) |
|---|---:|---:|---:|---:|---:|
| Birds | 676 | 21.12% [19.52%, 22.73%] | 25.07% [23.50%, 26.65%] | 4.47 [4.32, 4.62] | 13.46% [11.23%, 15.69%] |
| Bog folk | 309 | 9.66% [8.58%, 10.73%] | 11.74% [10.55%, 12.93%] | 4.21 [3.97, 4.44] | 17.15% [13.31%, 21.00%] |
| Fairies | 81 | 2.53% [1.97%, 3.10%] | 3.14% [2.46%, 3.83%] | 3.78 [3.33, 4.23] | 19.75% [11.46%, 28.05%] |
| Hedgerow folk | 113 | 3.53% [2.90%, 4.16%] | 4.20% [3.48%, 4.93%] | 3.52 [3.12, 3.93] | 20.35% [12.86%, 27.85%] |
| Hunters | 315 | 9.84% [8.80%, 10.89%] | 11.41% [10.29%, 12.53%] | 4.91 [4.69, 5.13] | 7.62% [4.73%, 10.50%] |
| Oozes | 336 | 10.50% [9.35%, 11.65%] | 12.69% [11.42%, 13.96%] | 4.27 [4.04, 4.50] | 13.10% [9.75%, 16.44%] |
| no_tribe | 1370 | 42.81% [41.00%, 44.62%] | — | 4.67 [4.57, 4.76] | 10.88% [9.61%, 12.14%] |

`no_tribe`: 872 mixed, 498 tied_plurality. [Full reason/plurality breakdown](baseline-step2/after-birds-pass1/free_choice_plain.no_tribe.csv).

All 72 unchanged benchmark snapshots, including all Birds unit IDs, loaded; none were skipped. Reran 180 pairs × 200 seeds × both orientations: 72,000 fights, 2,000 per board. This preserves the starting snapshot baseline while evaluating the new Birds mechanics; the historical snapshots do not represent newly designed optimal Birds boards. [Updated board results](baseline-step2/after-birds-pass1/benchmark.boards.csv) and [limitations](baseline-step2/after-birds-pass1/benchmark.limitations.json) accompany the raw fights.

Gate: all steps pass; 1499 Godot tests, 22907 assertions and 50 Python tests. `combat.gd` is 999 lines. [Gate log](baseline-step2/after-birds-pass1/gate.log); [provenance and hashes](baseline-step2/after-birds-pass1/provenance.json).
