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
