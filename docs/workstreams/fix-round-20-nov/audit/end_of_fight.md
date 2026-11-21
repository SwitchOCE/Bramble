# Effects at or after the end of a fight

Code at `13f44dd9` (branch plan/fix-round-20-nov). Paths are under `src/`.

## 1. When "after the fight" runs

The order inside `GameSession.finish_round` (`core/session/game_session.gd:174-203`):

1. `recruit.end_turn` for every living player (`:178-179`). End-of-turn effects run here, before any fight (`core/recruit/recruit.gd:87-100`).
2. For each pair, `_fight(a, b)` (`:227-281`):
   1. `Combat.run` plays the whole fight (`core/combat/combat.gd:114-157`). When it ends, `FightDeaths.finish` builds the result and logs `combat_end` (`core/combat/fight_deaths.gd:166-199`). **No mechanic hook runs at combat end.** The core has no "end of combat" hook (`core/mechanics/mechanic.gd`).
   2. Hero damage is applied to the loser (`game_session.gd:245-255`).
   3. **`_after_fight`** runs for player a, then for player b unless b is the ghost (`:266-268`). It builds a `FightReport` (`:285-297`; `core/state/fight_report.gd`) with `outcome` (won 1 / tie 0 / lost -1), `survivors` (recruit uids alive at the end, returns included), `deaths` and `outnumbered_by`. `outnumbered_by` is counted when the fight starts, before Start of Combat effects, and is fixed for the whole fight (`combat.gd:203-207`).
   4. `Recruit.after_fight` calls `after_fight(ctx, unit, report, params)` on every unit of the player's **recruit board**, in reading order, then on the player's standing mechanics with unit = null (`recruit.gd:574-587`).
   5. The events those calls log are stored in `fight["after"]` (`game_session.gd:270`).
3. `_eliminate()` runs after all fights (`:192`, `:358`).
4. Next round: `start_round` → `recruit.start_turn` (`game_session.gd:123-134`; `recruit.gd:58-82`). This adds income plus `gold_next_turn`, refills the shop, then runs start-of-turn effects.

**Dead or alive.** `after_fight` runs on the recruit board. A fight never removes units from that board: the fight plays on copies (`FightSide`, `core/combat/fight_side.gd:1-9`). So **every after-fight effect fires whether or not the unit died in the fight**, unless its own code checks `report.survived`. Only Old Campaigner checks it. Tokens summoned in the fight, and Reserve units that came from the hand, are not on the recruit board, so they get nothing.

**What the report fields are used for:** `outnumbered_by` by Grudge and Relic Seeker, `survived` by Old Campaigner. Nothing reads `outcome` (win or loss) or `deaths` today (`grep report.` over `src/content`).

## 2. Effects that resolve after the fight (`after_fight`)

