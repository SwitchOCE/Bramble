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
