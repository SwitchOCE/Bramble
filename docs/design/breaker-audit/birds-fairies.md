# Breaker audit: Birds and Fairies

Snapshot: `/home/alex/code/Bramble-ideation-rules` (ideation/design-hard-rules), preset B. Code read: `src/core/pass3_birds.gd`, `pass3_fairies.gd`, `held_units.gd`, `combat/pass3_bird_combat.gd`, `combat/pass3_fairy_combat.gd`, `pass3_neutrals.gd`, `mechanics/shy.gd`. Nothing was run; the maths is by hand from the code.

Yardstick: the a35-run1 fit aims at a median board of about 900 total Attack + Health at round 12 (bot play).

## Top findings

1. **Fly South itself breaks rule 1.** Every homecoming multiplies the Bird's whole permanent body by 2.5 (golden 3), with no cap on trips. Best play is one trip per 2 turns, so x1.58 a turn. A tier-1 Chiffchaff is about 590/703 by turn 11 and 3,700/4,400 by turn 15. This is the tribe's default line, not a combo.
2. **Fairy Monarch breaks rules 1 and 2 on her own.** Ring size x3 every 2nd End of Turn (golden x4), no cap. Every Ring on every slot scales with it. Two Midsummers after she lands the board is over 30,000 total.
3. **The Cuckoo is a closed loop even with homecoming growth removed.** Landed Bird gives a seventh of its stats to the Birds on board, who fly, land and give back. About x1.43 a turn with six flyers; about x1.9 a turn on top of the 2.5.
4. **Great Lump and Gabble Ratchet remove Fly South's only cost** (missing a fight). Fine by the rules, but they make finding 1 unanswerable. They are fine once 1 is fixed.
5. **Mr Redbreast, Golden Egg and Jack Daw are one-way or one-shot.** They are only a problem because they sit on an exponential Bird. No change needed after 1 and 3.
6. **Rule 1's "on play / when sold is one-shot" is a loophole.** A Fly South Bird is played, sold and comes home every 2 turns.
7. **Rule 2's "a share of a unit's current stats is multiplication" would wrongly kill** Redbreast, Jack Daw, Cradle Fetch, Redwing and the Lump. None of them loop.
8. **Rings are count x size.** Cluricaun with Annis or the Queen is quadratic. That is a power fantasy and the rules should say it is allowed. Text bug: Spore Cloud and Boundary Stone say "+2/+2" and "+3/+3" but add 2 and 3 Rings (+8/+8 and +12/+12 at B, more as Ring size grows).

## Table

