# Card power table (`data/card_power.json`)

What it is: each shop unit's **fight value** at each stage of the game, measured on the real
engine. `delta` = P(A + X beats B) − P(A beats B), a tie counting ½. It is a marginal win-rate
change for one fight, and it is not gold or tempo value.

## Method

- **Corpus:** every non-ghost `fight_boards` payload in `<corpus>/records/*.jsonl`. The table
  now is from a 200-game `flow` vs `tribe` match (17,988 payloads):
  `target/release/league match --red flow --blue tribe --games 200 --seeds /home/alex/league/blue/out/seeds1k.txt --clock-ms 1000 --threads 1 --no-decisions --out /home/alex/league/blue/out/cardpower/corpus` (35 s).
- **Samples:** for each round bucket, draw A from the bucket, then B from the **same round of a
  different game**, plus one fight seed. Fight A vs B and A+X vs B with that same seed (paired,
  common random numbers), at A's round.
- **Placing X** (fresh, no buffs, uid 987654): two row rules, both measured on every sample.
  `front`: the first empty front slot (0-3); else A's weakest front unit moves to an empty back slot
  and X takes its place; else X replaces the weakest front unit. `back`: the first empty back slot
  (4-6); else the first empty front slot; else X replaces the weakest back unit. "Weakest" means
  lowest attack + health from the snapshot layers. `delta` is the better rule's mean, and
  `best_row` says which rule. `delta_front`/`delta_back` hold both. Taking the max of two
  correlated estimates biases `delta` up a little (well under 1 se).
- **Boards are full (4 front + 3 back) from about round 6 in this corpus,** so from bucket 7-9 on,
  `delta` means *X replacing A's weakest unit of a row*. That is an upgrade value: tier-1/2 cards
  go slightly negative, because they replace a buffed unit with a fresh one.
- **In tribe / off tribe:** A has ≥ 3 units (before X) of one of X's tribes, counting `All`
  units. `n_in_tribe` gives the in-tribe sample count. Ignore splits with fewer than about 60
  samples. Early buckets have almost no in-tribe boards.
- **Golden:** the same samples (the first `--golden-pairs`) and the same baseline, with X golden
  at its better rule.
- **What it can't see:** recruit-phase text never runs: When played, End of turn, start of turn,
  sell/eat, Order, Bury, gold, Tide gained between fights, medals earned over games, slot buffs a
  card would have built. Cards whose value is mostly there (Sentry, Whetstone Vole, Lance
  Corporal, Prophet of the Dust, Horde Runner, Relic Seeker, Hedge-layer, Grindstone Miller,
  Dormouse Cook, Colour Sergeant, Master-at-Arms, Harvest Piper, Gorger, Granary Glutton) are
  **under-rated** here by design. Fight-time effects (Start of fight, deaths, auras, Thorns,
  Fury, Overrun, rows) are all measured. The corpus is FlowBot/TribeBot boards, so it is weak at
  synergy: rerun it on our own bot's matches.

## Rerun

```sh
export PATH="$HOME/.cargo/bin:$PATH"; cd /home/alex/league/blue/tools/league
CARGO_BUILD_JOBS=2 cargo build --offline --locked --release -p blue-tools
timeout 900 target/release/blue-tools cardpower <corpus-match-dir> bots/blue/data/card_power.json \
  [--pairs 450] [--golden-pairs 200] [--golden 7-9,13-99] [--buckets 1-3,4-6,7-9,10-12,13-99] [--seed 1]
```

It is one thread. The table is rewritten (atomically) after every bucket, so a timeout keeps the
buckets already done. Buckets that never ran are `null`, and `"complete": false` says so.
`--buckets 10-12,13-99` runs only the late buckets, to a separate output file (a run does not
merge into an existing table).

## Timing and precision

CPU time per fight: 0.30 ms (rounds 1-3), 0.52 ms (4-6), 0.69 ms (7-9), about 0.79 ms (10-12),
about 0.85 ms (13+). One sample costs 1 + 95 × 2 fights (fewer when both rules pick the same
slot), and golden adds 95. Per-bucket CPU at 450 samples: 26 s, 44 s, 59 s (+14 s golden). The
10-12 and 13+ buckets are estimated at about 65 s and 75 s. The whole table is about 5 minutes
of CPU on an idle core.

