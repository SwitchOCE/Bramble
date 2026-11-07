# Playtest pt3-a: five Hard games, strategy lens

Played on d27abb7 with `tools/play/play.sh`, Hard, seeds 101–505. Fresh tester; no earlier reports read.

| Game | Build | Hero | Place |
|---|---|---|---|
| 1 | Bog folk: Mire wall, two Spitfire Sals, golden Jenny and Prima Donna | Brother Bracken | 2 |
| 2 | Hunters: Pack, Grizel (golden), Laird | Pipkin | 4 |
| 3 | Oozes: Sixpenny Pie, Granny Stir-Up (golden) | March Hare | 1 |
| 4 | Fairies: Rainbow, sold Chaser at seven bands | Old Mother Mousewife | 2 |
| 5 | Birds: Fly South, Jack Daw, Mag Pye | Little King Wren | 3 |

**Verdict: okay.** Games 3 and 5 had two misplays of mine from shifting hand numbers.

## What's best
Lane play is real. Mire locks, Snap and Spitfire Sal made a clear Bog engine. Whirligig's row swap made me put tanks in the back row. Rings stay on slots, so moving a unit onto one is a choice. The Queen of Elfland's Teind is a planning puzzle. The seventh Rainbow band (keep the stats or cash out for 12 gold) was a real dilemma. Triples combine across Bellies.

## Top 5 problems
1. **Neutral scaling beats tribe identity.** *Alone stops "very good".* Charcoal Burner turns all spare gold into permanent stats every turn, with no cap: my Spider went from 6/7 to 36/37 in five turns, and that won game 3, not the Oozes. Queen of Elfland's split gave the March Hare bot +13/+13 on five units in one turn. That bot won games 1 and 4, and in game 1 it finished on 40 health.
2. **Tribe supply is too thin to build around.** *Alone stops "very good".* Birds showed up about six times in 15 rounds, and Ring Fairies almost never. Oozes and Birds faded into generic boards; whether a build happens is decided by the shop, not by me.
3. **Early rounds have few decisions.** Rounds 1–4 are mostly 0-damage ties. Early Hunters (2/1, 1/3) lost six fights in a row in game 2.
4. **Hidden geometry and unclear wording.** "Behind F2" means B1 and B2, so the Teind cost me a Spitfire Sal I thought was safe. "Their stats" doesn't say it means the destroyed units' stats. Possible bug: in game 2, round 14, Mag Pye fired twice and took the text of a unit that wasn't across from it.
5. **Endings are foregone.** Losses cap at about 12 damage, so the last duels drag on while the bigger stat pile wins. Every final felt decided two rounds earlier.

Doc mismatch: PLAYTEST.md says five tribes per lobby. All five games had six, and `full_game()` sets `tribes_per_lobby` to 6.

## Builds that felt really different: 3
Bog folk (Mire), Hunters (Pack and Quarry), Fairies (Rainbow). Oozes and Birds didn't feel distinct.

There are real decisions in most turns from round 5 on, but generic stat engines decide the games.

Verdict: okay.
