# Damage v0.5

Pre-registered 2026-11-08, before measurements. Baseline: b99b5ad full_game damage (40 Health, compressed tiers, floor, caps, toll). All arms retain Last Stand/Last Blow. v0.5 replaces toll with round base: toll would double-charge pacing and damage ties, contrary to v0.5. No cap; +1 per own starting survivor, including returns/golden, excluding combat creations and stolen units.

Schedules (round-indexed; final entry repeats):

|Arm|Health|Base R1 onward|
|---|---:|---|
|A|40|0,0,1,1,2,2,3,3,4,4,5,6,7,8,9,10|
|B|40|0,0,0,1,1,2,2,3,4,5,7,9,11,13|
|C|40|0,0,0,0,1,1,2,2,3,4,6,8,10,12|
|D|40|1,1,1,1,2,2,2,2,4,4,6,6,8,8,10|
|E|48|0,0,0,1,1,2,2,3,4,5,7,9,11,13|

200 complete best-bot lobbies/arm via BenchSuites.hard_lobby_hard, paired seeds 860001–860200; four shards on cores 1–4. Each background batch has a 3000-second hard timeout and logs. No adaptive tuning. Record per-round Health/results, final placements/elimination rounds, and base/performance damage to real heroes. Baseline performance attribution is surviving-tier contribution after floor/cap/toll (base allocated first). T3 uses resolved combat charges, including Armor/overkill, before Last Stand, excluding damage to ghosts; also report effective absorbed damage sensitivity.

Targets: T1 qualifying players (maximal consecutive-loss streak length ≥5, starting ≤R6; draws break streaks) have median elimination ≥baseline+2; T2 median final round within ±1; T3 performance/all hero damage 25–45%; T4 median first elimination ≥baseline+1; T5 eventual top-four fraction among bottom two living by Health after R8 ≥baseline (ties: seat ID). Survivors use final round+1 for elimination censoring; report counts. Pick most targets; ties: fewer base changes, then 40 Health, then alphabetical.

Analytic Health after consecutive losses from R3, three survivors; no Armor/saves. Baseline assumes winner tiers R3–10 = 2,2,3,3,4,4,5,5 and three same-tier survivors, eight living (caps retained). Negative values show theoretical continuation.

|Arm|R3|R4|R5|R6|R7|R8|R9|R10|
|---|---:|---:|---:|---:|---:|---:|---:|---:|
|Baseline|35|29|22|14|5|-5|-16|-28|
|A|36|32|27|22|16|10|3|-4|
|B|37|33|29|24|19|13|6|-2|
|C|37|34|30|26|21|16|10|3|
|D|36|32|27|22|17|12|5|-2|
|E|45|41|37|32|27|21|14|6|

Results: all 1,200 games complete; logs clean. Frozen official release runtime matched editor JSON byte-for-byte on baseline/A smoke games. [Raw data, provenance and validation](damage-v05/) include 75,043 verified charges.

|Arm|Streak out (n/censored)|Game end|First out|Performance|Effective performance|Comeback|Targets|
|---|---:|---:|---:|---:|---:|---:|---|
|baseline|10.0 (258/12)|17.0|9.0|19.97%|18.22%|88/400 (22.00%)|—|
|A|13 (283/9)|21.0|12.0|28.79%|31.05%|114/400 (28.50%)|T1,T3,T4,T5|
|B|13.0 (278/19)|19.0|12.0|25.75%|28.98%|122/400 (30.50%)|T1,T3,T4,T5|
|C|14.0 (278/19)|20.0|12.0|27.46%|30.70%|143/400 (35.75%)|T1,T3,T4,T5|
|D|13 (287/16)|21.0|12.0|28.50%|30.74%|120/400 (30.00%)|T1,T3,T4,T5|
|E|14 (275/18)|21.0|13.0|24.13%|26.53%|128/400 (32.00%)|T1,T4,T5|

Selected D by preregistered target count and tie-breaks.

D remains opt-in; legacy stays default. A–D meet T1/T3/T4/T5; E misses T3 too. All miss T2. D wins simplicity (5 changes). Player text awaits wording work.

Validation: `./scripts/check.sh` passed (1,310 tests). No new soak; prior gate/soak archived separately for 9d3006c.
