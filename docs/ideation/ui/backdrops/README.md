# Painted board backdrop concepts — Step 0b.3

Four AI-generated world paintings for comparison behind the real build-8 Ink-B units.
These are concepts, not shipped backgrounds. The shot hook is off unless `BACKDROP` is set;
it replaces only `table_background.gd` nodes with centered, cover-scaled TextureRects.
Unit art, trays, panels, screen layout and gameplay are unchanged. No `src/` change was needed.

| JPEG | Starting zone painting | Source prompt | Extra image references |
| --- | --- | --- | --- |
| `backdrop-weald-glow.jpg` | `docs/folio/art/web/zone-weald.jpg` | `tools/art/prompts/zones-a.txt`, item 1 | None |
| `backdrop-highcrown-rays.jpg` | `docs/folio/art/web/zone-canopy.jpg` | `tools/art/prompts/zones-a.txt`, item 4 | None |
| `backdrop-mosswood-mist.jpg` | `docs/folio/art/web/zone-mosswood.jpg` | `tools/art/prompts/zones-c.txt`, item 1 | None |
| `backdrop-fen-wisplight.jpg` | `docs/folio/art/web/zone-fen.jpg` | `tools/art/prompts/zones-a.txt`, item 2 | Three Ori frames below |

The requested `tools/art/run-codex-image.sh` succeeded after sandbox escalation; no fallback
image tool was used. The initial three items ran together with the Weald, Canopy and Mosswood
images. Ori frames arrived while that invocation was running, so item 4 ran separately with
Fen and three frames. The complete prompt set is `tools/art/prompts/backdrops-11nov.txt`.

Ori lighting references (kept out of git):
`/data/bramble-reference/ori/candidates/wisps-gameplay/wisps-gameplay-0011.jpg` (28.5 s),
`wisps-gameplay-0012.jpg` (29.5 s), and `wisps-gameplay-0024.jpg` (45.5 s).
Source: the Ori and the Will of the Wisps trailer on its
[Steam page](https://store.steampowered.com/app/1057090/), as recorded by the capture worker
in the adjacent `candidates.json`. They informed atmosphere, haze and layered light only.

PNG masters: `docs/folio/art/masters/backdrops/` (gitignored), 1672×941 pixels.
Committed JPEGs retain that resolution, quality 88, optimized progressive RGB.

Render a comparison, including both requested viewport sizes:

```sh
BACKDROP=docs/ideation/ui/backdrops/backdrop-mosswood-mist.jpg \
SCREEN_OUT=build/backdrop-composites/mosswood-mist \
tests/ui/render_screens.sh recruit combat_mid
```

The renderer acquires a Godot slot. Without `BACKDROP`, normal output remains in
`build/screens/`; `SCREEN_OUT` is optional. External image paths work without importing art.
The placeholder proof uses the original `zone-weald.jpg` for `recruit`, `recruit_late` and
`combat_mid` at 1920×1080 and 1688×780, under `build/backdrop-proof/placeholder/`.

Final comparison JPEGs and `sheet.jpg` live in `/data/bramble-gallery/loop1/backdrops/`.
The contact sheet includes the paintings and all sixteen recruit/combat composites.

Viewed every composite at both sizes:

- Weald Glow: units sit well; golden woodland and wooden trays feel cohesive, with clear ink silhouettes.
- Highcrown Rays: units sit well; pale jade light and receding trees give depth without competing with pieces.
- Mosswood Mist: units sit well; cool haze gives the cream frames and warm wood the clearest separation.
- Fen Wisplight: units sit well; pale lavender mist keeps the ink shapes legible and the edges atmospheric.
