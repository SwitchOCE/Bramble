# Round 3 fixes

Scope: agreed build-2 review findings, in the requested order. No Ooze/Bird strength tuning and no tribes 5/6. Work stays on `ideation/round3`.

## Method

`tools/sim/round3_probe.gd`: 12 all-Hard lobbies, seeds 41–52; opening plans rotate by seat/seed (32 seats each). Original queue bug fixed for this baseline; balance settings are unchanged. Shops: 10,000 full-pool shops per tavern tier, seed 41; each shop returns its copies before the next. Simulations run in bounded background tool sessions on CPU 2, with a 900-second hard timeout. This is a small diagnostic sample, not a balance verdict. Raw JSON is under `build/round3/`.

## 1. Rule clarity

Golden Changeling firing twice was a bug: a change of side caused the second queue to revisit it. Both initial queues are now captured before triggers. Its one +4/+4 bonus correctly lasts through its return until the fight ends; no permanent recruit buff is applied. Added a 20-seed regression across start orders.

Added glossary reminders, named Shy departure and Nest-loss feedback, explicit front/behind geometry and Seven Whistlers' exclusion of hand Birds. Fight end names the empty board and survivors; unchanged stat text and raw no-room card ids are suppressed. Pipkin warns when the second unit buy uses the cap. Stable CLI `@handle` plays survive buys; removed handles refuse instead of choosing another card. Numeric positions remain for old saves.

Baseline opening placements: tempo **4.156**, economy **4.531**, climb **4.812**, 32 seats each. Baseline late losses reached **33** damage. Shop and per-round comparisons follow in their item sections.

## 2. Phone layout

`taskset -c 2 tests/ui/render_screens.sh recruit_held recruit_held_bird recruit_held_ooze scout_held recruit_slice` at desktop and 1688×780; rendered images inspected. Gold/Tier/Refresh remain visible with birds away. Nest captions and slot names have separate space; Ring chips clear labels. Opponent scout slot centers match the player's on phone. Wrapped side hints reserve measured height. Four focused phone tests cover controls, hint bounds, all seven opposing centers and Nest/Ring caption clearance. [Held](round3-phone-recruit_held.jpg), [scout](round3-phone-scout_held.jpg). No real phone was tested.

Items 1–2 full gate: **all steps passed, 966/966 GUT tests** (shared working-tree validation before their separate pushes). Phone focused run: **4/4, 33 assertions**. Earlier gate attempts caught the long Whistlers text and a phone-test viewport mismatch; both corrected before pushing.

## 3. Shop distribution

10,000 independent shops at each tavern tier, with all copies returned between shops. Share of unit slots at each card tier (%); depleted live pools can differ.

| Shop tier | Before T1/T2/T3/T4/T5/T6 | After T1/T2/T3/T4/T5/T6 | Shops without current tier, before → after |
|---|---|---|---|
| 1 | 100.0/0.0/0.0/0.0/0.0/0.0 | 100.0/0.0/0.0/0.0/0.0/0.0 | 0.00% → 0.00% |
| 2 | 59.8/40.2/0.0/0.0/0.0/0.0 | 49.9/50.1/0.0/0.0/0.0/0.0 | 12.63% → 6.07% |
| 3 | 35.1/39.6/25.2/0.0/0.0/0.0 | 19.9/29.9/50.2/0.0/0.0/0.0 | 30.91% → 5.73% |
| 4 | 20.0/30.0/35.0/15.0/0.0/0.0 | 10.0/14.9/25.1/50.0/0.0/0.0 | 44.82% → 3.09% |
| 5 | 10.1/15.1/30.0/27.9/16.9/0.0 | 5.2/10.0/15.2/24.9/44.7/0.0 | 39.41% → 5.04% |
| 6 | 5.1/10.0/20.0/29.7/22.2/13.0 | 5.1/5.0/10.0/15.1/24.7/40.3 | 43.30% → 4.48% |

