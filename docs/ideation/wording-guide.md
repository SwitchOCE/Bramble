# Wording guide

The owner, 8 Nov 2026: "Clear and concise wording. Make complicated things simple... If it's implied, let it be implied and the player can find out in additional details some mechanism elsewhere." And on reminders: "italicized and made smaller and on hover" (`docs/design/owner-notes/2026-11-08e-text-too-wordy.md`).

Effects never change for wording; only words do. The evidence behind these rules is `docs/ideation/wording-study.md` on `ideation/c-wording-study` (ten games) and the counts in `evidence/wording-pass.md`.

## Three kinds of text

| | Card text | Reminder | Details |
|---|---|---|---|
| What it is | What this card does | What a keyword or term means | A ruling for this card: a cap, a tie, a timing exception |
| Where | Card face, details panel, Discover slips, combat note | The reminder slip | The same slip, from the muted *Details* link |
| How it opens | Always shown | Hover the word (PC), tap it (phone); tap again or leave to close | As a reminder |
| Look | Upright ink; keywords bold and underlined, first mention only | Italic, muted brown, a size smaller, on its own cream slip | As a reminder |
| Length | Median ≤ 11 words, p90 ≤ 17, max 22 | One sentence: aim for 12 words, never over 16 | One or two short sentences |
| Lives in | The card's `text` / `golden_text` | `content/schema/effects.json`, `src/ui/keyword_rules.gd`, `CardDetail.STATE_WORDS` | The card's `details` / `golden_details` |

Reminders sit off the card, as in Hearthstone, Legends of Runeterra and Slay the Spire, and look like Magic's italic reminder text. The slip code is `src/ui/widgets/reminder_slip.gd`.

## Card text

1. **Trigger, colon, effect.** One timing phrase from the list below starts the sentence. *(Hearthstone, Marvel Snap, LoR.)*
2. **Say the main effect once.** Rounding, ties, rare caps and timing exceptions go to Details or nowhere. A condition that changes how you play stays (Mire's back row, Hasty Pudding's "if this has room"). *(Hearthstone, Snap's "if able" only where a reader would wonder.)*
3. **Keywords do the explaining.** Write `Bristle 2.`, never what Bristle does, and put the number on the keyword: `Shell 4`, `Mark 2`. *(Battlegrounds' Avenge (X), Dominion's bonuses.)*
4. **Durations are implied.** Combat changes end with the fight, so never write "this combat". Say **permanently** only when it lasts. *(Battlegrounds.)*
5. **Digits, stat pairs, short words.** `+1/+1`, `a 1/1`, `2 gold`, "this" for the card itself. *(Battlegrounds, Magic, Pokémon.)*
6. **Limits go last:** `Once a fight.` `Twice a fight.` `Once a turn.`
7. **Golden text is the same sentence with numbers doubled**, or "two" for "a".
8. **Too long after trimming is a design problem.** Flag it rather than cut a condition. *(The study's Part 4.)*
9. **The rulebook wins.** Cards and reminders can be incomplete without being wrong. *(Twilight Imperium, Magic.)*

## Reminders

- Define the common case only, in one sentence. No card names, no exceptions. *(Hearthstone's Reborn, Dominion, Slay the Spire's Vulnerable.)*
- Start with the effect or the trigger: "Takes half damage when attacked."
- A term a reminder uses (Behind, Next to, Cycle) is explained on the same slip, under it.

## One word per concept

*(Magic's templating; Snap and Battlegrounds keep near-identical effects apart by wording.)*

| Concept | Write | Not |
|---|---|---|
| A unit is removed | **dies** (event), **destroy** (a card does it) | faints |
| Fight start | **Start of Combat** | at the bell, Bell |
| Turn start / end | **Start of Turn**, **End of Turn** | Start of your turn |
| A fight-long limit | **a fight** (`Twice a fight`) | this combat, per combat |
| Left or right in the same row | **beside** | neighbour, next to |
| Beside, in front or behind | **next to** | neighbour, beside |
| A run of units along the zigzag | **touching** | adjacent |
| A unit's quarry dies | **Take** (capital T; its own reminder) | — |

"Beside" is the engine's `adjacent`; "next to" is `neighbours` (`src/core/board_geometry.gd`). Never swap them in a rewrite: it changes the effect.

## Keyword budget

Snap runs on two keywords and Battlegrounds on about ten. Bramble has more, so every term must save more reading than it costs to learn. *(Snap, Battlegrounds, LoR's keyword-versus-vocabulary split.)*

- A new keyword needs three or more cards and must shorten each of them.
- A keyword on one card is written as plain words if the plain version is about as short (Still-Water Heron's Fast and Feast, Hazel Dormouse's Bide). A one-card keyword stays if the plain version would be long, or the word is also a status in fights.
- Don't coin words for things the player never acts on (the bell was a timing step inside Start of Combat).

## Let the interface carry it

*(Snap's tap-for-detail, Slay the Spire's live numbers, TFT's highlights.)* Already in the game: the Sell button reads "Fly south" for a Bird, Bellies that can take a unit light up, and selecting a unit lights the slots its text reaches. A card needn't say what those show. Bigger cues, such as lighting slots when a spatial word is hovered or showing a live number for a formula, are listed in `evidence/wording-pass.md` for later.
