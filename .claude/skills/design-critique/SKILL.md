---
name: design-critique
description: Get structured feedback on a Bramble game screen or mock-up — usability, feel, hierarchy, layout and consistency. Use this instead of design:design-critique in this repo. Trigger with "review this screen", "critique this mock-up", "critique this layout", or when sharing a screenshot, design-lab page or Figma link for feedback.
argument-hint: "<screenshot, page path or URL, Figma URL, or description>"
---

# /design-critique

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../CONNECTORS.md).

Get structured design feedback on a game screen across multiple dimensions.

## Usage

```
/design-critique $ARGUMENTS
```

Review the design: @$1

If it's an HTML mock-up, open it in the browser pane and screenshot it at the size it was designed for (the design lab uses 1920 × 1080), and play through a turn and a fight if the page allows. If a Figma URL is provided, pull the design from Figma. If a file is referenced, read it. Otherwise, ask the user to describe or share their design.

The platform isn't decided. Check phone size only when asked, and judge only text and target size there; journey-lab layouts pack only at 16:9.

## What I Need From You

- **The design**: screenshot, page, Figma URL, or detailed description
- **Context**: What is this? Who is it for? Which phase (recruit, fight, travel, menu)? What stage (exploration, refinement, final)?
- **Focus** (optional): "Focus on the fight" or "Just the shop"

## Bramble's Layout Rules

Check `docs/design/owner-notes/` and CLAUDE.md for anything newer first.

**Fixed (owner, 14 Nov 2026).** A breach is a top finding.

- The board is 4 front and 3 behind, the back row offset half a slot. "I want the board to be 4 and 3 if I possibly can get it. If we really can't do it, okay, I'll reevaluate."
- Units are tall hexes: "these are the right path."

**Current direction, open to change.** These come from the owner's 11 Nov 2026 layout notes (full list: `docs/design-lab/journey/HANDOFF.md` on `archive/design-lab`). The owner, 14 Nov: they "were just things I suggested for improvements... suggestions that became rules", and "I'm not completely attached to anything." Check the design against them. If one has to break to make the screen work, say which one and why, with the evidence. Breaking one is not a failure.

- Your board never moves or resizes between recruit, fight and travel, and is centred.
- Every unit is the same size everywhere: shop, hand and both boards.
- The shop is its own zone, with tier up, refresh and freeze inside it.
- Vertical space goes to the boards.
- Open: where the hand, the hero and End turn sit, the hand size limit, and whether the other players show during play.

What matters most to the owner: "the game's look and feel, its moment-to-moment gameplay is good."

## Critique Framework

### 1. First Impression (2 seconds)
- What draws the eye first? Is that correct for this phase?
- What's the emotional reaction? Does it feel like the woodland: do frames, counters and buttons look made of something from this world?
- Is the purpose immediately clear: which phase this is and what to do?

### 2. Usability
- Can the player accomplish their goal?
- Is the navigation between screens and menus intuitive?
- Can the player do each turn action (buy, sell, place, play a spell, refresh, freeze, tier up, hero power, end turn) without hunting?
- Is it obvious what can be clicked, what can be afforded, and where a held unit can go?
- Are there unnecessary steps, clicks or confirmations?

### 3. Feel and Readability
- Squint: can you tell the board state, who is winning, and which unit is the carry?
- At real unit size, do Attack, Health, tier, tribe and keywords read, and is the art recognisable?
- Does each action have weight (pick up, drop, buy, triple, hit, death)?
- In a fight, is there one focus at a time, and do chains (a death that summons) stay followable?
- If you only saw a still, write "not judged" for motion and fights. Never pass them.

### 4. Visual Hierarchy
- Is there a clear reading order? The first stop is this phase's decision (recruit: shop offers and gold; fight: the attacker and its target). The eye loops between shop, gold and board without crossing unrelated chrome; End turn is easy to find but not first.
- Are the right elements emphasized? One action accent, on what to press next. Tier, tribe, golden, buff and keyword colours are a coded set, not accents, and none reuses the accent.
- Is whitespace used effectively? Space goes to boards and units; empty area is quiet ground, never padding that makes units smaller.
- Is typography creating the right hierarchy? Name, stats and rules text each have one clear level.
- Constant depth is fine (units on the board, inset frames). Does a change in depth mark only hovered, held, on top or attacking?

