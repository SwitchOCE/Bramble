# Loop 1: ink, wash and glow

Chosen style, now frozen in [inkglow/header.txt](../../../../tools/art/prompts/inkglow/header.txt): strong outer ink; minimal interior drawing; large almost-flat washes; little surface texture; upper-right cream key and warm rim. The two fixed references are [Mrs Mallow](../../../../tools/art/prompts/inkglow/anchors/mrs_mallow.jpg) and [Lantern Man](../../../../tools/art/prompts/inkglow/anchors/lantern_man.jpg). Every batch passes the current original first, then both anchors; the header explicitly simplifies their rendering.

Background families: Fairies lavender; Oozes seafoam; Hedgerow folk oat; Hunters silver-blue; Bog folk reed/lichen; Birds warm sky-grey; Neutral clay-rose. Backgrounds stay quiet and lighter/warmer than the board counter. Untribed assets use an explicitly supplied visual family without gaining a gameplay tribe.

Round two: Pill Bug, Grey Agnes and Wee Wobbly redone; Beltane Bonfire, Elderflower Cordial, Dame Hoolet, Brother Bracken, Stash and the Fairies fallback added. Nine generations, no retries. Bigger wash planes and fewer marks read more simply at 150px; the two heroes remain recognisable in real 70px round lobby plaques. Slight grain persists in some masters. Five earlier unit studies remain for comparison. Initial study: nine generations, one leaf/scarf retry.

[Contact-sheet tool](../../../../tools/art/contact_sheet.py) groups paired current/repaint images by first tribe, labels kinds and exports a JSON index. Verified against all 155 portraits, including exact 150px cells and missing-original failure.

Evidence: `build/loop1/inkglow-round2/` contains the 14-identity contact sheet, real recruit render using exact identity matches, lobby-chip comparison, logs and PNG masters. JPEGs: `assets/portraits_inkglow/`; fallback: `assets/ui/portraits_inkglow/`. Production lookup unchanged. Godot import/renders, GDScript format/lint and scope checks passed; tests unchanged. Full rollout has not started.

Batch 0 rollout: 51/57 accepted so far (51 assigned IDs plus six fallbacks), each checked against preserved originals at 150px before overwriting production JPEGs. Four round-two portraits reused; heroes checked at 70px, with a darker local background for Dame Hoolet. Identity/prop changes are retried before acceptance. Frozen recipe, anchors and all `.import` files unchanged. Progress/identity notes: `tools/art/prompts/inkglow/batch0.json`; evidence and original backups: `build/loop1/batch0/`.
