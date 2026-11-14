---
name: ux-copy
description: Write or review Bramble's in-game text — buttons, card and keyword text, reminder text, notices, empty states, confirmations. Use this instead of design:ux-copy in this repo. Trigger with "write copy for", "what should this button say?", "review this card text", or when naming a button, wording a keyword or confirmation, filling an empty state, or writing tutorial text. Not for judging a card's design or power.
argument-hint: "<context or copy to review>"
---

# /ux-copy

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../CONNECTORS.md).

Write or review text for any part of the game's interface.

## Usage

```
/ux-copy $ARGUMENTS
```

## What I Need From You

- **Context**: What screen, phase, or card?
- **Player state**: What is the player trying to do? How are they feeling?
- **Tone**: Formal, friendly, playful, reassuring?
- **Constraints**: Space on the card or button, character limits, platform guidelines?

## The Owner's Rule

> **Clear, short wording in the game (owner, 8 Nov).** Card, keyword, tooltip and guide text says the main effect plainly, in as few words as it takes, and uses keywords to save sentences, as Battlegrounds does. It doesn't explain edge cases or anything the mechanic implies. Those go in a second layer (reminder text on hover or tap, the guide, the rulebook) or stay implied. Purpose: build 6's text was "far too long, far too wordy", and the point of an explanation is to "make complicated things simple", not "to handle every use case". Where it doesn't apply: the rulebook and engine specs, which must stay exact because they are where the edge cases live.

Source: `docs/design/owner-notes/2026-11-08d-clear-concise-wording.md` (on `design/tribes-and-budget`). The live version is in CLAUDE.md; check it and the owner notes for anything newer.

## Principles

1. **Clear**: Say exactly what you mean. No jargon beyond the game's own keywords, no ambiguity.
2. **Concise**: Use the fewest words that convey the main effect.
3. **Consistent**: Same terms for the same things everywhere. Use the rulebook's words (unit, shop, tier), one verb per action, and keywords spelled the same on every card.
4. **Useful**: Every word should help the player accomplish their goal.
5. **Human**: Write like a helpful person, not a robot.

## Copy Patterns

The examples below are illustrations, not decided text.

### Buttons
- Start with a verb: "End turn", "Refresh", "Freeze"
- Be specific: "Concede" not "Quit"
- Match the outcome to the label

### Card and Keyword Text
- Keyword first, then the main effect, as Battlegrounds writes "Deathrattle: Summon a 1/1." (a Battlegrounds keyword; Bramble's are its own)
- Card text is templated, not conversational: the same trigger word always means the same timing
- Numbers as digits, stats as +2/+1 (Attack/Health)
- Anything the mechanic implies stays implied
- Check it fits the card at real size in the lines allowed

### Notices and Errors
Structure: What happened + Why + How to fix, in as few words as that takes
- Mid-turn: "Not enough gold." Don't repeat what the screen already shows.
- Outside play: "Connection lost. Reconnecting…"

### Empty States
Structure: What this is + Why it's empty + How to start
- Empty hand: "Units you buy go here."

### Confirmation Dialogs
- Only for actions that can't be undone; never for routine turn moves
- Make the action clear: "Concede this game?" not "Are you sure?"
- Describe consequences: "You'll leave the game."
- Label buttons with the action: "Concede" / "Keep playing" not "OK" / "Cancel"

### Reminder Text
- The second layer: what the keyword does, as short as it can be. Edge cases go here, in the guide or in the rulebook, or stay implied.
- Concise, helpful, never obvious

### Loading States
- Set expectations, reduce anxiety: "Finding opponents…"

### Tutorial
- Progressive disclosure, one mechanic at a time, taught by doing

## Voice and Tone

Flavour can live in names, keyword names and flavour text, and in notices where it costs no words. Rules sentences and buttons stay plain. Spectacle belongs to the animation, not the text. Adapt tone to context:
- **Success**: Celebratory but not over the top
- **Error**: Empathetic and helpful
- **Warning**: Clear and actionable ("Board full")
- **Neutral**: Informative and concise

## Output

```markdown
## UX Copy: [Context]

### Recommended Copy
**[Element]**: [Copy]

### Alternatives
| Option | Copy | Tone | Best For |
|--------|------|------|----------|
| A | [Copy] | [Tone] | [When to use] |
| B | [Copy] | [Tone] | [When to use] |
| C | [Copy] | [Tone] | [When to use] |

### Rationale
[Why this copy works — player context, clarity, action-orientation, length]

### Localization Notes
[Anything translators should know — idioms to avoid, character expansion, cultural context]
```

## If Connectors Available

If **~~knowledge base** is connected:
- Pull your brand voice guidelines and content style guide
- Check for existing copy patterns and terminology standards

If **~~design tool** is connected:
- View the screen context in Figma to understand the full user flow
- Check character limits and layout constraints from the design

## Tips

1. **Be specific about context** — "Notice when the player can't afford a unit" is better than "error message."
2. **Share the voice** — "Warm woodland storybook" helps me match your tone.
3. **Consider the player's emotional state** — Error messages need empathy. Success messages can celebrate. Mid-turn text gets read at a glance; menu text can say more.
4. **Compare with Battlegrounds** — Its card text is the length benchmark the owner set.
