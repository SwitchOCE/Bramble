# Wording guide

The owner, 8 Nov 2026: "Clear and concise wording. Make complicated things simple... Not to be overly specific, not to handle every use case... If it's implied, let it be implied" (`docs/design/owner-notes/2026-11-08e-text-too-wordy.md`). This guide is how Bramble writes anything that explains: card text, keyword reminders, tooltips and guide pages. Effects never change for wording; only words do.

## What Battlegrounds does (measured)

From `docs/research/battlegrounds/data/` (current pool, build 37.0.0) and `docs/research/galaxy/data/cards.json` (current, non-token). Words are counted the same way for every row (`tools/research/word_counts.py`).

| Set | Cards | Median | p90 | Max |
|---|---|---|---|---|
| BG minions | 303 | 11 | 16 | 23 |
| BG Tavern spells | 76 | 9 | 16 | 27 |
| BG hero powers | 123 | 13 | 18 | 25 |
| Galaxy cards | 600 | 11 | 19 | 27 |

What the numbers hide:

- **One sentence, one effect.** Most BG cards are `Trigger: effect.` and nothing else. "Deathrattle: Summon two 1/1 Skeletons." "Rally: Get a random Chromadrake." A second sentence is rare and is a second effect, never a ruling.
- **Keywords do the explaining.** 51 current minions say Deathrattle, 47 Battlecry, 26 Rally, 23 End of Turn. The card never says what Deathrattle means, how Divine Shield rounds or what Taunt does to targeting. Keyword-only cards are common: "Divine Shield Windfury".
- **Timing is a keyword with a colon.** "Start of Combat:", "Avenge (3):", "Spellcraft:". The colon replaces "when this happens, then".
- **Duration is implied.** Combat buffs end with combat (rulebook 12.1.2), so BG says nothing. Only the exception is spelled out: "permanently", "this game", "until next turn".
- **Numbers are digits and stat pairs.** "+2/+2", "a 1/1", "(2)". Never "two Attack and two Health".
- **Golden text is the same sentence with doubled numbers**, or "two" for "a".
- **Left implied:** ties are random, damage rounds sensibly, caps that rarely bind don't exist, a summon with no room fails, a dead unit's trigger still works. Players find these out by playing.
- **Counters live in brackets**, not in prose: "(35 left!)", "(1 left!)".

## Rules

1. **Say the main effect, once.** If a sentence handles a rare case, rounding, a tie, a cap that rarely binds or a timing exception, take it off the card. Put it in the card's `details` (shown on the details panel's second layer, and the text tool's `card`) or drop it if the effect already implies it.
2. **Lead with the trigger, then a colon.** `Start of Combat:`, `End of Turn:`, `Start of Turn:`, `When played:`, `When sold:`, `When this dies:`. A passive needs no trigger.
3. **Keywords stand in for explanation.** If a mechanic is on more than two cards, it gets (or reuses) a keyword, and the card just names it: `Mire.`, `Quarry.`, `Pass right +1/+1.` The card never re-explains a keyword.
4. **Don't say "this combat" or "this fight"** on something that happens in combat: combat changes already end with the fight. Say **permanently** when a combat change stays.
5. **Digits, stat pairs, short words.** `+1/+1`, `a 1/1 Kit`, `2 gold`. "this" for the card itself, "your" for friendly. Spatial words come from the glossary: in front, behind, beside, across, touching.
6. **Limits go last, as a short tail.** `Twice a fight.` `Once a turn.` Prefer that to weaving the limit through the sentence.
7. **Golden text is the same sentence with numbers doubled**, or "two" for "a". If golden adds something, add the fewest words that say it.
8. **Target length.** Card text: median ≤ 11 words, p90 ≤ 17, nothing over 22 (BG's minion max is 23). A keyword reminder is one line, ≤ 12 words. A guide page is ≤ 40 words.
9. **Reminders define; they don't rule.** A reminder says what the keyword does in the common case. Exceptions go to the rulebook, not the reminder.
10. **Tooltips and guides teach the one idea.** One idea a page. No numbers a card already shows. No exceptions.

## Before and after (from our cards)

| Card | Before | After |
|---|---|---|
| Hasty Pudding | Belly 1. Start of Combat: if this has room, swallow the enemy across. It goes back to its own side when this dies, after 3 of your units die, or when its side has nobody else. (36) | Belly 1. Start of Combat: swallow the enemy across. *(details: its release conditions)* |
| Elder Ooze | Belly 1. Whenever a unit comes out of one of your Oozes, it gains +1/+1 this combat for each of your units that has come out this fight, up to +3/+3. (31) | Belly 1. When a unit comes out of your Oozes, it gains +1/+1 for each that has come out. *(cap in details)* |
| Belladonna Sprite | Start of Combat: give the enemy with the highest Health Nightshade (a tie is broken at random). (17) | Start of Combat: give the highest-Health enemy Nightshade. |
| Lamp Moth | Start of Combat: the units in front of this gain +1 Attack this combat. (14) | Start of Combat: give the units in front of this +1 Attack. |
| Garden Snail | Shell 4 (needs more than 4 Health to save it). (10) | Shell 4. |
| Mire (reminder) | At the bell, this makes a bog patch in the enemy slot across. Whoever stands there must attack this while this lives, even in your back row. (27) | The enemy across must attack this. |
| Pass (reminder) | When the card says to Pass, wait until End of Turn. The bonus then moves right... (48) | At End of Turn, the bonus moves right along touching units. The last keeps it. |

## Where the cut words go

- **`details`** (and `golden_details` where numbers double): an optional field on a unit, spell or hero file. The details panel shows it under the reminders, muted. Keep it to one or two short sentences. `check_units.py` counts its numbers, so a cap moved off the card still has its doubled value written down.
- **The rulebook** (`docs/design/rulebook.md`) keeps every ruling. Cards and reminders never need to be complete.
- **Nowhere**, when the effect implies it.