| Card | Tier | Growth class | Verdict | Reason |
|---|---|---|---|---|
| **Birds** | | | | |
| Chiffchaff | 1 | exponential | breaks a hard rule | (s+3) x 2.5 every 2 turns; biggest offender because of the +3 each replay |
| One Swallow | 1 | exponential | breaks a hard rule | 1-turn trips, so the 2-turn cycle needs no helper; plus 1 gold per cycle |
| Mrs Dunnock | 1 | flat (enabler) | fine | Cuts trips to 1 turn, so every Bird cycles in 2 turns |
| Mr Redbreast | 2 | follows its feeder | fine after Fly South fix | One-way: gains a sixth of each landing Bird, never feeds back |
| Mrs Jay | 2 | exponential body, flat Acorn | breaks a hard rule (keyword) | One Acorn per cycle is flat |
| Redwing | 2 | flat, fight only | fine | Eggs at half an away Bird's stats |
| Jack Daw | 3 | linear in enemy size | fine | Reads the enemy, not your own stats; permanent but no loop |
| Old Tern | 3 | exponential body | breaks a hard rule (keyword) | Mass recall is flat; golden trip is 1 turn (not in its text) |
| Tom Tit | 3 | flat | fine | 50% damage reduction on one Bird |
| The Cuckoo | 4 | exponential | breaks a hard rule | Closed share loop between flyers |
| Mag Pye | 4 | flat, fight only | fine | Text steal ends with the fight |
| Mrs Stork | 4 | flat (enabler) | fine | Recall needs a missed fight, so no faster than Dunnock |
| The Great Lump | 5 | flat x1 (golden x2), fight only | power fantasy | Stands in for the away Bird |
| Mother Goose | 5 | one-shot x3 per Bird | power fantasy | Egg is capped once per Bird; triples keep the mark |
| The Gabble Ratchet | 6 | flat, fight only | power fantasy | Away Birds fight anyway |
| The Seven Whistlers | 6 | flat, fight only | power fantasy | Halves enemies each fight; resets, never compounds |
| Fieldfare, Carrion Crow, Buzzard, Old Crane | 2-6 | flat | fine | Vanilla, not in pool |
| Still-Water Heron, Drumming Woodpecker, Barn Owl | 2-4 | flat / linear | fine | Not in pool; Heron +2/+2 per 2 turns |
| **Fairies** | | | | |
| Hedge Witch | 1 | flat (reads Ring) | fine | Attack loss equal to its slot's Ring |
| Nan Toadstool | 1 | flat | fine | 2 Rings on play, 2 on sale |
| Rainbow Chaser | 1 | flat gold | fine | Up to 7 gold a sale; rolling for it loses gold on average |
| Hob-in-the-Hearth | 2 | flat | fine | One Shield |
| Old Moth Annis | 2 | linear in sales | power fantasy | 1 Ring on 2 slots per sale and End of Turn |
| Sally Spore | 2 | flat | fine | One new Ring a turn, stops at 7 |
| Cluricaun | 3 | linear | power fantasy | +6 Ring size a turn; quadratic with Ring adders |
| Lob-Lie-by-the-Fire | 3 | linear | fine | +3 Ring size per turn stayed, paid on leaving |
| Silky | 3 | linear in gold | fine | +3 Ring size per Shy thanked, about 2 gold net each |
| Changeling | 4 | flat, fight only | power fantasy | Steals the enemy carry for one attack |
| Cradle Fetch | 4 | flat, fight only | power fantasy | One copy per fight, cannot chain |
| Will-o'-the-Wisp | 4 | flat | fine | Wisps wear the empty slots' Rings |
| Lady Belladonna | 5 | flat | fine | One Nightshade |
| Reel-Mistress | 5 | flat, fight only | fine | Each Ring used by up to 3 attackers |
| Fairy Monarch | 6 | exponential | breaks a hard rule | Ring size x3 per 2 turns, no cap |
| Queen of Elfland | 6 | linear | power fantasy | +7 Rings per victim, 2 victims a turn |
| Pixie Scout, Wisp, Hedge Sprite, Brownie Porter, Moth Fairy, Fairy Knight | 1-5 | flat | fine | Vanilla or token, not in pool |
| Belladonna Sprite | 6 | flat | fine | Not in pool |

## Detail

### Fly South (Chiffchaff, One Swallow, Mrs Jay, Old Tern, Mother Goose): breaks rule 1

Text (card details): "Sold, flies south for 2 turns; returns to hand at 2.5x permanent stats. Flying pays no sale gold; played this turn, it sells normally. Early recalls require a missed fight; each trip grows once."
Chiffchaff: "Fly South. When played: gain +3/+3." One Swallow: "Fly South. Its trips last 1 turn. When played: get 1 gold."

Code: `Pass3Birds.homecoming` calls `multiply_body(unit, 2.5)` on base plus all permanent stats, once per round, with no trip limit. Landing sets `played_round`, so a Bird cannot fly the turn it lands.

- **Best use.** Buy Chiffchaff and Mrs Dunnock on turns 1-2. Sell Chiffchaff on even turns; Dunnock shortens the trip to 1 turn; it lands and is replayed on odd turns. Run a second Bird on the opposite phase in the same slot so the slot is never empty.
- **Growth.** s(k+1) = 2.5 x s(k) + 3 per 2 turns. Exponential, x1.58 a turn. Landings: turn 3 13/16, turn 5 36/43, turn 7 93/111, turn 9 236/281, turn 11 593/706, turn 13 1,486/1,768, turn 15 3,715/4,420. One Swallow alone (no helper): 125/208 by turn 11, 783/1,300 by turn 15.
- **Combos.** Golden Egg x3 once (Chiffchaff about 4,000 total by turn 12). Golden homecoming is x3. Click Beetle replays "When played" before growth: (s+6) x 2.5 + 6. Jack Daw's steal and any spell buff (Last Orders) get multiplied on every later trip. The Cuckoo adds a second loop. Lump or Ratchet lets the away Bird fight anyway.
- **Fantasy or degenerate.** Assembly cost is two tier-1 cards. One Bird outgrows a whole median board (900 at round 12) by turn 11. Answers exist (Changeling, Seven Whistlers, Hasty Pudding, Belladonna) but a linear board cannot keep up past turn 13.
- **Frequency.** Birds are in 5 of 6 lobbies. Both pieces are tier 1 with 15 copies each; One Swallow needs nothing. Every Birds player who wants this gets it: near 100% of Birds games.
- **Verdict: breaks a hard rule, must change.** Smallest change that keeps "sell it now, it comes home bigger": the x2.5 applies to a Bird's **first** homecoming only (one-shot, allowed by rule 1); later homecomings add a fixed amount by tier. Alternative: keep x2.5 but "a Bird grows on its first two trips" (cap x6.25, x18.75 with an Egg). The first option keeps the loop alive all game.

