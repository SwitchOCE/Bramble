---
name: design-handoff
description: Generate engine handoff specs from a Bramble game UI design. Use this instead of design:design-handoff in this repo. Use when a screen or UI piece is ready to build in the game and needs a spec sheet covering layout, design tokens, component props, game states, input, screen sizes, edge cases, and animation details.
argument-hint: "<mock-up path, Figma URL or design description>"
---

# /design-handoff

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../CONNECTORS.md).

Generate comprehensive handoff documentation for building a game UI design in the engine.

## Usage

```
/design-handoff $ARGUMENTS
```

Generate handoff specs for: @$1

If it's an HTML mock-up, open it in the browser pane and read sizes from the page. If a Figma URL is provided, pull the design from Figma. Otherwise, work from the provided description or screenshot. Mock-up code is reference only: spec the design, not the HTML.

## What to Include

### Visual Specifications
- Exact measurements at the reference resolution (padding, margins, widths)
- Design token references (colors, typography, spacing, elevation)
- How it scales to other screen sizes and aspect ratios, and the safe area
- Component variants and states

### Interaction Specifications
- Click/tap behavior, and drag with a tap alternative
- Hover states, and what replaces hover on touch
- Transitions and animations (duration, easing, whether input waits for them); fight events also need their phases (wind-up, hit, settle), the impact cue, how they queue, and how they scale with fight speed
- Gesture support (drag, swipe, pinch, long-press)

### Content Specifications
- Character limits for names, rules text and labels
- Number range each stat or counter must fit inside its shape
- Truncation behavior
- Empty states (empty slot, empty hand)
- Loading states
- Error states (not enough gold, board full)

### Edge Cases
- Minimum/maximum content (empty board, full board, full hand, top tier)
- Largest numbers (the biggest stat the rules allow, many buffs)
- International text (longer strings)
- Slow connections, connection lost mid-turn or during a fight replay
- Missing data (placeholder art)

### Accessibility
- Focus order
- Labels and roles, and screen reader announcements once supported
- Input without dragging or hovering, including keyboard
- Colour-blind cues
- Smallest text and target sizes
- Reduced motion (swap in a non-motion cue; never drop the feedback) and fight speed

## Principles

1. **Don't assume** — If it's not specified, the developer will guess. Specify everything.
2. **Use tokens, not values** — Reference `spacing-group` not `16px`.
3. **Show all states** — Default, hover, active, disabled, loading, error, empty, and every game state the piece can be in.
4. **Describe the why** — "A held unit lifts one shadow level so the player sees it's above the board" helps developers make good judgment calls.
5. **Mark what's decided** — Tag each number and rule as the owner's decision, a mock-up choice, or your proposal, in every table. Design-lab numbers are not decisions.

## Output

```markdown
## Handoff Spec: [Screen or Component Name]

### Overview
[What this screen or piece does, which phase, what the player is doing]

### Layout
[Grid system, reference resolution, zones, how it scales and where it is anchored]

### Design Tokens Used
| Token | Value | Usage | Decided? |
|-------|-------|-------|----------|
| `color-gold` | #[hex] | Gold counter, costs | [Owner / mock-up] |
| `spacing-group` | [X]px | Between units in a row | [Owner / mock-up] |
| `font-unit-name` | [size/weight/family] | Unit name | [Owner / mock-up] |

### Components
| Component | Variant | Props | Notes |
|-----------|---------|-------|-------|
| [Component] | [Variant] | [Props] | [Special behavior] |

### States and Interactions
| Element | State | Behavior | Decided? |
|---------|-------|----------|----------|
| [Unit in shop] | Hover | [Behavior] | [Owner / mock-up / proposal] |
| [Unit in shop] | Unaffordable | [Behavior] | [Owner / mock-up / proposal] |
| [Board slot] | Valid drop target | [Behavior] | [Owner / mock-up / proposal] |

### Screen Sizes
| Screen | Changes | Decided? |
|--------|---------|----------|
| [Reference resolution] (the lab used 1920 × 1080) | [Default layout] | [Owner / mock-up] |
| [Other aspect ratio] | [What changes] | [Owner / mock-up / proposal] |
| [Phone, if in scope] | [What changes] | [Owner / mock-up / proposal] |

### Edge Cases
- **Empty state**: [What to show when nothing is there]
- **Long text**: [Truncation rules]
- **Large numbers**: [How they fit]
- **Loading**: [What shows]
- **Error**: [Error state appearance]

### Animation / Motion
| Element | Trigger | Phases and impact cue | Duration | Easing | Decided? |
|---------|---------|-----------------------|----------|--------|----------|
| [Element] | [Trigger] | [Wind-up, hit, settle; flash, shake, sound] | [ms] | [easing] | [Owner / mock-up / proposal] |

### Accessibility Notes
- [Focus order]
- [Labels needed]
- [Input without drag or hover, keyboard]
- [Colour-blind cues]
- [Reduced motion: the non-motion cue that replaces each effect]
```

## If Connectors Available

If **~~design tool** is connected:
- Pull exact measurements, tokens, and component specs from Figma
- Export assets and generate a complete spec sheet

If **~~project tracker** is connected:
- Link the handoff to the implementation ticket
- Create sub-tasks for each section of the spec

## Tips

1. **Share the mock-up or Figma link** — I can read exact measurements and tokens from it.
2. **Mention edge cases** — "What happens with a full board and huge stats?" helps me spec boundary conditions.
3. **Specify the engine** — Once one is chosen, naming it helps me give relevant implementation notes.
