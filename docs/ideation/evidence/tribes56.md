# Bog folk and Hunters: implementation and evidence

Branch `ideation/tribes56`, 7 Nov 2026. The owner's bar is interesting designs and strategic
depth. Great beasts remain on file. Round 3 fixes through `5e406fa` were merged as `4164d7f`.

## Built

All 14 Bog folk shop cards plus Prince Restored and Peatling; all 14 Hunters. The shared bell
runs after Mag Pye and before Goose/heroes/ordinary Start of Combat. Snapshot marks, first-claim
patches, live Bitter/aura distinctions, single Take credit, named replies and finite Pounce
chains follow the binding review. Costing exceptions and implementation calls are in DECISIONS.md.
Pack has its own cycle accounting; Poach reserves a real pool copy and expires its extra offer
after the following recruit phase. Ermeline discounts one successful upgrade.

Six bot strategies: Bog Bitter, Tongues and Borrowed Ground; Hunters Open Season, Sett and Pact.
The placer matches public scout lanes, distinguishes Mire/Quarry/loan targets, avoids Egg marks,
backs patches with Snap, and arranges Pack support. All seats receive scouts; carry slots remain
stable during fight search. Directed bot tests cover these choices and discounted Belly buys.
This establishes intentional play, not a measured positioning advantage.

Board patches and paw marks are visible in scout and combat, with reed/gold maker links. Empty
patches persist; marks follow their animal. Pack joins, Pounce, Takes, Poach, kisses and transforms
have specific feedback. A selected Poach offer states its provenance, price and refresh lifetime.
The guide and shared keyword glossary explain the rules.

## Renders inspected

Ran `tests/ui/render_screens.sh` for scout_lanes, scout_lanes_select, combat_lanes,
combat_lanes_after, recruit_poached and guide_9 at 1920×1080 and 1688×780. The implementation
reviewer inspected all lane states, and the lead inspected phone scout/selected offer/combat and
desktop scout. After art export the lead rendered and inspected fresh phone scout/combat shots
and refreshed the retained evidence images. Mud labels sit below stats; quarry links and Pack brackets remain visible, with
selected rules and economy controls available together. Captured JPEGs are in
`build/screens/jpg/`; retained evidence images are beside this file: [phone scout](tribes56-scout-phone.jpg),
[phone combat](tribes56-combat-phone.jpg), [desktop scout](tribes56-scout-desktop.jpg).

## Validation

Earlier Bog-only checkpoint: full gate passed 1,030 tests; soak seeds 53–152 passed 100 games,
1,704 rounds and 5,294 fights, zero violations. This is historical five-tribe evidence.

Six-tribe directed coverage includes 24 normal/golden Bog mirrors and 24 Hunter-versus-Bog
fights before each soak, including Belly refills, third kisses, Pack/Pounce limits and Take
uniqueness. Preliminary six-tribe soak seeds 53–64: 12 games, 636 fights, zero violations; every
new Hunter fired naturally in that sample, as did the restored Prince. Peat Cutter did not fire
in the earlier 100-game natural sample and has directed tests.

Checkpoint `a712dd0`: full gate PASS, 1,098 tests across 85 scripts, 13,852 assertions; all steps
passed. One final-asset gate attempt hit its seven-minute timeout near the final UI tests while
sharing core 2 with the probe. The gate was then rerun without the probe.

**Final full gate: PASS**, `source /opt/bramble/env.sh; taskset -c 2 ./scripts/check.sh`: all
steps pass, 1,098 tests across 85 scripts, 13,792 assertions, 112.8 seconds of GUT tests.
Portrait checks pass with an empty pending list.

