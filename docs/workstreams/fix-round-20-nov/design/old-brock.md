# Old Brock, Last of His Sett (proposal, not decided)

**For dev at 5d697e07** (origin/dev, PR #201). Old Brock's card and code are the same on dev as on main. The bot and fight-engine numbers below were measured before the dev Mouse and Pigeon reworks, so treat them as rough.

T6 8/20. "After a friendly unit dies, gain its Attack and Health this fight." Golden: double.

The owner (20 Nov): "How is Old Brock rated by the bots? Surely he's considered to be overpowered."

## What the bots say

- **Simple bots** value him at 62.8, from tier and stats only. They can't read his text.
- **Blue** (league bot) buys him 92% of the times he's offered. It values him at about 110, 5th of 95 cards. Blue rates him as a top card.
- **Red** never buys him, but red's value for him is an untuned first guess. That is a gap in the bot, not a verdict.
- **Boards holding him** win more fights than with any other tier 6 card: +0.09 to +0.17. The samples are small, because he turns up late (rounds 14-16).
- **Power on the fight engine:**
  - A full mid board: about x4-5 his stats, which is 5-7 tier 6 bodies. The tier guide's in-fight target is about 6, so this is on target.
  - A big late board: about 19 bodies, three times the target.
  - What explains both: he is a **board multiplier**. The plain side needs about x2.2 its whole board to break even, whether the board is mid or late (`scratchpad/brock/board_scale_results.json`). So his worth grows with everything else on the board.
  - Sortie is the only counter seen.

So: on target mid-game, about 3x over late, and one strong bot agrees he's top-tier.

## His defence

He is on target where most games are decided, mid board. Badgers are the weakest tribe, for both bots and for the owner, and he may be part of what keeps them in the game. A T6 is meant to be "a big scaling payoff". He has a real counter (Sortie reaches him in the back row). Late, every scaler is big, not only him. The samples are small, red's view is a guess, and the 20 Nov rule says balance needs bots that reach at least a local maximum. Neither league bot plays Badgers specially.

**Why the case against still wins, narrowly:** the late-game excess comes from how he is built, not from his numbers. His gain is a share of the board, so every buff a unit owns (Grudge, Fury gained in the fight, Gate Warden's growth, the Mice's permanent Attack) also buffs him. He takes "own" stats (shared ruling 43), so Renown, Tide, auras and lent stats don't reach him. That will get worse as the stat scale rises, which the owner wants. Fix how he scales and leave his mid-board power alone.

## Support check: what feeds him

- **Every permanent scaler on his board.** A unit with +30/+30 from Grudge gives him +30/+30 more when it dies. This is the main cause of the late excess.
- **Units that die twice:** Molt and Root returns pay twice. On dev, Privates and reservists step into slots and die again (Recruiting Sergeant, Bugler, Quartermaster, Air Marshal).
- **Tokens:** Hoppers, Cousins, Privates. The "real Locust board" scenario gave him more (x1.9 the board) than the "real Badger board" (x1.6).
- **Sword-heir** (T3, the same effect for the unit in front). Its inherited stats pass on to him when it dies.

Fixing the feeders instead (Hoppers, the Locust pass) would not touch the main cause, the permanent scalers. If the Locust pass cuts Hopper counts as the owner wants, that lowers his Locust value too. Don't count it twice (no double tap).

## Four kinds of change

| Kind | Option | What it does |
|---|---|---|
| Numbers | "gain **half** its Attack and Health" | Halves everything. Late lands at about 1.5x the target, but mid drops to about 3 bodies, half the target: a nerf where he is fine. |
| Economy (tier) | No tier above 6. The lever left is his body: 8/20 to 6/14 | He dies sooner, before the late collection. It barely touches the multiplier, and it makes a back-row capstone fragile. Weak. |
| Replace | A Badger capstone on Outnumbered, the tribe's own idea: "Start of fight: Your Badgers gain +3/+3 this fight for each unit you're outnumbered by." | A fixed payoff that fits the tribe. It loses a card that works and that players like, and it needs its own costing. |
| Rework | "After a friendly unit dies, gain its **base** Attack and Health this fight." (Golden: "double its base Attack and Health".) | He counts the card's printed stats, not its buffs. Mid boards (mostly near printed stats) keep most of his value. Late, he is cut to about a fixed 5-6 bodies, because buffs no longer pass through him. The Sword-heir chain stops feeding him. |

## Recommendation

**The rework: count base stats.** It aims at the one thing that is wrong, his scaling with the rest of the board, keeps the fantasy and the mid-board power, and needs no other card to change. The golden still doubles the cool part. One wording point for ux-copy: "base" has to be defined in the reminder ("its stats as printed; goldens are double"), or the text could say "printed".

**How to check:** rerun the board-scale scenarios on the fight engine (mid, late big, real Badger, real Locust) with base stats. The target is about 6 tier 6 bodies on both the mid and the late board. Then, in a league with a bot that plays Badgers to a local maximum, his fight lift should sit inside the tier 6 pack.
