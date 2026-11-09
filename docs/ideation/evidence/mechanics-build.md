# Shared scale mechanics — BRAMBLE ideation

Step 1 / Track B, 9 November 2026, branch `ideation/mechanics`.
These are experimental mechanisms and dials, not a selected balance configuration.
The scale problem is **not fixed yet**: lever selection and the tribe builds remain.

## Built and how to enable

Set configuration **before** `GameSession.create(seed, library, config)`. Defaults
retain both size caps and rate limits, select no synthetic units, and keep hero/spell
scaling off. Configuration is immutable input for a game; create a new game to
change any switch or dial.
No existing card file or its flat numbers changed.

| Piece | Data / configuration | Behaviour |
| --- | --- | --- |
| Biggest answer target | `{"select":"enemies","pick":"biggest"}` | Highest current Attack + Health, any row; uniform ties use fight RNG in combat (rulebook 1.2.2). |
| Most Attack / Health | `{"select":"enemies","pick":"highest_attack"}` / `highest_health` | Same all-row reach and uniform ties, after selector filters. Ordinary random effects retain their effect RNG stream. |
| Proportional stat verb | `{"effect":"stat_fraction","stat":"both","operation":"reduce","numerator":25,"denominator":100}` | Removes a quarter of current Attack and Health; set/gain also supported. Floor fractional amounts; shrinking leaves 0 Attack / 1 Health. Standard duration rules apply. |
| Proportional debuffs | Optional `percent` on `bitter`, `hex`, `jenny`, `jack_daw` | Replaces flat loss. Flat parameters may be omitted when percent is supplied; percentages do not double on golden. Hex's percentage grows per spell and carries into combat. |
| Damage Reduction | `{"id":"damage_reduction","n":2}` or `{"id":"damage_reduction","percent":25}` | Each hit loses N or floor(percent of damage). Before Shield / Shell. |
| Shield | `{"id":"shield"}` | Prevents the first positive hit after reduction; simultaneous hits use event order. |
| Cleave | `{"id":"cleave"}` | Attack damage also hits occupied slots beside the target, per strike, without collateral retaliation. |
| Disable card ceilings | `card_size_caps=false` | Per-game data overlay, described below; defaults true. |
| Disable card rate limits | `card_rate_limits=false` | Independent per-game overlay; defaults true. |
| Select synthetic levers for shops | `scale_levers=[]` | List selected IDs: `scale_engine`, `scale_answer`, `scale_doubler`, `scale_economy`, `scale_biggest_answer`, `scale_defender`, `scale_cleaver`. Never a boolean. Neutral tier-3 source cards in `content/levers/` stay `pool:false`; default libraries do not load them. |
| Engine rate | `scale_engine_percent=25` | End of Turn: recipients permanently gain floor(25% of their own Attack/Health). |
| Flat engine rate | `scale_engine_flat=0` | Set above zero for +N/+N instead of percent. Golden doubles the gain. |
| Engine target | `scale_engine_self=false`, `scale_engine_tribe="Hedgerow folk"` | False: your units of that exact content tribe name; true: the engine itself. |
| Answer rate | `scale_answer_percent=50` | Start of Combat: reduce the biggest enemy's Attack and Health by that percentage. 0 is the null dial; 100 leaves 0/1. Same percentage on golden. |
| Fixed biggest answer | `scale_biggest_answer` (Carry Check) | Start of Combat: reduce the biggest enemy's stats by 50%. Separate from the adjustable answer dial. |
| Defender | `scale_defender` (Steadfast Tester) | Shield and Damage Reduction 2 (4 golden). |
| Cleaver | `scale_cleaver` (Wide Swing) | An 8/8 with Cleave. |
| Doubler | `scale_doubler` (Second Helping) | Your End of Turn effects gain one firing; golden adds two. Multiple doublers add, never recurse; normal limits and trigger guards still apply. |
| Economy rate ceiling | `scale_economy_cap=10` | End of Turn: improve income by 1, then bank that much gold for next turn, capped by this dial. Golden doubles payout; triples keep the most advanced income. Repeated firings improve again. Zero is inert. Ordinary shops and stat buys spend this gold. |
| Hero/spell scaling | `scale_hero_spell_stats=true`, `scale_hero_spell_percent=10` | Each positive printed stat point gives 10% of the recipient's corresponding stat, with the original flat gain as a floor. Defaults off. |

Example compounding carry experiment:

```gdscript
var config := GameConfig.full_game()
config.set_value("card_size_caps", false)
config.set_value("card_rate_limits", false)
config.set_value("scale_levers", ["scale_engine", "scale_answer", "scale_doubler"])
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

`GameSession.create` calls `ScaleOverlay.library_for` once to build a private
configured library before constructing units, heroes or pools. It clears compiled
caches and preserves the caller's library. `Combat.create` uses the supplied library
without rebuilding its overlay. Standalone tools configure their library once
before the combat loop; direct recruit fixtures construct units from that library.
Changing caps, rates, lever selections or dials requires creating a new game.

The schema splits two independent switches, both default true:

| Switch | Removed or relaxed when false |
| --- | --- |
| `card_size_caps` | `permanent_buff_cap`, `most`, `golden_most`, `per_max`, `max_steps`, `takes_max`, `gold_max`; Whistlers' homecoming ceiling; Ring, tribe-bonus and shop-size ceilings. |
| `card_rate_limits` | `once`, `once_per_enemy`, `limit`, `lifetime`, `attack_limit`, `gold_limit`, `uses_per_turn`; Savings' maximum counted turns; Stone Soup/Nell/Kiss/Bubble/Reel-Mistress per-turn or per-fight limits; Figgy's cooldown; first-spell discount and first-free-refresh limits; Harvest's once-per-turn limit; Market Stall's lifetime two-upgrade limit; hero use and buy rates. |

**Designer warning:** classification follows **key names** in `size_cap_overlay`
and `rate_limit_overlay`, not card prose. `most` is SIZE; `limit`, `lifetime` and
`once` are RATE. Review the authored keys when selecting a switch. A card can carry
both kinds of limit. Displayed overlay text removes only disabled clauses, keeping
still-active limits, multipliers and loop guards. Dynamic lever text is generated
from numeric config. Second Helping reads “Your End of Turn effects trigger an
extra time.” Golden adds two extra firings; copies add rather than multiply.

Attack/trigger **config** guards remain on, as do numeric safety (1 billion),
keyword charges, resource availability, seven board slots, hand capacity,
timing/target conditions and recursion rules such as Pack/Pounce's once-per-cycle
and Gabble Ratchet's once-per-Nest guard. Split copies retain their recursion guard.
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

The results below record the earlier build. They are historical evidence, not a
fresh gate for the review follow-up described at the end of this document.

The [early phone render](big-numbers/README.md) checks full 4-3 boards in recruit and
combat. The original render found five-digit clipping. The requester-approved follow-up now
fits stat numerals and uses compact k/m labels, with exact integers one tap away.
The linked evidence has new recruit/combat captures at 4, 5 and 7 digits.

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

No simulation harness or bot files changed. The original five-digit clipping was fixed in the subsequent phone-stat follow-up;
see the updated big-number evidence for the six renders and exact-value access.
No actions were denied.


## Review follow-up — 9 November 2026

The review separates size ceilings from rate limits and makes `scale_levers` an
explicit selected-ID list, default `[]`. Seven IDs are available, including fixed
biggest-answer, defender and cleaver data cards. The adjustable answer still defaults
to 50% reduction. Configuration is fixed per game, and the session prepares the
private library once; combat reuses it. The engine guide and rulebook now describe
those boundaries and the schema key-name classification above.

All three custom enemy selectors were removed in favour of ordinary selectors and
ranked picks: `{"select":"enemies","pick":"biggest"}`, `highest_attack` and
`highest_health`. Ranking ties use uniform fight RNG in combat under rulebook
1.2.2, while ordinary random effects retain their effect RNG stream.

Percent Hex now reaches recruit slips, combat logs, replay state and slot badges.
`hex_amount`/`hex_stored` and event `amount`/`total` remain flat-only;
`hex_percent_amount`/`hex_percent_stored` expose effective versus stored percentage.
A `slot_hex` event's `percent_amount` narrates this application and its `percent`
preserves the active slot percentage even when flat Hex is subsequently applied.
Mixed badges show both components, and capped recruit slips show stored growth.
Shield has an explicit status tag and a linked reminder; replay removes the tag
when Shield is spent. Targeted UI coverage is in `tests/ui/test_scale_feedback.gd`.

Phone rendering evidence and the current font treatment are tracked in the
[big-number README](big-numbers/README.md). All six recruit/combat screenshots at
4, 5 and 7 digits were regenerated and inspected. Stat fonts never fall below the
shared minimum of 31; compact notation adapts to available width, with exact
values one tap away. The layout checker has no stat-font exception. The attribution
now correctly identifies the requester as having asked for compact numbers.

**Review validation: PASS.** `./scripts/check.sh` passed all 11 steps, including
**1,649/1,649 GUT tests, 26,770 assertions**, 53 Python tests, content validation,
import, compilation and unchanged default shop parity (109 units).
[Current gate log](mechanics-review-gate.log.txt).

Focused contracts: **11/11 core review tests, 383 assertions**
([log](mechanics-review-core.log.txt)); **4/4 Hex/Shield UI tests, 32 assertions**
([log](mechanics-review-ui.log.txt)); **6/6 phone-number tests, 1,844 assertions**
([log](big-numbers/focused.log.txt)). The existing scale suite also passes 20/20.
These cover both overlays independently and together, each lever alone, numeric
text and additive doublers, new-card combat, trigger guards, ranked RNG ties,
percentage feedback, minimum fonts, exact-value access and library reuse.

Short default soak: **PASS**, `tools/checks/soak.sh 12 93001`, seeds 93001–93012:
**12 games, 206 rounds, 643 fights, zero violations**; every fight ended with an
empty board, without attack/trigger-limit stalls.
[Current soak log](mechanics-review-soak.log.txt).

All Godot runs sourced `/opt/bramble/env.sh` and ran sequentially under
`systemd-run --user --scope -p MemoryMax=3G` and `timeout`. `combat.gd` is 931 lines.
No `tools/sim` or bot files changed. No approval actions were denied.