Hiring Fair: 6 → 4 gold. It deliberately draws from the same tier-6 pool as a high-tier Triple Reward; eight eligible designs in the current slice. The offer regression proves successive offers advance and access more than one trio.

The shop gate caught a test that exhausted its refresh budget; the test now funds and asserts every refresh. All 968 tests then passed, but the gate falsely rejected the strict-hook marker: `grep -q` closed a large piped log early and `pipefail` treated the writer’s broken pipe as a missing marker. The marker check now consumes the full stream. This preserves strict validation and removes an intermittent false failure.

Item 3 full gate: **all steps passed, 968/968 GUT tests**. Shop probe: 12 lobbies, 185.6 seconds under shared-core scheduling; all 60,000 sampled shops completed.

## 4. Damage and openings

Matched 12-lobby samples before/after damage only, after the shop change. Loss damage is after the round cap and before armor; ties excluded from the mean, included in fight counts.

| Round | Fights before/after | Mean loss before → after | Maximum before → after |
|---|---|---|---|
| 1 | 48/48 | 2.04 → 4.00 | 3 → 4 |
| 2 | 48/48 | 2.65 → 4.00 | 3 → 4 |
| 3 | 48/48 | 2.81 → 4.00 | 3 → 4 |
| 4 | 48/48 | 3.80 → 4.20 | 4 → 6 |
| 5 | 48/48 | 4.51 → 4.82 | 5 → 7 |
| 6 | 48/48 | 5.60 → 5.78 | 6 → 8 |
| 7 | 48/48 | 6.24 → 5.86 | 7 → 9 |
| 8 | 48/48 | 7.14 → 7.17 | 8 → 10 |
| 9 | 48/48 | 8.33 → 7.52 | 9 → 11 |
| 10 | 48/48 | 8.84 → 8.33 | 10 → 12 |
| 11 | 47/47 | 9.89 → 8.62 | 11 → 12 |
| 12 | 42/42 | 10.13 → 9.44 | 12 → 12 |
| 13 | 34/36 | 11.34 → 10.09 | 18 → 12 |
| 14 | 28/31 | 14.58 → 10.21 | 22 → 12 |
| 15 | 23/27 | 13.42 → 10.08 | 23 → 12 |
| 16 | 19/24 | 16.18 → 10.05 | 27 → 12 |
| 17 | 11/18 | 15.78 → 10.56 | 25 → 12 |
| 18 | 8/12 | 13.20 → 10.09 | 22 → 12 |
| 19 | 6/4 | 11.75 → 9.50 | 13 → 11 |
| 20 | 4/2 | 12.00 → 10.00 | 15 → 12 |
| 21 | 3/1 | 15.67 → 8.00 | 23 → 8 |
| 22 | 2/0 | 22.50 → — | 24 → 0 |

| Opening | Seats per arm | Before place | After place |
|---|---|---|---|
| tempo | 32/32 | 4.875 | 4.406 |
| economy | 32/32 | 4.750 | 4.875 |
| climb | 32/32 | 3.875 | 4.219 |

Lower place is better. These are diagnostic samples; they cannot establish close balance or detect small regressions. The same seeds and rotating opening assignments are used in both samples.

Placement arms, seeds 41–43, before/after damage only; focus seat against seven Hard bots.

| Arm | Games before/after | Before place | After place |
|---|---|---|---|
| place_search | 3/3 | 3.667 | 2.667 |
| place_rule | 3/3 | 3.667 | 2.667 |
| place_shuffled | 3/3 | 3.667 | 3.333 |

Three games per placement arm are too few to establish a placement edge. The separate opening probe has 32 seats per opening. Raw arm CSVs and reports are in `build/round3/place_before/` and `place_after/`. Both bounded bench runs completed without runtime errors.

Opening bar: initial baseline means were tempo/economy/climb 4.156/4.531/4.812 (range **0.656**). Shops alone moved them to 4.875/4.750/3.875 (range **1.000**). With the damage change they are **4.406/4.875/4.219**, range **0.656**: the initial gap has not widened, and the shop-only climb advantage shrinks. These small samples do not prove equal strength; none is farther than 0.375 of a place from 4.5. Maximum observed late loss is **27 → 12** in the matched damage comparison (33 in the initial baseline).

