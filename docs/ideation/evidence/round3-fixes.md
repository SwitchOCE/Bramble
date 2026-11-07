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