### 5. Layout and Grouping
- **Proximity**: gaps inside a group are clearly smaller than gaps between groups. Controls sit next to what they act on.
- **Framing**: each zone (board, shop, hand, leaderboard) reads as one region by its frame or ground.
- **Alignment**: zone frames and chrome share edges and centre lines; look for stray edges there. Inside a zone, follow its own packing: the hex offset is a rule, not a misalignment.
- **Stability**: counters and buttons stay put between turns.

### 6. Consistency
- Does it follow the design system?
- Are spacing, colors, and typography consistent?
- Do similar elements behave similarly?

### 7. Accessibility
- Color contrast ratios, including text over art
- Nothing told by colour alone (tribe, tier, buffs)
- Touch target sizes
- Text readability

### Art Only
- Unit and hero portraits: one subject, centred, face and silhouette inside the hex's safe middle, clear of stat and keyword badges. Check at real size and in greyscale, and that it's tellable from its tribe-mates.
- Splash and key art: subject near a third line; odd-numbered groups read more naturally.
- Backgrounds stay quieter than the units on them.

## How to Give Feedback

- **Be specific**: "End turn competes with refresh" not "the layout is confusing"
- **Explain why**: Connect feedback to design principles or player needs, such as what the player is doing that turn
- **Suggest alternatives**: Don't just identify problems, propose solutions
- **Acknowledge what works**: Good feedback includes positive observations
- **Match the stage**: Early exploration gets different feedback than final polish
- **Judge it as played**: mid-turn with a full board, not only the tidy empty state

## Output

```markdown
## Design Critique: [Screen and phase]

### Overall Impression
[1-2 sentence first reaction — what works, what's the biggest opportunity]

### Usability
| Finding | Severity | Recommendation |
|---------|----------|----------------|
| [Issue] | 🔴 Critical / 🟡 Moderate / 🟢 Minor | [Fix] |

### Feel and Readability
- **At a glance**: [Board state, who's winning, the carry]
- **At real size**: [Stats, tier, tribe, keywords, art]
- **Weight and fights**: [Or "not judged" from a still]

### Visual Hierarchy
- **What draws the eye first**: [Element] — [Is this correct?]
- **Eye path**: [Stops in order] — [Does it serve this phase's decision?]
- **Emphasis**: [One action accent? Depth changes only on what's active?]

### Layout and Grouping
| Principle | Issue | Recommendation |
|-----------|-------|----------------|
| [Proximity/framing/alignment/stability/layout rule] | [Issue] | [Fix] |

### Consistency
| Element | Issue | Recommendation |
|---------|-------|----------------|
| [Typography/spacing/color] | [Inconsistency] | [Fix] |

### Accessibility
- **Color contrast**: [Pass/fail for key text]
- **Colour alone**: [Any meaning with no second cue?]
- **Touch targets**: [Adequate size?]
- **Text readability**: [Font size, line height, text over art]

### What Works Well
- [Positive observation 1]
- [Positive observation 2]

### Priority Recommendations
1. **[Most impactful change]** — [Why and how]
2. **[Second priority]** — [Why and how]
3. **[Third priority]** — [Why and how]
```

## If Connectors Available

If **~~design tool** is connected:
- Pull the design directly from Figma and inspect components, tokens, and layers
- Compare against the existing design system for consistency

If **~~user feedback** is connected:
- Cross-reference design decisions with recent user feedback and support tickets

## Tips

1. **Share the context** — "Recruit phase, turn 6, full board" helps me give relevant feedback.
2. **Specify your stage** — Early exploration gets different feedback than final polish.
3. **Ask me to focus** — "Just look at the shop" gives you more depth on one area.
