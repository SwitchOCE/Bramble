---
name: accessibility-review
description: Run an accessibility audit on a Bramble game screen, mock-up or UI piece, using WCAG 2.1 AA figures where they apply and game accessibility practice for the rest. Use this instead of design:accessibility-review in this repo. Trigger with "audit accessibility", "check a11y", "is this accessible?", or when reviewing a design for color contrast, text size, input, motion, or timing before handoff.
argument-hint: "<screenshot, page path or URL, Figma URL, or description>"
---

# /accessibility-review

> If you see unfamiliar placeholders or need to check which tools are connected, see [CONNECTORS.md](../CONNECTORS.md).

Audit a game screen or mock-up for accessibility.

## Usage

```
/accessibility-review $ARGUMENTS
```

Audit for accessibility: @$1

If it's an HTML mock-up, open it in the browser pane at its design size. The platform isn't decided. Check phone size only when asked, and judge only text and target size there; journey-lab layouts pack only at 16:9.

## Quick Reference

WCAG 2.1 AA figures are the floor for contrast. The rest follows common game accessibility practice (the Game Accessibility Guidelines, Xbox Accessibility Guidelines). Settings Bramble hasn't decided on are recommendations, not failures. On a mock-up, list settings, keyboard and scaling once under "Later (engine stage)" and don't score them.

### Perceivable
- **1.1.1** Non-text content has a text alternative: meaningful images, icons, keyword and tribe marks have a name
- **1.3.1** Info and structure conveyed semantically (HTML mock-ups)
- **1.4.3** Contrast ratio >= 4.5:1 (normal text), >= 3:1 (large text), including text over art: measure against the worst pixel behind, and an outline or stroke on the text counts
- **1.4.11** Non-text contrast >= 3:1 (UI components, stat shapes, slot frames)
- **1.4.1** Colour is never the only cue (tiers, tribes, buffs, valid targets)
- Text stays readable at the smallest supported size (lab floor: 11 CSS px on phone; a lesson, not a decision), and a text or UI scale setting exists
- Sound cues have a visual equivalent

