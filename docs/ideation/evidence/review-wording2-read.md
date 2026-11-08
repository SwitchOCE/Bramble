# Wording pass 2: a fresh read as a player

Reviewer: cloud Claude, 8 Nov 2026. Branch read: `ideation/c-wording2`. I changed no code or content. I didn't open the branch's wording guide, evidence or study files, so this is how the text reads cold.

**Verdict: mostly.** The owner would see a large improvement. Card text now averages 12 words (median 12, longest 26). Only 9 of the 142 cards with text run past 18 words. Keyword reminders are one line each. The reminder slip is italic, smaller and boxed, and it opens on hover or tap, as the owner asked. About 15 cards are still dense multi-clause sentences, though, and the vocabulary drifts: three words mean "base stats", "band" means two things, and "gain" and "get" are both used for gold. The owner will still trip over those cards.

## What I ran

- **Two full games** with `tools/play/` (seed 11 as Little King Wren, seed 23 as Little King Wren), run by a simple scripted policy that logged every screen. Both games ended in 8th place, because the policy plays badly. Across them I read the 62 unit and spell texts the shops offered, a Discover (tier 6: Whirligig Beetle, Granny Stir-Up, Queen of Elfland), two hero choices and every keyword and details line the screen printed.
- **Renders at 1920x1080 and 1688x780**: `recruit`, `recruit_select` (details panel), `reminder` (details panel with the Acorn reminder open), `discover` and `combat_mid` / `combat_reminder` (a fight with the Ring and Quarry reminders open). All 12 rendered without errors.
- **Read every text** in `content/units` (144 files), `content/spells` (25), `content/heroes` (12), every keyword in `content/schema/effects.json` and `src/ui/keyword_rules.gd`, and every `details` note.

## What works

- Most commons now read at Battlegrounds length: "Pinch of Dust: Give a unit +1/+1." "Ichneumon Wasp: An enemy this damages dies after its next attack." "Turnip Scarecrow: The enemy across from this skips its first attack." "Hazel Dormouse: Skips its attacks, gaining +1/+1 each time, until it's hurt."
- Keywords carry the weight: Mire / Snap / Bitter, Quarry / Take / Pounce, Belly, Fly South / Nest. The reminders are short and concrete. The best are Nightshade ("When attacked, this first loses half its Health."), Mire, Quarry and Fly South.
- Edge cases have moved into **Details** (for example "Mrs Dunnock: Never sooner than next turn." and "Hasty Pudding: It goes back when..."). That is exactly the owner's "let it be implied, find it in additional details".
- The reminder slip looks distinct on both sizes: italic, smaller and boxed under the rules text. In fights, the keyword panel under the log works well.

## The 15 that still read worst

Each rewrite keeps the effect. Golden versions follow the same pattern.

