---
name: design-system
description: Audit, document, or extend Bramble's game UI system. Use this instead of design:design-system in this repo. Use when checking for naming inconsistencies or hardcoded values across game UI pieces (units, slots, shop, buttons, counters), writing documentation for a piece's variants, states, and accessibility notes, or designing a new pattern that fits the existing system.
argument-hint: "[audit | document | extend] <component or system>"
---

# /design-system

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../CONNECTORS.md).

Manage Bramble's game UI system — audit for consistency, document components, or design new patterns.

## Usage

```
/design-system audit                    # Full system audit
/design-system document [component]     # Document a component
/design-system extend [pattern]         # Design a new component or pattern
```

## Components of a Design System

### Design Tokens
Atomic values that define the visual language:
- Colors (brand, semantic, neutral). One action accent, kept for what the player should press next. Semantic colours (tiers, tribes, keywords, buffs, damage, gold) are a separate coded set, not accents; each needs a second cue (icon, shape or label), never colour alone.
- Typography (scale, weights, line heights) for names, stats, rules text and counters
- Spacing (scale, component padding; steps by role: inside a group, between groups, between zones, each clearly larger than the last)
- Borders (radius, width), including zone frames
- Shadows (elevation levels, each with one meaning: resting, hovered, held, overlay)
- Motion (durations, easings) for buy, place, attack, damage, death and phase change; for fight events also the phases (wind-up, hit, settle), the impact cue, how events queue, and how it scales with fight speed

Tokens split into layout (positions and sizes every look shares) and skin (materials, frames, typefaces, textures that give a look its character).

### Components
Reusable UI elements with defined:
- Variants (unit, spell; primary, secondary and ghost buttons)
- States (default, hover, active, disabled, loading, error; and game states: held, valid or invalid drop target, frozen, unaffordable, attacking, damaged, dying, buffed, golden)
- Sizes (one unit size everywhere; controls may vary, e.g. sm, md, lg)
- Behavior (interactions, animations)
- Accessibility (ARIA where it applies, keyboard, input without drag, colour-blind cue, minimum size)

Core pieces: unit, board slot, board, shop, hand, hero portrait, leaderboard portrait, turn buttons (End turn, refresh, freeze, tier up, hero power), gold and tier counters, keyword icon, stat display, reminder text.

### Patterns
Common UI solutions combining components:
- Forms (settings, sign-in, lobby: input groups, validation, submission)
- Navigation (menus, tabs, back paths between screens)
- Data display (leaderboard, match history, card lists)
- Feedback (toasts, modals, inline messages)
- Placement (drag or tap to buy, place, move and sell)
- Targeting (choosing a unit for a spell or effect)
- Choices (pick one of several offers)
- Combat feedback (attack, damage numbers, deaths, results)
- Notices (not enough gold, board full, hand full)

## Principles

1. **Consistency over creativity** — The system exists so teams don't reinvent the wheel
2. **Flexibility within constraints** — Components should be composable, not rigid
3. **Document everything** — If it's not documented, it doesn't exist
4. **Version and migrate** — Breaking changes need migration paths

## Output — Audit

Lab code is reference only; don't count its hardcoded values.

```markdown
## Design System Audit

### Summary
**Components reviewed:** [X] | **Issues found:** [X] | **Score:** [X/100]

### Naming Consistency
| Issue | Components | Recommendation |
|-------|------------|----------------|
| [Inconsistent naming] | [List] | [Standard to adopt] |

### Token Coverage
| Category | Defined | Hardcoded Values Found |
|----------|---------|----------------------|
| Colors | [X] | [X] instances of hardcoded hex |
| Spacing | [X] | [X] instances of arbitrary values |
| Typography | [X] | [X] instances of custom fonts/sizes |
| Elevation | [X] | [X] shadows with no defined meaning |

### Component Completeness
| Component | States | Variants | Docs | Score |
|-----------|--------|----------|------|-------|
| Unit | ✅ | ✅ | ⚠️ | 8/10 |
| Refresh button | ✅ | ⚠️ | ❌ | 5/10 |

### Priority Actions
1. [Most impactful improvement]
2. [Second priority]
3. [Third priority]
```

## Output — Document

```markdown
## Component: [Name]

### Description
[What this component is and when to use it]

### Variants
| Variant | Use When |
|---------|----------|
| [Primary] | [Main actions] |
| [Secondary] | [Supporting actions] |

### Props / Properties
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| [prop] | [type] | [default] | [description] |

### States
| State | Visual | Behavior |
|-------|--------|----------|
| Default | [description] | — |
| Hover | [description] | [interaction] |
| Active | [description] | [interaction] |
| Held | [description] | [interaction] |
| Disabled | [description] | Non-interactive |
| Loading | [description] | [animation] |
| [Game state, e.g. Frozen] | [description] | [behavior] |

### Accessibility
- **Role**: [ARIA role, where it applies]
- **Keyboard**: [Tab, Enter, Escape behavior]
- **Screen reader**: [Announced as..., once supported]
- **Input**: [Mouse and touch; how to do it without dragging]
- **Colour**: [The second cue for any colour meaning]
- **Size**: [Smallest text and target size]

### Do's and Don'ts
| ✅ Do | ❌ Don't |
|------|---------|
| [Best practice] | [Anti-pattern] |

### Code Example
[Engine-appropriate snippet, once an engine is chosen]
```

## Output — Extend

```markdown
## New Component: [Name]

### Problem
[What player need or gap this component addresses]

### Existing Patterns
| Related Component | Similarity | Why It's Not Enough |
|-------------------|-----------|---------------------|
| [Component] | [What's shared] | [What's missing] |

### Proposed Design

#### API / Props
| Property | Type | Default | Description |
|----------|------|---------|-------------|
| [prop] | [type] | [default] | [description] |

#### Variants
| Variant | Use When | Visual |
|---------|----------|--------|
| [Variant] | [Scenario] | [Description] |

#### States
| State | Behavior | Notes |
|-------|----------|-------|
| Default | [Description] | — |
| Hover | [Description] | [Interaction] |
| Disabled | [Description] | Non-interactive |
| Loading | [Description] | [Animation] |
| [Game state] | [Description] | [Animation] |

#### Tokens Used
- Colors: [Which tokens]
- Spacing: [Which tokens]
- Typography: [Which tokens]
- Elevation and motion: [Which tokens]

### Accessibility
- **Role**: [ARIA role, where it applies]
- **Keyboard**: [Expected interactions]
- **Screen reader**: [Announced as..., once supported]
- **Input**: [Mouse and touch, without dragging]
- **Colour**: [Second cue]
- **Size**: [Smallest text and target size]

### Open Questions
- [Decision that needs design review]
- [Edge case to resolve]
```

## Where Things Are

- Mock-ups and their tokens: the design lab (`docs/design-lab/` on `archive/design-lab`). Its numbers are lab choices, not decisions.
- The owner's layout rules: see the design-critique skill.
## If Connectors Available

If **~~design tool** is connected:
- Audit components directly in Figma — check naming, variants, and token usage
- Pull component properties and layer structure for documentation

If **~~knowledge base** is connected:
- Search for existing component documentation and usage guidelines
- Publish updated documentation to your wiki

## Tips

1. **Start with an audit** — Know where you are before deciding where to go.
2. **Document as you build** — It's easier to document a component while designing it.
3. **Prioritize coverage over perfection** — 80% of components documented beats 100% of 10 components.
