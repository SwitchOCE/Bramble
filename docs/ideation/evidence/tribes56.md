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
desktop scout. Mud labels sit below stats; quarry links and Pack brackets remain visible, with
selected rules and economy controls available together. Captured JPEGs are in
`build/screens/jpg/`; retained evidence images are beside this file.

## Validation

Earlier Bog-only checkpoint: full gate passed 1,030 tests; soak seeds 53–152 passed 100 games,
1,704 rounds and 5,294 fights, zero violations. This is historical five-tribe evidence.

Six-tribe directed coverage includes 24 normal/golden Bog mirrors and 24 Hunter-versus-Bog
fights before each soak, including Belly refills, third kisses, Pack/Pounce limits and Take
uniqueness. Preliminary six-tribe soak seeds 53–64: 12 games, 636 fights, zero violations; every
new Hunter fired naturally in that sample, as did the restored Prince. Peat Cutter did not fire
in the earlier 100-game natural sample and has directed tests.

Final gate and 100-game six-tribe soak: pending the final asset/measurement step.

## Measurements

Pending: `tools/sim/tribes56_probe.gd`, 24 Normal focus games per tribe, seeds 56000–56143.
Each focus seat rotates through the lobby, pins its tribe's strategies round-robin and faces
seven unpinned Normal bots. All six tribes appear in every lobby. Report win share, mean place,
final on-tribe board share and visible on-tribe shop-unit share, with denominators. Shop samples
include starts and refreshes, including retained offers; they measure exposure, not independent
draws. This small sample does not justify strength tuning or a claim that placement now wins.

## Art and limits

Portraits are generated last with `tools/art/run-codex-image.sh`, using Mag Pye and Mrs Burdock
as style references. Prompts are retained in `tools/art/prompts/tribes56-*.txt`. Final export is
512×512 JPEG in assets/portraits; successful portraits leave the explicit pending list.

Not done: a new human playtest, a large Hard-bot balance/placement benchmark, or the broader
ideation release criteria. No Great beasts are implemented. The requested `evidence/placing.md`
is absent in this checkout; `position-test.md` and `design-review-3.md` supplied that context.
