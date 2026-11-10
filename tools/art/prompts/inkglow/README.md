# Frozen inkglow recipe

`header.txt` is the reusable header. Append an asset's kind, background family and short identity paragraph. The `round2-*.txt` files are the exact composed prompts used for the coverage study; `round2.json` records source, destination and visual family. Do not infer gameplay tribes for heroes, spells or items: their family is an art direction choice. For units, use the first tribe in content; empty tribe lists use Neutral.

Every generation batch must pass these three references in this order:

1. The asset's CURRENT original (`assets/portraits/<id>.jpg`, or `assets/ui/portraits/<tribe>.jpg`).
2. `anchors/mrs_mallow.jpg` — approachable character, strong ink, cream key.
3. `anchors/lantern_man.jpg` — light direction, silhouette separation, local glow.

The anchors are independent frozen copies of finished first-round portraits. The header deliberately reduces their interior marks and texture, and replaces their dark teal backgrounds with the supplied hue family. Neither anchor supplies the subject. Keep these anchor bytes fixed through rollout; hashes are in `anchors/sha256.txt`.

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
