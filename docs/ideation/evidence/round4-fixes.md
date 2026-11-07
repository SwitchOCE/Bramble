# Round 4 fixes

Six items, six commits on `ideation/round4`. Card power, tribe design/supply and Birds were left to the cloud round. PLAN acceptance bars are unchanged. These are focused matched measurements, not the full 2,000-game depth/soak signoff.

## Difficulty ladder

The supplied completed bench at `~/code/Bramble-ideation/build/sim/ideation4-d75d3d8-1108-0239/` reports Hard among Normal **3.29** (500 games), Normal among Easy **2.39** (500), Hard among Easy **1.65** (300). It finished with exit 0. Read with `bench-reading.md`: bot strategies, selection and survival affect these results; stat totals alone are not a measure of card power.

Matched comparison below: seeds **1–30**, eight seats, freely choosing focus bots. Before is an isolated archived `0cb68b3` project with measurement-only `plain_easy` and `gold_left` instrumentation. Policy-only is the new ladder before the toll. Final includes the toll and presentation/hero fixes. The plain player is the existing `balanced` scripted policy (tier/stat buys, fixed climb, simple placement); it is a first-game proxy, not a human playtest.

| Suite | Stage | Games | Mean place ± 95% margin | Wins | Top 4 |
|---|---|---:|---:|---:|---:|
| plain_easy | Before | 30 | 5.13 ± 1.10 | 30.0% | 40.0% |
| plain_easy | Policy only | 30 | 1.77 ± 0.67 | 83.3% | 86.7% |
| plain_easy | Final | 30 | 1.70 ± 0.61 | 80.0% | 90.0% |
| normal_easy | Before | 30 | 2.83 ± 0.89 | 46.7% | 76.7% |
| normal_easy | Policy only | 30 | 1.00 (all firsts) | 100.0% | 100.0% |
| normal_easy | Final | 30 | 1.00 (all firsts) | 100.0% | 100.0% |
| hard_normal | Before | 30 | 3.70 ± 0.83 | 16.7% | 73.3% |
| hard_normal | Policy only | 30 | 2.53 ± 0.63 | 36.7% | 83.3% |
| hard_normal | Final | 30 | 2.63 ± 0.62 | 36.7% | 83.3% |
| hard_easy | Before | 30 | 2.20 ± 0.59 | 46.7% | 86.7% |
| hard_easy | Policy only | 30 | 1.00 (all firsts) | 100.0% | 100.0% |
| hard_easy | Final | 30 | 1.00 (all firsts) | 100.0% | 100.0% |

Place margins are the normal approximation for the seed-level mean; all-first samples have no useful estimated margin and still have uncertainty. Thirty games are too small to establish the long-run PLAN bars by themselves. Hard retains its legal full policy; it can lose to Normal. Easy/Normal limits and their tested decisions are in `DECISIONS.md`.

## Stats each round

Mean **total board Attack / total board Health**, conditional on that seat still playing. These pool the four equally sized suites; the mix of opponents differs by level, so compare each column only to itself across stages. Board counts and separate suite/level rows (including the plain player) are in [round4-stats.csv](round4-stats.csv). Health here is unit Health, not hero Health. No stat bonuses or combat handicaps were given to a difficulty.