Standard error per card at 450 samples: median 0.020 / 0.016 / 0.014, max 0.022 / 0.023 / 0.022
(buckets 1-3 / 4-6 / 7-9).

**This run's state (18 Nov, 22:02):** buckets 1-3, 4-6 and 7-9 (with golden) are filled.
**10-12 and 13+ are null.** The box was at load 11 and the tool got about 20% of a core, so the
12-minute cap stopped it during 10-12. A 100-pair trial on bucket 13+ (se about 0.022) ranked
Old Brock, Elder Mother, Sky-darkener, The Colonel and Orchard Stripper top, and Sentry, Whetstone
Vole, Hedge-layer, Bramble Runner and Flying Ace bottom. Treat that as rough.

## Findings (rounds 1-9)

1. **Orchard Stripper (T4) is a top-2 card in every bucket**: 0.46 / 0.45 / 0.30. Its "deal 5
   to all enemies" on death plus Molt beats every T5 and most T6 cards.
2. **Old Brock (T6) is the strongest fight card everywhere** (0.48 / 0.47 / 0.34). The next T6s
   are well behind it from round 4.
3. **Elder Mother (T5)** is 3rd at rounds 7-9 (0.21), and 0.30 in tribe against 0.19 off tribe:
   Compost copies are strong even on off-tribe boards with a heap.
4. **Gleaner (T3)** and **Sword-heir (T3)** fight like T5s at rounds 4-9 (0.28 / 0.27 at 4-6).
5. **Lone Hawthorn (T5)** is the best card at rounds 1-3 and 3rd at 4-6, then falls to 0.14 at
   7-9.
6. **Stat-only T5/T6 with no fight text** (Mother Midden, Regimental Sergeant-Major, Brigadier,
   Field Marshal, Mother of Thousands, Dirge Singer) are mid-pack by round 7-9. Their value is
   recruit-phase or needs a built board, and this table can't see that.
7. **Synergy cards that only work in tribe** (7-9, in vs off): Parish Standard-bearer
   +0.23 vs −0.01, The Old Hedge +0.22 vs +0.04, Briar King +0.19 vs +0.06, King Speck +0.30 vs
   +0.15, Dame of the Old Sett +0.13 vs +0.03, Squadron Leader +0.14 vs +0.05. At 4-6: Colour
   Ensign, Recruiting Sergeant, Ivy Climber, Lieutenant.
8. **Badger Squires do worse in tribe** at 4-6 (Armsbearer 0.00 vs 0.14, Shield-bearer 0.08 vs
   0.19, Marshal 0.16 vs 0.26). They replace a front Badger the lend/Fury depends on. Locust
   bodies (Sky-darkener, Skin-shedder, Husk Sentry) also do worse in tribe at 7-9.
9. **Golden gains (7-9)** are largest for Master of Engines (+0.09 → +0.30), Ironhide
   Berserker (+0.05 → +0.25), Marshal of the Red Mist (+0.06 → +0.25), Hawthorn Warden
   (+0.08 → +0.26), The Oakfeller (+0.14 → +0.33) and Field Marshal (+0.03 → +0.22).
10. **Weak for their tier:** Dormouse Cook (T4) and Grindstone Miller (T4) are bottom-15 at
    4-6 and 7-9, with recruit-only text. Padre (T3) is bottom-15 from round 4. Famine Caller (T4)
    is bottom-10 at 1-3.

## Ranked tables

### Rounds 1-3  (n=450; tier means: T1 +0.200, T2 +0.230, T3 +0.318, T4 +0.325, T5 +0.392, T6 +0.413)

Top 15:

