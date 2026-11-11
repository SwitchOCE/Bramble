# Batch 1 portrait notch repaint

11 November 2026 — `ideation/ui-art-n1`.

- Slice: 52 batch-one identities; 47 repainted and accepted. Five approved trials skipped: lamp_moth, lantern_man, lob_lie_by_the_fire, mrs_jay, mrs_mallow.
- Visual retries: 0. Failed repaints retained unrepainted: 0. All 47 passed comparison by eye for identity, essential props, upper-right painted form and crisp outer ink.
- Used the existing Codex image wrapper and built-in image tool, four ordered references and the unchanged production header. Composed prompts are `tools/art/prompts/inkglow/notch-<id>.txt`; old flat-background colour wording was removed from identity paragraphs.
- Runtime exports: 47 RGB JPEGs, 512×512, quality 90. PNG masters remain ignored at `build/notch/<id>/<id>.png`.
- Contact sheet: `build/notch/art-notch-1-contact-sheet.png` and matching JSON, 47 current/new pairs at exactly 150px, generated with `tools/art/contact_sheet.py`. Current originals were exported byte-for-byte from `e6af222d` into `build/notch/current-e6af222d/`.
- Checked the full sheet and five heroes in 70px circular crops (`build/notch/hero-chips-70px.png`), export properties, header preservation and allowed-file scope. No code, content or tests changed; Godot was not run.
- Checkpoints: `7a59ca03` (12), `ca44518b` (8), `d8602ecb` (12), `b85b0257` (9), with the final six in the completion commit. No push or merge.