| Round | Easy before → final | Normal before → final | Hard before → final |
|---:|---:|---:|---:|
| 1 | 1.5/2.4 (n=630) → 1.4/2.5 (n=630) | 0.6/0.9 (n=240) → 0.6/0.9 (n=240) | 0.6/0.8 (n=60) → 0.6/0.8 (n=60) |
| 2 | 3.1/5.0 (n=630) → 3.0/5.1 (n=630) | 2.7/4.5 (n=240) → 2.7/4.6 (n=240) | 3.5/5.0 (n=60) → 3.5/5.1 (n=60) |
| 3 | 6.5/10.3 (n=630) → 6.2/10.3 (n=630) | 6.1/9.8 (n=240) → 6.2/9.9 (n=240) | 6.5/9.7 (n=60) → 6.6/9.7 (n=60) |
| 4 | 10.6/16.3 (n=630) → 9.5/15.3 (n=630) | 9.3/14.5 (n=240) → 9.0/14.6 (n=240) | 9.8/14.8 (n=60) → 9.9/14.5 (n=60) |
| 5 | 13.5/20.4 (n=630) → 10.8/17.3 (n=630) | 13.1/20.1 (n=240) → 12.7/20.1 (n=240) | 13.7/20.3 (n=60) → 14.2/20.8 (n=60) |
| 6 | 16.0/23.7 (n=630) → 11.0/17.6 (n=630) | 16.3/24.5 (n=240) → 15.5/24.1 (n=240) | 17.1/25.4 (n=60) → 16.8/25.6 (n=60) |
| 7 | 19.5/28.0 (n=630) → 11.1/17.7 (n=630) | 21.0/31.4 (n=240) → 19.6/29.7 (n=240) | 22.6/34.2 (n=60) → 21.2/33.0 (n=60) |
| 8 | 23.8/34.6 (n=630) → 11.1/17.8 (n=630) | 25.7/38.4 (n=240) → 23.4/35.4 (n=240) | 27.3/41.7 (n=60) → 26.9/41.1 (n=60) |
| 9 | 28.3/41.9 (n=630) → 11.7/18.8 (n=617) | 30.5/45.5 (n=240) → 27.2/41.1 (n=237) | 33.8/50.2 (n=60) → 31.7/48.2 (n=60) |
| 10 | 32.8/48.9 (n=627) → 12.4/20.0 (n=556) | 35.6/52.0 (n=237) → 32.0/47.2 (n=215) | 39.7/58.2 (n=59) → 38.3/55.9 (n=60) |
| 11 | 37.1/55.3 (n=611) → 12.9/21.0 (n=458) | 41.9/60.0 (n=224) → 38.0/54.4 (n=181) | 44.9/64.1 (n=58) → 43.0/61.4 (n=59) |
| 12 | 41.9/62.5 (n=565) → 15.4/25.2 (n=335) | 46.3/64.4 (n=208) → 44.7/61.4 (n=150) | 49.6/68.6 (n=55) → 50.1/68.8 (n=58) |
| 13 | 46.2/68.4 (n=498) → 17.9/28.8 (n=236) | 54.2/72.7 (n=171) → 52.1/68.3 (n=122) | 56.4/76.0 (n=54) → 56.8/76.4 (n=57) |
| 14 | 49.3/72.3 (n=448) → 20.8/32.8 (n=156) | 58.8/77.8 (n=148) → 57.8/73.8 (n=92) | 61.6/82.4 (n=50) → 61.9/82.0 (n=51) |
| 15 | 54.8/79.2 (n=370) → 23.0/35.6 (n=102) | 66.6/85.5 (n=125) → 66.2/82.6 (n=73) | 65.7/87.0 (n=49) → 68.6/90.1 (n=40) |
| 16 | 58.6/84.0 (n=305) → 24.3/37.5 (n=62) | 75.2/93.9 (n=105) → 77.0/93.4 (n=38) | 71.7/94.2 (n=46) → 77.2/101.4 (n=21) |
| 17 | 62.6/88.9 (n=241) → 25.3/37.6 (n=19) | 84.2/104.3 (n=91) → 100.2/115.2 (n=6) | 78.9/102.2 (n=45) → 78.5/106.0 (n=4) |
| 18 | 69.5/96.6 (n=186) → 31.0/41.0 (n=1) | 91.5/112.1 (n=79) → — | 85.1/110.0 (n=37) → — |
| 19 | 74.8/102.5 (n=149) → — | 97.4/117.7 (n=61) → — | 91.6/118.0 (n=28) → — |
| 20 | 81.1/109.8 (n=111) → — | 104.4/123.6 (n=46) → — | 100.7/130.6 (n=20) → — |
| 21 | 85.4/114.2 (n=70) → — | 109.7/132.2 (n=25) → — | 116.5/146.8 (n=11) → — |
| 22 | 94.5/125.5 (n=42) → — | 111.3/132.2 (n=17) → — | 122.0/158.2 (n=6) → — |
| 23 | 96.3/126.8 (n=17) → — | 121.8/143.4 (n=9) → — | 106.7/138.7 (n=3) → — |
| 24 | 88.6/105.8 (n=5) → — | 120.0/149.8 (n=5) → — | 116.0/152.5 (n=2) → — |
| 25 | — → — | 135.0/163.0 (n=4) → — | 117.0/154.5 (n=2) → — |
| 26 | — → — | 169.5/210.0 (n=2) → — | 121.5/160.5 (n=2) → — |
| 27 | — → — | 179.5/222.0 (n=2) → — | 125.5/165.0 (n=2) → — |

