# Wording study: concise text in ten big games

Research only. No game code or content is changed here. Scope is the owner's note of 8 Nov 2026, `docs/design/owner-notes/2026-11-08e-text-too-wordy.md`, all four sections. The last section asks for this study: "If we have a good sample set from a bunch of different games and look at how they do concise wording well, so we can learn from how they do it, that's our goal. Our goal is to get excellent concise wording, not to copy anyone's style."

Base: `origin/ideation/main` at `e383234`. Compared against `docs/ideation/wording-guide.md` on `origin/ideation/c-wording` at `659187d`.

## How the quotes were checked

This session could search the web but could not open pages: wiki and publisher hosts were outside the network allowlist. Each quote is marked:

- **[D]** taken from the repo's card data (`docs/research/battlegrounds/data/minions.csv`, HearthstoneJSON build 37.0.0; `docs/research/galaxy/data/cards.json`).
- **[S]** confirmed in web search results this session.
- **[M]** from memory and believed exact, but not checked this session. Wording may differ by printing or patch.

Sources searched: mtg.wiki (Reminder text, Ward), the MTG Bloomburrow "enters" templating change, hearthstone.wiki.gg and outof.games (keywords), Riot's LoR "Keywords and Game Vocab" support page, snap.fan and Marvel Snap databases, slaythespire.wiki.gg (Bash, Vulnerable), the Dominion Strategy wiki (Village, Militia), Wingspan's rulebook and appendix listings, the Pokémon TCG Advanced Manual, TFT trait cheat sheets, and the Twilight Imperium 4 Rules Reference.

## Measured baseline

| Set | Current cards | Median chars | p90 | Max |
|---|---|---|---|---|
| Battlegrounds minions [D] | 303 | 64 | 91 | 117 |
| Galaxy cards [D] | 698 rows | 60 | — | 156 |
| Bramble, the 12 texts in Part 3 | 12 | 180 | 204 | 264 |

Bramble's twelve wordiest texts all run longer than Battlegrounds' longest current minion.

---

## Part 1: the games

### 1. Magic: The Gathering (Wizards of the Coast)

Texts:
- Lightning Bolt: "Lightning Bolt deals 3 damage to any target." [M]
- Llanowar Elves: "{T}: Add {G}." [M]
- Serra Angel: "Flying, vigilance" [M]
- Ward reminder: "Ward {2} *(Whenever this creature becomes the target of a spell or ability an opponent controls, counter it unless that player pays {2}.)*" [S]
- Bloomburrow onward: "When this creature enters, …" replaces "enters the battlefield" [S].

Keywords and reminder text:
- Reminder text is italic and in parentheses, on the card itself, right after the keyword. It "has no effect on play" [S]: it is a summary, and the Comprehensive Rules govern.
- It is printed where players need it, such as on commons, on new mechanics and in starter products. It is dropped where they don't: evergreen keywords on rares and in experienced sets ("Flying, vigilance" stands alone). Rosewater polled players in 2024–25 on putting reminder text back on alternate-art cards [S], which shows how deliberate the choice is.
- Keywords stack on one line with commas.

Templating habits:
- One fixed phrase per concept, enforced across thousands of cards: "any target", "enters", "this creature".
- When a stock phrase can lose words, the whole game changes at once: "enters the battlefield" became "enters" [S], and card names in rules text became "this creature" [S].
- Cost, then a colon, then the effect.

What it leaves unsaid: timing, layers, ordering of simultaneous triggers and replacement effects. All of it lives in the Comprehensive Rules. No card explains the stack.

### 2. Hearthstone and Battlegrounds (Blizzard)

Texts:
- Brann Bronzebeard: "Your Battlecries trigger twice." [D]
- Titus Rivendare: "Your Deathrattles trigger an extra time." [D]
- Cave Hydra: "Also damages the minions next to whomever this attacks." [D]
- Scallywag: "Deathrattle: Summon a 1/1 Pirate. It attacks immediately." [D]
- Leeroy the Reckless: "Deathrattle: Destroy the minion that killed this." [D]
- Reborn reminder: "Resurrects with 1 Health the first time it dies." [D]

