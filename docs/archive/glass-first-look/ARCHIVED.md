# Archived: the first stained-glass card and screen

**This is not the game's card or screen.** The card is now one lead frame drawn in code, the same at every tier, and the buy screen is the L1 look: see [../../design/look-l1/](../../design/look-l1/README.md). Lead and stained glass is still the art direction ([../../design/art-direction/](../../design/art-direction/README.md)).

What this was: the work of 15 to 17 Nov 2026 that gave the first glass build its card, from the plan to dial in the stained-glass direction.

- [glass-dial-in.md](glass-dial-in.md): the plan to dial in the direction (card frames and the screen first). Its card and screen steps were overtaken by the L1 look; its style-rules step was already replaced by the card art recipe.
- [glass-frames.md](glass-frames.md): the plan and record of the six tier frames, one painted border per tier, which the owner locked on 15 Nov 2026.
- `frame-lab/`: the frames (`final/`), their roundel places (`final/roundels.json`), the guides they were drawn to, and the study of the art space inside a 0.56 card (`art-space.md`). The full-size masters are in Cloudflare R2: `python tools/assets/assets.py pull docs/archive/glass-first-look/frame-lab`.
- `tools/`: the scripts that cut the frames out of Codex pictures, measured them and blanked their roundels. Kept to remake the frames, not used by anything now.
- `examples/`: the card under each tier frame, the recipe's steps with a tier 1 frame, and the first full-screen mock-up (a window of three lights in stone) with its card sheet.

The owner rejected every card frame on 24 Nov 2026 ("All of these frames feel bad") and chose the L1 look ([decisions-l1.md](../../design/look-l1/decisions-l1.md)). Paths inside these files are as they were before the move, except links, which point to the files here.

The six frame pictures the first build drew are still in `assets/glass/frames/`, with their disc places in `assets/glass/card_data.json`: `tools/glass/pull_mockups.py` writes them, and a branch not yet merged still reads them. Their removal is a separate step.

## The first mock-up

The pictures in `examples/` (`glass-mockup-*.jpg`, `glass-cards.jpg`) and `docs/design/art-direction/examples/glass-mockup.jpg` (left there because the owner note of 15 Nov links it) are of the first full-screen mock-up (15 Nov 2026): one window of three lights in dark stone, the cards the bright panels, with a woodland-backdrop variant. Its working files are on the Optiplex at `/data/bramble-art/stained-glass/glass/`. What the agent who built it found weak (from its notes):

- The centre arch is wide and flat; it reads as a vault more than a pointed window head.
- With the leaderboard hidden, the side lights are empty quarries; the top right is the quietest corner.
- The count of panes that marks tier is faint at game size on the darker tiers (blue, purple).
- The Ring slot's amber halo is close to End turn's amber accent.
- Many fighters and portraits are hedgerow amber; the leaderboard has three warm-orange roundels in a row.
- In the woodland version the glass cards have no frame or light of their own.