| # | card | T | tribe | delta | se | in tribe | off tribe | golden | row |
|---|---|---|---|---|---|---|---|---|---|
| 1 | lone-hawthorn | 5 | Briar | +0.486 | 0.022 | +0.647 (17) | +0.479 |   –   | front |
| 2 | the-oakfeller | 6 | Badger | +0.480 | 0.022 | +0.250 (18) | +0.490 |   –   | front |
| 3 | old-brock | 6 | Badger | +0.480 | 0.022 | +0.250 (18) | +0.490 |   –   | back |
| 4 | king-speck | 6 | Mouse | +0.480 | 0.022 | +0.500 (13) | +0.479 |   –   | back |
| 5 | tourney-champion | 5 | Badger | +0.468 | 0.022 | +0.250 (18) | +0.477 |   –   | front |
| 6 | ironhide-berserker | 5 | Badger | +0.466 | 0.022 | +0.250 (18) | +0.474 |   –   | front |
| 7 | orchard-stripper | 4 | Locust | +0.461 | 0.021 | +0.375 (8) | +0.463 |   –   | front |
| 8 | dame-of-the-old-sett | 5 | Badger | +0.441 | 0.021 | +0.250 (18) | +0.449 |   –   | back |
| 9 | marshal-of-the-red-mist | 6 | Badger | +0.440 | 0.021 | +0.250 (18) | +0.448 |   –   | front |
| 10 | the-old-hedge | 6 | Briar | +0.432 | 0.021 | +0.647 (17) | +0.424 |   –   | front |
| 11 | briar-king | 6 | Briar | +0.424 | 0.021 | +0.529 (17) | +0.420 |   –   | front |
| 12 | field-marshal | 6 | Pigeon | +0.421 | 0.021 | +0.062 (8) | +0.428 |   –   | front |
| 13 | mother-midden | 6 | Briar | +0.419 | 0.021 | +0.500 (17) | +0.416 |   –   | front |
| 14 | dame-bodkin | 6 | Mouse | +0.417 | 0.021 | +0.308 (13) | +0.420 |   –   | back |
| 15 | squadron-leader | 4 | Pigeon | +0.417 | 0.021 | +0.125 (8) | +0.422 |   –   | back |

Bottom 15:

| # | card | T | tribe | delta | se | in tribe | off tribe | golden | row |
|---|---|---|---|---|---|---|---|---|---|
| 81 | green-recruit | 1 | Locust | +0.194 | 0.017 | +0.000 (8) | +0.198 |   –   | back |
| 82 | shrew-cutpurse | 2 | Mouse | +0.191 | 0.018 | +0.000 (13) | +0.197 |   –   | back |
| 83 | dormouse-cook | 4 | Mouse | +0.191 | 0.017 | +0.000 (13) | +0.197 |   –   | back |
| 84 | bramble-runner | 1 | Briar | +0.186 | 0.018 | +0.118 (17) | +0.188 |   –   | front |
| 85 | territorial | 1 | Pigeon | +0.184 | 0.018 | -0.125 (8) | +0.190 |   –   | front |
| 86 | relic-seeker | 2 | Badger | +0.174 | 0.015 | +0.111 (18) | +0.177 |   –   | back |
| 87 | hedge-knight | 1 | Badger | +0.172 | 0.017 | +0.056 (18) | +0.177 |   –   | back |
| 88 | famine-caller | 4 | Locust | +0.164 | 0.017 | +0.000 (8) | +0.167 |   –   | front |
| 89 | lance-corporal | 2 | Pigeon | +0.164 | 0.018 | -0.125 (8) | +0.170 |   –   | front |
| 90 | hedge-layer | 2 | Briar | +0.160 | 0.017 | +0.088 (17) | +0.163 |   –   | back |
| 91 | prophet-of-the-dust | 2 | Locust | +0.159 | 0.017 | +0.000 (8) | +0.162 |   –   | back |
| 92 | horde-runner | 2 | Locust | +0.157 | 0.018 | +0.000 (8) | +0.160 |   –   | front |
| 93 | brock-cub | 1 | Badger | +0.129 | 0.016 | +0.028 (18) | +0.133 |   –   | back |
| 94 | whetstone-vole | 2 | Mouse | +0.110 | 0.016 | +0.000 (13) | +0.113 |   –   | back |
| 95 | sentry | 1 | Pigeon | +0.110 | 0.016 | +0.000 (8) | +0.112 |   –   | back |

### Rounds 4-6  (n=450; tier means: T1 +0.062, T2 +0.076, T3 +0.140, T4 +0.140, T5 +0.212, T6 +0.235)

Top 15:

