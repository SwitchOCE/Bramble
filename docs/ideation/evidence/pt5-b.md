# Playtest pt5-b: build 7 (b2c3f01), fresh player, 4 games

Lens: a player who has played a little Hearthstone and never an auto-battler. Played with `tools/play/play.sh` against the full-strength bots, after reading the how-to-play.

**Places:** 1st (Bracken, Hunters), 1st (Pipkin, Bog folk), 7th (Hob, Birds, out in round 9), 4th (Mousewife, Hex Witch and Oozes).

**Verdict: good, not very good.** There's real strategy here, but the text and the fight log still need an apology.

**What's best:** placement decisions that come from Scout. Mire traps, Hex lanes and Whirligig row swaps made me reread the enemy board every turn. The Hunters Take cascade with Laird was exciting to watch.

## Top 5 problems
1. **Too many keywords, and some text you can't parse.** I had to look up Pass, Cycle, Take, Pounce, Mire/Mired, Spill, Touching, Bell, Swoop and Bristle. These four I couldn't parse: Pass ("…or keeps it. While recruiting, at End of Turn"), Brother Wolf ("It lets them attack first"), Changeling ("It fights for you until it attacks"), Young Brock ("…and the enemy across from this as quarry"). **This alone stops "very good".**
2. **The fight log is vague.** "X's ability goes off", an undefined "-- Bell" line, and Swoop/Bristle used in fights but never defined unless you own one. Two units with the same name can't be told apart ("Hasty Pudding (F1) loses mired / (B1) gains mired"). Rings print as raw `{slot: Ring +1/+1}`. Units have two sell tags. A Hob sat at "health 0" without being out.
3. **The damage curve is harsh and swingy.** Losses cost 7–12 from round 6. In game 4 I went 8–0, then three losses of 12 took me to 6 health. Last Stand then gave a three-way finish with everyone on 1 health. That was tense, but it felt artificial.
4. **The bots don't adapt.** Wren kept a 30/30 Queen on a +18 Ring slot for two fights after my Whirligig had moved it off. No bot answered my Mire placements. Early bots are soft: I went 5–0 and 8–0 with simple play.
5. **Hero and tribe traps.** Hob's loan repeats every turn and quietly cost me about 6 Health. Bracken's power does nothing once the board fills. Fly South cost me tempo: Birds sell for 0 gold, the Egg is 1/1, and a unit standing on a Nest stops it counting for Redbreast.

## Builds that felt different
Hunters (Take snowball), Bog folk (Mire control, the clearest positional build), and Hex Witch with spells plus Oozes (resilience). Birds felt flat.

## Lens answers
- **Hover/tap:** the keyword list per screen covered my own cards. It didn't cover enemy-only keywords that show up in fights.
- **When I understood wins and losses:** game 1, round 7, reading the Pack/Take log. I was sure by game 2, round 11, when a trap I planned from Scout worked.
- **(P)** Game 2, round 11: I moved Madame Bufo to B2, across Hob's 17/18 Alderman Dozey. Dozey had to attack it, both died, and I won. In round 15 a Whirligig moved Wren's Queen off the +18 Ring slot (30/30 to 11/11), and I won at 1 Health. In game 4, the enemy Cradle Fetch copied their Whirligig, my rows swapped twice, and I lost 28.
- **(B)** I changed placement to answer each opponent's board, spent all my gold with Beltane Bonfire, and timed Hiring Fair for a five-unit tribe. The bots fielded the same boards from turn to turn.
- **(W)** The four cards in problem 1. Madame Bufo's Bitter didn't hit a Wick that joined an attack into it with Pack, which contradicts "an enemy attacks this". Mrs Posset's death damage fizzled silently with no enemy across. Sergeant-at-Conkers threw my 5-gold Stash. Its live note was accurate, but "smallest Acorn" alone didn't warn me.
