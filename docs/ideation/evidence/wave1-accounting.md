# Wave 1 accounting check

Current wave-1 combat, pass 3 on, size/rate caps off, loop guards on, unchanged `content/pass3/rates.json` dials. No new gameplay bars.

640 independent fresh lobbies, seeds 1901001–1901640. One seat per written line and four blind Hard seats; all tribes available, real heroes/fights/damage/elimination/shared pool. Four timing-pilot lobbies are excluded.

Godot simulation time: 1672.2 s. Chunk execution wall time: 1906.7 s (includes startup, locking, compression and validation). The full gate uses the same worker's harness lock, so its time can appear as waiting in one chunk. No concurrent Godot processes from this worker.

Committed seat of each assigned line only for line comparisons. Original tempo seat identity retained after its R7 switch. Surviving boards at each round; no zero imputation for eliminated seats.

95% percentile bootstrap of all predeclared independent lobby seeds, including eliminated empty clusters; all seats/rounds kept together. Paper is a fixed authored plan, not estimated data.

The only criterion is the R12 real/paper ratio inside 0.5–2×. The point is classified; intervals are reported, without an extra confidence-bound gate.

| Line | Round | Real pre-start median [seed 95% interval] | Boards | Paper pre-start | Real / paper [95% interval] | R12 inside 0.5–2× |
|---|---:|---|---:|---:|---|---|
| birds_homecoming | 8 | 74.000 [71.000, 76.000] | 640 | 96.000 | 0.771 [0.740, 0.792] | — |
| birds_homecoming | 10 | 147.000 [143.000, 154.000] | 640 | 240.000 | 0.613 [0.596, 0.642] | — |
| birds_homecoming | 12 | 270.000 [254.463, 283.000] | 593 | 615.000 | 0.439 [0.414, 0.460] | False |
| birds_homecoming | 14 | 495.500 [464.000, 536.000] | 508 | 1275.000 | 0.389 [0.364, 0.420] | — |
| birds_tempo | 8 | 75.000 [74.000, 78.000] | 640 | 106.000 | 0.708 [0.698, 0.736] | — |
| birds_tempo | 10 | 145.000 [140.000, 153.000] | 639 | 159.000 | 0.912 [0.881, 0.962] | — |
| birds_tempo | 12 | 260.500 [245.000, 276.000] | 588 | 361.000 | 0.722 [0.679, 0.765] | True |
| birds_tempo | 14 | 462.000 [430.000, 485.512] | 515 | 894.000 | 0.517 [0.481, 0.543] | — |
| fairies_ring | 8 | 63.500 [62.000, 65.000] | 640 | 92.000 | 0.690 [0.674, 0.707] | — |
| fairies_ring | 10 | 98.000 [96.000, 100.000] | 626 | 275.000 | 0.356 [0.349, 0.364] | — |
| fairies_ring | 12 | 142.000 [135.000, 147.500] | 468 | 530.000 | 0.268 [0.255, 0.278] | False |
| fairies_ring | 14 | 249.000 [226.000, 284.000] | 285 | 1410.000 | 0.177 [0.160, 0.201] | — |
| fairies_court | 8 | 59.500 [58.000, 61.000] | 640 | 107.000 | 0.556 [0.542, 0.570] | — |
| fairies_court | 10 | 92.000 [89.000, 95.000] | 619 | 389.000 | 0.237 [0.229, 0.244] | — |
| fairies_court | 12 | 160.000 [148.000, 166.000] | 398 | 945.000 | 0.169 [0.157, 0.176] | False |
| fairies_court | 14 | 362.000 [329.000, 425.000] | 236 | 1325.000 | 0.273 [0.248, 0.321] | — |

## Counting and built-dial reconciliation

Sum original Game.snapshot active Attack+Health after auras, before Start of Combat. Eggs and the Lump's borrowed Nest stats are already included. The printed board total already excludes sky/away and hand bodies; do not add or subtract the separately printed sky.

Use original snapshot recruit total (rec), not combat (comb): this retains the printed Fetch body and occupied-slot Rings, removes the Start-of-Combat Fetch replacement/twin and Wisps on empty Ring slots. Per-round removed_start_effect_stats is comb minus rec. Built Fetch share 0.5 replaces authored default 1.0, though it changes only combat, not rec.

Bird paper figures were rerun with the built h/s/k/f/g/egg values and fights disabled. Fairy figures were rerun with Fetch 0.5, guards on and the built Lob/Monarch/Queen values. The original Fairy `.out.txt` is absent; current source is rerun and hashed.