| # | Card | Now | Rewrite | Why |
|---|---|---|---|---|
| 1 | Dishwater Nell (T2) | Start of Turn: swap your shop's lowest-tier unit for one of your tier. If that's 2+ tiers up and this touches an Ooze, gain 1 gold. | Start of Turn: upgrade your shop's lowest unit to your tier. If it rose 2+ tiers and this touches an Ooze, gain 1 gold. | The longest card (26 words) and a 2-tier common. Two conditions on a bonus is one too many: think about cutting the Ooze clause in design. |
| 2 | Rainbow Chaser (T1) | Rainbow. Has +1/+1 per band. When sold: wash the bands for 1 gold each, 5 more for all seven. | Rainbow. +1/+1 per band. When sold: clear your bands; gain 1 gold each (+5 for all 7). | "Wash" isn't defined. "Band" is never defined anywhere (see inconsistencies). |
| 3 | Jack Daw (T3) | Fly South. Start of Combat: steal a quarter of the enemy across's buffs. If you took any, get 1 gold next turn. | Fly South. Start of Combat: steal ¼ of the buffs on the enemy across. If you do, get 1 gold next turn. | "across's" is ugly. "If you took any" can just be "if you do". |
| 4 | Queen of Elfland (T6) | Every 3rd End of Turn: destroy the units behind this (or this, if none). Split their stats among your other Fairies. | Every 3 turns: destroy the units behind this and share their stats among your other Fairies. None? Destroy this. | The parenthetical sits in the middle of the main action. |
| 5 | Old Brock (T4) | Units next to this have Pounce, +1 Attack, and the enemy across from this as quarry, wherever it stands. | Units next to this have +1 Attack, Pounce and this unit's quarry. | "wherever it stands" is implied. Sharing a quarry says the rest. |
| 6 | Young Brock (T1) | Start of Combat: units beside this get the enemy across from this as quarry, with +1 Attack. | Start of Combat: units beside this share its quarry and gain +1 Attack. | The same idea as Brock, worded twice in two different ways. |
| 7 | Figgy Duff (T6) | Belly 1. Once a turn: a bought unit inside this makes a golden with just one bought copy. | Belly 1. The unit inside goes golden with just 2 copies. Once a turn. | It took me three reads to understand the current wording. |
| 8 | Belladonna Sprite (T5, `belladonna`) | Start of Combat: give the enemy across Nightshade. In the back row, the 2 facing this instead. | Start of Combat: give Nightshade to the enemy across, or from the back row, to both enemies facing this. | "Facing" is used only here and isn't defined next to "across". This card also shares its name with the T6 card (blocker below). |
| 9 | Jenny Greenteeth (T4) | Mire. The enemy this Mires has -2 Attack. After it attacks this, your highest-Attack unit beside this attacks it. | Mire. Its Mired enemy has -2 Attack. After that enemy attacks this, your strongest unit beside this hits it. | Three "this" and two "it" in one sentence. |
| 10 | Prima Donna (T5) | Mire, also beside the slot across. Bitter 3, once per enemy. | Mires the enemy across and both beside it. Bitter 3 (once per enemy). | "Mire, also beside the slot across" is shorthand that doesn't parse. |
| 11 | Charcoal Burner (T4) | End of Turn: burn gold above 5, up to 6. Units behind this gain +1/+1 per 2 burned. | End of Turn: spend your gold above 5 (max 6). Units behind this gain +1/+1 per 2 spent. | "Burn" is a new verb, and "up to 6" reads as "up to 6 gold left". |
| 12 | Elder Ooze (T6) | Belly 1. When a unit comes out of your Oozes, it gains +1/+1 per unit out, up to +3/+3. | Belly 1. Units leaving your Oozes gain +1/+1 for each that has left this fight (max +3/+3). | "Per unit out" is opaque. Its Details note has to explain it. |
| 13 | Changeling (T4) | Start of Combat: swap with the enemy across until it attacks. | Start of Combat: this and the enemy across are Borrowed. | It's unclear who "it" is. The game already has the Borrowed keyword for exactly this. |
| 14 | Harvest Supper (spell) | Pick a unit. Your units of its tribe gain +1/+1, even ones you get later, up to +3/+3. Once a turn. | Choose a unit's tribe. That tribe gains +1/+1 for the rest of the game (max +3/+3). Once a turn. | "Even ones you get later" is how tribe bonuses always work, and the guide already says so. |
| 15 | Mistress Russet (T2) | Quarry. Take: if it's your tier or lower, your next shop has a copy, 1 gold cheaper. | Quarry. Take: your next shop has a copy of it, 1 gold cheaper (up to your tier). | "It" points to the quarry only by inference. Lead with the payoff and put the limit in brackets. |

