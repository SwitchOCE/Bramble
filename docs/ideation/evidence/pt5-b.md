# Playtest pt5-b: build 7 (b2c3f01), fresh player

New to auto-battlers, a little Hearthstone. Four games via `tools/play/play.sh` against the bots.

**Places:** 1 (Bracken, Hunters), 1 (Pipkin, Bog folk), 7 (Hob, Birds, out in round 9), 4 (Mousewife, Hex Witch and Oozes).

**Verdict: good, not very good.** Real depth, but the text and the log still need an apology.

**Best:** placement read from Scout. Mire traps, Hex lanes and Whirligig swaps made every turn a puzzle. The Hunters Take cascade was fun to watch.

## Top 5 problems
1. **Too many keywords, some unparseable.** I looked up Pass, Cycle, Take, Pounce, Mired, Spill, Touching, Bell, Swoop and Bristle. Couldn't parse: Pass ("…or keeps it. While recruiting, at End of Turn"), Brother Wolf ("It lets them attack first"), Changeling ("fights for you until it attacks"), Young Brock ("…the enemy across from this as quarry"). **This alone stops "very good".**
2. **Vague fight log.** "X's ability goes off", an undefined "-- Bell", and undefined enemy-only keywords. Same-name units can't be told apart. Rings print as raw `{slot: Ring +1/+1}`, and units show two sell tags. A hero sat at "health 0" without being out.
3. **Harsh, swingy damage.** Losses cost 7–12 from round 6. In game 4 I went 8–0, then three losses took me to 6. Last Stand then gave a three-way finish on 1 Health: tense, but it felt artificial.
4. **Bots don't adapt.** Wren left a 30/30 Queen on a +18 Ring slot two fights after my Whirligig moved it off. No bot answered my Mire. Early bots are soft.
5. **Trap heroes and tribe.** Hob's loan repeats and cost me about 6 Health. Bracken's power does nothing on a full board. Fly South costs tempo: Birds sell for 0, the Egg is 1/1, and a unit standing on a Nest stops it counting for Redbreast.

**Builds that felt different:** Hunters (Take snowball), Bog folk (Mire control), Hex Witch with spells and Oozes. Birds felt flat.

## Lens answers
- **Hover/tap:** the keyword list covered my own cards, not enemy keywords that show up in fights.
- **When I understood:** game 1, round 7, reading the Pack/Take log. I was sure by game 2, round 11, when a trap I planned from Scout worked.
- **(P)** Game 2: I moved Bufo across Hob's 17/18 Alderman. It was forced to attack, both died, and I won. Later, my Whirligig moved Wren's Queen off her Ring (30/30 to 11/11), and I won at 1 Health. In game 4, an enemy Cradle Fetch copied their Whirligig, my rows swapped twice, and I lost 28.
- **(B)** I changed placement to answer each opponent's board, spent all my gold with Beltane Bonfire, and timed Hiring Fair for a five-unit tribe. The bots repeated their boards.
- **(W)** The four cards in problem 1. Bufo's Bitter didn't hit a Wick that joined an attack into it with Pack, which contradicts "an enemy attacks this". Posset's death damage fizzled silently with no enemy across. Sergeant-at-Conkers threw my 5-gold Stash: the live note was right, but "smallest Acorn" alone didn't warn me.
