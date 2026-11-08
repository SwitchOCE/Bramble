# Wording guide

How on-screen text is written and shown on the ideation branch. Source: the owner, 8 Nov 2026 (`docs/design/owner-notes/2026-11-08e-text-too-wordy.md`) and the owner's addition on reminder text relayed by the orchestrator the same day.

> "Clear and concise wording. Make complicated things simple... If it's implied, let it be implied and the player can find out in additional details some mechanism elsewhere."

> "If some things are reminder text, they need to be italicized and made smaller and on hover... when you hover over a mechanic, it explains how the mechanic works. But even those... need to be communicated differently visually, and we need to make sure that the wording is concise and clear."

## Two kinds of text

| | Rules text | Reminder text |
|---|---|---|
| What it is | What this card does | What a keyword means |
| Where | On the card face, the details panel, Discover slips, the combat note | Only on the reminder slip, when the player asks |
| How it opens | Always shown | Hover the keyword (PC) or tap it (phone). Tapping it again closes it; on PC it closes when the pointer leaves the word |
| Look | Upright, ink, the card's size | Italic, muted brown, smaller, on its own cream slip with a thick left edge |
| Length | The main effect only | One or two short sentences |

## Rules text

- Say the main effect. Keywords carry the repeated mechanics: write `Bristle 2.`, not what Bristle does.
- No reminder text on the card, in brackets or otherwise. If a sentence explains how a keyword works, it belongs in that keyword's reminder.
- Edge cases, rounding and timing exceptions come off the card. Put them in the reminder if a player needs them, or in the guide, or leave them implied.
- Every keyword in the rules text becomes a link on the details panel, the Discover slips and the combat note: bold and underlined, first mention only. Write the keyword exactly as it's named (`Nightshade`, `First Bite`) so it's found. A plural is fine (`Nests`).
- What's true of the unit right now (statuses, Golden, Created, tribe bonus totals) is a short line naming the word. Its meaning is a reminder like any keyword's.

## Reminder text

- Lives in `src/ui/keyword_rules.gd` (help terms, older keywords), `content/schema/effects.json` (game keywords) and `CardDetail.STATE_WORDS` (Golden, Created, Tribe bonus).
- Says what the keyword does in general, never what one card does with it. No card names (Pass's reminder doesn't mention Mr Crumb).
- One or two sentences. Aim for about 20 words; over 30 is too long.
- Start with the trigger or the effect, as Battlegrounds does: "Takes half damage when attacked, rounded up."
- A term the reminder uses (Behind, Beside, Touching, Bell, Cycle) is explained on the same slip, underneath, so the player never chases a second link.
- The slip shows the keyword in bold italic, then a colon, then the reminder.

## How it looks, and why

- **Italic and muted** on both PC and phone, so a reminder never reads as rules.
- **Smaller:** on PC the reminder is 25 against the rules' 31. A phone can't go under its minimum (31), so on a phone the details panel's rules go up to 34 instead and the reminder stays at 31.
- **Set apart:** the reminder has its own slip. In the details panel it docks under the rules and never covers them; long rules scroll above it. On Discover slips it opens under the slip's last line. In a fight it sits just above the unit note.
- Nothing shows until the player asks. A new card closes the last card's reminder.
- On PC, hovering a card opens its details. The panel now stays open while the pointer moves onto it, so the player can hover a keyword there.

The code: `src/ui/widgets/reminder_slip.gd` (the slip, its look and hover/tap handling), `CardDetail.full_text_bbcode` (rules with keyword links, no reminders) and `CardDetail.reminder_for` (a word's reminder for a card). Tests: `tests/ui/test_reminder_slip.gd`.

## Still to do in the wording pass

The reminder slip changes where reminder text goes. It doesn't shorten the text. Over 30 words now: Pass (47), Tribe bonus (38), Fly South (37), Nest (37), Quarry (35), Cycle (32) and Belly (30). Shy, Mire, Pack, Pounce and Bell are 27 to 28 and carry edge cases. One card still carries reminder text in brackets: Garden Snail, "Shell 4 (needs more than 4 Health to save it)". A design review asked for that bracket so new players don't read the card as broken, so whether to cut it, or move it into Shell's reminder, is the pass's call.
