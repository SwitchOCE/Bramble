# Bazaar Stack — loop 1

Stage 1 adds the Highcrown painting at the two stable `assets/ui/world/*_backdrop.jpg` paths, layered edge foliage, and thin painted stump surfaces with contact shadows. Recruit and fight use the world; menus retain their existing background. This first commit intentionally retains the old layout for comparison. Look at `build/loop1/stack/world-table-pc.png` and `world-table-phone.png`.

Stage 2 will fold the hand into the central stack, bring the economy and actions into the hero bar and compact the lobby. Stage 3 will tighten the opposing fight ranks and strengthen the player portrait and Health.

Checks so far: Godot import and changed-script lint. No UI tests rewritten or deleted yet. No gameplay changes. The painted backdrop files are placeholders for the world worker's replacements.

The requested design-critique and accessibility-review skills will guide the final comparison with Bazaar frames and the phone contrast/touch review. Final state captures and the full required check remain pending.
