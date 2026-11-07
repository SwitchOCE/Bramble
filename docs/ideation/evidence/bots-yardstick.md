# Bots: the promotion yardstick and cost of a turn

8 November 2026. Work on `ideation/bots`, based on `7529183` (Easy and Normal already removed). Scope: BOTS steps 2–3 and step-4 preparation; no bot-strength changes. Read the plan and interrogation with `git show origin/ideation/main:<path>`. Everything proposed below is agent analysis, not an additional owner quote.

## The head-to-head yardstick

**"clearly better" = margin excludes 0 and gain at least 0.15 of a place, on fresh seeds.** Gain is incumbent mean place minus candidate mean place, so positive is better. Declare the candidate and seed range before running; development seeds and this A/A range cannot be reused for promotion. Per-strategy results are exploratory, not eight or twenty-one separate promotion tests.

`BenchSuites.REGISTRY` is the one registration point: an alias maps to a profile and a `BotBrain` script. A step-5 worker implements a subclass and adds one entry (e.g. `"saving": {"profile": "hard", "script": preload("res://…/saving.gd")}`). Keep the incumbent and shared behavior unchanged during the comparison; override only the candidate. `GameSession` accepts an optional tools factory, defaulting to ordinary `Bot.create`; the policy is created after `BotLobby.resolve` deals the usual eligible strategies without replacement. This does not introduce a new player-facing strength.

Each seed shuffles an eight-seat partition, four per side. Its second game uses exactly the same game seed, tribe draw, seat RNG streams and strategy deal, with the side labels exchanged. Both games really run. A/A policies consequently replay the same decisions. Candidate/incumbent aliases, seed, leg, seat, side and dealt strategy are recorded in `players.csv`. Shard boundaries cannot change seating.

The sample is **one paired-seed mean difference**, averaging its two games. The summary uses sample standard deviation / √(paired seeds), with a two-sided Student-t critical value, for its 95% margin. It never treats eight correlated seats or two related games as independent observations. Broken, duplicated, mixed-policy or unswapped pairs fail validation. For fewer than two seeds the margin is infinite. Per-strategy means use only seeds dealing that strategy, again grouped by seed; their intervals have no multiple-comparison correction.

```sh
taskset -c 0,1 tools/sim/bench.sh --cores 2 --timeout 2250 \
  --out build/sim/yardstick/aa --report build/sim/yardstick/aa.md \
  --seed 91001 --candidate hard --incumbent hard head_to_head=200
# head_to_head=200 means 200 paired seeds, 400 games.
# Future comparison: change the two registry aliases and use an untouched seed range.
```

**A/A PASS: Hard vs Hard, 200 paired seeds / 400 analyzed games / 3,200 seats, seeds 91001–91200: mean place gain +0.000 ±0.000 (95%).** Zero lies in the margin. All 21 dealt strategies also cancel exactly. Raw player CSV SHA-256: `ea22b3cfd0c4f2082e5e3b1e59af4e593eeedfd70b3bb99ee0a628c140b6af3e`. The initial shards became uneven; the slower shard was stopped and its remaining seeds balanced over the same two cores, replaying any incomplete pair and including each seed exactly once. The long run began before the factory refactor; both creation paths select the same Hard policy and normal build deal. Runtime code was the uncommitted yardstick work over `7529183`, including both optimizations; this was not a clean-base timing run.

Exact cancellation in A/A checks side assignment, replay and aggregation; a zero margin here **does not establish empirical 95% coverage or the sample size needed to resolve 0.15 places**. The tests additionally exercise noisy nonzero seed differences (including the small-sample t margin), missing/duplicated games and changed strategy deals. A `rule` versus `hard` smoke run at seeds 93001–93002 executed four games: gain −0.375 ±7.941 places (95%, two paired seeds). This checks distinct-policy dispatch and a nonzero, noisy result; it is not a promotion sample.

## Profiling and identical play

The machine is an Intel i5-9500T (2.20 GHz), Godot 4.7.2, limited throughout to CPUs 0 and 1. These are local measurements, not a new cloud-VM or phone measurement. `profile=on` records exclusive microseconds per turn for evaluation entry points, lane scoring/arrangement, held-unit decisions, placement-problem setup and quiet search fights (construction plus combat). Nested calls are charged only to the innermost category. `other` is the remainder: recruit rules, shopping/control flow, ordinary placement and search bookkeeping. This is attribution, not a clock cutoff; search remains 20 fights. Profiling overhead means the component totals are diagnostic; speed comparisons use `profile=off`.

Measurements below were taken after the paired run finished, with no other task simulations running, profiling off, the same 12 seeds (81001–81012), and alternating six-game blocks before/after. Both timed arms include identical disabled profiling hooks, isolating the two reductions rather than claiming a clean-checkout-to-final-branch speedup. p95 is the nearest-rank percentile of individual turns, not a percentile of seven-bot waits.

