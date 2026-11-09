# Shared scale mechanics — BRAMBLE ideation

Step 1 / Track B, 9 November 2026, branch `ideation/mechanics`.
These are experimental mechanisms and dials, not a selected balance configuration.
The scale problem is **not fixed yet**: lever selection and the tribe builds remain.

## Built and how to enable

Set configuration **before** `GameSession.create(seed, library, config)`. Defaults
retain card caps, exclude the four synthetic units, and keep hero/spell scaling off.
No existing card file or its flat numbers changed.

| Piece | Data / configuration | Behaviour |
| --- | --- | --- |
| Biggest answer target | `{"select":"biggest_enemy"}` | Highest current Attack + Health, any row; ties F1–F4 then B1–B3; no RNG consumed. |
| Most Attack / Health | `highest_attack_enemy`, `highest_health_enemy` | Same all-row reach and deterministic ties, after selector filters. |
| Proportional stat verb | `{"effect":"stat_fraction","stat":"both","operation":"reduce","numerator":25,"denominator":100}` | Removes a quarter of current Attack and Health; set/gain also supported. Floor fractional amounts; shrinking leaves 0 Attack / 1 Health. Standard duration rules apply. |
| Proportional debuffs | Optional `percent` on `bitter`, `hex`, `jenny`, `jack_daw` | Replaces flat loss. Flat parameters may be omitted when percent is supplied; percentages do not double on golden. Hex's percentage grows per spell and carries into combat. |
| Damage Reduction | `{"id":"damage_reduction","n":2}` or `{"id":"damage_reduction","percent":25}` | Each hit loses N or floor(percent of damage). Before Shield / Shell. |
| Shield | `{"id":"shield"}` | Prevents the first positive hit after reduction; simultaneous hits use event order. |
| Cleave | `{"id":"cleave"}` | Attack damage also hits occupied slots beside the target, per strike, without collateral retaliation. |
| Disable card ceilings | `card_size_caps=false` | Per-game data overlay, described below; defaults true. |
| Put synthetic levers in shops | `scale_levers=true` | Adds `scale_engine`, `scale_answer`, `scale_doubler`, `scale_economy` as neutral tier-3 pool units. Source JSON in `content/levers/` stays `pool:false`; default libraries do not load it. |
| Engine rate | `scale_engine_percent=25` | End of Turn: recipients permanently gain floor(25% of their own Attack/Health). |
| Flat engine rate | `scale_engine_flat=0` | Set above zero for +N/+N instead of percent. Golden doubles the gain. |
| Engine target | `scale_engine_self=false`, `scale_engine_tribe="Hedgerow folk"` | False: your units of that exact content tribe name; true: the engine itself. |
| Answer rate | `scale_answer_percent=50` | Start of Combat: reduce the biggest enemy's Attack and Health by that percentage. 0 is the null dial; 100 leaves 0/1. Same percentage on golden. |
| Doubler | `scale_doubler` (Second Helping) | Your End of Turn effects gain one firing; golden adds two. Multiple doublers add, never recurse; normal limits and trigger guards still apply. |
| Economy rate ceiling | `scale_economy_cap=10` | End of Turn: improve income by 1, then bank that much gold for next turn, capped by this dial. Golden doubles payout; triples keep the most advanced income. Repeated firings improve again. Zero is inert. Ordinary shops and stat buys spend this gold. |
| Hero/spell scaling | `scale_hero_spell_stats=true`, `scale_hero_spell_percent=10` | Each positive printed stat point gives 10% of the recipient's corresponding stat, with the original flat gain as a floor. Defaults off. |

Example compounding carry experiment:

```gdscript
var config := GameConfig.full_game()
config.set_value("card_size_caps", false)
config.set_value("scale_levers", true)
config.set_value("scale_engine_self", true)
config.set_value("scale_engine_percent", 50)
config.set_value("scale_answer_percent", 25)
config.set_value("scale_hero_spell_stats", true)
var game := GameSession.create(123, UnitLibrary.load_dir(), config)
```

Units may use the new selectors/effects/keywords directly, independently of synthetic
levers. Reminder text lives in `content/schema/effects.json`; the existing keyword
UI reads it. The [rulebook](../../design/rulebook.md) and [engine guide](../engine.md)
record rounding, ties, prevention, collateral and repeat timing.