### Operable
- Every action works without dragging (tap to pick up, tap to place) and without hovering
- **2.1.1** If keyboard is supported, every action can be done from it
- **2.5.5 (AAA)** Touch target >= 44x44 CSS pixels, a common game target and not a Bramble decision (the AA floor is 24x24, WCAG 2.2's 2.5.8)
- **2.4.3** Logical focus order, where keyboard or controller is supported
- **2.4.7** Visible focus or selection state
- **2.2.1** Timing: the recruit phase has no timer (rulebook 3.1.2). Any timed choice (the hero pick, if it stays timed) shows its time and warns before it ends.

### Understandable
- **3.2.1** Hovering never rearranges units or changes the phase. Units parting to show where a held unit will land is good feedback, not a failure.
- **3.3.1** Error identification: say why an action failed ("Not enough gold")
- **3.3.2** Labels or instructions for controls, including icon-only buttons
- Rules text has its reminder text one hover or tap away
- The same icon or keyword means the same thing everywhere

### Motion and Sensory
- **2.3.1** Nothing flashes more than 3 times a second
- Fights can be slowed or stepped through; motion and screen shake can be reduced, with a non-motion cue (flash, number, outline) in place of each effect, never no feedback
- One attack at a time is clear: who hit whom, and what died

### Robust
- **4.1.2** Name, role, value: screen-reader support is a later engine decision. Note gaps; don't fail them.

## Common Issues

1. Insufficient color contrast, especially text over art
2. Missing labels on icon-only controls
3. No keyboard access to interactive elements, where keyboard is supported
4. Missing alt text on meaningful images (HTML mock-ups)
5. Focus traps in modals and menus
6. Missing ARIA landmarks (HTML mock-ups)
7. Auto-playing media without controls
8. Time limits without extension options or a clear warning
9. Text too small at the smallest supported size (stats, names, rules text)
10. Meaning carried by colour alone (tier, tribe, buffed, frozen)
11. Drag-only or hover-only actions and information
12. Numbers spilling out of stat shapes
13. Fast or flashing fight effects with no way to slow them

## Testing Approach

1. Automated scan of HTML mock-ups (catches ~30% of issues)
2. Keyboard-only navigation where supported, and a mouse-free, touch-only run through a turn
3. Screen reader testing (VoiceOver, NVDA) on HTML mock-ups, and in the engine once supported
4. Color contrast verification
5. Zoom to 200% or the largest text setting — does layout break?
6. Screenshot at design size, and at phone size if in scope
7. Greyscale and colour-blind simulation
8. Reduced motion and slowest fight speed — can the fight be followed?

## Output

```markdown
## Accessibility Audit: [Screen or Component Name]
**Standard:** WCAG 2.1 AA figures + game accessibility practice | **Date:** [Date]

### Summary
**Issues found:** [X] | **Critical:** [X] | **Major:** [X] | **Minor:** [X]

### Findings

#### Perceivable
| # | Issue | Criterion | Severity | Recommendation |
|---|-------|-----------|----------|----------------|
| 1 | [Issue] | [1.4.3 Contrast] | 🔴 Critical | [Fix] |

#### Operable
| # | Issue | Criterion | Severity | Recommendation |
|---|-------|-----------|----------|----------------|
| 1 | [Issue] | [Drag-only] | 🟡 Major | [Fix] |

#### Understandable
| # | Issue | Criterion | Severity | Recommendation |
|---|-------|-----------|----------|----------------|
| 1 | [Issue] | [3.3.1 Errors] | 🟢 Minor | [Fix] |

#### Motion and Sensory
| # | Issue | Criterion | Severity | Recommendation |
|---|-------|-----------|----------|----------------|
| 1 | [Issue] | [2.3.1 Flashing] | 🟡 Major | [Fix] |

#### Robust
| # | Issue | Criterion | Severity | Recommendation |
|---|-------|-----------|----------|----------------|
| 1 | [Issue] | [4.1.2 Name, Role, Value] | 🟡 Major | [Fix] |

### Color Contrast Check
| Element | Foreground | Background | Ratio | Required | Pass? |
|---------|-----------|------------|-------|----------|-------|
| [Attack number] | [color] | [color] | [X]:1 | 4.5:1 | ✅/❌ |

### Colour-Blind Check
| Meaning | Colour | Second Cue | Pass? |
|---------|--------|------------|-------|
| [Tier 3] | [color] | [Number on badge] | ✅/❌ |

### Input
| Action | Mouse | Touch | Keyboard | Without Drag/Hover |
|--------|-------|-------|----------|--------------------|
| [Buy unit] | [Behavior] | [Behavior] | [Behavior] | ✅/❌ |

### Keyboard Navigation
| Element | Tab Order | Enter/Space | Escape | Arrow Keys |
|---------|-----------|-------------|--------|------------|
| [Element] | [Order] | [Behavior] | [Behavior] | [Behavior] |

### Screen Reader
| Element | Announced As | Issue |
|---------|-------------|-------|
| [Element] | [What SR says] | [Problem if any] |

### Priority Fixes
1. **[Critical fix]** — Affects [who] and blocks [what]
2. **[Major fix]** — Improves [what] for [who]
3. **[Minor fix]** — Nice to have
```

## If Connectors Available

If **~~design tool** is connected:
- Inspect color values, font sizes, and touch targets directly from Figma
- Check component ARIA roles and keyboard behavior in the design spec

If **~~project tracker** is connected:
- Create tickets for each accessibility finding with severity and WCAG criterion
- Link findings to existing accessibility remediation epics

## Tips

1. **Start with contrast, text size and keyboard** — These catch the most common and impactful issues.
2. **Test with real assistive technology and devices** — My audit is a great start, but manual testing with VoiceOver/NVDA and playing on real hardware catches things I can't.
3. **Prioritize by impact** — Fix issues that block players first, polish later.
