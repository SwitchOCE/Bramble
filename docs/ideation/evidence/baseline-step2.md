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

Supplied slots, stat totals, goldens, Bellies and supported counters are preserved. Tests check all 72 starting boards and aura removal. Missing state affects 27 boards: full Ring amounts/layouts, Nest identities/away buffs/goldens, paint identities, prior kisses and Conkers ammunition. Known prose values load; uncertain state is itemized in [limitations](baseline-step2/benchmark.limitations.json). Snapshots ignore heroes and economy; bots retain card hints, heroes and ordinary five-tribe rotation.

Free choice: 400 lobbies, seeds 1–400 (3,200 seats), using the seed-validated official release pack. Equal zero tribe priors; no named routes. Labels require a strict majority of occupied final fight-start slots; Eggs occupy neutral slots, away Birds/Bellies add none. Mixed/tied/empty boards are `no_tribe`. Pick uses all 3,200 seats; placement and first rate condition on the label.

| Final tribe | Seats | Pick | Mean place | First |
|---|---:|---:|---:|---:|
| Birds | 1 | 0.03% | 3.00 | 0.0% |
| Bog folk | 612 | 19.1% | 4.47 | 14.9% |
| Fairies | 103 | 3.2% | 3.51 | 21.4% |
| Hedgerow folk | 123 | 3.8% | 3.85 | 25.2% |
| Hunters | 833 | 26.0% | 4.73 | 10.6% |
| Oozes | 210 | 6.6% | 4.64 | 8.6% |
| no_tribe | 1318 | 41.2% | 4.49 | 11.4% |

Birds are last in 10/12 cells; R6 low improves to fifth, and the neutral-assisted R3 low wins, broadly matching the audit.
Oozes R12 average win 91.0%, first versus guessed fourth: the audit’s weak-top claim is unsupported by this Belly snapshot.
Hedgerow R12 low wins 70.3%, second versus guessed fifth, despite its thin shop supply.
Fairies R12 average fall to fourth versus guessed first; their middle-game dominance does not extend to every late board.
Only one final board has a Birds majority; its placement average rests on one seat. Another 41.2% have no strict tribe majority, covering several different board types.

Gate: all steps pass, including 1,472 Godot tests. [Raw fights and summaries](baseline-step2/benchmark.summary.json) retain rates, draws, guesses and per-pair results; [gate log](baseline-step2/gate.log).
