# Inkglow batch 2

Completed 52/52 portraits on 11 November 2026 using the prescribed Codex wrapper and built-in image generation. Pill Bug, Wee Wobbly and Stash reuse frozen-header round-two images. Every accepted portrait was compared with its saved original at exactly 150 px; Pipkin also passed a 70 px circular lobby-chip check.

Three retries: Old Tern restored the original leftward gaze and watch arrangement; Squire Lollop restored both handshakes after a mistaken chair reading; Squirrel Away restored the stored acorn pile. No outstanding identity doubts after those corrections.

All 52 prompts are `tools/art/prompts/inkglow/batch2-<id>.txt`. Accepted art overwrites `assets/portraits/<id>.jpg` as 512×512 RGB JPEG. PNG masters, saved originals, rejected attempts and review pairs stay under ignored `build/loop1/batch2/`. Final contact sheet: `build/loop1/batch2/contact-sheet.png` with JSON index, built with `tools/art/contact_sheet.py` against saved originals.

Checks passed: exact frozen header in all prompts, correct asset kinds and first unit tribe families, both anchor hashes, JPEG dimensions/format, PNG-master coverage, contact-sheet coverage and allowed-file scope. Import metadata, gameplay, card text and tests are unchanged; no UI tests rewritten/deleted. No Godot or in-engine check was run for this asset-only batch. Nothing pushed or merged.
