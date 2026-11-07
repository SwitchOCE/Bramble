# Round 3 playtest

Build 4 (d27abb7), three fresh cloud reviewers with the stricter test: "you'd hand it to a keen player tomorrow, with no apology, and they'd want another game". All three: **okay**.

## Where they agree

| Item | Who | Next |
|---|---|---|
| Generic stat engines and piles decide games; committing to a tribe doesn't pay | A, B, C | Design round (`ideation/c-commit`) |
| Tribe supply thin: the shop decides whether a build happens | A, C | Design round |
| Ladder not real: Easy bots too strong, Hard a wall | B, C | Round 4 |
| Foregone or stalled endings | A, C | Round 4, with the design round |
| Hidden geometry and wording: "behind", Shy | A, B, C | Round 4 |
| Birds weak or generic | A, C | Design round |
| Hand numbers shift and cause misplays | A | Round 4 |

## Where they split

Hunters: A built it to 4th and counted it a really different build; C found it flat and offered late. Oozes: C calls them the most distinct tribe, A says they turned generic.


## Reviewer A

# Playtest pt3-a: five Hard games, strategy lens

d27abb7, `tools/play/play.sh`, Hard, seeds 101–505. No earlier reports read.

| Game | Build | Place |
|---|---|---|
| 1 | Bog folk: Mire, Spitfire Sals, golden Jenny and Prima Donna | 2 |
| 2 | Hunters: Pack, golden Grizel, Laird | 4 |
| 3 | Oozes: Pie, golden Granny (won by Charcoal Burner) | 1 |
| 4 | Fairies: Rainbow, sold Chaser at seven bands | 2 |
| 5 | Birds: Fly South, Jack Daw, Mag Pye | 3 |

**Verdict: okay.** Games 3 and 5 had two misplays of mine from shifting hand numbers.

## Best
Lane play is real. Mire, Snap and Sal made a clear engine. Whirligig's swap made me put tanks in the back row. Rings stay on slots. The Queen of Elfland's Teind is a planning puzzle. The seventh band (keep the stats or cash out 12 gold) was a real dilemma.

## Top 5 problems
1. **Neutral scaling beats tribes.** *Alone stops "very good".* Charcoal Burner turns spare gold into permanent stats every turn, with no cap: my Spider went from 6/7 to 36/37 in five turns. The Queen's split gave the March Hare bot +13/+13 on five units at once. That bot won games 1 (finishing on 40 health) and 4.
2. **Tribe supply is too thin.** *Alone stops "very good".* Birds showed up about six times in 15 rounds, and Ring Fairies almost never. The shop decides whether a build happens.
3. **Early rounds have few decisions.** Rounds 1–4 are mostly 0-damage ties. Early Hunters lost six fights in a row.
4. **Hidden geometry and wording.** "Behind F2" means B1 and B2, so the Teind cost me a Sal. "Their stats" is ambiguous. Possible bug: in game 2, round 14, Mag Pye fired twice and took a non-across unit's text.
5. **Foregone endings.** About 12 damage per loss, so the bigger stat pile wins slow finals decided two rounds earlier.

Doc mismatch: PLAYTEST.md says five tribes per lobby. Every game had six (`tribes_per_lobby` is 6).

## Really different builds: 3
Bog folk, Hunters, Rainbow Fairies. Oozes and Birds turned generic.

From round 5 there are real decisions most turns, but generic stat engines decide games.

Verdict: okay.

## Reviewer B

# Playtest 3-b: newcomer, five games (d27abb7)

Learned from How to play and card text only; PLAYTEST.md read afterwards. Phone renders at 1688x780: recruit, scout, combat.

Places: Easy 7 (Bracken; rounds 7-12 run by my own scripted policy), Easy 5 (Pipkin; 10 losses in a row), Normal 6 (Hob), Normal 2 (Mousewife; lost the final duel), Hard 4 (Wren).

**Verdict: okay.**

**Best:** the brick-wall board. Rows, lanes, Mire and Scout make where units stand matter. Fight logs explain every hit. Big turns pay off: seven Rainbow bands, a golden Old Mother Mast with Last Orders, a golden Charcoal Burner. Game 4's duel was tense, and I wanted another game.

**Top 5 problems:**