| Version | Games | Bot turns | Mean turn ms | p95 turn ms | Full-game seconds | Projected 2,000-game cost |
|---|---:|---:|---:|---:|---:|---|
| Before | 12 | 1183 | 90.74 | 196.73 | 9.35 | 5.19 core-hours; 2.60 h on two cores |
| After | 12 | 1183 | 87.07 | 188.60 | 8.98 | 4.99 core-hours; 2.50 h on two cores |

Observed mean-turn change: -4.0%. The full-game cost includes actual lobby combat, recruit-phase rules and CSV/trace output, not just bot decisions. The 2,000-game costs are **extrapolations from 12 spread games**, not completed 2,000-game runs; different seeds/strategies and concurrent load change the cost. The existing `spread` suite can pin a tribe absent from its five-tribe lobby; this comparison preserves that suite for reproducibility and makes no balance claim. The head-to-head suite uses the normal eligible strategy deal.

Separate diagnostic profiles use seeds 82001–82002 (two games each). These are small attribution samples, with profiler overhead, not extra timing evidence. The historical column uses the exported two-tribe `1d12de0` core/content with timing hooks added; current columns use `7529183` before/after the two reductions.

| Exclusive ms per bot turn | Historical two tribes | Current before | Current after |
|---|---:|---:|---:|
| Evaluation | 1.805 | 3.044 | 2.988 |
| Lane scoring/arrangement | 0.000 | 8.017 | 7.313 |
| Held units | 0.000 | 0.934 | 0.939 |
| Placement search problem setup | 0.026 | 0.077 | 0.078 |
| Search fights, including fight construction | 28.443 | 63.884 | 61.743 |
| Other turn work | 3.612 | 6.006 | 6.005 |

| Search diagnostic | Historical | Current before | Current after |
|---|---:|---:|---:|
| Searches per turn | 0.621 | 0.602 | 0.602 |
| Fights per turn | 9.293 | 11.571 | 11.571 |
| Milliseconds per search fight | 3.061 | 5.521 | 5.336 |

**Why 35 ms became about 87 ms:** the old report pooled Hard turns from several suites and a two-tribe engine; the interrogation used a small all-Hard sample on another VM. Those numbers alone do not identify a regression. The same-machine diagnostic total rises from 33.89 to 81.96 ms: search combat rises from 28.44 to 63.88 ms, and the added lane scorer takes 8.02 ms. Together those explain about 90% of that increase. Search frequency actually falls slightly (0.621 to 0.602 searches/turn), but fights per search rise from 15.0 to 19.2 and each fight costs 3.06 to 5.52 ms (about 80% more). Evaluation, held-unit decisions and placement-problem construction explain little of the rise. The search budget is still 20; actual fights per turn and cost per fight are separated above. The expanded combat path includes Mire/Quarry/Pack and held-unit/return mechanics. This comparison does not separately attribute the increase to tribe count versus simultaneous engine, card and policy changes.

Seven bots at the after mean take about 0.61 s on this core. At the old unmeasured 3× phone factor that is 1.83 s; the seven-bots-in-about-one-second phone aim remains unproven and is not met by that projection. No device was timed.


Two reductions in repeated work:

- Score the fixed starting layout once per placement search, rather than again for every candidate's bonus. Layout candidates, scores, ordering, fight budget and RNG draws remain identical.
- For quiet combat, skip building summon views, attack/damage payload dictionaries and stat payloads that `_emit` would immediately discard. Logged fights still produce those payloads. No simulation state updates, triggers, damage, or RNG calls are skipped.

**Identical play on all 12 seeds:** all 1,183 end-of-bot-turn boards matched, together with slot effects, gold, tier and bot RNG state. The player outcomes, every round row and final-card rows also matched exactly (96 final player boards). This checks more than just final placement. Both trace SHA-256 hashes: `d5a3260ee0ca4c460448105cc87b69f48668f997a4cdebd6cf44ac5cb4b995e4`. Raw CSVs, trace files, logs and `comparison.json` are under `build/sim/yardstick/` (ignored generated artifacts).

Reproduce a comparison by running the same `suite=spread games=12 first_seed=81001 trace=on` against the unoptimized and optimized trees with matching load, distinct `out` prefixes and profiling off, then:

```sh
python3 tools/sim/compare_bots.py <before-prefix> <after-prefix>
# For attribution, separately repeat with profile=on (the .profile.csv file).
```

The unoptimized tree is base `7529183` with only the bench/factory/timer instrumentation; revert the fixed-layout cache and the four quiet-combat payload guards to recreate it. The old two-tribe comparison uses exported `1d12de0` source/content and the same timing tooling; it changes neither this branch nor another worktree. Godot's writable data/config directories were pointed into `/tmp/bramble-bots/` because the sandbox disallows writes to the ordinary user config directory. Initial contended and interrupted timing trials were discarded from the speed comparison.

