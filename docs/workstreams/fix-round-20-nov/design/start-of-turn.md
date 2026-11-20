# End-of-fight effects move to the start of the turn (proposal, not decided)

**For dev at 5d697e07** (origin/dev, PR #201).

The owner (20 Nov): "I don't really think we should have any end-of-fight effects. Start-of-turn effects would be better. It's effectively the same thing, but we don't get to show an animation for an end-of-fight effect."

**On dev there are three after-fight effects, not four.** The only `after_fight` code is `grudge_pay.gd`, `relic.gd` and `campaigner.gd`. Adjutant is gone, and Old Campaigner now gives Renown instead of Medals. Grudge and Relic Seeker are the same as on main.

## The owner's question first: does Grudge need the unit alive?

No. Today Grudge pays **every Grudge unit on the board, alive or dead, win, lose or tie**. It even pays +N Health when you weren't outnumbered. This happens because the fight plays on copies, and Grudge pays the real board after it. The code says so: "win or lose, alive or dead" (`grudge_pay.gd:2`). Nothing shows it happening now.

**Proposal: keep it that way.** Reasons:
- At the start of the turn every unit is back on the board, so "alive" would mean "survived a fight you can no longer see". That is hidden state.
- Paying only survivors would mostly pay the back row. The front-row Knights that soak the hits would get nothing, and they are the ones Grudge is for.
- Badgers are already the weak tribe, for the bots and for the owner. A survivor rule is a nerf with no case for it.
- The flavour holds: a grudge is held by the sett, not earned by surviving.

## The effects

All three read last fight's result (outnumbered count, survived) at the start of the next turn.

| Card | Now (dev) | Proposed |
|---|---|---|
| **Grudge** (Brock Cub, Sett Shield-bearer, Armsbearer; Knights through Grudge-keeper) | Card: "Grudge." Reminder: "After each fight, gain +1 Health, and +1/+1 more for each unit you were outnumbered by." | Card: "Grudge 1." (golden "Grudge 2."). Reminder: "At the start of your turn, gain +N/+N for each unit you were outnumbered by last fight, and +N Health." |
| **Grudge-keeper** | "Your Knights have Grudge." | "Your Knights have Grudge 1." (golden "Grudge 2.") |
| **Relic Seeker** | "After each fight, gain 1 gold, or 2 if you were outnumbered by 3 or more." | "At the start of your turn, gain 1 gold, or 2 if you were outnumbered by 3 or more last fight." |
| **Old Campaigner** | "After each fight, give this slot 1 Renown, or 2 if this survived." | "At the start of your turn, give this slot 1 Renown, or 2 if this survived last fight." |

**The Grudge reminder bug** is still there on dev. On a golden the card says +2, but the reminder still says "+1". The reminder in `badger/display.json` has no N. Making Grudge a numbered keyword ("Grudge N", as Fury N is) fixes it: the reminder uses N and the mark shows the number. It also replaces the long golden line ("Grudge gives +2 Health, and +2/+2 more for each.") with "Grudge 2."

## What changes in balance and timing

Almost nothing changes, which is the point.
- **Gold.** Relic Seeker's gold now lands right after the fight. Gold carries over and there is no cap, so it is the same gold at the same moment you can spend it. Better still: pay it the way Shrew Cutpurse does (`gold_next_turn`). Then the "+N gold from the last fight" notice counts it. Today that notice leaves Relic Seeker out.
- **Renown.** Old Campaigner's Renown goes on the slot, and Renown counts from the next fight either way (rulebook 11.7.6), so moving it changes nothing.
- **Sold or moved units.** Nothing can happen between the fight and the next start of turn. The board that is paid is the board that fought.
- **Units bought this turn.** Start-of-turn effects run before the shop opens, so a new unit is never paid for a fight it missed. A unit bought this turn fights, then gets paid next turn, as now.
- **A unit that died.** A Grudge unit is on the board at the start of the turn and gets paid, as now. A keeper that died still gives its Knights Grudge. Old Campaigner gets the smaller count, as now. A return (Molt or Root) counts as survived. Tokens and reservists from the hand get nothing, as now.
- **The first turn.** No last fight, so nothing pays. Today nothing pays either.
- **The last turn of the game.** Today the final fight's pays happen and do nothing, since the game is over. Moved, they never happen. The result doesn't change.
- **Last fight's numbers have to be kept.** The core needs to keep last fight's report on the player until the next start of turn. Today it is thrown away after the after-fight pass.
- **Order.** They run with the other start-of-turn effects, in reading order, after gold and the shop refill (`recruit.gd` `start_turn`). No current start-of-turn effect interacts with them.

## The animation needs one more piece

Moving the effects to the start of the turn doesn't by itself show anything. The recruit screen opens with no events: `_next_round` in `game_controller.gd` calls `_show_recruit` with none, and it does the same on dev. So today's start-of-turn effects don't animate either: Horde-runner's Hopper just appears. To show the move, the recruit screen has to play the events `start_round` logs. Examples: each Grudge unit glowing with "Outnumbered by 2", the +N/+N popping, Relic Seeker's coins flying to the gold readout, Renown rising on Old Campaigner's slot. That is a screen task alongside the rules change.