Close runners-up: Beadle Warrenby (two keywords chained across fight and shop timing: "Your summons Spill. Each Spill: Pass right +1/+1. Twice a fight."), Tiddy Mun ("its maker" should be "the unit that Mired it"), Wee Wobbly ("(or a Drip)" names a token the player has never seen: "or a 1/1 Drip if empty"), Reel-Mistress ("dances to your next unit": next in what order?), Brother Wolf ("Won't lead while a unit beside it can"), Alderman Dozey (two separate mechanics on one T3 card), Bridge Toad ("top-Attack enemy" should be "the enemy with the most Attack"), Mrs Stork ("After you spend 6 gold": each 6? once a turn?), The Toll-Bard golden ("2 gold, up to 3 a fight": 3 gold or 3 times?) and Jill Down-the-Tree ("tavern tier" is the only "tavern" in the game; "Climbing back costs only 2" doesn't say for how long).

## Confusing, inconsistent or still over-explained

**Inconsistent words**
- **Base stats has three names**: "printed copy" (Cradle Fetch, Great Lump), "card Attack" (Mother Goose) and "plain copy" (Cut-and-Come-Again). Pick one. Battlegrounds and Snap say "base".
- **"Band" means two things.** The guide's first line is "Build a band" (your board), and the Rainbow cards use "bands" for painted slots. The Rainbow reminder never uses the word "band", so Cluricaun's "Your units on bands" can't be decoded without guessing. Rename the painted slots ("stripes"?) or say "on a Rainbow slot".
- **Gold is gained or got at random**: "gain 1 gold next turn" (Cricket Busker, Sexton Beetle) against "get 1 gold next turn" (Little Nip, Tom Tit, Peat Cutter). Pick one verb for gold and one for cards ("get an Acorn").
- **"Facing" against "across"**: only Belladonna uses "facing".
- **Upgrading has four words**: "upgrade" (spells, Ermeline, March Hare), "Tier up" (button), "tavern tier" and "climbing back" (Jill).
- **Trigger punctuation varies**: "When this dies: summon" (Earwig), "When this dies, deal" (Posset) and "When this dies, summon" (Hoglet Mother). Settle on "Trigger: effect", as the Start of Combat cards already do.
- **On-card tags don't match the text**: the tags say "Fight start" and "Turn start", while the rules say "Start of Combat" and "Start of Turn". A new player sees two names for one thing on the same card.
- **Two pool cards are both named "Belladonna Sprite"** (`belladonna`, T5 4/8, and `belladonna_sprite`, T6 4/5), with different text.

**Under-explained (the reverse problem)**
- "Peck 2": the reminder ("split across several strikes") doesn't say what the 2 is.
- "Both Ends": "Partners at both ends of a row grow and guard each other" doesn't tell me what the card does. Only the golden text "(+2/+4, pricks for 4)" hints at it.
- "Ring this slot +1/+1" (Nan Toadstool, Sally Spore and the Ring spells) uses Ring as a verb. The reminder "The unit on this slot gets this bonus" reads fine once you know that, but say it the way the card does: "Ring a slot +X/+X: whatever stands there has +X/+X."
- "Eats Acorns" (Alderman Dozey) isn't a keyword, and the Acorn reminder doesn't mention eating.
- "Pass right +1/+1" in a fight (Beadle, Dr Urchin) while the Pass reminder says "At End of Turn": the timing is unclear.

**Still over-explained**
- The golden text repeats keyword reminders: "Shy (4 gold)" when Shy's reminder already says "4 if golden", and "Bystander (+2/+2)".
- **"Next income: +10 gold." is appended inside the rules text** of cards that mention gold (I saw it on Sergeant-at-Conkers, PC and phone). It reads as part of the card's effect. Show it beside the gold counter only.
- Screen chrome is still wordy or full of jargon: the End turn button reads "Toll: up to 1; hit cap 9", and the play screen's Last Stand line runs 25 words ("Once a game, a lethal loss to another hero from 2+ Health leaves 1. Ghosts never use it.").
- Combat log: "The Toll-Bard (F1)'s ability goes off" says nothing. Name the effect ("The Toll-Bard: +1 gold next turn").

## Render notes

- PC details panel (`reminder_1920x1080`): the reminder slip covers the "Details" link, so only a sliver of it shows under the Acorn slip.
- The Discover render (`discover`) is a fixture with retired cards (Scurry, Lesser Spotted, Bog Lantern). Its "reminder" for Scurry just repeats "Scurry.", so it doesn't show what a real Discover looks like. The live Discover I met in play (tier 6) read fine.
- Phone shop cards show a tag instead of the text (good). On PC, the full text fits on 3 lines for every card I saw.

## Blocks a playtest?

Nothing stops a game from being played. Two things would confuse the owner on sight and are cheap to fix first:

1. The two pool cards named "Belladonna Sprite".
2. "Next income: +N gold." showing inside card rules text.

The undefined "band" (Rainbow Chaser and Cluricaun are T1 and T3 commons) is next.
