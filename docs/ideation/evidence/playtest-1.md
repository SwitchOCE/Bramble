# Playtest round 1: Ideation build 1

Three fresh reviewers, not shown each other's work, played 12 full games through `tools/play`, on ideation/main at ff1cc2c. They saw the UI only as screenshots. Saves stayed in the session scratchpad.

| Reviewer | Angle | Games | Verdict |
|---|---|---|---|
| A | Economy, greed by hand | 5: 3rd, 7th, 7th, 7th, 1st (no greed) | Good, not very good: economy close to a trap, two tribes get thin |
| B | Board and scouting | 4: 8th, 6th, 6th, 6th | Not there yet: one or two snowballing units decide games, no late game forms |
| C | First hour | 3: 5th (Easy), 6th (Normal), 2nd (Hard) | Good, not very good: ladder doesn't read, tier 6 hollow, one card dominates |

## Agreed by all three

- **Where units stand is a real decision,** most turns from about round 3 or 4. Rings on slots, the brick wall and Hex felt fresh. It reads as its own game on top of a Battlegrounds shell.
- **Only 2 or 3 builds felt different,** and they end the same way: one huge unit stacked with cheap spells.
- **Dozey and Hedge Witch run away.** Dozey 76/106 by round 10, 96/94 by round 13. A tier 1 Witch hexing -29 and -45.
- **Stat spells outclass units:** 2 gold for +4/+4 or more, against 3 gold for a 2/5.
- **Late shops are hollow:** mostly tier 1 and 2 units at tier 6, gold unspent, turns reduced to refreshing for spells.
- **Rounds 1 and 2 are nearly scripted.**

## Agreed by two

- Games end before a late game forms: losses cost 9-15 from about round 6 against 30 Health (A, B).
- Belladonna in the front row silently does nothing (B, C).
- Ghost fights aren't labelled (B, C).
- "You goes first", "You's F1" (B, C). "You's" was fixed in build 1's log; the tool's line wasn't.
- Rainbow Chaser, Treasurer, Sexton Beetle, Old Mother Mast and Charcoal Burner fell flat (at least two of these per reviewer).
- Acorn plans don't form (A partly, C): Stash rarely reached.

## From one, worth fixing

- **Economy (A, whose job it was): too weak.** Holding gold left A at 2 health by round 7 with gold topping out at 15-20. Hob's debt costs tempo, and Jill's drop resets the upgrade cost so it had no use. Small sample.
- Easy feels no easier: died earliest there on one game (C).
- Bots shuffle: about half their units keep a slot between rounds, which blunts scouting (B).
- Discover offered only 2 options at tiers 4 and 6 (A). Triple Reward offered only Mast or Queen (C).
- A triple silently wipes a pending Cold Frame and the Dozey timer (A). Triple Reward arrives next turn with no warning (B).
- Raw ids in the fight log, such as `spill_shrewlet` (B). Ghost shows no hero (B).
- The tool's scout shows no Hex value (C). Keywords lose their names in the tool's list (C).
- Scout panel covers the shop; game-over "Round by round" box mostly empty (B). Board tags like "Ability" say nothing without a tap (C).
- The guide and test shots mention Oozes and Birds, which aren't in the lobby yet (A, B, C all noticed the mismatch).
