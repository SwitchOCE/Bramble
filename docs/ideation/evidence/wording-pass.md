# Wording pass: before and after

The owner, 8 Nov 2026 (`docs/design/owner-notes/2026-11-08e-text-too-wordy.md`): "Clear and concise wording. Make complicated things simple." Effects, numbers, mechanics JSON and art are unchanged. Only the words changed. Base: `4b109c8`. Style rules: `docs/ideation/wording-guide.md`. The counts come from `python3 tools/research/word_counts.py --ref 4b109c8`.

## Words per card

| | Cards | Median | p90 | Max |
|---|---|---|---|---|
| **Bramble before** (units, spells, heroes) | 152 | 13 | 24 | 36 |
| **Bramble after** | 152 | 11 | 17 | 25 |
| Bramble golden text, before | 115 | 15 | 26 | 41 |
| Bramble golden text, after | 115 | 12 | 18 | 26 |
| BG minions (current pool) | 303 | 11 | 16 | 23 |
| BG Tavern spells | 76 | 9 | 16 | 27 |
| BG hero powers | 123 | 13 | 18 | 25 |
| Galaxy cards | 600 | 11 | 19 | 27 |

Full breakdown:

| Set | Cards | Median | p90 | Max |
|---|---|---|---|---|
| BG minions | 303 | 11 | 16 | 23 |
| BG Tavern spells | 76 | 9 | 16 | 27 |
| BG hero powers | 123 | 13 | 18 | 25 |
| Galaxy cards | 600 | 11 | 19 | 27 |
| Bramble all cards (4b109c8) | 152 | 13 | 24 | 36 |
| Bramble pool cards (4b109c8) | 140 | 14 | 25 | 36 |
| Bramble units (4b109c8) | 115 | 14 | 25 | 36 |
| Bramble spells (4b109c8) | 25 | 10 | 19 | 34 |
| Bramble heroes (4b109c8) | 12 | 14.5 | 18 | 25 |
| Bramble golden text (4b109c8) | 115 | 15 | 26 | 41 |
| Bramble all cards (now) | 152 | 11 | 17 | 25 |
| Bramble pool cards (now) | 140 | 12 | 18 | 25 |
| Bramble units (now) | 115 | 11 | 18 | 25 |
| Bramble spells (now) | 25 | 9 | 15 | 21 |
| Bramble heroes (now) | 12 | 12 | 15 | 16 |
| Bramble golden text (now) | 115 | 12 | 18 | 26 |

The longest card is still Dishwater Nell, at 25 words. It has two conditions that decide whether it pays: the unit must rise 2+ tiers, and Nell must touch an Ooze. A shorter version dropped one of them, and the drift check rejected it. Only five cards are over 20 words.

## Other on-screen text

| What | Before | After |
|---|---|---|
| Keyword and glossary reminders (41) | median 17 words, max 47 | median 11, max 16 |
| How to play (14 pages) | 825 words, longest page 97 | 357 words, longest page 33 (a test now holds each page to 40) |
| Pass reminder | 48 | 14 |
| Mire reminder | 27 | 6 |
| Tribe bonus explainer | 41 | 6 |
| Charcoal Burner plan line | 37 | 12 |

Combat log and result lines, gold plaque, tribe bonuses, Discover notices, held-unit and slot notes, and the text tool's help and README were cut the same way. Cards that explain themselves when tapped are no longer explained in the guide.

## Where the cut words went

Rulings that came off a card face now go in an optional `details` field, or `golden_details` where numbers double. The details panel shows it, muted, under the keyword reminders, and the text tool prints it under KEYWORDS (`src/ui/card_rulings.gd`). `check_units.py` counts numbers in `details`, so a cap that leaves the card still has its golden doubling written down. Some cuts were dropped outright because the game already implies them: combat buffs end with the fight, ties are random, and a Belly needs room.

## Checks

- **Meaning drift.** A fresh reviewer compared all 97 changed cards against their `mechanics`, `do` or `power` JSON and the core code. It raised 10 flags, all now fixed:
  - Madame Bufo's penalty only applies when the enemy she Mires kills her. The card said anyone. **Wrong**, fixed.
  - The card no longer said "if this has room" (Hasty Pudding) or "if you took any" (Jack Daw). Fixed.
  - Brother Wolf "won't lead" is back on the card. So are Mistress Russet's tier condition and the caps for Elder Ooze and Harvest Supper.
  - Reel-Mistress and golden Changeling were ambiguous. Both are reworded.
  - Hoglet Mother's text is back to the original.
  - Old Brock keeps "next to". In the code that means neighbours, which are not the same as "beside".