Keywords and reminder text:
- Keywords are bold on the card.
- The definition is never on the card. Hover on PC, or press and hold on phone, shows a separate tooltip panel beside the card, one per keyword [S].
- Tooltips are one sentence. Taunt says enemies must attack this minion [S]. Divine Shield: "The first time a Shielded minion takes damage, ignore it." [S]
- Parameterised keywords carry their number: "Avenge (3)".

Templating habits:
- `Trigger: effect.` and nothing more.
- Durations are left out, because combat buffs end with combat by rule.
- Stat pairs are written as digits ("a 1/1").
- "this" for the card itself; "your" for your side.
- Baron Rivendare's "trigger twice" became Titus's "an extra time" [D], which settles how two copies stack without saying so.

What it leaves unsaid: the order in which effects resolve, what happens on a full board, tie-breaks, how Divine Shield interacts with Venomous, and Avenge's repeat behaviour. Players learn these by playing or from the wiki. Even the wiki marks some of them uncertain (see `keywords.md`).

### 3. Marvel Snap (Second Dinner)

Texts:
- Iron Man: "Ongoing: Your total Power is doubled at this location." [S]
- Medusa: "On Reveal: If this is at the middle location, +3 Power." [S]
- Mystique: "On Reveal: If the last card you played has an Ongoing, copy its text. (if able)" [S]
- Onslaught: "Ongoing: Your other Ongoing effects here apply an additional time." [S]
- Hulk: no text [M].

Keywords and reminder text:
- There are two keywords, On Reveal and Ongoing, and nearly every card uses one of them [S].
- Everything else is plain words.
- Tapping a card opens a large detail view with a short explanation. The card face carries the text only.

Templating habits:
- "here" stands for "at this location": one word for a whole spatial idea.
- "+3 Power" is used as an effect with no verb.
- A trailing "(if able)" handles failure in two words.

Where it slipped:
- Wong's "happen twice" versus Onslaught's "apply an additional time" confused players about stacking [S].
- Developers later corrected wording that implied an effect was on the card when it was really a property of the card type [S].
- Lesson: similar effects need identical wording.

What it leaves unsaid: resolution order, which it puts in a game-wide rule ("reveal order") instead of on cards.

### 4. Legends of Runeterra (Riot)