## Early and late shape: one rule

**Round toll:** failing to win costs one additional hero damage through round 8, then one more each round (round 14: seven). Draws charge both heroes. The existing total damage cap and Armor apply; winners pay nothing. The End turn button displays the current toll, the result/log explains it, and the guide states the rule. This changes no card. A gold sink was not added; the measured first intervention is fewer free rounds and faster conclusions.

Controlled toll comparison: same final code, seeds **41–60**, 20 games each; `toll=off` versus default in `bench.gd`. Other rules, bots and hero picking are identical. “Tie rate” counts tied player-rounds / all player-rounds (including ghost fights), not deduplicated pairing counts. Spare gold is the real `gold_left` after the recruit/combat round, not starting bank minus spending.

| Lobby | Toll | Games | Mean rounds | Tie player-rounds | Tie rate | R1–4 tie rate | R12+ tie rate | Mean spare gold | R12+ spare gold | Max spare gold |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| hard_lobby_normal | Off | 20 | 18.80 | 292/2309 | 12.6% | 20.3% | 9.4% | 1.89 | 1.45 | 21 |
| hard_lobby_normal | On | 20 | 15.90 | 271/1985 | 13.7% | 20.3% | 11.7% | 1.90 | 1.46 | 21 |
| hard_lobby_hard | Off | 20 | 18.75 | 306/2380 | 12.9% | 22.2% | 7.1% | 1.04 | 0.70 | 12 |
| hard_lobby_hard | On | 20 | 15.30 | 307/2017 | 15.2% | 22.2% | 12.3% | 1.06 | 0.77 | 12 |

The toll reduced duration by 2.90 and 3.45 rounds. It did **not** reduce draw frequency or spare gold. Every draw now has a positive damage charge (subject to Armor), replacing the old free draws. The bots did not reproduce the human 56-gold bank; early shop choices are unchanged. These limits remain explicit, with no second rule or card power change added.

Reproduction (use separate output folders; CPU limits are external taskset masks):

```sh
tools/sim/bench.sh --cores 1 --seed 1 --out build/sim/round4-final --report build/sim/round4-final/report.md plain_easy=30 normal_easy=30 hard_normal=30 hard_easy=30
godot --headless -s res://tools/sim/bench.gd -- suite=hard_lobby_normal games=20 first_seed=41 out=build/sim/round4-pace-before/hard_lobby_normal toll=off
# Repeat for hard_lobby_hard, then both suites without toll=off in round4-pace-after.
```

## Guide, geometry, bugs and finish

- Ten short guide pages teach the recruit loop before combat; real cards, gold examples and leaf controls demonstrate it. Keyword reminders remain card-local. All ten pages pass the phone canvas check.
- Selecting or placing a card highlights exactly the geometry it reads; F2 highlights B1 and B2, with gold name strips. Shy runs the actual action on isolated state and names departures before confirmation. Forecast tests verify pool, RNG, ids, gold and hand are unchanged. Sergeant has compact ammunition on the tile and full next-throw detail in the reader. Queen wording explicitly names destroyed units’ stats.
- Hero choice waits for the person before bots pick remaining heroes. Hand spells keep the price actually paid. Whirligig same-board moves no longer repeat ownership. Echo explicitly says zero-cost Last Orders repeats give no stats.
- Mag Pye historical seed 202 cannot reconstruct round 14 without the lost human action transcript. Regression fights cover all seven matching slots and a legitimate golden double theft, including ordering before row swaps. No unconfirmed power change.
- Portraits stay on long shop cards; Natterjack name height is measured; the first-hit panel has waiting copy; Mire/Hex labels clear names. PLAYTEST says six tribes. Stable @handles were already default in tool output, now tested.
- Inspected staged 1688×780 renders: guide shop controls, selected Queen geometry with Hedge Witch/Sexton/Natterjack in the shop, and named Shy pre-action warning. First render exposed a too-long Sergeant label; compact tile copy fixes it. These are desktop renders, not a device playtest.

## Validation and limits

