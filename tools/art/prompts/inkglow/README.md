# Frozen inkglow recipe

`header.txt` is the reusable header. Append an asset's kind, background family and short identity paragraph. The `round2-*.txt` files are the exact composed prompts used for the coverage study; `round2.json` records source, destination and visual family. Do not infer gameplay tribes for heroes, spells or items: their family is an art direction choice. For units, use the first tribe in content; empty tribe lists use Neutral.

Every generation batch must pass these three references in this order:

1. The asset's CURRENT original (`assets/portraits/<id>.jpg`, or `assets/ui/portraits/<tribe>.jpg`).
2. `anchors/mrs_mallow.jpg` — approachable character, strong ink, cream key.
3. `anchors/lantern_man.jpg` — light direction, silhouette separation, local glow.

The anchors are independent frozen copies of finished first-round portraits. The header deliberately reduces their interior marks and texture, and replaces their dark teal backgrounds with the supplied hue family. Neither anchor supplies the subject. Keep these anchor files unchanged; git pins their bytes.

Run a composed prompt using the existing Codex image wrapper:

```sh
tools/art/run-codex-image.sh \
  tools/art/prompts/inkglow/round2-grey_agnes.txt \
  build/inkglow/grey_agnes \
  assets/portraits/grey_agnes.jpg \
  tools/art/prompts/inkglow/anchors/mrs_mallow.jpg \
  tools/art/prompts/inkglow/anchors/lantern_man.jpg
```

Review a whole repaint folder alongside current art, at exactly 150px per portrait, grouped by first gameplay tribe (untribed assets under Neutral; asset kind remains labelled):

```sh
python tools/art/contact_sheet.py assets/portraits \
  --fallbacks assets/ui/portraits --current <old portraits> --current-fallbacks <old fallbacks> \
  --out build/inkglow/contact-sheet.png
```

The result is one PNG and a JSON index with identity, tribe, source paths and exact 150px rectangles. It fails on missing current art, unknown identities and duplicate IDs. `--columns` changes the number of pairs per row, without shrinking portraits. Pillow is the only dependency. A full 155-portrait folder was checked during the second study. PNG masters and review outputs stay in ignored `build/`.

## Backdrops and world surfaces

Use the SAME unchanged `header.txt` and both frozen portrait anchors. Compose the shared header with an environment adaptation and the asset's preservation notes; exact jobs are `world-*.txt`. References remain: (1) current world asset, (2) Mrs Mallow, (3) Lantern Man. Fight may also receive the accepted recruit repaint as reference 4 to keep the same canopy and rendering treatment.

The environment adaptation overrides portrait-only subject framing, the square canvas for the two wide backdrops, and tribe-specific portrait grounds. It keeps the shared ink, broad simple washes, sparse interior lines, cream upper-right key/rim and restrained local glow. Retain the current woodland palette, tree arch, door and dwelling positions, perspective and quiet clearing. Near trunks, architecture and big leaf clumps get sparse confident contours; distant trees use two or three quieter planes. Remove fine bark/leaf detail and most light shafts/bloom. Edges and corners carry the place; the centre stays calm for play surfaces. No characters, cards or UI are painted in.

Runtime assets are `assets/ui/world/recruit_backdrop.jpg`, `fight_backdrop.jpg`, `foreground.png` and `stump.jpg`. Keep existing canvas proportions and dimensions when exporting. The foreground remains a genuinely transparent left/bottom corner cutout, mirrored by the renderer; never flatten it onto a matte. The stump remains a top-down material with a few broad seams and muted wash planes. Preserve PNG masters and pre-repaint originals under ignored `build/loop1/art/backdrop/`; commit only the runtime exports and prompts.

Review in the actual layout at phone and PC sizes. Stage the same ten pool-unit hand before both old/new recruit captures so the side-by-side compares art, not scene contents. Keep composition and alpha checks alongside those captures, and run the full project gate before committing.