## Overlay boundary

`ScaleOverlay.library_for` copies experiment content before the session creates units,
heroes or pools, clearing compiled caches and preserving the caller's library. Source
card text is retained as baseline text; experimental switches are recorded separately.
Combat and RecruitRules construction also apply the overlay, reusing an already
configured library. Direct recruit fixtures should construct units from the rules
library (or use `ScaleOverlay.library_for` first). Changing caps halfway through a session is not supported.

`size_cap_overlay` in the schema declares removed fields (`permanent_buff_cap`,
`most`, `golden_most`, `per_max`, `lifetime`), unbounded fields (`limit`, `max_steps`,
`takes_max`, `gold_max`, `attack_limit`, `gold_limit`, `uses_per_turn`), and disabled
one-shot ceilings (`once`, `once_per_enemy`). It also removes the Snail's lifetime
turn ceiling and Whistlers' three-homecoming ceiling. Market Stall's per-player and
unit-shop ceilings, Ring size, Pipkin's buy limit, Stone Soup/Nell/kiss payment limits,
Bubble's original-body split count, Harvest Supper's turn/size limits and
Reel-Mistress's repeat-dance limit are disabled
in this mode. Split copies retain the recursion guard.

Attack/trigger **config** guards remain on, as do numeric safety (1 billion), resource
availability, seven board slots, hand capacity, timing/target conditions and recursion
rules such as Pack/Pounce's once-per-cycle and Gabble Ratchet's once-per-Nest guard.
The economy lever's experimental config ceiling remains a separate explicit dial.

Hero/spell scaling covers targeted and board buffs, activated and passive powers,
combat-start hero buffs, slot buffs and standing tribe bonuses. Delayed buffs lock in the scaled amount at cast time. Empty-slot buffs use
mean living board Attack/Health at cast time; tribe bonuses use the lesser mean.
Negative stat changes, unit text and explicitly proportional effects are unchanged.

Minimal integration outside the owned mechanics directories wires the isolated
library into GameSession, opt-in units into UnitPool, extra end-turn firings into
RecruitEvents, cap state into recruit/Market Stall rules, percentage Hex into snapshots,
and optional schema parameters into the content checker. No sim or bot files changed.

## Evidence

The [early phone render](big-numbers/README.md) checks full 4-3 boards in recruit and
combat. Four digits read tightly; five digits clip on both screens. A five-digit era
needs a separate UI badge/layout change. This task does not silently abbreviate stats.

Focused tests in `tests/core/test_scale_mechanics.gd` cover selectors, fractions,
all proportional debuffs, prevention and collateral damage, overlay isolation and
payment limits, opt-in pools, both engine modes, the answer dial, doubler limits and
trigger guards, income spending, reminders, and recruit/combat hero/spell scaling.
Focused result: **20/20 tests, 134 assertions**, no warnings or pending/risky tests
([log](mechanics-focused.log.txt)). The content checker also has three new schema
validation tests. Final gate and short-soak results follow below.


Final gate: **PASS**, `./scripts/check.sh`, all eleven steps. **1,628/1,628 GUT
tests, 24,512 assertions**, plus 53 Python tests, content validation, import,
compilation and default shop parity (109 units). [Gate log](mechanics-gate.log.txt).
The existing default library/state contract tests pass without changing their expected
counts or fixture keys. `combat.gd` is 930 lines, below its 1,000-line lint limit.


Short default soak: **PASS**, `tools/checks/soak.sh 12 92001`, seeds 92001–92012.
**12 games, 204 rounds, 629 fights, zero violations**, all fights ended with an empty
board; no attack/trigger-limit stalls. The three seed modes cover legacy defaults,
the real full-game pool, and fixture content (four games each). [Soak log](mechanics-soak.log.txt).
Both gate and soak ran after sourcing `/opt/bramble/env.sh`, one Godot at a time,
under `systemd-run --user --scope -p MemoryMax=3G` and `timeout`.

No simulation harness or bot files changed. The only remaining UI limitation is the
five-digit clipping recorded in the early phone check; a UI resize is a follow-up,
not a hidden reduction in the mechanics' numeric range. No actions were denied.