### The Cuckoo: breaks rule 1

Text: "After a Bird comes home: other Birds gain a seventh of its stats." Golden: two sevenths. Details: "Other Birds means Birds on your board, except the returning Bird. Fractions round up; copies trigger separately."

- **Best use.** Six flyers in two groups of three, Cuckoo on board. Each turn three land and the three on board (and the Cuckoo) each gain 3/7 of a lander. They then fly and return the favour.
- **Growth.** With homecoming growth set to x1, x(next) = x + (3/7) x: x1.43 a turn. Exponential on its own. With x2.5 homecomings, about x1.9 a turn. Two Cuckoos or a golden one: x1.86 a turn before homecoming growth.
- **Combos.** Old Tern (lands the whole flock), Mrs Stork, Dunnock: more landings a turn.
- **Fantasy or degenerate.** Tier 4, one card plus the tribe's normal play. Not a chase; it just happens.
- **Frequency.** 11 copies at tier 4; most committed Birds players see one by turn 8-9. Roughly half of Birds games.
- **Verdict: breaks a hard rule.** Smallest change: "other Birds gain a seventh of what it **gained on that trip**". With fixed trip gains that is a fixed gift. Or make the gift last until the next fight only.

### Fairy Monarch: breaks rules 1 and 2

Text: "Every 2nd End of Turn: triple your Ring size." Golden: "multiply your Ring size by 4." Details: "Midsummer shares one countdown across copies. Extra triggers never advance it or repeat its growth."

Code: `_monarch` does `player.ring_size *= 3.0` whenever the shared counter reaches 2. No cap. Every slot's Ring is count x Ring size.

- **Best use.** Ring board: all 7 slots ringed (Nan, Sally, Annis), Cluricaun for +6 a turn, Monarch from turn 10.
- **Growth.** Ring size x3 per 2 turns (x1.73 a turn), plus Cluricaun. Example: size 22 at turn 10. Turn 11: 102. Turn 13: 342. Turn 15: 1,062. Turn 17: about 3,200. With 45 Rings across the board at turn 13 that is 45 x 342 x 2 = about 30,800 total stats; turn 15 with 60 Rings, about 127,000.
- **Combos.** Rings belong to slots, so any tribe's units get it. Queen of Elfland (+14 Rings a turn), Annis with Birds flying (free sales), Will-o'-the-Wisp (empty slots become full-size Wisps), Hedge Witch (zeroes any attacker).
- **Fantasy or degenerate.** One card. Nothing to assemble beyond the Rings every Fairy board has. Horseshoe halves one Ring for one fight, which does not matter. Unbeatable two Midsummers in.
- **Frequency.** Tier 6. Hiring Fair (tier 5, 6 gold) offers a Fairy tier-6 unit to a 5-Fairy board, and the pool has only two (Monarch, Queen): about 50% a cast. A committed Fairy player gets her by turn 10-11 in about half their games.
- **Verdict: must change.** Smallest change keeping Midsummer: "On your 2nd End of Turn after playing this: triple your Ring size. Once a game." (golden x4). A one-shot x3 on a size that grew by addition is a big, fair payoff.

### Power fantasies (keep)