- Final `scripts/check.sh --keep-going`: **all ten steps passed**, **1,175/1,175 tests**, 15,547 assertions, strict hook clean. Compilation: 340 scripts/resources, zero failures. The first pass caught three old expectations (Normal refreshes, state keys, old guide page); all were updated to the actual behavior before this clean gate.
- Then, serially, `tools/checks/soak.sh 100 41`: **100 games, seeds 41–140, 1,527 rounds, 4,820 fights, zero violations, exit 0** in 73.4 seconds. This runner deliberately mixes bare-rule, synthetic and slice games. Two no-attacks endings were reported in bare-rule seeds 87 and 120; neither is a rules violation. No crashes or problematic engine log lines. Echo was bought but did not fire in the soak; its behavior is covered by direct regression tests.
- Gate ran before the soak and never at the same time. Controlled pace suites and all four final ladder suites completed without script errors. Final runtime contents were frozen before the clean gate; the final commit adds these records and generated script UIDs.

Runtime logs and raw CSVs are under `build/check/round4-*` and `build/sim/round4-*` (ignored build artifacts). All long jobs had hard timeouts. Only CPU 2 was used while the supplied bench was running; its finished/exit records permitted up to cores 2, 3 and 4 afterwards. Early contended 180-second trials were rerun with completed suites; interrupted files are excluded from this report.

Not completed here: exact historical Mag Pye human-turn replay (no action transcript), the 56-gold human case, a new gold sink, new release exports/device/audio testing, fresh reviewer approval, and full PLAN depth/2,000-game/20-UI-game evidence. The cloud tribe/card round is still separate; no claim of release readiness or broader bar completion is made. The final rule shortens games but does not create more opening shop choices or reduce the measured tie rate.

Phone renders: [guide shop controls](round4-guide.jpg), [selected geometry, readable shop and compact ammo](round4-geometry.jpg), [Shy warning before spending the spell](round4-shy.jpg).

Automatic approval review rejected `git push origin HEAD:refs/heads/ideation/round4`, saying external publication authorization/trust was not established. No retry or alternate route was used; the six local commits are ready for the orchestrator to push.


## Cloud review follow-up — C1 (8 Nov 2026)

Read `origin/ideation/c-review-round4:docs/ideation/evidence/review-round4.md`, reviewing 93c1a50. The toll formula is unchanged. The guide now states that the smaller opening caps reach 12 in round 10 and stay there through the final duel. Newcomer sentence: “Lose or draw and the toll can add damage, but no fight can deal more than 12.” End turn says “Toll: up to N; hit cap C”. The result and log use the actual added damage after the cap, including zero or a partial toll; these totals precede Armor as before.

Validation: `taskset -c 2 timeout 180 godot --headless -s addons/gut/gut_cmdln.gd -gselect=round4 -gexit`: **22/22 tests, 596 assertions, strict hook clean**. New regressions exercise full, partial and fully capped tolls, the permanent cap in a two-player final, and the visible result/log/hint. The ten-page phone guide still fits. Final combined gate and soak follow A1 below.


## Cloud review follow-up — C2 (8 Nov 2026)

Restored the complete one-line `Format:` example above the Round 4 entries (all six retained, including the prior difficulty entry). Corrected the tribes56 follow-up's “The owner will merge” to “The orchestrator will merge”. Validation: Python assertions checked the exact format line, all six headings outside the format, balanced inline backticks in the repaired section and the corrected merge actor; `git diff --check` passed. No owner statement was added.


## Cloud review follow-up — A1 (8 Nov 2026)

The requested target is a three-rung ladder: the plain first-game proxy near third on Easy, Easy clearly ahead of Naive, Normal near 2.5 among Easy and Hard below 3.5 among Normal. The plain policy is still the unmodified `balanced` script; it is an active player that buys, climbs, casts and places each turn, not a human or an idle board.

Final policy: Easy's placement label now accurately says simple (the old random label already used simple hand placement). It reaches tier 5 on the same late curve, refreshes once and buys one spell per turn, retaining its other teaching limits. Normal retains its builds, rule placement, hero choices, tier-6 access and two replacements and buys at most one shop spell per turn from round 12. Its early opening purchases are blocked; spells from other sources can still be cast. These measured policy differences are recorded in DECISIONS. Hard's search, refresh, economy and spell-shopping settings remain. All sides use identical legal rules, card numbers, income and pools. The toll formula and caps are unchanged.