| # | card | T | tribe | delta | se | in tribe | off tribe | golden | row |
|---|---|---|---|---|---|---|---|---|---|
| 1 | old-brock | 6 | Badger | +0.466 | 0.023 | +0.414 (93) | +0.479 |   –   | back |
| 2 | orchard-stripper | 4 | Locust | +0.451 | 0.023 | +0.475 (59) | +0.448 |   –   | front |
| 3 | lone-hawthorn | 5 | Briar | +0.390 | 0.022 | +0.366 (97) | +0.397 |   –   | front |
| 4 | the-oakfeller | 6 | Badger | +0.381 | 0.022 | +0.323 (93) | +0.396 |   –   | front |
| 5 | king-speck | 6 | Mouse | +0.378 | 0.022 | +0.490 (49) | +0.364 |   –   | back |
| 6 | tourney-champion | 5 | Badger | +0.323 | 0.021 | +0.263 (93) | +0.339 |   –   | front |
| 7 | dame-bodkin | 6 | Mouse | +0.286 | 0.021 | +0.408 (49) | +0.271 |   –   | back |
| 8 | gleaner | 3 | Locust | +0.278 | 0.021 | +0.314 (59) | +0.272 |   –   | back |
| 9 | sword-heir | 3 | Badger | +0.274 | 0.020 | +0.199 (93) | +0.294 |   –   | back |
| 10 | ironhide-berserker | 5 | Badger | +0.274 | 0.020 | +0.210 (93) | +0.291 |   –   | front |
| 11 | elder-mother | 5 | Briar | +0.266 | 0.020 | +0.289 (97) | +0.259 |   –   | front |
| 12 | briar-king | 6 | Briar | +0.261 | 0.020 | +0.320 (97) | +0.245 |   –   | front |
| 13 | the-eighth-plague | 5 | Locust | +0.260 | 0.020 | +0.297 (59) | +0.255 |   –   | back |
| 14 | the-old-hedge | 6 | Briar | +0.247 | 0.020 | +0.263 (97) | +0.242 |   –   | front |
| 15 | marshal-of-the-red-mist | 6 | Badger | +0.241 | 0.020 | +0.156 (93) | +0.263 |   –   | front |

Bottom 15:

| # | card | T | tribe | delta | se | in tribe | off tribe | golden | row |
|---|---|---|---|---|---|---|---|---|---|
| 81 | territorial | 1 | Pigeon | +0.056 | 0.012 | +0.089 (95) | +0.046 |   –   | front |
| 82 | grindstone-miller | 4 | Mouse | +0.053 | 0.012 | +0.122 (49) | +0.045 |   –   | front |
| 83 | padre | 3 | Pigeon | +0.052 | 0.013 | +0.079 (95) | +0.045 |   –   | front |
| 84 | hedge-knight | 1 | Badger | +0.050 | 0.014 | +0.032 (93) | +0.055 |   –   | front |
| 85 | nettle-sprout | 1 | Briar | +0.047 | 0.013 | +0.036 (97) | +0.050 |   –   | front |
| 86 | shrew-cutpurse | 2 | Mouse | +0.046 | 0.013 | +0.133 (49) | +0.035 |   –   | front |
| 87 | horde-runner | 2 | Locust | +0.042 | 0.012 | +0.025 (59) | +0.045 |   –   | front |
| 88 | lance-corporal | 2 | Pigeon | +0.042 | 0.012 | +0.058 (95) | +0.038 |   –   | front |
| 89 | dormouse-cook | 4 | Mouse | +0.036 | 0.013 | +0.143 (49) | +0.022 |   –   | front |
| 90 | prophet-of-the-dust | 2 | Locust | +0.030 | 0.012 | +0.051 (59) | +0.027 |   –   | front |
| 91 | brock-cub | 1 | Badger | +0.028 | 0.012 | +0.021 (93) | +0.029 |   –   | front |
| 92 | hedge-layer | 2 | Briar | +0.026 | 0.013 | +0.000 (97) | +0.033 |   –   | front |
| 93 | relic-seeker | 2 | Badger | +0.024 | 0.012 | +0.016 (93) | +0.027 |   –   | front |
| 94 | whetstone-vole | 2 | Mouse | +0.024 | 0.012 | +0.092 (49) | +0.016 |   –   | front |
| 95 | sentry | 1 | Pigeon | +0.024 | 0.012 | +0.063 (95) | +0.014 |   –   | front |

### Rounds 7-9  (n=450; tier means: T1 -0.017, T2 -0.012, T3 +0.024, T4 +0.027, T5 +0.066, T6 +0.077)

Top 15:

