# Bramble design skills

Forks of five skills from Anthropic's `design` plugin (version 1.2.0, `anthropics/knowledge-work-plugins`), refocused on Bramble's game and game UI: `design-critique`, `design-system`, `design-handoff`, `accessibility-review` and `ux-copy`.

What changed from the originals:
- Examples, states and edge cases are about game screens (board, shop, hand, units, fights) instead of business software.
- Layout principles the originals lacked: proximity, framing, alignment, eye path, depth and colour as emphasis. Rule of thirds and odd groups apply to art only.
- The owner's layout rules are in design-critique: one fixed (the 4-3 board); the unit shape and the rest are current direction that can change. ux-copy holds the owner's wording rule.
- Nothing assumes undecided matters: no turn timer (Bramble has none), no fixed platform, no engine, and design-lab numbers stay mock-up choices. Examples are marked as illustrations.
- Game qualities the originals lacked: feel and readability at a glance, fights and motion, and art that reads at unit size.
- Process guidance from the originals is kept, including the connector sections (`CONNECTORS.md` is copied here). Only subject-specific content was swapped for game equivalents.

The plugin's own versions still load as `design:<name>`. In this repo, use these. To compare with a newer plugin release, diff each `SKILL.md` against the plugin's copy.