Two intentional timing changes have no equivalent original CLI dial: One Swallow is one turn in the build but two in the paper script; Cluricaun adds +1 Ring size at tier-up in the build but every third rainbow-complete End of Turn in the paper. The authored denominator above preserves those old algorithms rather than hiding the difference. A separately labelled timing reconciliation applies only these two built events to the same authored arrivals and budgets; it is not a Godot reproduction.

| Line | Round | Built-timing paper | Real / built-timing paper | R12 inside same band |
|---|---:|---:|---:|---|
| birds_homecoming | 8 | 99.000 | 0.747 | — |
| birds_homecoming | 10 | 228.000 | 0.645 | — |
| birds_homecoming | 12 | 551.000 | 0.490 | False |
| birds_homecoming | 14 | 856.000 | 0.579 | — |
| birds_tempo | 8 | 102.000 | 0.735 | — |
| birds_tempo | 10 | 108.000 | 1.343 | — |
| birds_tempo | 12 | 297.000 | 0.877 | True |
| birds_tempo | 14 | 647.000 | 0.714 | — |
| fairies_ring | 8 | 92.000 | 0.690 | — |
| fairies_ring | 10 | 275.000 | 0.356 | — |
| fairies_ring | 12 | 530.000 | 0.268 | False |
| fairies_ring | 14 | 1410.000 | 0.177 | — |
| fairies_court | 8 | 165.000 | 0.361 | — |
| fairies_court | 10 | 473.000 | 0.195 | — |
| fairies_court | 12 | 945.000 | 0.169 | False |
| fairies_court | 14 | 1325.000 | 0.273 | — |

## Preliminary pre-start growth

Preliminary pre-start pooled-survivor median growth, not within-player compounding. Includes Hard for all-seat estimate; committed-only and per-line figures are separate. No growth pass/fail for this accounting step.

| Population | R8–R14 geometric growth per round [95% seed interval] |
|---|---|
| All eight seats | 1.290 [1.279, 1.297] |
| Committed seats only | 1.356 [1.346, 1.365] |
| birds_homecoming | 1.373 [1.358, 1.393] |
| birds_tempo | 1.354 [1.337, 1.364] |
| fairies_ring | 1.256 [1.235, 1.283] |
| fairies_court | 1.351 [1.328, 1.388] |

## Accounting diagnostics

| Line | R12 survivors / lobbies | Tier 6 | Median Ring size | Median Rings | Annis present | Cluricaun present | Monarch present | Queen present |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| birds_homecoming | 593/640 | 82.3% | 1.000 | 4.000 | 0.0% | 0.0% | 0.2% | 5.4% |
| birds_tempo | 588/640 | 84.7% | 1.000 | 5.000 | 0.0% | 0.0% | 0.2% | 7.3% |
| fairies_ring | 468/640 | 89.3% | 2.000 | 18.000 | 43.4% | 37.4% | 62.2% | 37.6% |
| fairies_court | 398/640 | 95.2% | 2.000 | 31.000 | 37.7% | 29.6% | 60.1% | 75.9% |

Largest measured R12 shortfall: **line_fairies_court**. Interpret engine availability and Ring size/count against the authored state; these lobbies do not execute the paper's guaranteed arrivals, purchases and spell/thank/tithe sequences. Partial prose execution in the shared Hard adapters, real shop supply, pool competition and survival selection can all contribute. This measures these scripts against their accounting plan, not an isolated causal estimate of card balance.

Exact source/config/model hashes, conversions, per-line diagnostics and archive provenance are in `tools/sim/evidence/wave1-accounting-results.json` and its plan/paper/progress files. Raw captures remain under `build/sim/wave1-accounting/run/` as gzip JSONL. Post-start medians are included beside pre-start in the JSON for context.

For line_fairies_court, R12 median Ring size is 2.000 versus paper 6.000, and median Ring count 31.000 versus paper 76.000. 95.2% of its R12 survivors have reached tier 6. Among those survivors, Lob was seen on board during R8–R12 in 38.4% and Silky in 26.6%. These are observed-presence windows, not lifetime purchase or thank counts. The likely large gap is failure to realize the paper's accumulated Rings/Ring size and engine sequence under actual shops and these scripts. The timing-reconciled denominator above shows whether the two known paper/build timing changes explain the R12 gap.