| # | card | T | tribe | delta | se | in tribe | off tribe | golden | row |
|---|---|---|---|---|---|---|---|---|---|
| 1 | old-brock | 6 | Badger | +0.342 | 0.022 | +0.318 (85) | +0.348 | +0.458 | back |
| 2 | orchard-stripper | 4 | Locust | +0.296 | 0.021 | +0.205 (78) | +0.315 | +0.393 | front |
| 3 | elder-mother | 5 | Briar | +0.212 | 0.020 | +0.296 (86) | +0.192 | +0.380 | front |
| 4 | king-speck | 6 | Mouse | +0.169 | 0.020 | +0.297 (64) | +0.148 | +0.340 | back |
| 5 | tourney-champion | 5 | Badger | +0.149 | 0.018 | +0.165 (85) | +0.145 | +0.292 | front |
| 6 | the-oakfeller | 6 | Badger | +0.144 | 0.018 | +0.176 (85) | +0.137 | +0.325 | front |
| 7 | lone-hawthorn | 5 | Briar | +0.144 | 0.019 | +0.174 (86) | +0.137 | +0.320 | front |
| 8 | sword-heir | 3 | Badger | +0.116 | 0.017 | +0.118 (85) | +0.115 | +0.250 | back |
| 9 | dame-bodkin | 6 | Mouse | +0.112 | 0.017 | +0.164 (64) | +0.104 | +0.210 | back |
| 10 | the-eighth-plague | 5 | Locust | +0.108 | 0.017 | +0.115 (78) | +0.106 | +0.240 | back |
| 11 | master-of-engines | 5 | Mouse | +0.087 | 0.018 | +0.102 (64) | +0.084 | +0.295 | back |
| 12 | gleaner | 3 | Locust | +0.082 | 0.017 | +0.045 (78) | +0.090 | +0.233 | back |
| 13 | briar-king | 6 | Briar | +0.082 | 0.017 | +0.192 (86) | +0.056 | +0.247 | front |
| 14 | the-colonel | 6 | Pigeon | +0.081 | 0.015 | +0.050 (91) | +0.089 | +0.200 | front |
| 15 | sky-darkener | 4 | Locust | +0.078 | 0.016 | +0.019 (78) | +0.090 | +0.168 | front |

Bottom 15:

| # | card | T | tribe | delta | se | in tribe | off tribe | golden | row |
|---|---|---|---|---|---|---|---|---|---|
| 81 | nettle-sprout | 1 | Briar | -0.029 | 0.012 | +0.000 (86) | -0.036 | +0.022 | front |
| 82 | shrew-cutpurse | 2 | Mouse | -0.030 | 0.013 | +0.000 (64) | -0.035 | -0.007 | front |
| 83 | padre | 3 | Pigeon | -0.031 | 0.012 | -0.022 (91) | -0.033 | +0.015 | front |
| 84 | sweetbriar | 2 | Briar | -0.031 | 0.012 | +0.000 (86) | -0.038 | +0.018 | front |
| 85 | hedge-knight | 1 | Badger | -0.033 | 0.015 | -0.053 (85) | -0.029 | -0.005 | front |
| 86 | grindstone-miller | 4 | Mouse | -0.033 | 0.012 | +0.016 (64) | -0.042 | +0.018 | front |
| 87 | prophet-of-the-dust | 2 | Locust | -0.034 | 0.012 | -0.083 (78) | -0.024 | +0.005 | front |
| 88 | horde-runner | 2 | Locust | -0.036 | 0.013 | -0.083 (78) | -0.025 | +0.020 | front |
| 89 | lance-corporal | 2 | Pigeon | -0.038 | 0.013 | -0.017 (91) | -0.043 | +0.007 | front |
| 90 | dormouse-cook | 4 | Mouse | -0.039 | 0.012 | +0.031 (64) | -0.051 | -0.003 | front |
| 91 | hedge-layer | 2 | Briar | -0.039 | 0.012 | -0.017 (86) | -0.044 | -0.005 | front |
| 92 | whetstone-vole | 2 | Mouse | -0.040 | 0.013 | +0.008 (64) | -0.048 | -0.020 | front |
| 93 | brock-cub | 1 | Badger | -0.041 | 0.013 | -0.029 (85) | -0.044 | -0.010 | front |
| 94 | relic-seeker | 2 | Badger | -0.041 | 0.013 | -0.029 (85) | -0.044 | -0.018 | front |
| 95 | sentry | 1 | Pigeon | -0.042 | 0.013 | -0.022 (91) | -0.047 | -0.020 | front |

### Rounds 10-12: not measured in this run


### Rounds 13-99: not measured in this run