Texts:
- Elusive: "Can only be blocked by an Elusive unit." [S, paraphrase on Riot's page]
- Fearsome: "Can only be blocked by enemies with 3 or more Power." [S, paraphrase]
- Tough: "Takes 1 less damage from all sources." [M]
- Round Start: "Get this effect when the round starts." [S]
- Barrier: "Negates the next damage the unit would take. Lasts one round." [M]

Keywords and reminder text:
- Riot splits two classes [S]:
  - **Keywords** are persistent properties, shown as an icon plus a bold word above the text box.
  - **Vocab** are trigger words in bold inside the text: "Play:", "Strike:", "Last Breath:", "Round Start:".
- Hover on PC, or tap on phone, shows a definition panel beside the card, with icons.
- The definitions are one line.

Templating habits:
- The icon means a player can read a unit's keywords on the board without opening the card.
- Effects are "Strike: …" with the trigger first.

What it leaves unsaid: interaction order, such as Barrier before Tough, which is on Riot's support page and not in the tooltip [S]; and how Challenger and Elusive interact.

### 5. Pokémon TCG (The Pokémon Company)

Texts:
- "This attack does 20 damage to 1 of your opponent's Benched Pokémon. *(Don't apply Weakness and Resistance for Benched Pokémon.)*" [S]
- "Flip a coin. If heads, your opponent's Active Pokémon is now Paralyzed." [M]
- Pokémon ex rule box: "When your Pokémon ex is Knocked Out, your opponent takes 2 Prize cards." [M]
- Switch: "Switch your Active Pokémon with 1 of your Benched Pokémon." [M]

Keywords and reminder text:
- Reminder text is in parentheses and italic, inside the attack text, like Magic's.
- Special card classes get a separate **rule box**: a boxed, visually distinct strip at the bottom, apart from the effects.
- Conditions such as Paralyzed are defined in the rulebook, not on the card.

Templating habits:
- The damage number sits beside the attack name, so the text describes only the side effect.
- "1 of your" uses a digit, never "one".

What it leaves unsaid: order of operations. The Advanced Manual says "follow the attack text in sequence" and settles the rest [S], so no card spells out its order.

### 6. Teamfight Tactics (Riot)

Texts (format examples; the exact numbers change each set) [S]:
- A trait line: "(2) 18% DA, 20% gold (4) 20% DA, 30% gold (6) 22% DA".
- Bruiser: "(2) 125 Health (4) 225 (6) 450 (8) 800".
- A champion ability: "Deal 250/375/600 magic damage to the target."

Keywords and reminder text:
- Traits are icons with a count, such as "3/4".
- Hover shows the breakpoints, with the active one lit and the rest dimmed.
- Ability numbers are listed per star level, separated by slashes. The current star's number is highlighted.

Templating habits:
- Numbers and breakpoints, not sentences.
- The tooltip shows the live, computed value with the player's items and level included. The text never says "increased by Ability Power"; the number already includes it.

What it leaves unsaid: targeting, mana gain, and when abilities cast. They are learned by watching, which suits an auto-battler.

### 7. Slay the Spire (Mega Crit)

Texts:
- Strike: "Deal 6 damage." [M]
- Defend: "Gain 5 Block." [M]
- Bash: "Deal 8 damage. Apply 2 Vulnerable." [S; upgraded 10 and 3]
- Vulnerable tooltip: "Vulnerable creatures take 50% more damage from Attacks." [S]
- Exhaust: "Removed until end of combat." [M]

Keywords and reminder text:
- Keywords are coloured (gold) in the card text.
- Hover shows a stack of boxes beside the card, one per keyword.
- Nothing is in parentheses on the card.

Templating habits:
- Imperative verbs: Deal, Gain, Apply.
- Numbers on cards are live. They recolour green or red when Strength or Weak changes them, so the card never says "plus your Strength".

What it leaves unsaid: that Vulnerable affects only Attack damage, not poison or Thorns [S]; and that stacks extend duration rather than intensity [S]. Both are left to the wiki or to discovery.

### 8. Dominion (Rio Grande)

Texts:
- Village: "**+1 Card** **+2 Actions**" [S]
- Smithy: "**+3 Cards**" [M]
- Militia: "**+$2** Each other player discards down to 3 cards in hand." [S for the attack line, M for +$2]
- Moat: "**+2 Cards** — When another player plays an Attack card, you may first reveal this from your hand, to be unaffected by it." [M]

Keywords and reminder text:
- There is no reminder text.
- The fixed bonuses are bold, large and stacked at the top, so they read at a glance. Prose follows only for what can't be a bonus.
- A dividing line separates on-play text from text that works at other times (Moat).

Templating habits:
- A bonus is a symbol and a number, with no verb ("+1 Card").
- "Each other player" is a stock phrase.

What it leaves unsaid: every edge case. The rulebook's per-card **card explanations** section at the back holds them.

### 9. Wingspan (Stonemaier)

Texts:
- Mute Swan, paraphrased from search: choose 1–3 birds in your wetland, tuck a card from hand behind each, and if you did, draw 1 [S, paraphrase].
- Typical brown power: "**When activated:** Tuck 1 [card] from your hand behind this bird. If you do, draw 1 [card]." [M]
- "**When activated:** Gain 1 [seed] from the birdfeeder." [M]

Keywords and reminder text:
- Power timing is a coloured band with a fixed lead-in: brown "When activated", pink "Once between turns", white "When played".
- The colour carries the meaning even before the words are read.
- Nouns are icons: food, eggs, cards and habitats. Wingspan Pocket goes further and is mostly icons [S].

Templating habits:
- "If you do" ties a reward to a cost in three words.
- "1" is written as a digit.

What it leaves unsaid: everything per bird. A separate **Appendix** booklet gives each power's rulings [S].

### 10. Twilight Imperium 4: the big rulebook (Fantasy Flight)

What it does:
- Two documents [S]. **Learn to Play** is read first and teaches the common path. The **Rules Reference** is an alphabetical glossary with an index, consulted when questions come up.
- A precedence rule ends ambiguity: the Reference beats Learn to Play, and card text beats both [S].
- **Living** versions colour-code what changed [S].

Lesson: a reference that can be looked up lets the teaching text stay short. Precedence ("the card wins") lets the card stay short, because it doesn't have to restate a general rule it overrides.

---

## Part 2: rules for Bramble

Each rule names the games that show it.

1. **Card text has a hard budget.** Aim for 65 characters, with a ceiling of 120. *(BG median 64 and max 117 [D]; Galaxy median 60 [D].)* A card that won't fit after trimming is a design problem, not a wording problem: flag it to design.
2. **Trigger, colon, effect.** One timing word, from a closed list, starts the sentence. *(HS, Snap, LoR, StS, MTG cost-colon, Wingspan's banded lead-ins.)*
3. **One word per concept, everywhere.** If two phrases mean the same, pick one. If two concepts share a word, split them. *(MTG templating, Snap's Wong versus Onslaught, BG's Baron versus Titus.)* Bramble today mixes these:
   - "dies", "faints" and "destroy" for death;
   - "this fight" and "this combat";
   - "Start of your turn" and "Start of Turn";
   - "At the bell" and "Start of Combat";
   - "next to", "beside" and "touching" for three different spatial sets. In the engine, "next to" is `neighbours`, which is beside plus in front plus behind, and it has no help word.
4. **Durations by default; say only the exception.** A change made in combat ends with the fight (rulebook 12.1.2), so never print "this combat" or "this fight". Print "permanently" only when it lasts. *(HS/BG.)*
5. **A clause repeated on three or more cards becomes a keyword, but keywords have a budget too.**
   - Snap runs on two keywords, BG on about ten.
   - Bramble already has 24 schema keywords, 12 library words and 6 help words.
   - Every new keyword must save more reading than it costs to learn. *(Snap, BG, LoR.)*
6. **A reminder is one sentence of at most about 60 characters, and it defines the common case only.** *(HS Reborn 47 characters [D], StS Vulnerable, LoR Elusive, Dominion.)* Rulings, rounding, ties, caps and "even if both at once" go to the rulebook. *(MTG CR, TI4, Dominion's card explanations, Wingspan's appendix, Pokémon's Advanced Manual.)*
7. **Reminder text is a visibly different layer.** The owner asked for this directly: "italicized and made smaller and on hover".
   - On the card face: keyword in bold, no reminder. *(HS, LoR, StS, Snap.)*
   - On hover (PC) or long-press (phone): a separate panel beside the card, one box per keyword, italic and a size smaller than the rules text, muted colour. *(MTG's italic parenthetical for the look; HS, LoR and StS for the placement.)*
   - Today `card_detail.gd` appends reminders muted but not italic or smaller, as lines under the card text rather than in a separate panel.
8. **Show live numbers; don't print formulas.** If the game can compute the value, the card shows the number and the hover shows how it was reached. *(StS recolouring, TFT's per-star highlight.)* Example: Jack Daw's "a quarter of what the enemy across has gained" can show "+3/+2" in combat.
9. **Let the interface carry exceptions and how-to.**
   - The drag target teaches where a Belly takes units from.
   - The sell button can read "Fly" or "Sell", so Fly South needn't explain when a sale is final. *(Snap's tap-for-detail, HS's play affordances, StS's live numbers.)*
10. **Let capacity and failure imply themselves.**
    - "Belly 1" already says it's full after one; no "if this has room".
    - A summon with no room fails.
    - Snap writes "(if able)" only where a reader would really wonder. *(BG, Snap.)*
11. **Digits, stat pairs, "this", "your".** "+1/+1", "a 1/1", "2 gold", "this" for itself. Never the card's own name. *(MTG's 2024 change, BG, Pokémon, Dominion.)*
12. **Put the parameter on the keyword.** Write "Belly 2", "Fly South (2)", "Bristle 1", never a sentence restating the number. *(BG Avenge (X), Dominion bonuses, TFT breakpoints.)*
13. **Spatial words get a picture, not a sentence.** Hovering "behind" or "touching" should light the slots on the board rather than spell out "B1 is behind F1 and F2". *(Wingspan's icons and LoR's board arrows show the idea; this rule goes beyond what the games prove, and it's my recommendation.)*
14. **The rulebook wins, and says so.** A one-line precedence rule (card text, then reference) lets cards and reminders stay incomplete without being wrong. *(TI4, MTG.)*

### Where the games disagree, and the call for Bramble

| Question | One side | Other side | Fit for phone + PC auto-battler |
|---|---|---|---|
| Where reminder text lives | On the card, italic and parenthesised (MTG, Pokémon) | Off the card, in a hover or press panel (HS, LoR, StS, Snap) | **Off the card.** Phone cards are small, and auto-battler players read many cards a turn. Keep the italic, smaller look for the panel. |
| Icons or words | Icons for nouns and keywords (Wingspan, LoR, Dominion, TFT) | Words (HS, Snap, StS) | **Icons for resources and persistent keywords** (gold, stats, Belly, Shy) so the board reads at a glance, as in TFT and LoR. **Words for triggers.** |
| Precision | Rules-exact templates (MTG) | Plain speech plus "(if able)" (Snap) | **Plain**, backed by the rulebook. Players don't resolve rules by hand; the engine does. That is the auto-battler advantage MTG doesn't have. |
| Numbers per level | All levels listed, "250/375/600" (TFT) | Only the current number (HS shows the golden card separately) | **Current number only.** Golden shows its own text, as now. |
| Reminder on rares and veterans | Dropped as players learn (MTG) | Always available on hover (HS, LoR) | **Always on hover, never on the face.** A digital game pays nothing to keep it a press away. |

---

## Part 3: the twelve wordiest texts, before and after

Selection: every `text`, `golden_text` and reminder in `content/` (units, spells, heroes, schema keywords) and in `src/ui/keyword_rules.gd`, ranked by character count. A card's base and golden text count as one entry, at its longer length; the top twelve follow. The wordiest hero, 13th, is added because the brief names heroes. Effects are unchanged; only the words move. "Dropped" lists what the after leaves out and why that's fine, and where it goes.

| # | Text | Before | After |
|---|---|---|---|
| 1 | **Pass** reminder, schema (264) | When the card says to Pass, wait until End of Turn. The bonus then moves right through touching units along F1-B1-F2-B2-F3-B3-F4. The last unit keeps it permanently. Start from this unit's slot. If it has left, start from where it stood when the card said to Pass. | *At End of Turn, the bonus moves right along touching units. The last one keeps it.* (83) |
| 2 | **Tribe bonus** help text, `keyword_rules.gd` (222) | The tribe icon records the bonus. It also reaches your hand, units inside Bellies, units away and later arrivals. A unit with two tribes gets both bonuses, and Supper raises both. Becoming golden does not double the bonus. | *Every unit of this tribe has it, wherever it is, including ones you get later.* (80) |
| 3 | **Hasty Pudding** (175; golden 204) | Belly 1. Start of Combat: if this has room, swallow the enemy across. It goes back to its own side when this dies, after 3 of your units die, or when its side has nobody else. | Belly 1. Start of Combat: swallow the enemy across. It returns when this dies or after 3 of your units die. (107) · Golden: Belly 2. Start of Combat: swallow the enemy across and the one nearest it. They return when this dies or after 3 of your units die. (135) |
| 4 | **Nest** reminder, schema (196) | The slot a Bird left, until it comes home. Empty, it holds a textless Egg with half that Bird's current Attack and Health, each rounded up. Mother Goose's own Egg stays 0/2. A slot holds one Nest. | *While a Bird is away, its empty slot fights as an Egg with half its stats.* (73) |
| 5 | **Quarry** reminder, schema (192) | At the bell, mark the enemy across. This attacks that enemy whenever rows allow. The mark follows the unit. Take: when it faints while this Hunter is on the board, even if both faint together. | **Quarry:** *At the bell, mark the enemy across. This attacks it whenever it can.* (69) · **Take:** *Your Hunter's quarry dies.* (26) |
| 6 | **Queen of Elfland** (166; golden 187) | Every 3rd End of Turn: destroy the units behind this (or this, if none). Split their printed Attack and Health, plus permanent buffs, evenly among your other Fairies. | Every 3rd End of Turn: destroy the units behind this, or this if none. Split their stats among your other Fairies. (113) · Golden: … Split double their stats among your other Fairies. (120) |
| 7 | **Fly South** reminder, schema (180) | Flies for no sale gold; back to hand in 2 turns. Its empty Nest fights as a textless Egg with half its Attack and Health, rounded up. A sale is final if played or landed this turn. | *Selling sends this away for no gold. It returns to your hand in 2 turns.* (72) |
| 8 | **Harvest Supper** spell (178) | Aim at a unit with a tribe: your units of that tribe gain +1/+1 permanently, including ones you get later. Once a turn. Tribe bonus: up to +3/+3; not on units summoned in fights. | Choose a unit. Its tribe gets +1/+1 for the rest of the game, up to +3/+3. Once a turn. (88) |
| 9 | **Dishwater Nell** (171; golden 176) | Start of your turn: swap the lowest-tier unit in your shop for one of your tier. If it was 2+ tiers lower and this touches an Ooze, gain 1 gold. Only your first Nell pays. | Start of Turn: replace your shop's lowest-tier unit with one of your tier. If it was 2+ tiers lower and this touches an Ooze, gain 1 gold. (138) |
| 10 | **Old Brock** (166) | At the bell, your units next to this with no quarry take the enemy across from this as quarry and can reach it anywhere. Units next to this have Pounce and +1 Attack. | Units next to this have +1 Attack and Pounce, and share this one's Quarry if they have none. They can reach it anywhere. (115) |
| 11 | **Cycle** help text, `keyword_rules.gd` (162) | One pass through a side's attack order, F1 to F4 then B1 to B3. Its next cycle starts when no eligible unit has an unused attack. Each side counts its own cycles. | *One round of attacks, in which each of your units that can attack does so once.* (80) |
| 12 | **Belly** reminder, schema (157) | Holds this many units, dropped in from the shop, your hand or your board. They wait inside, idle and safe. When this dies they come out alive, last in first. | *Holds this many of your units, safe and out of the fight. When this dies, they come out.* (89) |
| 13 | **Hob Mumblecrust**, hero (127) | Power (free, once a turn): borrow 3 gold. Next turn, repay it and lose 1 Health. Each gold you can't repay costs 1 Health more. | Borrow 3 gold. Next turn, repay it and lose 1 Health, plus 1 for each gold you can't repay. (92) |

The twelve (base texts) go from 2,229 characters to 1,133 with Take's new line, about half. Every card text in the after column is within the 120-character ceiling of rule 1 except golden Hasty Pudding (135) and Dishwater Nell (138); see the flags below.

### What each after drops, and why that's fine

1. **Pass.**
   - Drops "when the card says to Pass": the reminder is attached to the word, so it goes without saying.
   - Drops the slot route: the Touching help word and the hover highlight (rule 13) show it.
   - Drops "permanently": it happens out of combat, where changes last (rule 4).
   - Drops "start from this unit's slot": implied. The case where it has left goes to the rulebook.
2. **Tribe bonus.**
   - Drops the hand, Bellies and away list: "wherever it is" covers them.
   - Drops two tribes and Supper raising both: implied by "every unit of this tribe".
   - Drops "golden doesn't double": golden doubles only the numbers in a card's own text (the golden note), and the bonus isn't card text.
   - Drops "the icon records it": the icon shows it.
   - All of this is already in rulebook 5.2.9.
3. **Hasty Pudding.**
   - Drops "if this has room": Belly 1 already means one (rule 10).
   - Drops "to its own side": "returns" is enough for an enemy.
   - Drops "when its side has nobody else": a stalemate guard players will seldom meet. It goes to the rulebook or the `details` layer.
   - Keeps "after 3 of your units die", because that is how long the effect lasts, the heart of the card.
4. **Nest.**
   - Drops "textless", "rounded up" and "one Nest a slot": rulings, all in rulebook 12.1.4.
   - Drops Mother Goose's 0/2 Egg: her own card says it.
5. **Quarry.**
   - Drops "the mark follows the unit": "mark the enemy" already marks the unit, not the slot.
   - Drops "while this Hunter is on the board, even if both faint together": a simultaneity ruling, for the rulebook.
   - Splits Take into its own one-line reminder. It was a second keyword hidden inside the first.
   - Uses "dies" for "faints" (rule 3).
6. **Queen of Elfland.**
   - Drops "printed … plus permanent buffs" and "evenly". Rulebook 12.1.5 excludes tribe bonuses and auras, so "their stats" leaves that exclusion out. The hover should show the pooled number live (rule 8), which makes the exact accounting visible without words.
   - The golden version keeps one extra word, "double".
7. **Fly South.**
   - Drops the Egg sentence: the Nest reminder says it, and showing both on one card repeated it.
   - Drops "a sale is final if played or landed this turn": the sell button can say "Sell" rather than "Fly" on those turns (rule 9).
   - The trip length could move onto the keyword as "Fly South (2)" (rule 12), which would cut "in 2 turns".
8. **Harvest Supper.**
   - Drops "permanently, including ones you get later": "for the rest of the game" says both. This is the BG phrase for player-level buffs, which rulebook 12.1.1 calls "this game".
   - Drops "not on units summoned in fights": an edge case for the rulebook (5.2.9).
   - "Aim at a unit with a tribe" becomes "Choose a unit": a unit without a tribe simply can't be chosen, and the targeting shows it.
9. **Dishwater Nell.**
   - Drops "Only your first Nell pays": a non-stacking ruling, which belongs in `details` or a game-wide rule ("gold from copies of one unit doesn't stack").
   - Standardises "Start of your turn" as "Start of Turn".
   - **Flag:** still 138 characters, because the card has three conditions: lowest tier, 2+ tiers lower, and touches an Ooze. That is rule 1's design smell. Wording can't fix it.
10. **Old Brock.**
    - Drops "At the bell": the timing of sharing a Quarry is the Quarry keyword's own timing.
    - Drops "take the enemy across from this as quarry": "share this one's Quarry" says it.
    - Keeps "next to", which is correct for `neighbours` (beside, in front and behind). But "next to" needs a help word or a distinct term (rule 3), because players will read it as "beside".
11. **Cycle.**
    - Drops the slot order: attack order is a base rule, shown by the combat replay.
    - Drops "each side counts its own": implied by "your units".
    - Drops "eligible … unused attack": "that can attack does so once" says it in plain words.
12. **Belly.**
    - Drops "from the shop, your hand or your board": the drop target teaches it (rule 9).
    - Drops "alive": coming out implies it.
    - Drops "last in first": order of release, a ruling for the rulebook.
13. **Hob Mumblecrust.**
    - Drops "Power (free, once a turn)": the hero power button shows the cost, and once a turn is the default for hero powers, as in BG. A different limit would need saying.

Two after texts introduce nothing new, but three change vocabulary: "dies" for "faints", "Start of Turn" and "Take" as its own reminder. These need a game-wide decision, not a card-by-card one.

---

## Part 4: the wording guide on `ideation/c-wording`, compared

The guide (`docs/ideation/wording-guide.md` at `659187d`) is sound on the card text itself. Its rules 1–4 and 6–9 match this study's rules 1–6. Its `details` second layer is a good answer to where cut words go. Its gaps and errors:

1. **It studies only BG and Galaxy.** The owner's fourth section asks for "not just Battlegrounds", from 5–10 big games. The guide's rules are BG's habits. It has nothing from LoR's keyword-versus-vocab split, StS's and TFT's live numbers, Dominion's and Wingspan's icon bonuses, or TI4's precedence rule.
2. **It doesn't cover the owner's third section, reminder presentation.**
   - The owner asked for reminder text that is "italicized and made smaller and on hover", visually distinct.
   - The guide's `details` layer is "muted", and nothing makes reminders italic, smaller or hover-only.
   - Rule 7 here covers it: a hover or long-press panel, italic, a size smaller, one box per keyword.
3. **Its spatial glossary is wrong for one word.** Its rule 5 lists "in front, behind, beside, across, touching". But Old Brock, Pounce and other cards say "next to", which in the engine is `neighbours`: beside plus in front plus behind. That is not "beside". Following rule 5 literally would quietly change an effect, or leave "next to" undefined.
4. **It doesn't enforce one word per concept.** "dies", "faints" and "destroy" coexist, as do "At the bell" and "Start of Combat", and "Start of your turn" and "Start of Turn". The guide's examples don't catch these. Rule 3 here does.
5. **It has no keyword budget.**
   - Its rule 3 adds a keyword for any mechanic on more than two cards.
   - Bramble already has about 42 terms with reminders, against BG's roughly ten and Snap's two.
   - The guide needs the cost side: a keyword must save more reading than it costs to learn.
6. **Two of its afters over-cut.** Each cuts the main effect, which goes against its own rule 1.
   - **Mire**, "The enemy across must attack this.", drops "even in your back row". That is the reason a player puts Mire in the back row, and it overrides the base targeting rule. It also turns a slot effect ("whoever stands there", so a unit that moves in is caught) into a unit effect.
   - **Hasty Pudding**, "swallow the enemy across", with every release condition moved to details, drops how long the swallow lasts. A player can't judge the card without "when this dies or after 3 of your units die".
7. **It has no live-number rule.** Formula text such as Jack Daw's "a quarter of what … has gained" is still prose. StS and TFT show the number instead.
8. **It lets the interface carry nothing.**
   - It never says that the UI (drag targets, button labels, slot highlights) can replace text.
   - So Belly's "from the shop, your hand or your board" and Fly South's "sale is final" lines have nowhere to go except `details`.
9. **It doesn't flag the design smell.** Some cards (Dishwater Nell, golden Hasty Pudding) stay long after any rewording, because they carry three conditions. The guide should send those to design rather than trim until meaning is lost.
10. **Smaller points.**
    - It measures in words, while this study measures in characters. Characters predict phone line-wrap better. Either works if used consistently.
    - Its Elder Ooze after drops "of your units" ("for each that has come out"), which reads as counting Oozes, not units.