### Selection probes (30 games each; seeds 501–530)

These are tuning samples, not the final numbers. Each row is a separate run with the listed policy; changes are relative to the named preceding probe. `—` means not run. Means below come from focus seats only, shuffled by seed. Build artifacts retain the raw players/rounds/cards/turns CSVs under `build/sim/round4-review-probe*`.

| Probe | Change | Plain among Easy | Easy among Naive | Normal among Easy |
|---|---|---:|---:|---:|
| P1 | Simple placement + tier 5 only | 1.23 | 4.03 | 1.00 |
| P2 | P1 + Easy economy cards | 1.37 | 3.73 | 1.00 |
| P3 | P1 + Easy spells and one refresh; economy still off | 4.87 | 1.00 | 2.07 |
| P4 | P3 without Easy refreshes | 2.57 | 1.30 | 1.03 |
| P5 | P4 without Normal refreshes | — | — | 1.50 |
| P6 | P5 + Normal buy noise 0.3 | — | — | 1.20 |
| P7 | P3 with one spell per turn on both teaching levels | 2.90 | 1.40 | 1.57 |
| P8 | P7 without Normal triple hunting | — | — | 1.40 |
| P9 | P7 without Normal text evaluation | — | — | 1.23 |
| P10 | P7 + Easy buy noise 0.3 / replace margin 5 | 3.50 | 1.07 | 1.60 |
| P11 | P7 with Normal capped at tier 5 | — | — | 1.63 |
| P12 | P7 + Easy text evaluation | 2.87 | 1.57 | 1.03 |
| P13 | P7 + Easy economy cards | 2.97 | 1.33 | 1.10 |
| P14 | P7 + Easy triple hunting | 4.53 | 1.20 | 1.70 |
| P15 | P7 with Normal considering two sampled builds | — | — | 1.03 |
| P16 | P7 without Normal spell purchases | — | — | 2.40 |
| P18 | P7 with Normal spells starting in round 6 | — | — | 1.20 |
| P19 | P7 with Normal spells starting in round 12 (selected) | — | — | 1.90 |

A broader check of P16 on seeds 1001–1100 completed 100 games each for plain_easy (**2.57 ± 0.50**, 69% wins, 76% top 4), easy_naive (**1.62 ± 0.22**, 63% wins, 96% top 4), and normal_easy (**3.11 ± 0.50**). These are selection evidence, not the final ladder: the last figure justified giving Normal limited late spell growth. The superseded Hard suite was stopped and is excluded. P17 was stopped because the intended round guard was not applied; P18 is the corrected round-6 run. No interrupted sample supplies a final number.

The first attempt at P1 completed Normal's games but failed the bench's log check because the sandbox could not write Godot's default user log. P1b repeats it with `XDG_DATA_HOME=/tmp/bramble-round4-review`; all accepted runs use that writable location. No failed/interrupted run supplies a final number. The probes show why merely lifting the tier cap or removing random placement was insufficient, and why several apparently weaker Normal policies were rejected: they actually improved its placement.

Focused policy validation: **34/34 tests, 625 assertions, strict hook clean** (`round4-review-a1-policy-final.log`). New tests exercise paid tier-5 access and the tier-6 stop, one actual spell purchase/cast across both shopping passes and its reset next turn, initially refusing Normal spell purchases, multiple Hard spell purchases, and a failed purchase preserving the spell budget. The final timing/unlimited-Hard revision passes the three focused spell tests (**3/3, 16 assertions**, strict hook clean): round 11 refuses a purchase, round 12 allows one across both shopping passes, and Hard can buy two even with its counter already at 60. C1's state-schema regression also passes **20/20, 659 assertions**.

### Independent final ladder (100 games per suite; seeds 2001–2100)

All final suites use CPU 2 only, one shard, and the same combined C1/C2/A1 runtime. These seeds were not used to select the policy. Placement margins use the existing normal-approximation 95% interval on independent game seeds. A first-time human and the exact historical round-7 Rainbow save are not reproduced by this proxy.

