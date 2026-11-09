# Card audit: Birds, Bog folk, Fairies (pass 2 slice content)

Source: /home/alex/code/Bramble-ideation-balance (ideation/pass2, HEAD c233260; content unchanged since the benchmark code commit c50f6c8: `git diff --stat c50f6c8 HEAD -- content src` shows only src/core/bots/bot_lanes.gd).
Card files: content/units/<id>.json, "set": "slice". Pool cards per tribe: 16 (Barn Owl, Peatling, Prince Restored and Wisp have `pool: false`).
Rules used: docs/design/rulebook.md 12.1.4 Flying and Eggs (line 790), 8.5.4 Ring cap (506), 9.4.5a Mire waits (555), 9.6.0 Bitter first (598), 12.1.5 Queen (793), 12.1.7 Shy (797), 5.2.9 Supper (309), 12.1.1a permanent caps (780).
Engine checks (read only): src/core/mechanics/*.gd, src/core/board_geometry.gd:15 ("adjacent" = same row only, so "beside" reaches at most 2 units), src/core/combat/combat_moves.gd:248-257 (Nightshade halves current Health each time the unit is attacked), src/core/held_units.gd:335-376 (Egg = half of the Bird's current stats, rounded up; Redwing/Tom Tit raise it).
Economy: income 3,4,...,10 from round 8 (src/core/game_config.gd defaults), unit 3 gold, tier-ups 5/7/8/11/13 less 1 per turn waited (game_config.gd:21).

"Typical R10 board" used for per-trigger estimates: own tier 4-5, one or two Harvest Suppers (+1/+1 or +2/+2 tribe), 7 units; enemy units about 7/9 on average, carry about 10/12, 4 in front and 3 behind. These match the bot lobby average at R10 (about 16 stats a unit on the recruit board).

Columns: Cond = condition; Payoff = what it gives, with an R10 estimate; Perm = permanent / standing aura (recruit and combat, not banked) / combat only / one-shot / economy; Breadth; Growth; Cap (binds before R12?); Enabler (whose conditions or payoffs it makes or multiplies); Conc = can it pile stats onto one unit; Bot = final boards it appears on across 3,200 bot seats, and their mean place (survivor bias: late cards sit on boards that lived long).

## Birds (16 in pool)

| Card | T, stats | Cond | Payoff (typical R10) | Perm | Breadth | Growth | Cap (binds <R12?) | Enabler | Conc | Bot |
|---|---|---|---|---|---|---|---|---|---|---|
| Chiffchaff | T1 1/2 | Played again after a trip (it must fight once at home before it can fly) | +1/+1 per play, about one play per 3 turns (per 2 with Stork): 0.7-1 stats a turn | Permanent | Self | Per trigger, linear | None | Payload for Cuckoo, Lump, Redwing, Ratchet, Goose | Partly (slow alone; the Cuckoo makes it the Bird carry) | 34 boards, 5.24 |
| Mrs Dunnock | T1 2/3 | A Bird's Nest beside her (same row) at End of Turn, trip not already ending next turn | Trip one turn shorter, one Nest a turn: about +0.3 replays a turn; no stats | None (tempo) | One Bird | n/a | Never sooner than next turn; first eligible Nest only (yes) | Chiffchaff, Swallow, Jay, Goose homecoming, Old Tern, Whistlers count. Works against the Cuckoo | No | 199, 5.81 |
| One Swallow | T1 1/2 | Played (each replay) | 1 gold per play: 0.33-0.5 gold a turn. Fly South pays no sale gold (12.1.4) | Economy | n/a | Per trigger | None | Stork's 6-gold count (barely) | No | 5, 5.80 |
| Mr Redbreast | T2 2/4 | Nests (Birds away; a covered Nest still counts) | +1/+1 per Nest: 2-3 Nests = +2-3/+2-3 (4-6 stats) | Standing aura | Self | Flat, scales with Nest count | 7 Nests by geometry; in practice 2-4 (yes, by count) | None | Partly (self, bounded) | 164, 5.55 |
| Mrs Jay | T2 3/3 | Flown (sold after fighting once) | 1 Acorn (1 gold) per trip: about 0.33 gold a turn | Economy | n/a | Per trigger | None | Hedgerow Acorn payoffs (Dozey, Pym, Beadle, Treasurer, Hayward); a good Cuckoo body | No | 165, 5.31 |
| Redwing | T2 2/4 | Eggs beside it (same row, at most 2) and Redwing itself on the board, not flying | Eggs fight at the Bird's full stats instead of half: +4/+4 per Egg of an 8/9 Bird, +8-16 stats a fight | Combat only | Adjacent Eggs | Multiplier (x2 on Egg stats) | Only the strongest Redwing; competes with the Cuckoo for the same adjacency (yes, by geometry) | Cuckoo, Chiffchaff, Goose (their stats show up whole) | Yes (expresses the grown Bird) | 124, 5.50 |
| Jack Daw | T3 3/3 | An enemy across at Start of Combat | Steals 2 Attack: a 4-Attack swing in one lane (enemy at about 7 Attack loses 30%) | Combat only | One enemy, self | Flat | 2 (golden 4); no scaling (yes) | None | No | 121, 5.39 |
| Old Tern | T3 3/4 | Its own trip ends with other Birds away | All away Birds land in hand: 2-3 replays at once (Chiffchaff +1/+1, Swallow 1 gold, Goose +1/+1 to every Bird, Whistlers count) | None (tempo) | All away Birds | Per trigger | Landed Birds can't fly that turn | Chiffchaff, Swallow, Jay, Goose, Whistlers, Stork chains. Ends Cuckoo trips early | No | 255, 5.75 |
| Tom Tit | T3 3/4 | Eggs on the board (Birds away, Nests empty) | Eggs get the Bird's full Health (golden: full stats): +4-5 Health per Egg, +8-12 a fight | Combat only | All Eggs | Multiplier (x2 on Egg Health) | Strongest Tom Tit only; doesn't stack with Redwing (yes) | Cuckoo Birds survive as Eggs; surviving Eggs add hero damage. Delays the Ratchet's landing | Partly | 23, 5.30 |
| Cuckoo | T4 3/6 | Birds away whose Nests are beside it (same row, at most 2) at End of Turn | +2/+2 each per End of Turn (golden +4/+4), and their trips last one turn longer: about +6 stats a turn on a lined-up board | Permanent (rides home with the Bird) | Up to 2 Birds | Linear per turn, uncapped | None | Lump, Redwing, Tom Tit, Ratchet, Goose's Egg all read the grown Bird | Yes (the tribe's only open-ended pile) | 409, 5.89 (worst Bird T4) |
| Mag Pye | T4 3/6 | Enemy across has text worth taking (Start of Combat, first of all) | Enemy loses its text and Mag Pye has it: 0 vs vanilla; large vs Committee, Lollop, Lantern Man, Belladonna. Typical about 5-10 stats of value | Combat only | One enemy (golden two) | Flat | n/a | None (an answer) | No | 402, 5.71 |
| Mrs Stork | T4 3/6 | Every 6 gold spent, a Bird away that has missed a fight | The Bird away longest comes home: about 1 homecoming a turn at 10 income (golden 2) | None (tempo) | One Bird | Per trigger | Must have missed a fight (yes) | Chiffchaff, Swallow, Jay, Goose homecoming, Whistlers count, Old Tern chains. Pulls Cuckoo Birds home early | No | 410, 5.78 |
| The Great Lump | T5 3/5 | Stands on a Nest whose Bird is away | +half the Bird's current stats (golden full): +4/+5 off an 8/9 Bird, +10/+11 off a 20/21 Bird | Standing aura | Self | Tracks a growing pile (x0.5) | Lost when the Bird lands; covers the Egg (yes) | Ratchet: if the Lump dies, the Bird lands there | Yes | 60, 4.66 |
| Mother Goose | T5 4/7 | Away: Nests with enemies across. Home: her trip ends | Away: each Nest strikes across for 2 at Start of Combat (3 Nests = 6 damage). Home: every Bird you own +1/+1 (6-8 Birds = 12-16 stats), every 2-3 turns | Permanent (homecoming) + combat (strikes) | Every Bird; Nests | Per trigger, spreading | None | Gives Stork, Tern and Dunnock a payoff | No (spreads) | 268, 4.69 |
| The Gabble Ratchet | T6 3/7 | A unit on a Nest dies (Egg or a unit standing there); once per Nest a fight | The away Bird lands there at current stats (golden double Attack): 2-3 Nests of 8/9-12/13 Birds = 30-50 stats arrive mid-fight | Combat only | Summons | Tracks Bird size | Once per Nest per fight (yes) | Cuckoo, Lump, Tom Tit (Lump dies, then the Bird lands: the pile counts 1.5x) | Yes | 86, 3.34 |
| The Seven Whistlers | T6 5/7 | Birds came home this turn | Enemies across your Birds -1/-1 per homecoming, up to -3/-3: 1-2 homecomings x 4 lanes = -8 to -16 enemy stats | Combat only | Enemies across your Birds (Eggs aren't Birds) | Per homecoming | Up to 3 homecomings (rarely binds: needs Stork + Tern) | None | No (anti-wide; small vs one big unit) | 231, 3.22 |
| Barn Owl | T4 3/4 | not in pool | Swoop; no damage attacking the back row | Combat | Self | Flat | n/a | n/a | n/a | 0 |

## Bog folk (16 in pool)

| Card | T, stats | Cond | Payoff (typical R10) | Perm | Breadth | Growth | Cap (binds <R12?) | Enabler | Conc | Bot |
|---|---|---|---|---|---|---|---|---|---|---|
| Bridge Toad | T1 1/3 | Its own Mired enemy attacks it | +1/+1 per such attack, about once a fight | Permanent | Self | Per trigger, capped | permanent_buff_cap 3 (bridge_toad.json:37) caps every permanent buff, Pinches included: stops at 4/6 by about R4-R6 (yes) | Mire patch for Snap, Lantern, Sal | No | 84, 6.50 |
| Warty Nan | T1 1/3 | Nan or a unit beside her is attacked | Bitter 1 on herself and lent to 2 neighbours: -1 Attack per attack before damage, about -3 to -4 enemy Attack a fight | Combat only | Self + adjacent | Flat, stacks with other Bitter | Bitter floor 1 Attack | Walls live, so Gideon, Jenny and Tiddy fire | No | 36, 5.53 |
| Young Pretender | T1 3/2 | Snap: kills a Mired enemy | 1 gold next turn per kill; a 4/3 rarely kills a 7/9 at R10: about 0.2-0.3 gold a fight | Economy | n/a | Per trigger | None | None | No | 180, 5.32 |
| Madame Bufo | T2 1/4 | Her Mired enemy attacks her (Bitter 2) and kills her (halving) | That enemy loses 2 Attack, then half: an 8-Attack enemy ends at 3; a 20-Attack carry at 9 | Combat only | One enemy | Multiplier (x0.5): grows with the enemy's size | Once (she dies) | Answer to concentration | No | 74, 5.64 |
| The Peat Cutter | T2 2/4 | A Mired enemy dies | 1 gold next turn, once a fight | Economy | n/a | Per trigger | Three times in all: 3 gold lifetime, spent by about R7-R9 (yes) | None | No | 174, 5.25 |
| Vaulting Hopkin | T2 3/1 | In the back row | Attacks first with +2 Attack, at the biggest Mired enemy (Snap): one 5-Attack early hit | Combat only | Self | Flat | n/a | None | No | 43, 5.72 |
| Gideon | T3 2/6 | His Mired enemy attacks him, both survive | He attacks it back with +2 Attack: about 6 damage per hit taken | Combat only | One enemy | Per trigger | None | None | No | 348, 6.03 |
| Natterjack Chorus | T3 3/4 | Units beside it (same row) | Lends Mire and Bitter 1 to up to 2 units: +2 patches; a borrowed non-Bog carry waits once | Combat only | Adjacent | n/a | One patch per enemy slot | Lantern (+3 Attack per patch), Sal (+2 damage per patch), Snap, Tiddy, Peat King, Peat Cutter, kisses | No | 158, 6.11 |
| Spitfire Sal | T3 1/3 | Mired enemies at Start of Combat | 2 damage to each (golden 4): 3-5 patches = 6-10 damage, spread | Combat only | All Mired enemies | Scales with patch count | 7 patches | None | No | 9, 5.56 |
| His Highness | T4 3/5 | A Mired enemy dies (once a fight), three fights | Becomes Prince Restored 6/7 with Mire and the first spell each turn 1 cheaper: +3/+2 and about 1 gold a turn | One-shot (permanent) | Self | One-shot | Once a fight, one transform (yes) | None | No | 114 + 115 restored (3.72) |
| Jenny Greenteeth | T4 3/5 | Her Mired enemy attacks her | Mired enemy has -2 Attack; after it hits her, her highest-Attack neighbour attacks it: an extra carry swing (about 8 damage) | Combat only | One enemy; one neighbour | Per trigger | None | Gives a neighbouring carry extra attacks | Partly | 218, 5.37 |
| Signor Ranocchio | T4 3/4 | Snap: attacks a Mired enemy (and lives to do it) | +1/+1 permanently (golden +2/+2): 2 stats a fight | Permanent | Self | Linear per fight | Once a fight (signor_ranocchio.json:20) (yes, it is the rate limit) | None | Partly (slow pile) | 140, 5.28 |
| The Prima Donna | T5 2/8 | Enemies in the 3 slots across and beside | 3 patches; Bitter 2 once per enemy: about -6 enemy Attack a fight | Combat only | 3 enemy slots | n/a | Once per enemy | Same list as the Chorus, x3 | No | 217, 4.45 |
| Tiddy Mun | T5 3/6 | A Mired enemy attacks one of your units | That unit +1/+1 permanently (after the hit, even if it dies), twice a fight: 4 stats a fight | Permanent | The units hit (mostly the mirers) | Linear per fight | Twice a fight (tiddy_mun.json:18) (yes) | Keeps walls alive for Gideon, Jenny, Peat King, Lantern | Partly (the same wall is often hit) | 111, 4.26 |
| The Lantern Man | T6 4/8 | Mired enemies alive | +3 Attack per Mired enemy (live): 3-5 = +9-15 Attack; Snap aims it at the biggest stuck enemy | Combat only | Self | Count x 3 | At most 7 Mired enemies | None | Yes (combat only; Health stays 8) | 248, 2.93 |
| The Peat King | T6 5/9 | A Mired enemy dies; an empty slot | Summons a 4/4 Peatling with Bitter 2 (golden 8/8, Bitter 4), twice a fight: +16 stats of bodies | Combat only | Summons | Per trigger | Twice a fight (yes) | Peatlings carry Bitter | No | 475, 2.78 |
| Peatling, Prince Restored | tokens | not in pool | | | | | | | | |

## Fairies (16 in pool)

| Card | T, stats | Cond | Payoff (typical R10) | Perm | Breadth | Growth | Cap (binds <R12?) | Enabler | Conc | Bot |
|---|---|---|---|---|---|---|---|---|---|---|
| Hedge Witch | T1 1/2 | Spells cast while it's owned | Hex: enemy across has -Hex Attack at Start of Combat; Hex 4-5 by R10: -4 Attack on one enemy | Combat only | One enemy | Per spell, capped | Your tier (golden tier+2): binds by R8-R10 (yes) | None | No | 3, 6.00 |
| Nan Toadstool | T1 2/1 | Played | Rings its slot +1/+1 (golden +2/+2) | Permanent (slot) | One slot | One-shot | Ring +4/+4 per slot | Wisp, Monarch, Reel-Mistress | Partly (slot, capped) | 8, 7.25 |
| Rainbow Chaser | T1 1/2 | Units played into empty slots while a Rainbow card is out; band fades when the unit moves or leaves | +1/+1 per 2 painted slots; sold: 1 gold per 2 painted, +2 at all seven. R10: +2/+2, sells for 2 | Standing aura + one-shot economy | Self | Flat | +3/+3 and 5 gold at most (yes) | Cluricaun shares the paint | No | 17, 5.11 |
| Hob-in-the-Hearth | T2 1/3 | In the back row with units in front | +1 Health to the 2 units in front each End of Turn: 2 stats a turn. Shy: can't be buffed; an aimed spell sends it off for 2 gold | Permanent | 2 units | Linear per turn | None | Silky | No | 2, 7.50 |
| Old Moth Annis | T2 2/2 | In the front row with units behind | +1 Attack to the 2 units behind each End of Turn: 2 stats a turn | Permanent | 2 units | Linear per turn | None | Any back-row unit | No | 16, 6.50 |
| Sally Spore | T2 1/3 | An empty slot | Rings the nearest empty slot +1/+1 each End of Turn: 2 stats a turn, filling one slot to +4/+4 in 4 turns | Permanent (slot) | One slot at a time | Linear per turn | Ring cap +4/+4; needs an empty slot (yes) | Wisp (empty Rings), Monarch, Reel-Mistress | Partly | 19, 6.53 |
| Cluricaun | T3 2/3 | Units on painted slots | +1 Attack each (golden +2): 3-5 painted = +3-5 Attack | Standing aura | Painted units | Flat | 7 slots | Rainbow Chaser | No | 17, 6.06 |
| Cradle Fetch | T3 2/3 | A unit behind it | Becomes a base copy at Start of Combat; its Start of Combat text fires. Behind a Belladonna: +7 stats and a second Nightshade | Combat only | Self | Flat | Can't copy a Fetch | Doubles Belladonna, Wisp, Changeling | No | 12, 6.00 |
| Lob-Lie-by-the-Fire | T3 2/3 | Units beside it (same row) | +1 Attack to each End of Turn: 2 stats a turn. Shy | Permanent | 2 units | Linear per turn | None | Silky | No | 1, 6.00 |
| Changeling | T4 2/2 | An enemy across | Swaps sides with it until it has attacked once: their unit hits its own team (about 7-10 damage; vs a 30-Attack carry, 30) | Combat only | One enemy | Scales with the enemy's Attack | Once a fight | Answer to concentration | No | 0 |
| Silky | T4 3/6 | A Shy unit leaves (aimed spell) | Rings its slot +2/+2 (golden +4/+4); Hob, Lob and Silky: +12 stats once, plus 2 gold each | Permanent (slot) | One slot each | One-shot | Once per Shy unit; Ring cap (yes) | Wisp, Monarch, Reel-Mistress | No | 165, 6.26 |
| Will-o'-the-Wisp | T4 3/6 | Empty slots holding Rings | A 1/1 Wisp (a Fairy) in each at Start of Combat: 1-2 Wisps of 3/3-5/5 = 6-20 stats | Combat only | Summons | Per empty Ring | Needs empty slots (conflicts with a full board) | Monarch boosts Wisps | No | 230, 6.12 |
| Lady Belladonna | T5 4/8 | Enemy across (front row) or the 2 across the slots in front (back row) | Nightshade: each time that enemy is attacked, it first loses half its current Health. A 30-Health carry drops to 15 before the first hit | Combat only | 1-2 enemies (golden 3) | Multiplier (x0.5 per hit): grows with the enemy's size | n/a | Answer to concentration | No | 298, 4.81 |
| Reel-Mistress | T5 4/7 | Units on Rings attack | Each Ring moves once to your next attacker, stacking past the cap: 3 Rings of +2-4 reused = +6-12 stats a fight | Combat only | Next attacker | Per Ring | Once per Ring a fight | Rings | Partly (stacks Rings on later attackers) | 152, 5.55 |
| Fairy Monarch | T6 4/6 | Fairies on Rings | +1/+1 each above the cap: 3-5 = +6-10 stats | Standing aura | Fairies on Rings | Flat | n/a | Wisps on Rings | No | 15, 1.59 |
| Queen of Elfland | T6 8/8 | Every 3rd End of Turn; units behind her (else she destroys herself); other Fairies on board | Destroys the units behind; other Fairies share their printed stats and permanent buffs (golden double). Two T5 bodies = about 30 stats per 3 turns, for 6 gold of rebuys | Permanent | Other Fairies, split evenly | Per trigger (transfer; x2 golden) | None, but split evenly (yes, it spreads unless you keep one other Fairy) | All Fairies | Yes, only if one other Fairy stands with her | 653 boards, only 19 on Fairy boards; 2.89 |
| Wisp | token | not in pool | | | | | | | | |

## Tribe summaries

Counts are pool cards whose payoff is stats or stat changes (economy and tempo-only cards listed separately).

| | Birds | Bog folk | Fairies | Hedgerow (for comparison) |
|---|---|---|---|---|
| Stat payoffs | 11 | 13 | 16 | 13 |
| Concentrating (yes / partly) | 4 / 3: Cuckoo, Redwing, Lump, Ratchet / Chiffchaff, Redbreast, Tom Tit | 1 / 3: Lantern (combat only) / Ranocchio, Tiddy, Jenny | 1 / 3: Queen (conditional) / Nan, Sally, Reel-Mistress | 6: Crumb, Pym, Beadle (Pass), Dozey, Treasurer, Urchin (combat Pass) |
| Spreading or no | 4: Jack Daw, Mag Pye, Goose, Whistlers | 9 | 12 | Mallow, Hayward, Committee, Lollop, Clover, Burdock, Sorrel |
| Permanent (unit) | 3: Chiffchaff, Cuckoo, Goose homecoming | 4: Toad (capped +3/+3), Highness (one-shot), Ranocchio, Tiddy | 4 unit (Hob, Annis, Lob, Queen) + 3 slot Rings (Nan, Sally, Silky; capped +4/+4) | 7: Crumb, Pym, Dozey, Beadle, Mallow, Hayward, Clover |
| Standing auras | 2: Redbreast, Lump | 0 | 3: Chaser, Cluricaun, Monarch | 1: Treasurer |
| Combat only | 6 (+ Goose strikes) | 9 | 6 | 4: Urchin, Sergeant, Committee, Lollop |
| Economy / tempo only | 5: Swallow, Jay, Dunnock, Tern, Stork | 3: Pretender, Peat Cutter, Chorus | 0 (Chaser and Shy pay one-shot gold) | Partner, Mast; Acorns feed Dozey, Pym, Beadle, Hayward, Treasurer, Sergeant |
| Gold-to-stats channel inside the tribe | Stork + Goose: 6 gold per homecoming, about 14 spread stats, at most every 2 turns | None | Queen: 6 gold of bodies per 3 turns becomes about 30 stats | Acorns: 1 gold Acorn = +1/+1 on Dozey (feeding rounds up); Pym +2/+2 per Stash; Beadle +1/+1 per Acorn; Hayward +1/+1 on each touching unit per Stash |

### Birds
- Core condition: absence. Birds pay off for being away (Nests, Eggs, Cuckoo growth) or for coming home (replayed text, Goose's buff, Whistlers' count). Fly South itself costs the body for 2 fights.
- Payoffs: Cuckoo growth (the only uncapped permanent pile), Goose's homecoming buff (spread), Redbreast's per-Nest aura, Lump, Ratchet and Redwing expressing the grown Bird.
- Enablers: Dunnock, Old Tern, Stork (shorten trips); Cuckoo (lengthens them and grows); Redwing, Tom Tit (Egg multipliers).
- Compounding: Cuckoo growth (linear, +2/+2 per away Bird per turn) times expression (Redwing x2 on the Egg, Lump +0.5x, Ratchet lands the full Bird when its Nest unit dies). A grown Bird can count about 1.5x in one fight (Lump on its Nest, then the Ratchet lands it).
- What stops it: (1) the pile is away, and shows only as an Egg at half stats unless Redwing is beside it; (2) Redwing and the Cuckoo both need to be beside the same Nest in the same row, so only one Nest per row gets both; (3) the Homecoming cards (Tern, Stork, Dunnock) end Cuckoo trips early, so the two routes fight each other; (4) Fly South's "must fight once at home" rule sets a floor of 2 turns a cycle.
- Economy is small and doesn't feed stats: Swallow 1 gold per cycle, Jay 1 Acorn per cycle, no sale gold on flights.

### Bog folk
- Core condition: the enemy attacks into your Mire (the lock makes the enemy across hit its maker first; the maker waits once). Almost every payoff fires on that attack or on a Mired enemy's death.
- Payoffs: mostly combat-only (Bitter, Bufo's halving, Gideon's and Jenny's extra attacks, Sal, Lantern, Peat King). Permanent growth is Ranocchio +1/+1 a fight, Tiddy +2/+2 a fight spread over the walls hit, and the Toad, capped at +3/+3.
- Enablers: Mire sources (Toad, Bufo, Cutter, Gideon, Jenny, Prima Donna x3, Peat King, Chorus lends 2). Bitter sources (Nan lends, Bufo, Chorus lends, Prima Donna, Peatlings).
- Compounding: patch count multiplies Lantern (+3 Attack each), Sal (2 damage each), Snap targeting, Tiddy and Peat King triggers. Bitter stacks (own + lent). All of it is this-fight only.
- What stops it: once- and twice-a-fight limits on every permanent grower; the Toad's +3/+3 cap; Peat Cutter's 3 gold lifetime; one patch per enemy slot; Mire wasted on an empty slot or an Egg.
- Bog is the tribe whose payoffs scale with the enemy's size (Bufo halves Attack, Snap and Lantern aim at the biggest stuck enemy). It is built as the answer to concentration, not as a concentrator.

### Fairies
- Core condition: slots. Rings belong to slots and need empty slots to be made (Sally) or used by summons (Wisp); Rainbow needs units played into empty slots; Annis, Hob and Lob need specific neighbours; Shy units refuse every buff except an aimed spell.
- Payoffs: Rings (capped +4/+4 a slot, so at most +28/+28 on the board), Monarch +1/+1 per Fairy on a Ring, Annis/Hob/Lob +2 stats a turn each, Silky's one-shot Rings, Cluricaun's +1 Attack per painted unit.
- Enablers: Ring makers (Nan, Sally, Silky; spells Spore Cloud, Boundary Stone) feed Wisp, Monarch, Reel-Mistress. Cradle Fetch doubles a Start of Combat text.
- Compounding: Rings x Monarch x Wisps x Reel-Mistress; golden Queen doubles the pool she shares.
- What stops it: the Ring cap (binds by R8-R10 on the slots in use), Shy units staying at printed stats, empty-slot needs fighting a full board, the Queen splitting evenly among every other Fairy.
- Fairies hold the strongest proportional answers: Belladonna's Nightshade (half current Health each time the enemy is attacked) and the Changeling (the enemy carry hits its own team). These get stronger as stat scale rises.

## Board estimates (combat stats, auras, Rings and Eggs included)

Method: "Bot" is the measured bot recruit-board average (base + permanent + tribe bonus; excludes auras, Rings, Eggs and combat-only effects: tools/sim/bench.gd:383-393 sums combat_spec, src/core/recruit_unit.gd:180-189). "Typical" is my estimate: T4 by R8-9, T5 by R11, T6 by R14-15 (bots: median T6 turn 14-15), Suppers 1/2/3 at R8/R12/R16, the key engine found 1-2 turns after its tier. "Highroll" is everything lining up: T4 R6, T5 R8, T6 R10, Suppers 1/2-3/3, key engine from its first tier turn; neutral stat spells (Pinch, Last Orders) left out. R9 fixture rows are the constructed boards in docs/ideation/evidence/pass2-followup-boards.md. Growth arithmetic: scratch scripts/growth.py.

| Tribe | Round | Bot avg stats/unit | Typical avg | Typical biggest | Highroll avg | Highroll biggest |
|---|---|---|---|---|---|---|
| Birds | R8 | 12.0 | ~11 | 6/8 (Redbreast, 2 Nests) | ~14 (R9 fixture 14.6) | 9/10 Egg beside Redwing (R9 fixture) |
| Birds | R12 | 19.6 | ~18 | 11/12 Cuckoo Bird (as Egg 6/12 with Tom Tit, or Lump 11/13 on its Nest) | ~21 | 18/19 Bird (full only beside Redwing); Ratchet lands it again mid-fight |
| Birds | R16 | 26.5 | ~25 | 19/20 | ~29 | 25/26; golden Cuckoo from R11 about 30/31 |
| Bog | R8 | 12.3 | ~11 | 4/6 Toad at cap or Gideon 3/7 | ~12 (R9 fixture 12.3) | 8/9 Ranocchio (R9 fixture) |
| Bog | R12 | 20.4 | ~19 | 8/9 Ranocchio | ~20 | 12/13 Ranocchio (golden 21/23); Lantern Man 22/11 in combat (golden 41/19) |
| Bog | R16 | 27.4 | ~26 | 13/14 Ranocchio; Lantern 19/11 in combat | ~27 | 16/17 Ranocchio or a Tiddy-fed wall about 21/25; Lantern 25/11 (golden 47/19) |
| Fairies | R8 | 12.2 (n=29) | ~10 | 6/8 (unit on a full Ring) | ~13 (R9 fixture 14.0) | 8/11 Reel-Mistress on a Ring (R9 fixture) |
| Fairies | R12 | 19.8 (n=26) | ~17 | 9/12 | ~23 | 12/20 standing (Ring, Monarch, Supper, Hob); a lone Queen-fed Fairy about 20/30 |
| Fairies | R16 | 29.3 (n=15) | ~23 | 12/16 | ~28 | 12/21 standing; lone Queen-fed Fairy after 3 Teinds about 44/68 (golden Queen about 80/125), on a board that has given up Monarch and Rings |

Reading: the biggest unit is about 1.5-2x the average unit on Bird boards, about 1.2x (permanent) to 1.8x (Lantern, combat Attack only) on Bog boards, and about 1.1-1.3x on Fairy boards unless the Queen is fed into one Fairy. Owner's reference for healthy Battlegrounds endgames: most units over 100/100. Our R16 average is about 13/14, and the best highroll pile in these three tribes (outside a golden Queen line) is about 25-30 per stat: 4-8x below that reference.

## Bot lobby data (sanity check only)

400 complete 8-player lobbies, 3,200 seats (benchmark finished: build/sim/pass2-followup/progress.json "stage": "complete"; the files are now free_choice_plain.{players,rounds,cards}.csv, not the hidden .0 files the brief named). Scripts: scratch scripts/bots1.py-bots4.py.

Summary (free_choice_plain.summary.csv): Birds 371 seats, mean place 5.10 (CI 4.91-5.29), first 4.9%; Bog 336, 4.30, 12.8%; Fairies 29, 3.79, 31% (n too small); Hedgerow 281, 3.75, 25.3%; Hunters 705, 3.89, 17.6%; Oozes 283, 4.76, 9.2%. Fair share of firsts is 12.5%.

Shape of the curve (all seats, total recruit stats): R8 p50 80, p99 116, max 129 (p99/p50 1.45); R12 p50 133, p99 191, max 226 (1.44); R16 p50 174, p99 266, max 318 (1.53). Within a lobby, the biggest board is 1.22x the median at R12 (p90 lobby 1.38, worst 1.63). Gold at start of R12: p50 12, p99 17, max 23. Bots produce almost no snowballs: the top board is under 2x the median at every round. The owner said a 10x top 1% is acceptable; bots show 1.5x.

Final-board card associations on own-tribe boards (survivor bias applies):
- Birds: Cuckoo on board, mean place 5.61 vs 4.57 without; Stork 5.44 vs 4.75; Goose 4.58 vs 5.41; any T6 Bird 3.65 vs 6.16. Only 66 of 371 Bird boards had Cuckoo with Redwing, Lump or Ratchet.
- Bog: Lantern Man 2.72 (25% first) vs 5.60; Peat King 2.67 vs 6.02; Tiddy 3.77 vs 4.46; Ranocchio 5.00 vs 4.06; Spitfire Sal on 3 Bog boards.
- Fairies: bots end on Fairies in 29 of 2,576 seats where Fairies were in the lobby. Queen of Elfland sits on 653 final boards, 634 of them not Fairy boards, where Teind has no one to share with.
- Hedgerow: Squire Lollop 2.18 (47.9% first) vs 5.44; Committee 2.89 (36.2%) vs 4.61; Old Mother Mast 2.62 vs 5.40; Alderman Dozey 4.07 vs 3.58 (worse with him).

## Constructed R9 fixtures (weighted above bot data, per the owner's 9 Nov note)

docs/ideation/evidence/pass2-followup-boards.md and pass2-followup/r9-results.md (13,200 fights). Scratch scripts/fixtures2.py.

| Board | Units | Total stats | Avg | Biggest | Biggest share | Same-roll win % |
|---|---|---|---|---|---|---|
| hedgerow_low | 6 | 65 | 10.8 | 10/16 (Dozey) | 0.40 | 99.6 |
| birds_low | 7 (1 Egg) | 68 | 9.7 | 6/8 | 0.21 | 62.1 |
| bog_low | 7 | 63 | 9.0 | 5/7 | 0.19 | 61.9 |
| fairies_low | 6 | 50 | 8.3 | 8/10 (Moss Ooze, 4 Pinches) | 0.36 | 10.2 |
| fairies_high | 7 | 98 | 14.0 | 8/11 | 0.19 | 77.0 |
| birds_high | 7 (2 Eggs) | 102 | 14.6 | 9/10 Egg | 0.19 | 34.5 |
| bog_high | 7 | 86 | 12.3 | 8/9 | 0.20 | 28.3 |
| hedgerow_high | 7 | 75 | 10.7 | 7/9 | 0.21 | 44.9 |

- For the owner's concentration claim: hedgerow_low has a middling total (65; the lows range 50-68, Birds low has 68) but one 10/16 unit, and wins 99.6% (100% against Bog, Birds, Fairies and Hunters lows). No other low has an outer unit with more than 10 Health.
- Against it, or rather incomplete: fairies_low also concentrates (36%) and wins 10%, because its total is 50 and its pile has 8/10, not 10/16. Concentration wins once the pile clears the enemy's Attack and Health thresholds; below them it doesn't.
- Birds_high has the biggest total (102) and wins 34.5%: its stats sit in textless Eggs, and Bird text is mostly recruit-phase.
- Caveat: +1/+1 on every unit moves most boards by 30-68 points (r9-results.md sensitivity table). These are threshold tests at one round, one board per roll.

## What sets Hedgerow apart (structure)

1. Economy and stats share a currency. Acorns come from Partner, Mast, Jay, and combine upward (3 Acorns = a 5-gold Stash). Dozey eats them at +1/+1 per Acorn (feeding rounds up), Pym Passes +2/+2 per Stash, Beadle +1/+1 per Acorn, Hayward +1/+1 to every touching Hedgerow unit per Stash, Treasurer reads held Acorns. An economy lead becomes a stat lead directly: the feedback loop the owner describes. Birds' and Bog's economy (Swallow, Jay, Pretender, Cutter) is 1 gold per trigger and feeds no tribal payoff; Fairies' is one-shot (Chaser, Shy).
2. A chosen, protected carry. Pass always lands on the last occupied slot in F1-B1-F2-B2-F3-B3-F4 (rulebook 12.1.6), so the player picks the pile and can put it in the back. Dozey adds the only x2 self-growth in these four tribes (once, up to +8/+8, inside a +12/+12 cap). Birds' pile is away (half stats as an Egg). Bog's pile is combat-only Attack (Lantern) or +1/+1 a fight (Ranocchio). Fairies' piles are capped at +4/+4 a slot.
3. Late payoffs whose condition is nearly free. Committee and Squire Lollop need only a full, unbroken board (+2/+1 and +2/+2 on all seven, 21 and 28 stats a fight), which every player wants anyway. Birds' conditions need absence, Fairies' need empty slots or Shy units that refuse buffs, and Bog's need the enemy to attack into its walls.
4. Both channels at once: one concentrated pile (Pass, Dozey) plus a buffed wide board (Committee, Lollop, Hayward, Mallow).
5. Growth happens while recruiting and is permanent, so it is there every fight and in every snapshot.

Bot evidence on which of these matters: Hedgerow's lobby wins track Lollop, Committee and Mast (points 1, 3, 4), not Dozey (Dozey boards place worse). The fixture evidence tracks Dozey (point 2). Both readings point at structure rather than at a single number, but they disagree on which structure.

## Assumptions found (explicit and implicit)

| # | Assumption | Where | Explicit? | Risk | For | Against | Test |
|---|---|---|---|---|---|---|---|
| 1 | Half-stat Eggs are a fair price for flying | rulebook 12.1.4 (line 790); held_units.gd:344 | Yes | High | Designers wanted flying to cost tempo (birds.md) | Birds last in lobbies (5.10, 4.9% first); birds_high has the biggest R9 total and wins 34.5%; Cuckoo boards place worse | Constructed R12/R16 Bird boards with Eggs at half vs full Health, vs the other tribes' R12/R16 boards |
| 2 | The Ring cap of +4/+4 a slot keeps Fairies fair without making them flat | 8.5.4 (line 506) | Yes | Medium-high | Fairies high wins 77% at R9 | Fairies' only concentrator is the Queen, which fights Monarch and Supper; fairies_low 10% | R12/R16 Fairy fixtures with cap 4 vs 8 or tier-scaled |
| 3 | Once- and twice-a-fight limits keep Bog growth safe | ranocchio once, tiddy twice, toad cap 3 | Partly (design notes) | High | Pass 2 Bog fix aimed to avoid "slow walls" (pass2-bog.md section 8) | Bog's best permanent growth is about +6 stats a fight on a highroll; the owner wants bigger numbers and rewards | R12/R16 Bog fixtures with Ranocchio twice a fight or Tiddy three times |
| 4 | Flat answers (Bitter 1-2, Jenny -2, Jack Daw 2, Hex up to tier) stay relevant | card texts | Implicit | Medium | Fine at R9 scale (enemy Attack 5-8) | Lose value linearly as stat scale rises; proportional answers (Bufo, Belladonna, Changeling) gain | Re-run fixtures with every stat doubled |
| 5 | Bot board totals compare tribes fairly | bench.gd:383-393 | Implicit | High (for reading lobbies) | Same measure for all | Excludes auras, Rings, Eggs and combat-only power: understates Birds, Fairies and Bog | Log combat-start stats per unit in the bench |
| 6 | Bot tribe choice says something about Fairies | free_choice_plain.summary.csv | Implicit | High (for reading lobbies) | — | 29 Fairy seats; Queen used on 634 non-Fairy boards where Teind only destroys | Don't use lobby Fairy rates; use fixtures |
| 7 | The two Bird routes mix | birds-pass1.md "Two routes that mix" | Yes | Medium | Goose and Cuckoo serve both | Tern, Stork and Dunnock end Cuckoo trips early; Redwing and Cuckoo compete for adjacency | Fixture: Hatchery-only vs mixed board at R12 |
| 8 | Bog's payoffs need the enemy to attack its walls, and walls survive | 9.4.5a, 9.6.0 | Partly | Medium | Bitter-first moved Bog high 12 to 51% (pass2-bog.md section 6) | One Supper short and Bog falls to 3.5% (same table): a cliff | Sensitivity of Bog fixtures to enemy Attack |
| 9 | Hedgerow's lead is structural, not two cards | owner note 09a | Explicit (owner) | Medium | Acorn economy feeds stats; Dozey fixture 99.6% | Lobby wins track Lollop/Committee (47.9%/36.2% first when on board) | Swap Lollop and Committee for plain T5/T6 bodies and re-run lobbies or fixtures |
| 10 | No tribe needs a gold-to-stats sink | content | Implicit | High | Neutral Last Orders and Pinch exist | Bog has none; Birds' is rate-limited; only Hedgerow's compounds | Fixtures at R12/R16 with surplus gold spent through each tribe's sink |