1. **The difficulty ladder isn't real.** By round 10, Easy bots had Wick 14/20 and Young Pretender 17/25. I lost 10 straight on Easy, then came 2nd on Normal. My places followed what I'd learned, not the level. *On its own, this stops "very good".*
2. **The guide skips how the game works.** It covers the board and tribes, but not gold, tiering up, refresh or freeze, spells, heroes, or how units grow, which is what wins. Then come about 20 keywords. Shy is a trap: my Stand Behind Me made a Hob-in-the-Hearth I'd just bought walk out. *On its own, this stops "very good".*
3. **Power curve.** Tier-6 offers (Seven Whistlers 3/3, Figgy Duff 3/4) are weaker than a Ringed tier-1 unit, so a 6-gold Hiring Fair felt wasted. Late fights go to whoever stacked one unit (Queen of Elfland 38/42).
4. **It doesn't look finished.** Shop cards with long text drop their portrait (Hedge Witch, Sexton Beetle), and Natterjack Chorus's name overprints its text on phone. The combat This hit panel starts as an empty purple box. Mire and Hex tags cover names. Guide page 8's labels overlap.
5. **Small wrongnesses.** I faced my own hero in three lobbies. The Whirligig log says "enemy X moves to the enemy's B1". A spell in hand shows its pre-discount cost. Pipistrelle Echo repeats Last Orders for 0 gold: correct by the rules, but it reads as a bug.

No crashes or rule errors.

Verdict: okay.

## Reviewer C

# Playtest 3-C: six tribes

Fresh playtester, d27abb7, `tools/play/play.sh`, one tribe per game. I didn't read earlier reports first.

| Game | Tribe | Level | Seed | Place |
|---|---|---|---|---|
| 1 | Hedgerow | Normal | 101 | 7th |
| 2 | Fairies | Hard | 202 | 6th |
| 3 | Oozes | Normal | 303 | **1st** |
| 4 | Birds | Hard | 404 | 7th |
| 5 | Bog folk | Normal | 505 | **1st** |
| 6 | Hunters | Hard | 606 | 8th |

I made a few command slips. Every Hard game ended in the bottom three.

## Tribes, ranked

1. **Bog folk.** Built it; won with 22 health. Ringed mirers soak hits, and His Highness became The Prince Restored. Distinct and very fun.
2. **Oozes.** Built it; won. Units in Bellies stay safe and grow from Aunt Aspic, and I made a golden Granny Stir-Up. The most distinct tribe.
3. **Fairies.** Partly built. Rings and bands work, and a bot's Rainbow Chaser was 15/20 by round 8. Good.
4. **Hedgerow.** Partly built. A Sergeant threw a Stash for 15 damage. Acorns are shared ammo for Sergeant, Treasurer and Dozey, a real tension, but slow to pay off.
5. **Hunters.** Barely built: no Hunters offered until round 4. Quarry and Take fired but felt small. Flat.
6. **Birds.** Couldn't build. Returning Birds need free slots and their Nests vanish, so Redbreast shrank. Clunky.

## What's best

The keyword engines (Belly, Mire's pull, the Prince's kisses, Granny's triple) are clever and read clearly in the fight log. Tier 6 fights were close and full of reversals.

## Top 5 problems

1. **Committing to a tribe doesn't pay.** Winning boards are stat piles from several tribes (Posset, Lodger, Dozey, Belladonna, Whirligig, stacked Rings). Both my wins leaned on Belladonna and Whirligig, and the bots' boards are mixed too.
2. **Birds are weak and fiddly.** Bots bought 2–9 Birds per lobby, against 28–42 Hunters. Fly South costs slots and tempo for little return.
3. **Snowballs; Hard is a wall.** One buffed unit runs over a board (Wick 17/16). Every losing game was a run of 4–6 straight losses with no way back. One Hard bot was still at 40 health in round 11.
4. **Late games stall.** Game 3 had 4 ties and game 5 had 2. Gold reached 56 with nothing to buy, and games ran 19–22 rounds.
5. **Rules surprise you.** A Shy unit walked out when buffed. Which back slot is "behind" which front slot isn't clear, and you can't see which Acorn a Sergeant will throw.

**#1 alone would stop "very good"**: the tribe fantasy is garnish on whoever has the biggest stats.

**Verdict: okay.**