Item 4 full gate: **all steps passed, 971/971 GUT tests**. Damage probe completed in 181.4 seconds with shared-core scheduling. Both placement benches completed their three arms (3 games each); all processes stayed on CPU 2 under hard timeouts. Egg and Belly damage regressions use larger tier examples so the new floor cannot hide an incorrect contribution.

## 5. Acorns and largest units

Matched 12-lobby samples before/after Acorn changes only, after the damage change. For each living player-round take the unit with greatest Attack + Health on the recruit board; report mean paired stats and the largest actual pair observed. Sample counts shrink as players are eliminated.

| Round | Player-rounds before/after | Mean largest A/H before → after | Largest observed pair before → after |
|---|---|---|---|
| 1 | 96/96 | 0.5/0.8 → 0.5/0.8 | 2/3 → 2/3 |
| 2 | 96/96 | 1.8/2.9 → 1.8/2.9 | 4/5 → 4/5 |
| 3 | 96/96 | 2.7/4.2 → 2.7/4.2 | 8/10 → 8/10 |
| 4 | 96/96 | 3.9/5.3 → 3.9/5.3 | 12/14 → 12/14 |
| 5 | 96/96 | 4.8/6.5 → 4.8/6.5 | 14/16 → 14/16 |
| 6 | 96/96 | 6.0/8.0 → 6.0/8.0 | 16/18 → 16/18 |
| 7 | 96/96 | 7.7/10.6 → 7.7/10.6 | 21/22 → 21/22 |
| 8 | 96/96 | 9.9/13.6 → 9.9/13.5 | 22/26 → 22/26 |
| 9 | 95/95 | 12.3/16.7 → 12.3/16.7 | 30/34 → 30/34 |
| 10 | 95/95 | 15.0/19.7 → 14.7/19.4 | 40/55 → 34/48 |
| 11 | 87/85 | 17.6/22.9 → 16.9/22.1 | 46/61 → 46/56 |
| 12 | 76/80 | 19.5/24.9 → 18.6/24.1 | 47/62 → 54/49 |
| 13 | 66/70 | 20.9/26.7 → 20.2/26.6 | 48/64 → 57/50 |
| 14 | 56/56 | 22.5/28.7 → 20.8/27.6 | 51/67 → 45/58 |
| 15 | 47/47 | 25.2/31.3 → 23.6/30.0 | 80/88 → 53/60 |
| 16 | 42/40 | 27.5/34.3 → 25.8/33.2 | 72/80 → 53/63 |
| 17 | 31/30 | 27.9/34.7 → 29.9/37.2 | 52/69 → 59/66 |
| 18 | 21/22 | 33.1/39.5 → 31.5/39.8 | 56/73 → 62/69 |
| 19 | 8/13 | 30.5/35.6 → 32.8/40.6 | 39/45 → 64/71 |
| 20 | 4/4 | 45.0/49.5 → 42.5/49.8 | 58/59 → 49/59 |
| 21 | 2/4 | 46.5/53.0 → 46.0/53.8 | 50/57 → 61/71 |

Great Hoard 20 → 16 gold; Treasurer +1/+1 per 2 → per 3 held gold with a +8/+8 cap (golden +16/+16). Dozey now eats at 1 per 2 gold rounded up. Mast still pays 1 or 2 Acorns once per turn; shared limit closes collecting both branches in a turn. Cut-and-Come-Again keeps its printed copies, which obey the bounded Treasurer aura. No card removed.

After the Acorn changes the opening means are tempo/economy/climb **4.812/4.438/4.250**, range **0.562**, narrower than the initial 0.656. Round-15 largest-unit mean drops **25.2/31.3 → 23.6/30.0**; its largest observed pair drops **80/88 → 53/60**. Round 18 remains mixed (mean 33.1/39.5 → 31.5/39.8), so this is reduced acceleration, not a universal size ceiling. The Treasurer's own bounded aura and reversibility also have directed tests.