Validation: `./scripts/check.sh` passed every step, including all 1,252 Godot tests and 18 Python tests. The head-to-head tests cover shuffled/complementary seats, the normal strategy deal and registry dispatch. Summary tests cover seed clustering, sign, the Student-t margin, missing/duplicate pairs, and strategy mismatch. `compare_bots.py` additionally passed explicit Python syntax/lint checks. No bot strength, card balance, owner notes or player-facing difficulty changed. The orchestrator still owns review and pushing this branch.

## Ranked human advantages for step 4

This is my ranked hypothesis list from one read of `src/core/bots/` and `bench-reading.md`, checked against the current strategy data. It is not a finding from strong-human play. Sizes below are guessed mean-place gains **within relevant seats**, before dilution across the whole lobby; they overlap and must not be added. Each requires its own fresh paired-seed test. The historical rates in `bench-reading.md` are two-tribe, older-bot evidence, not current balance findings. No strength fixes were made here.

| Rank | Gap and code evidence | Proposed fix | Guessed size (places, eligible seats) |
|---:|---|---|---:|
| 1 | **Reactive saving.** `BotBrain._held_back()` takes the maximum of a fixed strategy/hero save schedule and next-turn climb savings. It releases at low health, but does not price an ordinary purchase against future interest or a coming spending window. | Compare immediate board gain with the actual next bank threshold and projected survival; release reserves for unusually good shops or dangerous scouts. Keep Burner opportunity cost, which is already dynamic. | 0.20–0.50 |
| 2 | **Acorn Stash.** `_pay()` liquidates gold items using a linear `_hold_value()`; `_feed_eaters()` follows a turn-count rule. It lacks a joint choice between bank gold, Stash, feeding, a treasury payoff and buying tempo. Existing larder weights for Treasury/Treasurer/Mast mean this is incomplete planning, not total ignorance. | Price the actual next payoff of keeping each item, cashing it or feeding it, including threshold batches and hand room. Reserve just enough for that payoff; spend the rest. | 0.15–0.40 |
| 3 | **Rings.** `fairies_rings` caps itself at six bodies; `BotPlacer` assigns good units to large Rings, but recruit values stay mostly static and do not plan sequences that build, exploit and refill slots. The old 5.6-body result is a clue, not proof of the current cause. | Trace why a slot stays empty; value a seventh body versus the specific Ring engine, then plan mover/recipient/spell sequences including move costs and pins. Remove the six-body cap only when the engine benefits. | 0.20–0.60 |
| 4 | **Economy lines.** `neutrals_economy` still has a fast curve and no save plan. Three random opening plans and static card/hero priors do not build a coherent income-to-cash-out line. Burner forecasts and borrowing solely for due climbs already exist. | Give each economy engine a short income, survival and spending-window plan. Value loans by debt and lethal risk, and test the losing economy flavours as well as the leader. | 0.15–0.40 |
| 5 | **Tier-up timing.** `_target_round()` shifts a fixed curve by one using health and raw scout stats; `_climb(false)` runs before shopping and can price the climb at 100 points. It cannot compare the current shop against actual next-tier opportunities. | Compare a due climb with the best affordable current-shop improvement, board survival and remaining buys; use known tier odds and pool access rather than combat simulation first. | 0.10–0.30 |
| 6 | **Triples.** `BotEval` adds a fixed 18 + 2×tier for a third copy and 3 for a pair; `_unit_gain()` returns that worth directly for a triple, and Jill hunts any lower-tier pair. | Value the real golden replacement, lost bodies/held contents, reward tier, board/hand space and probability/cost of finding the third copy; defer or sell weak pairs when tempo matters. | 0.10–0.30 |
| 7 | **Signature tribe lines.** Hints and `BotHeld`, `BotEggs`, `BotLanes` cover text, flights, Belly depth and lane matchups; generic keep/buy values still miss multi-turn combinations, return timing and sacrificial sequences (Queen, Echo/Fetch, Fly South chains, borrowing text, Mire/Quarry support). | Add one explicit small plan per signature engine, chosen by current cards and scout, including opportunity cost of bodies, pins and delayed returns. Test each tribe's weaker lines. | 0.10–0.40 |
| 8 | **Pivots.** Normal lobby `:varied` seats become `pinned_strategy`, so `_choose_build()` immediately returns. Even unpinned bots apply a 1.3 stay multiplier and lock at round 9. A human can abandon a dealt line for a premium off-plan shop. | Treat the dealt strategy as a preference, retain it for identity, and allow measured pivots when a concrete available package outweighs sunk investment and transition losses. Preserve varied lobby coverage. | 0.10–0.35 |

The first five are the proposed bounded step-5 pass; stop after that list or two failed promotions in a row. These are implementation priorities, not attributed owner design choices. Hand play should add the question: “What did you do that the bots never did?”
