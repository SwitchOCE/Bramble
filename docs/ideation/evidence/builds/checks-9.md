# Build 9 checks — 12 Nov 2026

Source: `f2790b2f` on ideation/main (your lab's layout, hex units, the hand of 4, the recaptured strong-field library, PLAYTEST for build 9).

- **Cloud gate: PASS** on `f2790b2f`: https://github.com/SwitchOCE/Bramble/actions/runs/43082638013
- **200-game soak: PASS** on `ceeaa016` (same code; PLAYTEST added after): 200 played (120 preset B, 40 other preset, 40 strong field), 0 violations, 0 crashes. https://github.com/SwitchOCE/Bramble/actions/runs/43082618173 · [soak-9.json](soak-9.json)
  - The first soak, on `32a55657` with build 8's field library, failed all 40 field games at `GameSession.create`: the library sealed the old 10-card hand. Fixed by the recapture ([field-library-9.md](field-library-9.md)).
- **4-game UI run: 0 PROBLEM lines, 0 errors** (4 full games and both late checks at 1920×1080 and 1688×780), run by the arena worker on `9cf03c74`, the merged UI code; nothing under `src/` or `tests/` changed after it except Godot uid sidecars.
- **Memory: PASS.** `build/measure_memory.sh` on the dry-run export of `f2790b2f`: median peak RSS 409,332 KiB with bots and 558,912 KiB with the strong field; median added 153,169,920 bytes, within the 300 MB budget (build 8: 153.8 MB). [memory-9.json](memory-9.json)
- **Export checks: PASS** in the dry run (`build/export.sh --dry-run 9`); the real export repeats them.
- No real phone tested.