Item 5 full gate: **all steps passed, 975/975 GUT tests**. Acorn probe: all 12 lobbies completed in 141.4 seconds. Largest pair anywhere in the sample: **80/88 at round 15 → 64/71 at round 19**. New directed tests cover normal/golden/copy ceilings, cashing, Hoard combination, Dozey rounding and Mast's shared once-per-turn payment. Existing card-stat expectations were updated to the printed rules.

### Nest notice correction

The first notice incorrectly said stored Goose strikes were lost. Actual rule: the new Nest uses the new bird's Attack, the old bird still returns, and Mother Goose continues arming all Nests while away even if her own Nest was replaced. Corrected text plus a real sale/replacement/return regression; no Bird strength change.

## 6. Saving plain gold

Money Spider's threshold is 5 → 3 carried gold; normal income still caps at 2 and golden at 4. Focused boundary tests exercise 2/3/5/6/30 gold, normal and golden. Example: 3 saved paid 0 → 1; 6 paid 1 → 2; 30 still pays 2. A player can save the price of a single unit, collect interest, then spend. Hob's borrowing and all other saving cards remain unchanged. No claim of a measured economy win-rate gain is made from this local change.

## Final verification

- Full `source /opt/bramble/env.sh; taskset -c 2 ./scripts/check.sh`: **all ten steps passed; 977/977 GUT tests, 11,574 assertions; strict hook clean**. Writable XDG data/config directories under `/tmp` avoid sandbox log writes outside the worktree.
- `taskset -c 2 tools/checks/soak.sh 100 41`: **exit 0**, seeds **41–140**, **1,751 rounds**, **5,331 fights**, **0 violations**, **0 crashes/log errors**; 125.1 seconds. Two legitimate `no_attacks` endings; all other fights ended with an empty board. Every slice card fired; this is not exhaustive trigger/keyword coverage.
- Every long run used a background tool session and a hard timeout: gates 600 seconds, probes 900 (final confirmation 300), placement bench 900 overall/600 per shard, soak 480. All Godot/gate/bench/soak/render work stayed on CPU 2; no job remains running when this report is completed.
- Measurement stages: shop `6b0f761`; damage `582aeb9`; Acorns `296628d`. The baseline uses the original balance with the Changeling queue fix. Raw CSV/JSON/logs remain under `build/round3/`; the committed tables retain the numbers.
- Six item commits plus one separate Nest wording correction, pushed only to `ideation/round3`. No action denied. No exports, fresh reviewer verdicts, main merge or PR; no Ooze/Bird strength tuning, card removal, or tribes 5/6.

Final confirmation after Money Spider and the notice correction: 12 lobbies, seeds 41–52, 32 seats per opening; tempo/economy/climb **4.812/4.438/4.250**, range **0.562** versus initial **0.656**. Maximum fight loss remains **12**. Completed in 71.0 seconds.

## Cloud review follow-up (7 Nov 2026)

Read `origin/ideation/c-review-round3:docs/ideation/evidence/review-round3.md`, reviewing 52876e8. Changes below are separate commits on `ideation/round3`. Godot, renders and checks use shared CPU 2, with bounded background tool sessions. A focused test selection is used per item; full gate and 100-game soak follow the complete set.

### 1. Acorn reminder values

The schema now contains item-value placeholders, resolved once from each item's `gold_value` when the schema loads. This avoids a second stale Hoard number without recursively loading the unit library. The regression casts Acorn, Stash and Hoard, compares actual gold paid with their values, and checks that their reminders agree and contain no unresolved placeholders.

Item 1 focused test: **1/1, 13 assertions**. A supplementary full GUT run also passed **978/978** tests.

### 2. Shy amount restored

The shared reminder explicitly says **2 gold next turn, 4 if golden**, retaining the walk-out and not-a-sale explanation. The regression gives normal and golden Hob a buff, observes each walk-out and checks the actual queued gold. Focused text suite: **2/2 tests, 19 assertions**.