```sh
taskset -c 2 env XDG_DATA_HOME=/tmp/bramble-round4-review tools/sim/bench.sh --cores 1 --seed 2001 --out build/sim/round4-review-final2 --report build/sim/round4-review-final2/report.md --timeout 600 plain_easy=100 easy_naive=100 normal_easy=100 hard_normal=100
```

| Suite | Games | Mean place ± 95% margin | Wins | Top 4 |
|---|---:|---:|---:|---:|
| plain_easy | 100 | 3.11 ± 0.56 | 59% | 67% |
| easy_naive | 100 | 1.48 ± 0.18 | 69% | 98% |
| normal_easy | 100 | 2.33 ± 0.46 | 71% | 81% |
| hard_normal | 100 | 1.57 ± 0.15 | 56% | 100% |

All four final suites completed with exit 0 and no script-error log lines. An independent CSV check verifies 100 focus results per suite, exactly seeds 2001–2100, eight seats per seed and complete unique placements 1–8. The plain policy usually reaches the top four (67%) and its mean is near third; Easy clearly beats Naive; Normal's placement interval is well above 1 and below chance among Easy; Hard's upper placement bound is below 3.5 among Normal. These are the requested 100-game bot comparisons, not a claim about first-time human win rates or completion of the larger PLAN suites.

Game rules and bot policies were frozen before these fresh suites. Some bench stamps precede the A1 commit/rebase because the run began with those same uncommitted policies. After the suites, C1’s toll helper call was shortened to stay below the combat screen’s 1,000-line lint limit; its inputs/output are unchanged, and the 22 round-4 regressions pass again (596 assertions). No simulation rule or policy changed. All runs, tests and checks in this follow-up use `taskset -c 2`; other workers' CPU cores and worktrees were left alone. Raw data/report: `build/sim/round4-review-final2/`; logs: `build/check/round4-review-*.log`.


### Combined gate and soak

The first gate caught three issues before final validation: the combat screen reached 1,002 lines, Godot import tried to save editor settings outside the writable sandbox, and a fixed-seed Easy lobby no longer happened to fly a bird. The shared toll formatter now accepts the two integers directly, bringing the screen to 997 lines with identical output. Final validation uses both writable `XDG_DATA_HOME` and `XDG_CONFIG_HOME` under `/tmp`; no system/user configuration file is changed. The first failed gate is retained in `build/check/round4-review-gate.log`.


The flight expectation was conditional on Easy being cash-short, not guaranteed in every seed. Its deterministic cash-short test now verifies both leaving and returning after two turns; the unplanned Easy whole-game sample still verifies swallowing, and Normal/Hard whole-game samples still require flights and returns. No Bird or bot rule changed. Targeted `test_bot_held`: **27/27 tests, 63 assertions, strict hook clean**. Final gate reruns the entire suite after these fixes.


Final combined `scripts/check.sh --keep-going`: **all ten steps passed**, **1,180/1,180 tests across 99 scripts, 15,579 assertions**, strict hook clean, exit 0. Compilation loaded **340 files with zero failures**. Runtime/test files were unchanged after this passing gate; the last amendment records evidence only. Log: `build/check/round4-review-gate-final.log`.

```sh
taskset -c 2 env XDG_DATA_HOME=/tmp/bramble-round4-review XDG_CONFIG_HOME=/tmp/bramble-round4-review-config scripts/check.sh --keep-going
# After the gate completes:
taskset -c 2 env XDG_DATA_HOME=/tmp/bramble-round4-review XDG_CONFIG_HOME=/tmp/bramble-round4-review-config tools/checks/soak.sh 100 41
```


Then, serially, `tools/checks/soak.sh 100 41`: **100 games (seeds 41–140), 1,522 rounds, 4,800 fights, zero violations, exit 0**, 71.6 seconds. Three `no_attacks` endings (seeds 87, 120 and 130) were report-only and not violations. Coverage reports `trigger:on_home` and `trigger:on_swallow` unreached in this sample; directed unit regressions remain part of the passing gate. Logs: `build/check/round4-review-soak-final.log` and `build/check/soak.log`.

The final ladder finished before the gate; the soak began only after the passing gate completed. Gate and soak never ran together. All requested changes are committed as one commit each for C1, C2 and A1 on `ideation/round4`. No push was attempted in this follow-up; publication is left to the orchestrator. No action was denied by approval review during this follow-up.