- **Newcomer read.** A fresh agent who had never seen the game read 20 random cards cold. 6 were clear, 7 unsure and 7 confusing. Three keyword-only cards (Bide, Both Ends, Whistle) were unclear only because the sample file left out their reminders, which the game does show. Changes made after the read:
  - Queen of Elfland now says "Split their stats among your other Fairies".
  - The Ring reminder says "gets this bonus" instead of "has these stats", which read as "set to".
  - The Quarry reminder no longer ends on a fragment ("Take: when that enemy dies").
  - The Pounce reminder says whose quarry is hit.
  - Old Brock says "wherever it stands" instead of "reached anywhere".
  - Left as they are, because the game teaches them elsewhere: "Mired" on Spitfire Sal (Mire's own cards teach it), and Old Tern's 3 turns against Fly South's default of 2 (the card overrides the default).
- **Gate.** `./scripts/check.sh` passes. 1,308 tests.

## Tests that changed, and why

Each test still checks the same behaviour. Only the strings it expects changed.

- `test_round4_bugs`: the Last Orders ruling moved to Pipistrelle Echo's `details`, so the test asserts it there.
- `test_burner_hint`: asserts the shorter plan sentence. The "better buy" and "F2 and F3" advice is gone.
- `test_commitment`: Harvest Supper's rulings now live in `details` and the tribe-bonus line. The guide test checks the ideas the guide teaches, not card names.
- `test_clarity`:
  - Mire no longer drags in the Bell glossary line.
  - The Discover note is "no more eligible cards".
  - Brother Wolf's slip gets padded text, because it no longer overflows and the test exists to exercise scrolling.
- `test_engines`, `test_round4_guide`: the damage page teaches that winning hurts the loser's hero and that survivors hit harder. The Last Blow and toll rulings left the guide. A new test holds every page to 40 words.
- `test_round3_rules`, `test_polish`, `test_review_bog_preview`, `test_review_fixes`, `test_review_tribes56_log`, `test_followup_tribes56`, `test_lane_display`: these match the new reminder and log wording. Each still checks the same fact, such as the slot named, the permanent reward, the Mired maker or the poach claim.
- `docs/prototype/fixtures/combat_nightshade.json`: the replayed fixture carries Belladonna Sprite's new text.

## Keyword reminders

| Keyword | Before | After | Words |
|---|---|---|---|
| Acorn | Play for gold: Acorn {acorn}, Stash {stash}, Great Hoard {great_hoard}. Three of a size combine into the next size. | Play for gold: Acorn {acorn}, Stash {stash}, Great Hoard {great_hoard}. Three make the next size. | 20 → 16 |
| Spill | If a summon from this has no room, get an Acorn instead. | If a summon from this has no room, get an Acorn instead. | 12 → 12 |
| Pass | When the card says to Pass, wait until End of Turn. The bonus then moves right through touching units along F1-B1-F2-B2-F3-B3-F4. The last unit keeps it permanently. Start from this unit's slot. If it has left, start from where it stood when the card said to Pass. | At End of Turn, the bonus moves right along touching units; the last keeps it. | 47 → 15 |
| Ring | Whoever stands on this slot has these stats. | The unit on this slot gets this bonus. | 8 → 8 |
| Rainbow | A unit played into an empty slot paints it. A band fades if its unit moves or leaves. | A unit played into an empty slot paints it, until it leaves. | 18 → 12 |
| Shy | If this gains Attack or Health on your board during recruiting, it walks out. Gain 2 gold next turn (4 if golden). This is not a sale. | Buffed while recruiting: walks out for 2 gold next turn (4 if golden). | 27 → 13 |
| Bristle | When an enemy deals this damage in an attack, it takes this much back. | An enemy that hits this in an attack takes this much back. | 14 → 12 |
| Hunker | Takes half damage when attacked, rounded up. | Takes half damage when attacked. | 7 → 5 |
| Hex | Start of Combat: the enemy slot across from this has less Attack, whoever stands there, for this fight. | Start of Combat: the enemy slot across has this much less Attack. | 18 → 12 |
| Nightshade | Whenever attacked, this first loses half its current Health, rounded down. | When attacked, this first loses half its Health. | 11 → 8 |
| Belly | Holds this many units, dropped in from the shop, your hand or your board. They wait inside, idle and safe. When this dies they come out alive, last in first. | Holds this many units, safe inside. When this dies, they come out. | 30 → 12 |
| Fly South | Flies for no sale gold; back to hand in 2 turns. Its empty Nest fights as a textless Egg with half its Attack and Health, rounded up. A sale is final if played or landed this turn. | Sells for no gold: it flies off and returns in 2 turns. | 37 → 12 |
| Nest | The slot a Bird left, until it comes home. Empty, it holds a textless Egg with half that Bird's current Attack and Health, each rounded up. Mother Goose's own Egg stays 0/2. A slot holds one Nest. | While its Bird is away, an Egg with half its stats fights here. | 37 → 13 |
| Swoop | Attacks the enemy back row while there's anyone in it, from either row. | Attacks the enemy back row while anyone is in it. | 13 → 10 |
| Mired | Standing on a bog patch. While the unit that made it lives, this must attack that unit. Moving off the patch frees this. | Must attack the unit that mired it. | 23 → 7 |
| Borrowed | Fights for the other side until it has attacked once, then goes home. Combat buffs stay until the fight ends. | Fights for the other side for one attack, then goes home. | 20 → 11 |
| Pin | An enemy this hurts skips its next attack. | An enemy this hurts skips its next attack. | 8 → 8 |
| Stalled | Skips its next attack, then loses Stalled. | Skips its next attack, then loses Stalled. | 7 → 7 |
| Mire | At the bell, this makes a bog patch in the enemy slot across. Whoever stands there must attack this while this lives, even in your back row. | The enemy across must attack this. | 27 → 6 |
| Quarry | At the bell, mark the enemy across. This attacks that enemy whenever rows allow. The mark follows the unit. Take: when it faints while this Hunter is on the board, even if both faint together. | This attacks the enemy across whenever it can. Take: when that enemy dies. | 35 → 13 |
| Bitter | After an enemy attacks this, it loses this much Attack for the fight, to a minimum of 1. | After an enemy attacks this, it loses this much Attack, down to 1. | 18 → 13 |
| Snap | Attacks the Mired enemy with the most Attack, wherever it stands. | Attacks the Mired enemy with the most Attack. | 11 → 8 |
| Pack | When a unit beside this attacks on your turn, this joins it once a cycle. Only the leader takes counter-damage. Put this after its leader in the row. | When a unit beside this attacks, this joins in. Once a cycle. | 28 → 12 |
| Pounce | Once a cycle, after your side damages the quarry of a unit next to this, this attacks that quarry at once, wherever it stands. It takes counter-damage. | After a neighbour's quarry is hit, this attacks it too. Once a cycle. | 27 → 13 |
| Behind | B1 is behind F1 and F2; B2 behind F2 and F3; B3 behind F3 and F4. So F2 has both B1 and B2 behind it. | Each back slot is behind two front slots: B1 behind F1 and F2. | 25 → 13 |
| Beside | The slots immediately left and right in the same row. F2 has F1 and F3 beside it. | The slots left and right in the same row. | 17 → 9 |
| Touching | An unbroken run of units along F1-B1-F2-B2-F3-B3-F4, including this unit. An empty slot breaks the run; units in the same row do not touch directly. | An unbroken run of units along F1-B1-F2-B2-F3-B3-F4. | 25 → 7 |
| Bell | The opening of a fight, when Mire patches and Quarry marks are set. This happens after “first of all” text and before the other Start of Combat effects. | The start of a fight, before other Start of Combat effects. | 28 → 11 |
| Cycle | One pass through a side's attack order, F1 to F4 then B1 to B3. Its next cycle starts when no eligible unit has an unused attack. Each side counts its own cycles. | One pass through a side's attack order. | 32 → 7 |
| * | A golden unit, usually made by combining three ordinary copies. Its stronger stats and text are already shown. | Golden: made from three copies, with stronger stats and text. | 18 → 10 |
| Peck | Its attack strikes the target several times, its Attack split between the strikes. | Its Attack is split across several strikes on the target. | 13 → 10 |
| Quick | Deals its damage first. If that kills, it takes none. | Deals its damage first. If that kills, it takes none. | 10 → 10 |
| First Bite | Quick in this unit's first exchange each fight. | Quick in this unit's first exchange each fight. | 8 → 8 |
| Mark | Start of Combat: marks the enemy slot across. Units that enter it later take damage. | Start of Combat: marks the enemy slot across; units entering it take damage. | 15 → 13 |
| Bystander | When an enemy attacks one of your other units, this gains +1/+1 for this fight. | When an enemy attacks another of your units, this gains +1/+1. | 15 → 11 |
| Shell | The first time this takes damage in a fight, that damage is capped. | The first damage this takes each fight is capped. | 13 → 9 |
| Bide | Skips its attacks and grows each time its side's order passes it, until it is hurt. | Skips its attacks and grows each time it skips, until hurt. | 16 → 11 |
| Both Ends | With a partner at both ends of a row, each gets stronger and guards the other. | Partners at both ends of a row grow and guard each other. | 16 → 12 |
| Whistle | Never attacks. It warns the strongest enemy, whose next attack does half damage. | Never attacks. The strongest enemy's next attack does half damage. | 13 → 10 |
| Fast | End of Turn: with no paid refresh this turn, the count goes up, else back to 0. | End of Turn: counts up if you didn't pay to refresh, else resets. | 17 → 13 |
| Swarm | When a Swarm unit attacks, the others in its row join in on the same target. | When a Swarm unit attacks, others in its row join in. | 16 → 11 |

Reminders: 41. Before: median 17, max 47. After: median 11, max 16.

## Every card

### Units

| Card | Before | After | Words | Off the card (details) |
|---|---|---|---|---|
| Alderman Dozey | Feed Acorn items for +1/+1 per 2 gold, rounded up. After 3 turns in this slot: double, up to +8/+8. Permanent buffs cap at +12/+12. | Eats Acorns: +1/+1 per 2 gold. After 3 turns in this slot: double its stats, up to +8/+8. | 25 → 18 | Feeding rounds up. Its permanent buffs cap at +12/+12. |
| ↳ golden | Feed Acorn items for +2/+2 per 2 gold, rounded up. After 3 turns in this slot: double, up to +16/+16. Permanent buffs cap at +24/+24. | Eats Acorns: +2/+2 per 2 gold. After 3 turns in this slot: double its stats, up to +16/+16. | 25 → 18 | Feeding rounds up. Its permanent buffs cap at +24/+24. |
| Aunt Aspic | End of Turn: what's inside the Oozes in front of this gains +1/+1. | *(unchanged)* | 13 → 13 |  |
| Ballooning Spider | In your back row, this attacks the enemy back row. | *(unchanged)* | 10 → 10 |  |
| Beadle Warrenby | All your summons Spill. After a Spill: Pass right +1/+1, twice a fight. | All your summons Spill. After a Spill: Pass right +1/+1. Twice a fight. | 13 → 13 |  |
| ↳ golden | All your summons Spill. After a Spill: Pass right +2/+2, twice a fight. | All your summons Spill. After a Spill: Pass right +2/+2. Twice a fight. | 13 → 13 |  |
| Belladonna Sprite | Start of Combat: in the back row, the 2 front enemies facing this get Nightshade. In the front row, the enemy across does. | Start of Combat: give the enemy across Nightshade. In the back row, the 2 facing this instead. | 23 → 17 |  |
| ↳ golden | Start of Combat: the enemy across from this gets Nightshade, and in the back row so do the 2 front enemies facing this. | Start of Combat: give the enemy across Nightshade. In the back row, the 2 facing this too. | 23 → 17 |  |
| Belladonna Sprite | Start of Combat: give the enemy with the highest Health Nightshade (a tie is broken at random). | Start of Combat: give an enemy with the most Health Nightshade. | 17 → 11 |  |
| ↳ golden | Start of Combat: give the two enemies with the highest Health Nightshade. | Start of Combat: give two enemies with the most Health Nightshade. | 12 → 11 |  |
| Bitter Toad | Whenever this deals damage to an enemy, that enemy gains Nightshade. | Enemies this damages gain Nightshade. | 11 → 5 |  |
| ↳ golden | Whenever this deals damage to an enemy, or is dealt damage by an enemy, that enemy gains Nightshade. | Enemies this damages, or that damage this, gain Nightshade. | 18 → 9 |  |
| Bridge Toad | Mire. Once a fight, if the enemy this Mires had their top Attack at the bell and attacks this, get 1 gold next turn. | Mire. If this Mires the top-Attack enemy and it attacks this, get 1 gold next turn. | 24 → 16 | Once a fight. Top Attack is judged at the bell. |
| ↳ golden | Mire. Once a fight, if the enemy this Mires had their top Attack at the bell and attacks this, get 2 gold next turn. | Mire. If this Mires the top-Attack enemy and it attacks this, get 2 gold next turn. | 24 → 16 |  |
| Brother Wolf | Pack, once per unit beside this each cycle. Does not lead while a unit beside this can lead. | Pack, with each unit beside this. Won't lead while a neighbour can. | 18 → 12 | It joins each neighbour once a cycle. |
| ↳ golden | Pack, once per unit beside this each cycle. Does not lead while a unit beside this can lead. | Pack, with each unit beside this. Won't lead while a neighbour can. | 18 → 12 |  |
| Bubble and Squeak | Belly 1. Once a fight, after this survives a hit, half its stats split off into a copy in the nearest gap, with an empty Belly. | Belly 1. After this survives a hit, split half its stats into a copy. Once a fight. | 26 → 17 | The copy appears in the nearest gap with an empty Belly. |
| ↳ golden | Belly 2. Twice a fight, after this survives a hit, half its stats split off into a copy in the nearest gap, with an empty Belly. | Belly 2. After this survives a hit, split half its stats into a copy. Twice a fight. | 26 → 17 |  |
| Changeling | Start of Combat: trade places with the enemy across. Each fights for its new side until that enemy has attacked once. | Start of Combat: swap with the enemy across until it attacks. | 21 → 11 |  |
| ↳ golden | Start of Combat: trade places with the enemy across, which gains +4/+4 this combat. Each fights for its new side until that enemy has attacked once. | Start of Combat: swap with the enemy across until it attacks. That enemy gains +4/+4. | 26 → 15 |  |
| Charcoal Burner | End of Turn: burn your gold above 5, up to 6. Units behind this gain +1/+1 per 2 burned. | End of Turn: burn gold above 5, up to 6. Units behind this gain +1/+1 per 2 burned. | 19 → 18 |  |
| ↳ golden | End of Turn: burn your gold above 5, up to 12. Units behind this gain +1/+1 per 2 burned. | End of Turn: burn gold above 5, up to 12. Units behind this gain +1/+1 per 2 burned. | 19 → 18 |  |
| Chiffchaff | Fly South. When played: give the units in front of this +1 Attack. | *(unchanged)* | 13 → 13 |  |
| Cluricaun | Rainbow. Your units on bands have +1 Attack. | *(unchanged)* | 8 → 8 |  |
| Cradle Fetch | Start of Combat: become a copy of the unit behind this, as printed. | Start of Combat: become a printed copy of the unit behind. | 13 → 11 | The copy's Start of Combat text fires. |
| ↳ golden | Start of Combat: become a golden copy of the unit behind this, as printed, then gain +4/+4 this combat. | Start of Combat: become a golden printed copy of the unit behind, with +4/+4. | 19 → 14 |  |
| Cricket Busker | After you cast a spell, gain 1 gold next turn, twice a turn. | After you cast a spell: gain 1 gold next turn. Twice a turn. | 13 → 13 |  |
| ↳ golden | After you cast a spell, gain 2 gold next turn, twice a turn. | After you cast a spell: gain 2 gold next turn. Twice a turn. | 13 → 13 |  |
| Cut-and-Come-Again | Belly 1. Every other start of your turn: get a plain copy of the last non-Ooze inside (Created). Copies can't triple or Fly South; selling is final. | Belly 1. Every other Start of Turn: get a plain copy of the last non-Ooze inside. | 27 → 16 | Copies are Created: they can't triple or Fly South, and selling one is final. |
| ↳ golden | Belly 2. Every other start of your turn: get 2 plain copies of the last non-Ooze inside (Created). Copies can't triple or Fly South; selling is final. | Belly 2. Every other Start of Turn: get 2 plain copies of the last non-Ooze inside. | 27 → 16 |  |
| Dishwater Nell | Start of your turn: swap the lowest-tier unit in your shop for one of your tier. If it was 2+ tiers lower and this touches an Ooze, gain 1 gold. Only your first Nell pays. | Start of your turn: upgrade your shop's lowest-tier unit to your tier. If it rose 2+ tiers and this touches an Ooze, gain 1 gold. | 35 → 25 | It becomes a random unit of your tier. Only your first Nell pays. |
| ↳ golden | Start of your turn: swap the 2 lowest-tier units in your shop for ones of your tier. If one was 2+ tiers lower and this touches an Ooze, gain 2 gold. Only your first Nell pays. | Start of your turn: upgrade your shop's 2 lowest-tier units to your tier. If one rose 2+ tiers and this touches an Ooze, gain 2 gold. | 36 → 26 |  |
| Dr Urchin | Bristle 2. After this pricks: Pass right +1 Attack this combat. | Bristle 2. After this pricks: Pass right +1 Attack. | 11 → 9 |  |
| ↳ golden | Bristle 4. After this pricks: Pass right +2 Attack this combat. | Bristle 4. After this pricks: Pass right +2 Attack. | 11 → 9 |  |
| Drumming Woodpecker | Peck 2. Whenever this attacks, give your other Birds +1 Attack this combat. | Peck 2. Whenever this attacks: give your other Birds +1 Attack. | 13 → 11 |  |
| ↳ golden | Peck 2. Whenever this attacks, give your other Birds +2 Attack this combat. | Peck 2. Whenever this attacks: give your other Birds +2 Attack. | 13 → 11 |  |
| Earwig Mother | When this dies, summon two 1/1 Nymphs in empty slots behind it. | When this dies: summon two 1/1 Nymphs behind it. | 12 → 9 | If the slots behind are taken, they go to the nearest empty ones. |
| ↳ golden | When this dies, summon two 2/2 Nymphs in empty slots behind it. | When this dies: summon two 2/2 Nymphs behind it. | 12 → 9 |  |
| Elder Ooze | Belly 1. Whenever a unit comes out of one of your Oozes, it gains +1/+1 this combat for each of your units that has come out this fight, up to +3/+3. | Belly 1. When a unit comes out of your Oozes, it gains +1/+1 per unit out, up to +3/+3. | 31 → 19 | Counts every unit that has come out this fight. |
| ↳ golden | Belly 2. Whenever a unit comes out of one of your Oozes, it gains +2/+2 this combat for each of your units that has come out this fight, up to +6/+6. | Belly 2. When a unit comes out of your Oozes, it gains +2/+2 per unit out, up to +6/+6. | 31 → 19 |  |
| Ermine Duellist | Quick while this is undamaged. | *(unchanged)* | 5 → 5 |  |
| Fairy Monarch | Rings under your Fairies give +1/+1 more. | *(unchanged)* | 7 → 7 |  |
| Figgy Duff | Belly 1. Once a turn: two Bought copies make a golden if one is inside this. No Triple Reward. | Belly 1. Once a turn: two Bought copies make a golden if one is inside this. | 19 → 16 | This golden gives no Triple Reward. |
| ↳ golden | Belly 2. Once a turn: two Bought copies make a golden if one is inside this. No Triple Reward. | Belly 2. Once a turn: two Bought copies make a golden if one is inside this. | 19 → 16 |  |
| Fox Cub | Mark (2). | *(unchanged)* | 2 → 2 |  |
| Fox Notary | Bystander. | *(unchanged)* | 1 → 1 |  |
| Frumenty | Belly 1. This has the text of what's inside it. | *(unchanged)* | 10 → 10 |  |
| The Gabble Ratchet | When a unit on a Nest dies, an Egg too, its Bird lands there for this fight. | When a unit on a Nest dies: its Bird lands there. | 17 → 11 | Eggs count. Once per Nest each fight. |
| ↳ golden | When a unit on a Nest dies, an Egg too, its Bird lands there for this fight with 2 times its Attack. | When a unit on a Nest dies: its Bird lands there with twice its Attack. | 22 → 15 |  |
| Garden Snail | Shell 4 (needs more than 4 Health to save it). | Shell 4. | 10 → 2 |  |
| ↳ golden | Shell 4 (needs more than 4 Health to save it). | Shell 4. | 10 → 2 |  |
| Gideon, Basso Profundo | Mire. After the enemy this Mires attacks this, if this lives, this attacks back with +2 Attack. | Mire. After the enemy this Mires attacks this, attack it back with +2 Attack. | 17 → 14 |  |
| ↳ golden | Mire. After the enemy this Mires attacks this, if this lives, this attacks back with +4 Attack. | Mire. After the enemy this Mires attacks this, attack it back with +4 Attack. | 17 → 14 |  |
| Granny Stir-Up | Start of Combat: touching Oozes go inside this, and it gains their Attack. When this dies, they return to their slots, still holding what they hold. | Start of Combat: touching Oozes go inside this. Gain their Attack. | 26 → 11 | When this dies, they return to their slots, still holding what they hold. |
| ↳ golden | Start of Combat: touching Oozes go inside this, and it gains 2 times their Attack. When this dies, they return to their slots, still holding what they hold. | Start of Combat: touching Oozes go inside this. Gain twice their Attack. | 28 → 12 |  |
| The Great Lump | On a Nest, this also has the card stats of the Bird away. | On a Nest, this also has its Bird's card stats. | 13 → 10 |  |
| ↳ golden | On a Nest, this also has 2 times the card stats of the Bird away. | On a Nest, this also has twice its Bird's card stats. | 15 → 11 |  |
| Grizel | Pack. After a pack attack kills its target, its leader and joiners gain +1 Attack permanently. | Pack. After your pack attack kills: its attackers gain +1 Attack permanently. | 16 → 12 |  |
| ↳ golden | Pack. After a pack attack kills its target, its leader and joiners gain +2 Attack permanently. | Pack. After your pack attack kills: its attackers gain +2 Attack permanently. | 16 → 12 |  |
| Hasty Pudding | Belly 1. Start of Combat: if this has room, swallow the enemy across. It goes back to its own side when this dies, after 3 of your units die, or when its side has nobody else. | Belly 1. Start of Combat: if this has room, swallow the enemy across. | 36 → 13 | It goes back when this dies, after 3 of your units die, or when its side has nobody else. |
| ↳ golden | Belly 2. Start of Combat: if this has room, swallow the enemy across and the enemy nearest it. They go back to their own side when this dies, after 3 of your units die, or when their side has nobody else. | Belly 2. Start of Combat: if this has room, swallow the enemy across and the one nearest it. | 41 → 18 | They go back when this dies, after 3 of your units die, or when their side has nobody else. |
| Hazel Dormouse | Bide (Slumber). | *(unchanged)* | 2 → 2 |  |
| Hedge Witch | Start of Combat: the enemy across has -1 Attack. Each spell you cast adds -1, up to -8. | Hex 1. Each spell you cast adds 1. | 18 → 8 | Up to Hex 8. |
| ↳ golden | Start of Combat: the enemy across has -2 Attack. Each spell you cast adds -2, up to -16. | Hex 2. Each spell you cast adds 2. | 18 → 8 | Up to Hex 16. |
| Hedgehog Twin | Both Ends. | *(unchanged)* | 2 → 2 |  |
| His Highness, Allegedly | Snap. Once a fight, after a Mired enemy faints, get a kiss. Third kiss: become The Prince Restored. | *(unchanged)* | 18 → 18 |  |
| Hob-in-the-Hearth | Shy. End of Turn: give the units in front of this +1 Health. | Shy. End of Turn: give the units in front +1 Health. | 13 → 11 |  |
| ↳ golden | Shy (4 gold). End of Turn: give the units in front of this +2 Health. | Shy (4 gold). End of Turn: give the units in front +2 Health. | 15 → 13 |  |
| Hoglet | Bristle 1. | *(unchanged)* | 2 → 2 |  |
| Hoglet Mother | Bristle 1. When this dies, summon a 1/1 Hoglet with Bristle 1. | *(unchanged)* | 12 → 12 |  |
| The Honorary Treasurer | +1/+1 per 3 gold your held Acorns are worth, up to +8/+8. | +1/+1 per 3 gold of held Acorns, up to +8/+8. | 12 → 10 |  |
| ↳ golden | +2/+2 per 3 gold your held Acorns are worth, up to +16/+16. | +2/+2 per 3 gold of held Acorns, up to +16/+16. | 12 → 10 |  |
| Ichneumon Wasp | An enemy this damages with an attack dies after its next attack. | An enemy this damages dies after its next attack. | 12 → 9 |  |
| ↳ golden | An enemy this damages with an attack dies after its next attack. | An enemy this damages dies after its next attack. | 12 → 9 |  |
| Jack Daw | Fly South. Start of Combat: take a quarter of what the enemy across has gained on top of its card, up to +4/+4. If that took anything, get 1 gold next turn. | Fly South. Start of Combat: steal a quarter of the enemy across's buffs. If you took any, get 1 gold next turn. | 32 → 22 | Takes at most +4/+4. |
| ↳ golden | Fly South. Start of Combat: take a quarter of what the enemy across has gained on top of its card, up to +8/+8. If that took anything, get 2 gold next turn. | Fly South. Start of Combat: steal a quarter of the enemy across's buffs. If you took any, get 2 gold next turn. | 32 → 22 | Takes at most +8/+8. |
| Jenny Greenteeth | Mire. The enemy this Mires has -2 Attack. After it attacks this, your unit beside this with the most Attack attacks it at once. | Mire. The enemy this Mires has -2 Attack. After it attacks this, your highest-Attack unit beside this attacks it. | 24 → 19 |  |
| ↳ golden | Mire. The enemy this Mires has -4 Attack. After it attacks this, your unit beside this with the most Attack attacks it at once. | Mire. The enemy this Mires has -4 Attack. After it attacks this, your highest-Attack unit beside this attacks it. | 24 → 19 |  |
| The Laird of the Sett | At the bell, all your units with no quarry take the enemy across from them as quarry. After each Take this fight, your Hunters gain +1/+1 this combat. | All your units have Quarry. After each Take: your Hunters gain +1/+1. | 28 → 12 | A unit that already has a quarry keeps it. |
| ↳ golden | At the bell, all your units with no quarry take the enemy across from them as quarry. After each Take this fight, your Hunters gain +2/+2 this combat. | All your units have Quarry. After each Take: your Hunters gain +2/+2. | 28 → 12 |  |
| Lamp Moth | Start of Combat: the units in front of this gain +1 Attack this combat. | Start of Combat: give the units in front of this +1 Attack. | 14 → 12 |  |
| ↳ golden | Start of Combat: the units in front of this gain +2 Attack this combat. | Start of Combat: give the units in front of this +2 Attack. | 14 → 12 |  |
| Little Dollop | Belly 1. Units you buy into this cost 1 gold less. | *(unchanged)* | 11 → 11 |  |
| Little Nip | Quarry. Take: get 1 gold next turn. | *(unchanged)* | 7 → 7 |  |
| The Lodger | Pounce. After this pounces, it gains +2/+1 this fight. | Pounce. After this pounces: gain +2/+1. | 9 → 6 |  |
| ↳ golden | Pounce. After this pounces, it gains +4/+2 this fight. | Pounce. After this pounces: gain +4/+2. | 9 → 6 |  |
| Madame Bufo | Mire. Bitter 2. If the enemy this Mires kills this, it loses half its Attack this fight. | Mire. Bitter 2. If the enemy this Mires kills this, it loses half its Attack. | 17 → 15 |  |
| ↳ golden | Mire. Bitter 4. If the enemy this Mires kills this, it loses half its Attack this fight. | Mire. Bitter 4. If the enemy this Mires kills this, it loses half its Attack. | 17 → 15 |  |
| Madame Ermeline | After each fight, your next upgrade costs 1 less per Take (up to 3 Takes). At tier 6, gold instead (up to 2). | After each fight, your next upgrade costs 1 less per Take. At tier 6, get gold instead. | 23 → 17 | Counts up to 3 Takes. At tier 6, up to 2 gold. |
| ↳ golden | After each fight, your next upgrade costs 2 less per Take (up to 3 Takes). At tier 6, gold instead (up to 3). | After each fight, your next upgrade costs 2 less per Take. At tier 6, get gold instead. | 23 → 17 | Counts up to 3 Takes. At tier 6, up to 3 gold. |
| Mag Pye | Start of Combat, first of all: take the text of the enemy across for this fight. It has none, and this has it. A Belly stays. | Start of Combat: steal the text of the enemy across. | 26 → 10 | Happens before other Start of Combat effects. A Belly isn't text. |
| ↳ golden | Start of Combat, first of all: take the text of 2 enemies, across and across from the next slot along. They have none, and this has it. A Belly stays. | Start of Combat: steal the text of two enemies: the one across and the next along. | 30 → 16 |  |
| Marmot Lookout | Whistle. | *(unchanged)* | 1 → 1 |  |
| Mistress Russet | Quarry. Take: if its card is your tier or lower, a pool copy goes into your next shop, 1 gold cheaper. | Quarry. Take: if it's your tier or lower, your next shop has a copy, 1 gold cheaper. | 21 → 17 | The copy comes from the pool. |
| ↳ golden | Quarry. Take: if its card is your tier or lower, a pool copy goes into your next shop, 2 gold cheaper. | Quarry. Take: if it's your tier or lower, your next shop has a copy, 2 gold cheaper. | 21 → 17 |  |
| Money Spider | Start of your turn: gain 1 gold per 3 you carried over, up to 2. | *(unchanged)* | 15 → 15 |  |
| Moss Ooze | When a spell gives one of your Oozes stats, the units inside it gain them too. | When a spell gives your Ooze stats, what's inside gains them. | 16 → 11 |  |
| ↳ golden | When a spell gives one of your Oozes stats, the units inside it gain twice that. | When a spell gives your Ooze stats, what's inside gains twice that. | 16 → 12 |  |
| Mother Goose | Fly South. While this is away, Start of Combat: each Nest strikes the enemy across for its Bird's card Attack, once. | Fly South. While away, Start of Combat: each Nest strikes the enemy across for its Bird's card Attack. | 21 → 18 |  |
| ↳ golden | Fly South. While this is away, Start of Combat: each Nest strikes the enemy across for its Bird's card Attack, 2 times. | Fly South. While away, Start of Combat: each Nest strikes the enemy across twice for its Bird's card Attack. | 22 → 19 |  |
| The Mountain Glutton | After one of your Hunters makes a Take, this gains +2/+2 this fight. | After one of your Hunters makes a Take: gain +2/+2. | 13 → 10 |  |
| ↳ golden | After one of your Hunters makes a Take, this gains +4/+4 this fight. | After one of your Hunters makes a Take: gain +4/+4. | 13 → 10 |  |
| Mr Crumb | When played and when sold: Pass right +1/+1. | When played or sold: Pass right +1/+1. | 8 → 7 |  |
| ↳ golden | When played and when sold: Pass right +2/+2. | When played or sold: Pass right +2/+2. | 8 → 7 |  |
| Mr Redbreast | Has +1/+1 for each Nest you have. | *(unchanged)* | 7 → 7 |  |
| Mr Syllabub | When a unit comes out of one of your Oozes, its Start of Combat text fires. | When a unit comes out of your Oozes, its Start of Combat fires. | 16 → 13 |  |
| ↳ golden | When a unit comes out of one of your Oozes, its Start of Combat text fires 2 times. | When a unit comes out of your Oozes, its Start of Combat fires twice. | 18 → 14 |  |
| Mrs Burdock, Expecting Again | On play: summon a 1/1 Kit behind this. Spill. | When played: summon a 1/1 Kit behind this. Spill. | 9 → 9 |  |
| ↳ golden | On play: summon two 1/1 Kits behind this. Spill. | When played: summon two 1/1 Kits behind this. Spill. | 9 → 9 |  |
| Mrs Dunnock | End of Turn: if this stands on a Nest, that Bird comes home a turn sooner, next turn at the soonest. | End of Turn: if this is on a Nest, its Bird comes home a turn sooner. | 21 → 16 | Never sooner than next turn. |
| ↳ golden | End of Turn: if this stands on a Nest, that Bird comes home two turns sooner, next turn at the soonest. | End of Turn: if this is on a Nest, its Bird comes home two turns sooner. | 21 → 16 |  |
| Mrs Jay | Fly South. When sold: get an Acorn. | *(unchanged)* | 7 → 7 |  |
| Mrs Posset | Belly 1. When this dies, deal 3 damage to the enemy across. | *(unchanged)* | 12 → 12 |  |
| Mrs Sorrel, Harassed | After this attacks, summon a 1/1 Shrewlet behind this. Spill. | After this attacks: summon a 1/1 Shrewlet behind this. Spill. | 10 → 10 |  |
| ↳ golden | After this attacks, summon two 1/1 Shrewlets behind this. Spill. | After this attacks: summon two 1/1 Shrewlets behind this. Spill. | 10 → 10 |  |
| Mrs Stork | After you spend 6 gold: the Bird away longest that has missed a fight comes home. | After you spend 6 gold: a Bird away comes home. | 16 → 10 | The one away longest first. A Bird must have missed a fight. |
| ↳ golden | After you spend 6 gold: the two Birds away longest that have missed a fight come home. | After you spend 6 gold: two Birds away come home. | 17 → 10 |  |
| Mudwallow Toad | Pin. | *(unchanged)* | 1 → 1 |  |
| Nan Toadstool | When played: Ring this slot +1/+1. | *(unchanged)* | 6 → 6 |  |
| The Natterjack Chorus | Your units beside this have Mire and Bitter 1. | *(unchanged)* | 9 → 9 |  |
| Old Brock | At the bell, your units next to this with no quarry take the enemy across from this as quarry and can reach it anywhere. Units next to this have Pounce and +1 Attack. | Units next to this have Pounce, +1 Attack, and the enemy across from this as quarry, wherever it stands. | 33 → 19 | A unit that already has a quarry keeps it. |
| ↳ golden | At the bell, your units next to this with no quarry take the enemy across from this as quarry and can reach it anywhere. Units next to this have Pounce and +2 Attack. | Units next to this have Pounce, +2 Attack, and the enemy across from this as quarry, wherever it stands. | 33 → 19 |  |
| Old Lutra | Quarry, reaching it wherever it stands. Take: if it was in their back row, get 1 gold next turn. | Quarry, reaching it anywhere. Back-row Take: get 1 gold next turn. | 19 → 11 |  |
| ↳ golden | Quarry, reaching it wherever it stands. Take: if it was in their back row, get 2 gold next turn. | Quarry, reaching it anywhere. Back-row Take: get 2 gold next turn. | 19 → 11 |  |
| Old Moth Annis | End of Turn: give the units behind this +1 Attack. | *(unchanged)* | 10 → 10 |  |
| Old Mother Mast | After your first unit buy each turn: get an Acorn, or 2 if you hold a Hoard. | After your first unit buy each turn: get an Acorn, or 2 with a Great Hoard. | 17 → 16 |  |
| ↳ golden | After your first unit buy each turn: get 2 Acorns, or 4 if you hold a Hoard. | After your first unit buy each turn: get 2 Acorns, or 4 with a Great Hoard. | 17 → 16 |  |
| Old Tern | Fly South, for 3 turns. When this comes home: Discover a unit of your tier. | *(unchanged)* | 15 → 15 |  |
| ↳ golden | Fly South, for 3 turns. When this comes home: Discover two units of your tier, one after the other. | Fly South, for 3 turns. When this comes home: Discover two units of your tier. | 19 → 15 |  |
| One Swallow | Fly South. When played next to a Bird: gain 1 gold. | *(unchanged)* | 11 → 11 |  |
| The Peat Cutter | After a Mired enemy faints, get 1 gold next turn. Once a fight. | *(unchanged)* | 13 → 13 |  |
| The Peat King | Mire. Twice a fight, after a Mired enemy faints, summon a 4/4 Peatling with Bitter 2 in your empty slot nearest this. | Mire. After a Mired enemy faints, summon a 4/4 Peatling with Bitter 2. Twice a fight. | 22 → 16 | The Peatling appears in your empty slot nearest this. |
| ↳ golden | Mire. Twice a fight, after a Mired enemy faints, summon an 8/8 Peatling with Bitter 4 in your empty slot nearest this. | Mire. After a Mired enemy faints, summon an 8/8 Peatling with Bitter 4. Twice a fight. | 22 → 16 |  |
| Peatling | Bitter 2. | *(unchanged)* | 2 → 2 |  |
| Pennywort Snail | Sells for 1 more gold per turn it ended on your board, up to 3 turns. | Sells for 1 more gold per turn on your board, up to 3 turns. | 16 → 14 |  |
| ↳ golden | Sells for 2 more gold per turn it ended on your board, up to 3 turns. | Sells for 2 more gold per turn on your board, up to 3 turns. | 16 → 14 |  |
| Pill Bug | Whenever this is attacked, the units behind it gain +1 Attack this combat. | Whenever this is attacked: give the units behind it +1 Attack. | 13 → 11 |  |
| ↳ golden | Whenever this is attacked, the units behind it gain +2 Attack this combat. | Whenever this is attacked: give the units behind it +2 Attack. | 13 → 11 |  |
| Pipistrelle Echo | Spells you aim at this also hit the units beside it. Repeats spend no gold, so Last Orders repeats give no stats. | Spells you aim at this also hit the units beside it. | 22 → 11 | Repeats spend no gold, so Last Orders repeats give no stats. |
| ↳ golden | Spells you aim at this also hit the units beside it. Repeats spend no gold, so Last Orders repeats give no stats. | Spells you aim at this also hit the units beside it. | 22 → 11 |  |
| The Prima Donna | Mire, also on the enemy slots beside the one across. Bitter 3, once per enemy. | Mire, also beside the slot across. Bitter 3, once per enemy. | 15 → 11 |  |
| ↳ golden | Mire, also on the enemy slots beside the one across. Bitter 6, once per enemy. | Mire, also beside the slot across. Bitter 6, once per enemy. | 15 → 11 |  |
| The Prince Restored | Mire. Your first spell each turn costs 1 less. | *(unchanged)* | 9 → 9 |  |
| Queen of Elfland | Every 3rd End of Turn: destroy the units behind this (or this, if none). Split their printed Attack and Health, plus permanent buffs, evenly among your other Fairies. | Every 3rd End of Turn: destroy the units behind this (or this, if none). Split their stats among your other Fairies. | 28 → 21 |  |
| ↳ golden | Every 3rd End of Turn: destroy the units behind this (or this, if none). Double their printed stats and permanent buffs, then split that Attack and Health evenly among your other Fairies. | Every 3rd End of Turn: destroy the units behind this (or this, if none). Split double their stats among your other Fairies. | 32 → 22 |  |
| Rainbow Chaser | Rainbow. Has +1/+1 per band. When sold: gain 1 gold per band, 5 more for all seven, then wash them. | Rainbow. Has +1/+1 per band. When sold: wash the bands for 1 gold each, 5 more for all seven. | 20 → 19 |  |
| ↳ golden | Rainbow. Has +2/+2 per band. When sold: gain 2 gold per band, 10 more for all seven, then wash them. | Rainbow. Has +2/+2 per band. When sold: wash the bands for 2 gold each, 10 more for all seven. | 20 → 19 |  |
| Reel-Mistress | After a unit on a Ring attacks, that Ring dances to your next unit. Each Ring dances once a fight. | After a unit on a Ring attacks, its Ring dances to your next unit. Each Ring dances once a fight. | 20 → 20 |  |
| ↳ golden | After a unit on a Ring attacks, that Ring dances to your next unit and gains +1/+1. Each Ring dances once a fight. | After a unit on a Ring attacks, its Ring dances to your next unit and gains +1/+1. Each Ring dances once a fight. | 23 → 23 |  |
| Sable | Quarry. Start of Combat: if its quarry has more Attack than this, gain +3 Attack this fight. | Quarry. Start of Combat: if its quarry has more Attack, gain +3 Attack. | 17 → 13 |  |
| ↳ golden | Quarry. Start of Combat: if its quarry has more Attack than this, gain +6 Attack this fight. | Quarry. Start of Combat: if its quarry has more Attack, gain +6 Attack. | 17 → 13 |  |
| Sally Spore | End of Turn: Ring your empty slot nearest this +1/+1. | *(unchanged)* | 10 → 10 |  |
| Sergeant-at-Conkers | Start of Combat: throw your smallest Acorn item at the enemy across: 3 damage per gold it's worth. | Start of Combat: throw your smallest Acorn at the enemy across for 3 damage per gold. | 18 → 16 | The Acorn is spent. With no enemy across, it stays in hand. |
| ↳ golden | Start of Combat: throw your smallest Acorn item at the enemy across: 6 damage per gold it's worth. | Start of Combat: throw your smallest Acorn at the enemy across for 6 damage per gold. | 18 → 16 |  |
| Sett Warden | Hunker. Whenever this survives being attacked, the units behind this gain +1 Attack this combat. | Hunker. After this survives an attack: the units behind this gain +1 Attack. | 15 → 13 |  |
| ↳ golden | Hunker. Whenever this survives being attacked, the units behind this gain +2 Attack this combat. | Hunker. After this survives an attack: the units behind this gain +2 Attack. | 15 → 13 |  |
| The Seven Whistlers | Start of Combat: each enemy across from one of your Birds or Eggs loses 1 Attack and 1 Health this combat. | Start of Combat: give each enemy across from your Birds and Eggs -1/-1. | 21 → 13 |  |
| ↳ golden | Start of Combat: each enemy across from one of your Birds or Eggs loses 2 Attack and 2 Health this combat. | Start of Combat: give each enemy across from your Birds and Eggs -2/-2. | 21 → 13 |  |
| Sexton Beetle | After a friendly unit dies, gain 1 gold next turn, twice a fight. | After a friendly unit dies: gain 1 gold next turn. Twice a fight. | 13 → 13 |  |
| ↳ golden | After a friendly unit dies, gain 2 gold next turn, twice a fight. | After a friendly unit dies: gain 2 gold next turn. Twice a fight. | 13 → 13 |  |
| The Sixpenny Pie | Belly 3. If 2 or more come out when this dies, get 1 gold next turn, 3 times in all. | Belly 3. When this dies, if 2+ come out, get 1 gold next turn. Three times in all. | 20 → 18 |  |
| ↳ golden | Belly 6. If 2 or more come out when this dies, get 2 gold next turn, 3 times in all. | Belly 6. When this dies, if 2+ come out, get 2 gold next turn. Three times in all. | 20 → 18 |  |
| The Sleeping Partner | Every 3 turns in this slot: get 2 Acorns, 3 times in all. A move restarts the wait, not the count. | Every 3 turns in this slot: get 2 Acorns. Three times in all. | 21 → 13 | Moving it restarts the wait, not the count. |
| ↳ golden | Every 3 turns in this slot: get 4 Acorns, 3 times in all. A move restarts the wait, not the count. | Every 3 turns in this slot: get 4 Acorns. Three times in all. | 21 → 13 |  |
| Spitfire Sal | Start of Combat: deal 2 damage to each Mired enemy. | *(unchanged)* | 10 → 10 |  |
| The Standing Committee | Start of Combat: touching units get +2 Attack. If all 7 touch, +3. | Start of Combat: give touching units +2 Attack, or +3 if all 7 touch. | 13 → 14 |  |
| ↳ golden | Start of Combat: touching units get +4 Attack. If all 7 touch, +6. | Start of Combat: give touching units +4 Attack, or +6 if all 7 touch. | 13 → 14 |  |
| Still-Water Heron | Fast (refresh, 2). Feast: gain +2/+2 permanently. | *(unchanged)* | 7 → 7 |  |
| Stone Soup | Belly 1. After you buy a unit into any Belly, units in your shop gain +1/+1. A refresh or the end of the turn washes it out, unless you bought them. | Belly 1. After you buy into any Belly, your shop's units gain +1/+1 this turn. | 31 → 15 | Units you buy keep it. A refresh washes it out. |
| ↳ golden | Belly 2. After you buy a unit into any Belly, units in your shop gain +2/+2. A refresh or the end of the turn washes it out, unless you bought them. | Belly 2. After you buy into any Belly, your shop's units gain +2/+2 this turn. | 31 → 15 |  |
| Tiddy Mun | After a Mired enemy faints, its maker gains +1/+1 permanently (this, if the maker is gone). Twice a fight. | After a Mired enemy faints, its maker gains +1/+1 permanently. Twice a fight. | 19 → 13 | If the maker is gone, this gains it instead. |
| ↳ golden | After a Mired enemy faints, its maker gains +2/+2 permanently (this, if the maker is gone). Twice a fight. | After a Mired enemy faints, its maker gains +2/+2 permanently. Twice a fight. | 19 → 13 |  |
| The Toll-Bard | Quarry. After its quarry attacks, get 1 gold next turn, up to 3 gold a fight. | Quarry. After its quarry attacks: get 1 gold next turn, up to 3 a fight. | 16 → 15 |  |
| ↳ golden | Quarry. After its quarry attacks, get 2 gold next turn, up to 3 gold a fight. | Quarry. After its quarry attacks: get 2 gold next turn, up to 3 a fight. | 16 → 15 |  |
| Tom Tit | Swoop. After this kills a unit: get 1 gold next turn, once a fight. | Swoop. After this kills a unit: get 1 gold next turn. Once a fight. | 14 → 14 |  |
| ↳ golden | Swoop. After this kills a unit: get 2 gold next turn, once a fight. | Swoop. After this kills a unit: get 2 gold next turn. Once a fight. | 14 → 14 |  |
| Turnip Scarecrow | The enemy across from this skips its first attack. | *(unchanged)* | 9 → 9 |  |
| Vaulting Hopkin | Snap. In your back row, this attacks before your front row, with +2 Attack. | Snap. In your back row, this attacks first, with +2 Attack. | 14 → 11 |  |
| ↳ golden | Snap. In your back row, this attacks before your front row, with +4 Attack. | Snap. In your back row, this attacks first, with +4 Attack. | 14 → 11 |  |
| Warty Nan | Bitter 1. Your units beside this have Bitter 1. | *(unchanged)* | 9 → 9 |  |
| Weasel Second | Start of Combat: the units in front of this gain First Bite for this combat. | Start of Combat: give the units in front of this First Bite. | 15 → 12 |  |
| ↳ golden | Start of Combat: the units in front of this gain First Bite for this combat. | Start of Combat: give the units in front of this First Bite. | 15 → 12 |  |
| Wee Wobbly | Belly 1. After this survives a hit, the unit inside comes out in the nearest gap; with nobody inside, summon a Drip. Twice a fight. | Belly 1. After this survives a hit, the unit inside comes out (or a Drip). Twice a fight. | 25 → 18 |  |
| ↳ golden | Belly 2. After this survives a hit, a unit inside comes out in the nearest gap; with nobody inside, summon a golden Drip. Twice a fight. | Belly 2. After this survives a hit, a unit inside comes out (or a golden Drip). Twice a fight. | 26 → 19 |  |
| Whirligig Beetle | Start of Combat: the enemy's rows swap places. Each enemy moved takes 2 damage. | Start of Combat: swap the enemy's rows. Each enemy moved takes 2 damage. | 14 → 13 |  |
| ↳ golden | Start of Combat: the enemy's rows swap places. Each enemy moved takes 4 damage. | Start of Combat: swap the enemy's rows. Each enemy moved takes 4 damage. | 14 → 13 |  |
| Wick | Pack. After this joins an attack, it gains +1 Attack this fight. | Pack. After this joins an attack: gain +1 Attack. | 12 → 9 |  |
| ↳ golden | Pack. After this joins an attack, it gains +2 Attack this fight. | Pack. After this joins an attack: gain +2 Attack. | 12 → 9 |  |
| Will-o'-the-Wisp | Start of Combat: summon a 1/1 Wisp into each of your empty Rings. | Start of Combat: summon a 1/1 Wisp into each empty Ring. | 13 → 11 |  |
| ↳ golden | Start of Combat: summon a 2/2 Wisp into each of your empty Rings. | Start of Combat: summon a 2/2 Wisp into each empty Ring. | 13 → 11 |  |
| Worker Bee | Swarm. | *(unchanged)* | 1 → 1 |  |
| Young Brock | At the bell, your units beside this with no quarry take the enemy across from this as quarry and gain +1 Attack this fight. | Start of Combat: units beside this take the enemy across from this as quarry, with +1 Attack. | 24 → 17 | A unit that already has a quarry keeps it, without the Attack. |
| ↳ golden | At the bell, your units beside this with no quarry take the enemy across from this as quarry and gain +2 Attack this fight. | Start of Combat: units beside this take the enemy across from this as quarry, with +2 Attack. | 24 → 17 |  |
| Young Pretender | Snap. After this kills a Mired enemy, get 1 gold next turn. | *(unchanged)* | 12 → 12 |  |

### Spells

| Card | Before | After | Words | Off the card (details) |
|---|---|---|---|---|
| A Leg Up | Your next tavern upgrade costs 2 less. | Your next upgrade costs 2 less. | 7 → 6 |  |
| Acorn | Play for 1 gold. Three Acorns combine into a Stash. | Play for 1 gold. Three combine into a Stash. | 10 → 9 |  |
| Beltane Bonfire | Spend all your gold. Give a unit's row +1/+1 for every 4 spent. | *(unchanged)* | 13 → 13 |  |
| Boundary Stone | Ring a slot +3/+3. | *(unchanged)* | 4 → 4 |  |
| Bread from the Back | Aim at a back-row unit: the units in front of it gain +1/+1 permanently, or +2/+2 if they share its tribe. | Give the units in front of a back-row unit +1/+1, or +2/+2 if they share its tribe. | 21 → 17 |  |
| Cold Frame | After 2 turns in its slot, a unit gains +3/+3. | *(unchanged)* | 10 → 10 |  |
| Elderflower Cordial | Give a unit +1/+2 in the front row, or +2/+1 in the back row. | *(unchanged)* | 14 → 14 |  |
| Great Hoard | Play for 16 gold. | *(unchanged)* | 4 → 4 |  |
| Harvest Supper | Aim at a unit with a tribe: your units of that tribe gain +1/+1 permanently, including ones you get later. Once a turn. Tribe bonus: up to +3/+3; not on units summoned in fights. | Pick a unit. Your units of its tribe gain +1/+1, even ones you get later, up to +3/+3. Once a turn. | 34 → 21 | Units summoned in fights don't get it. |
| Hiring Fair | Discover a tier 6 unit. If 5 or more units on your board share a tribe, one of the three is of that tribe. | Discover a tier 6 unit. If 5 of your units share a tribe, one option is that tribe. | 24 → 18 |  |
| Hungry Gap | Gain 2 gold. Next turn, your shop has one fewer unit. | *(unchanged)* | 11 → 11 |  |
| Last Orders | Spend all your gold. Give a unit +1/+1 for every 2 spent. | *(unchanged)* | 12 → 12 |  |
| Market Day | This turn, units in your shop cost 2. | *(unchanged)* | 8 → 8 |  |
| Pinch of Dust | Give a unit +1/+1. | *(unchanged)* | 4 → 4 |  |
| Rainy Day | Next turn, gain 1 gold, or 3 if you lose your next fight. | *(unchanged)* | 13 → 13 |  |
| Sample Acorn | SAMPLE. Give a unit +1/+1. Hold it and it does nothing; play it onto a unit. | SAMPLE. Give a unit +1/+1. | 16 → 5 |  |
| Sample Find | SAMPLE. Discover a unit of your tier or lower. | *(unchanged)* | 9 → 9 |  |
| Sample Growth | SAMPLE. Give a unit +2/+2. | *(unchanged)* | 5 → 5 |  |
| Sample Windfall | SAMPLE. Gain 2 gold next turn. | *(unchanged)* | 6 → 6 |  |
| Shake the Tree | Refresh the shop, but keep one card you choose. | Refresh the shop, but keep one card. | 9 → 7 |  |
| Spore Cloud | Ring a slot +2/+2. | *(unchanged)* | 4 → 4 |  |
| Squirrel Away | Get 2 Acorns. | *(unchanged)* | 3 → 3 |  |
| Stand Behind Me | Aim at a front-row unit: the units behind it gain +1/+1 permanently, or +2/+2 if they share its tribe. | Give the units behind a front-row unit +1/+1, or +2/+2 if they share its tribe. | 19 → 15 |  |
| Stash | Play for 5 gold. Three Stashes combine into a Great Hoard. | Play for 5 gold. Three combine into a Great Hoard. | 11 → 10 |  |
| Triple Reward | Discover a unit from the tier above yours (tier 6 if you're at 6). | Discover a unit from the tier above yours. | 14 → 8 | At tier 6, it's a tier 6 unit. |

### Heroes

| Card | Before | After | Words | Off the card (details) |
|---|---|---|---|---|
| Brother Bracken | Start of Combat: each unit gains +1/+1 per empty slot next to it. | Start of Combat: your units gain +1/+1 for each empty slot beside them. | 13 → 13 |  |
| Dame Farthing | Start of turn: gain 1 gold per 4 you carried over, up to 5. | Start of Turn: gain 1 gold for every 4 you carried over. | 14 → 12 | Up to 5 gold a turn. |
| Dame Hoolet | Your back row attacks before your front row. | *(unchanged)* | 8 → 8 |  |
| Hob Mumblecrust | Power (free, once a turn): borrow 3 gold. Next turn, repay it and lose 1 Health. Each gold you can't repay costs 1 Health more. | Power: borrow 3 gold. Next turn, repay it and lose 1 Health. | 25 → 12 | Each gold you can't repay costs 1 more Health. |
| Jill Down-the-Tree | Power (free, once a turn): drop one tavern tier and gain 2 gold. Climbing back costs only 2. | Power: drop a tavern tier and gain 2 gold. Climbing back costs only 2. | 18 → 14 |  |
| Little King Wren | Start of Combat: your lowest-Attack unit uses the highest enemy Attack for its first attack. | *(unchanged)* | 15 → 15 |  |
| The March Hare | Your upgrades cost 4 more and climb two tiers. | *(unchanged)* | 9 → 9 |  |
| Old Mother Mousewife | After a front-row unit dies, summon a Mouse behind it, with stats equal to your tier. | *(unchanged)* | 16 → 16 |  |
| Pipkin | Your shop has 2 more cards, but you may buy only 2 units a turn. | *(unchanged)* | 15 → 15 |  |
| Sample Hoarder | SAMPLE. Passive: at the start of every other turn, get a Sample Acorn. | SAMPLE. Every other turn, get a Sample Acorn. | 13 → 8 |  |
| Sample Painter | SAMPLE. Power (2 gold, once a turn): paint a slot. Whatever stands in it has +1/+1 for the rest of the game. | SAMPLE. Power: paint a slot. Whatever stands there has +1/+1. | 22 → 10 | Costs 2 gold. The paint lasts the rest of the game. |
| Sample Thrifty | SAMPLE. Passive: your first Refresh each turn costs 0. Upgrades cost 1 more. | SAMPLE. Your first Refresh each turn is free. Upgrades cost 1 more. | 13 → 12 |  |
