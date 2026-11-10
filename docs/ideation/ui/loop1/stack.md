# Bazaar Stack — loop 1

Stage 1 adds the Highcrown painting at the two stable `assets/ui/world/*_backdrop.jpg` paths, layered edge foliage, and thin painted stump surfaces with contact shadows. Recruit and fight use the world; menus retain their existing background. This first commit intentionally retains the old layout for comparison. Look at `build/loop1/stack/world-table-pc.png` and `world-table-phone.png`.

Stage 2 puts every reserve card in a single exposed row on the formation's surface. Gold, tier, refresh, freeze, hero power, counters and End turn share the hero bar. The standings rail sorts by Health, with short reorder/countdown motion; eliminated portraits shrink. Selecting a card reserves no space and leaves the stack unchanged. A phone purchase and placement were exercised through `tools/look`; the first-render empty-shop sizing issue found during this check was fixed. Stage 3 will tighten fight ranks and strengthen portrait/Health.

Checks so far: Godot import and changed-script lint. No UI tests rewritten or deleted yet. No gameplay changes. The painted backdrop files are placeholders for the world worker's replacements.

The requested design-critique and accessibility-review skills will guide the final comparison with Bazaar frames and the phone contrast/touch review. Final state captures and the full required check remain pending.