**Final soak: PASS**, `taskset -c 2 tools/checks/soak.sh 100 53`: 100 games, seeds 53–152,
1,743 rounds, 5,341 fights, **0 violations**, exit 0, 93.5 seconds. Directed copy/text-transfer,
24 Bog mirrors and 24 Hunter-versus-Bog fights passed first. 5,338 fights ended board-empty,
three with neither side able to attack; none hit attack/trigger limits. Natural events include
1,944 patches, 2,807 Quarry marks, 771 Takes, 406 Pack triggers, 320 Pounces and 96 Poaches.
Every slice card recorded activity, including Peat Cutter (27) and the restored Prince (64).
These are reachability counts, not evidence of strong play or every branch firing.

The keyword collector still lists Borrowed, Bristle, Hunker, Mired, Pin and Stalled as quiet.
It does not fully map status/alias events: the same run records 856 Bristle and 641 Pin triggers
and 1,944 Mire patches. No keyword-coverage cleanup was made in this task; do not treat that
collector's list as proof those rules did not execute. Directed tests cover the new lane rules.

## Measurements

Command: `taskset -c 2 godot --headless -s res://tools/sim/tribes56_probe.gd -- 6 56000`
after sourcing `/opt/bramble/env.sh`. **36 completed games**, six Normal focus games per tribe,
seeds 56000–56035. Focus seats rotate (`seed % 8`), with a pinned tribe strategy round-robin
against seven unpinned Normal bots. Each new strategy appears twice; each Hedgerow strategy
three times. All eight seats scout; all six tribes are in every lobby. Earlier 24- and
12-game-per-tribe attempts were stopped for runtime and excluded. Raw per-game placements,
strategy IDs and counts: [focus/shop data](tribes56-focus.json).

| Tribe | Focus wins/share | Mean place | Final board on-tribe | Shop units on-tribe | Shops observed |
|---|---:|---:|---:|---:|---:|
| Hedgerow folk | 0/6 (0.0%) | 5.67 | 29/38 (76.3%) | 97/801 (12.1%) | 177 |
| Fairies | 2/6 (33.3%) | 3.67 | 17/32 (53.1%) | 140/964 (14.5%) | 194 |
| Oozes | 0/6 (0.0%) | 4.67 | 23/41 (56.1%) | 110/793 (13.9%) | 159 |
| Birds | 2/6 (33.3%) | 3.50 | 19/40 (47.5%) | 176/1027 (17.1%) | 185 |
| Bog folk | 0/6 (0.0%) | 3.67 | 30/42 (71.4%) | 138/861 (16.0%) | 188 |
| Hunters | 0/6 (0.0%) | 5.17 | 28/42 (66.7%) | 94/695 (13.5%) | 151 |

Final board share uses the focus seat's last recorded board before elimination. Shop samples
count focus-visible units at phase starts and after refreshes, including retained Poach offers;
they measure exposure, not independent pool draws. Spells are excluded. Initial shops are
sampled after session creation. This is a small reachability/assembly sample, not a balance or
positioning advantage benchmark: zero wins in six games does not establish a weak tribe.

**Lobby call: retain all six.** Visible shop share spans 12.1–17.1%, while focus boards assemble
47.5–76.3% on-tribe, including Bog 71.4% and Hunters 66.7%. This sample gives no shop-thinness
reason to rotate a tribe out. Mixed Borrowed Bog and Sett builds deliberately buy other tribes.
Revisit if human play or a larger comparison shows painful targeting/tripling scarcity. Do not
tune the 3.67 Bog / 5.17 Hunter mean placement from six games per tribe.

## Art and limits

Portraits are generated last with `tools/art/run-codex-image.sh`, using Mag Pye and Mrs Burdock
as style references. Prompts are retained in `tools/art/prompts/tribes56-*.txt`. All 30 generated portraits were
visually inspected on a contact sheet, exported and verified as
512×512 JPEG in assets/portraits. The pending list is empty. Contact sheet: [portraits](tribes56-portraits.jpg). No portrait generation failed.

Not done: a new human playtest, a large Hard-bot balance/placement benchmark, or the broader
ideation release criteria. No Great beasts are implemented. The requested `evidence/placing.md`
is absent in this checkout; `position-test.md` and `design-review-3.md` supplied that context.