- **Cluricaun** ("End of Turn: if every slot has a Ring, your Rings grow +6/+6"). Fixed +6 size a turn; output is +12 total per Ring on board. With Annis or the Queen adding Rings each turn the board grows quadratically: 30 Rings is +360 a turn, 67 Rings at size 40 is about 5,400 total by turn 13 with Queen. No multiplication, real assembly (7 ringed slots, tier 6, 6 gold a turn in victims). Keep; the +6 dial is hot against a 900 median and can come down without touching the design.
- **Queen of Elfland** ("Start of Turn: destroy the units behind this. Ring every slot for each."). +14 Rings a turn for two units. Linear. With Will-o'-the-Wisp the emptied slots still fight. Keep.
- **Old Moth Annis** ("End of Turn and after you sell: Ring the slots behind this."). Uncapped per turn, but each trigger needs a sale (about 2 gold net) or a Bird flying (free). Linear in sales. Keep.
- **Changeling** ("Start of Combat: steal the enemy across until it attacks."). The pool's answer to one giant unit. Positional, fight only. Keep.
- **Cradle Fetch** ("become a copy of the Fairy behind, Ring and all, with full stats"). One copy per fight; Fetches cannot copy Fetches or share a target. Keep.
- **Mother Goose / Golden Egg** ("Triple a Bird's stats. Once per Bird."). The cap is real in code (`egged` counter, kept through triples). Click Beetle makes more Eggs, not more Eggs per Bird. Keep.
- **Great Lump and Gabble Ratchet.** Lump on a Nest has the away Bird's stats; Ratchet drops the Bird in when the unit on its Nest dies (an Egg counts). Golden both: about 4x the Bird in one fight. Fight only, never compounds. Keep, after Fly South is fixed.
- **The Seven Whistlers.** Needs seven different Bird names on board at the bell, hard while Birds are flying. Halving resets each fight. Keep.
- **Jack Daw** ("your biggest Bird permanently steals a quarter of the stats of the enemy across"). Gain tracks the lobby, about +50/+50 a fight against a 200/200 unit. Keep.
- **Rainbow Chaser.** With 7 ringed slots a sale nets +5 gold. Rolling for copies returns about 0.4-0.6 gold per 1-gold roll, so it cannot loop. Keep.

## Rule wording problems

1. **"One-shot (on play, when sold)" is not one-shot for a card that comes back.** Fly South replays "When played", "When sold" and homecoming every 2 turns. Word it as "once per card per game", or "a trigger the same card can repeat is not one-shot".
2. **Rule 2's last sentence over-kills.** "Gain a share of a unit's current stats every turn is multiplication" would remove Redbreast, Jack Daw, Cradle Fetch, Redwing, the Lump and Hedge Witch. Suggested wording: "A permanent gain that is a share of stats is multiplication when those stats can be raised by the gain itself, directly or through other cards (A feeds B feeds A). A one-way share, a share of enemy stats, and anything that ends with the fight are not."
3. **Rule 1 names stats, gold, cards and triggers, not shared counters.** Monarch multiplies Ring size, which is none of those. Add "or any stored value that feeds stats (Ring size, Toll, Larder)".
4. **Polynomial growth is not mentioned.** Count x size (Annis or Queen with Cluricaun) is quadratic. Say outright that growth from two or more cards adding to different factors is allowed, or Cluricaun gets cut by a cautious reviewer.
5. **"A fixed amount each turn" needs "per target".** Cluricaun and Annis add a fixed amount per Ring or per sale, and total output depends on how many the player has.
6. **"States a cap" should bound the total.** "Up to three times a game" on a x3 is x27. Ask for the cap to be stated as a total multiple.
7. **Enemy debuffs each fight** (Whistlers halving, Hedge Witch) look like repeated multiplication. Add: effects that reset when the fight ends are not repeated.
8. **Loophole outside this group, seen while checking combos:** Charcoal Burner gives the units behind it a twentieth of their own body per gold burned, up to 6 gold: x1.3 a turn on any unit, including a Bird carry.

## Text that misleads

- Spore Cloud "+2/+2" and Boundary Stone "+3/+3" add 2 and 3 Rings, each worth the current Ring size.
- Golden Old Tern's text matches the normal one, but its trips last 1 turn.
- Dunnock, Redbreast, Cuckoo and Stork carry the Fly South keyword but cannot fly.
- Chiffchaff's JSON effect says +1/+1; the live value is +3/+3 from the preset.