| Card(s) | Text (plain / golden) | Mechanic | When in code | If the unit died | Depends on | Shown to the player? |
|---|---|---|---|---|---|---|
| **Grudge**: Brock Cub (T1), Sett Shield-bearer (T2), Armsbearer (T2), and Knights through **Grudge-keeper** (T3) | "Grudge." Golden: "Grudge gives +2 Health, and +2/+2 more for each." Reminder: "After each fight, gain +1 Health, and +1/+1 more for each unit you were outnumbered by." | `content/badger/mechanics/grudge.gd:1-7` (the number only). Paid by the standing, hidden `badger_grudge_pay`, `grudge_pay.gd:12-28`. Grudge-keeper's aura is `grudge_keeper.gd:18-29` | `after_fight` with unit = null, so it runs once per player after every board unit's own after_fight (`recruit.gd:574-580`). Each board unit with Grudge N (its own, or a Knight's taken from the biggest keeper) gains **+N×count Attack, +N×(count+1) Health, permanently** (`grudge_pay.gd:28`, `ctx.buff(..., true, ...)`) | **Pays alive or dead.** The file says so: "win or lose, alive or dead" (`grudge_pay.gd:2`). It pays every unit on the recruit board, including ones that died. A keeper that died still gives its Grudge, because the board is the recruit board | `outnumbered_by` at fight start (Squires in the back row are not counted). Pays +N Health even at count 0. Not win or loss, not deaths | **No.** The `trigger` and `buff` events go to `fight["after"]`, which `GameFlow.finish_round` drops (`game/game_flow.gd:95-107`) and no screen reads. The new numbers just pop when the recruit board is drawn next turn (`screens/card_keeper.gd:524-535`), mixed in with start-of-turn changes. In the fight, hovering over a Grudge or Fury unit adds "Outnumbered by N." (`screens/fight/fight_screen.gd:454-466`). Also, on a golden the reminder line still says "+1" (`content/badger/display.json` badger_grudge has no N) |
| **Relic Seeker** (T2) | "After each fight, gain 1 gold, or 2 if you were outnumbered by 3 or more." Golden: 2 / 4 | `content/badger/mechanics/relic.gd:17-35` | Its own `after_fight`. `ctx.gain_gold` adds to `player.gold` **at once**, right after the fight (`core/recruit/recruit_context.gd:106-118`). Gold carries over, so the player has it next turn on top of income (`recruit.gd:66`). Only one Relic Seeker pays: the biggest, the first on a tie (`relic.gd:26-33`) | **Pays alive or dead** (recruit board, no survival check) | `outnumbered_by >= 3` (`relic.gd:10,22`). Win or lose | **No.** The "+N gold from the last fight" notice counts only fight-log `gold` events (`game/game_controller.gd:111-116`; `game/view_adapter.gd:197-204`), so Relic Seeker's gold is left out. The gold readout shows the total next turn with no breakdown |
| **Old Campaigner** (T2) | "After each fight, earn a Medal. Earn 2 if this survived." Golden: 2 / 4 | `content/pigeon/mechanics/campaigner.gd:13-19`; `Medals.earn` `pigeon/lib/medals.gd:11-15` (+2/+2 permanently for each Medal) | Its own `after_fight` | **Fires if it died**, at the smaller count. `report.survived(unit)` picks the count (`campaigner.gd:18`). A Molt or Root return counts as survived (`fight_report.gd:10`) | Survival only | **No** (same `fight["after"]` gap). The Medal pill and stats change silently at the next recruit draw |
| **Adjutant** (T4) | "After each fight, the units in front of this earn 2 Medals." Golden: 4 | `content/pigeon/mechanics/adjutant.gd:12-25` | Its own `after_fight`. It reads the recruit-board slots in front of it (`:18-21`) | **Fires if the Adjutant died, and gives to units in front that died** ("whether or not they lived", `:2-3`) | Nothing from the fight. It needs a unit in a slot in front | **No** |

These four are the only `after_fight` implementations (`grep "func after_fight" src`: `grudge_pay.gd:12`, `relic.gd:17`, `campaigner.gd:13`, `adjutant.gd:12`).

## 3. In-fight effects whose results last past the fight (not "after the fight")

These resolve during the fight. A side that writes back (a live player, not the ghost) changes the real player at once (`fight_side.gd:1-9`, `:14`, `:44-50`).

| Effect | Card(s) | Code | When | If it died |
|---|---|---|---|---|
| **Sett Sexton** | Sett Sexton (T4): "After a unit in front of this gains Attack from Fury, it gains +2 Attack permanently (2 a fight each)." Golden +4 | `content/badger/lib/badger_rules.gd:69-87` (`sexton_pays`), called at the end of `rage` (`:55-65`); `sexton.gd` holds only the parameters | In the fight, right after each Fury gain. Permanent (`combat.buff(..., true)`), at most `limit` 2 times a fight for each unit | The Sexton must still be on the board (`holder.gone` skips it), and so must the unit in front (`unit.gone`) |
| **Compost from deaths** | Seed (Pip, Bramble Runner, Crab-apple; golden adds 2): "When this dies, add a copy to your Compost" | `content/thorn/mechanics/seed.gd:8-15` → `FightSide.heap_add` (`fight_side.gd:136-152`) | A death effect, in the fight. The heap **is** the player's real heap (`fight_side.gd:47-48`), so the entry is there at once | It fires on death |
| Lone Hawthorn | "Enemies your Thorns kill go into your Compost." | `content/thorn/mechanics/lone_hawthorn.gd:11-22` | In the fight, when an enemy dies | The Hawthorn must be alive (`on_any_death` with its unit) |
| Root (spends Compost) | Blackthorn Sapling, Nettle Skirmisher, Hawthorn Warden, via The Old Hedge | `content/thorn/mechanics/root.gd:43-48` | In the fight, on return. The spend is permanent | n/a |
| Fight gold | Shrew Cutpurse: "The first time this piles on each fight, gain 1 gold." | `content/mouse/lib/mouse_rules.gd:50-52` → `FightSide.add_gold` (`fight_side.gd:417-421`) adds to `player.gold_next_turn` | Logged in the fight. **Paid at the next start of turn** (`recruit.gd:66-69`) | n/a |
| Permanent in-fight gains | Gate Warden, Needle Pikeman, Fencing Master, Molt (+2/+2), Blackthorn Sapling, Sweetbriar, Hazel Coppicer, Padre (slot), Flying Ace (Medals, `medals.gd:21-25`), Brood Mother (Hopper bonus), Famine-caller and Swarm Lord (Tide) | the card's mechanic → `combat.buff(..., true)`, `add_unit_counter(..., true)` or `slot_buff` | At the moment they trigger in the fight, written to the real unit, slot or counter at once | Kept even if it then dies (`medals.gd:18-20`) |

The only end-of-fight bookkeeping is the result: winner, damage, survivors (`fight_deaths.gd:166-199`). "This fight" effects end with the fight copies; nothing is cleaned up on the recruit board.

## 4. What the player sees between the fight and the next recruit turn

- The fight replay ends on the result banner and the damage splash on the loser's portrait (see actions.md).
- After the result, `_on_playback_finished` redraws the fight screen. It shows the leaderboard, Health and the **player counters and heaps after the after-fight effects** (`game/game_controller.gd:133-153`), so a changed Tide or Compost plate pops (`screens/glass_counters.gd:141-148`). No current after-fight effect changes a player counter, though. Grudge and Medals change units, and Relic Seeker changes gold, which is not drawn there.
- `_next_round` → `start_round` runs start-of-turn effects, then shows the recruit screen with no events and only the gold notice (`game_controller.gd:96-103`). After-fight and start-of-turn changes arrive together, as number pops.

**Bottom line for the owner's Grudge question:** Grudge pays every unit that has it, **alive or dead**, win, lose or tie. It pays +N Health even when you weren't outnumbered. Right now nothing shows it happening.

## 5. For comparison: start-of-turn and end-of-turn effects

Start of turn (`recruit.gd:58-82`, in this order): gold = carried gold + income + `gold_next_turn`. Then the shop refreshes, unless frozen. Then `on_start_of_turn` runs for the board in reading order, then standing mechanics.

| Card | Text | Code |
|---|---|---|
| Horde-runner (T2) | "At the start of your turn, get a Hopper." Golden: 2 | `content/locust/mechanics/hopper_to_hand.gd:12-16` |
| (core effect `start_turn_gold`) | gold at the start of turn | `core/mechanics/effects/start_turn_gold.gd:9`. Used only by the stand-in cards (`game/data/stand_in_units.json`), not by any tribe |
| Fight gold paid now | Shrew Cutpurse's gold from the last fight | `recruit.gd:66` |

End of turn (`recruit.gd:87-100`, before the fight; this is the "At the end of your turn" timing): Prophet of the Dust (`tide_end_turn.gd:11`), Whetstone Vole (`whetstone.gd:9`), Grindstone Miller (`grindstone.gd:10`), Dormouse Cook (`cook.gd:10`), Sentry (`sentry.gd:9`), Colour Sergeant (`colour_sergeant.gd:10`), Grenadier Guard (`grenadier.gd:45`), Regimental Sergeant Major (`sergeant_major.gd:21`), and the stand-in-only `end_turn_buff.gd:9`.
