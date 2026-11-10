# S3 memory budget and packed field — 10 Nov 2026

**Update: the lazy loader now passes at +166.1 MB.** See [the lazy-loader result](memory-lazy.md).
The original eager baseline below is retained as historical evidence.

**The memory budget fails: field startup adds 665.4 MB of median
peak RSS, above the 300 MB limit. Keep normal Hard lobbies as the default.**
The pack-loading and missing-library checks pass. The shipped library is still
recaptured last before build 8; this throwaway measurement does not approve the
strong field as the shipped default. The orchestrator should log the default call.

Source of the Linux export: `7b550a2c674275ee0a51ba83c0d5c78de15e4206`.
Dry-run folder: `/home/alex/code/Bramble-ideation-sol/build/export-dry-run-8-1110-1214.0202BX/`.
README: `/home/alex/code/Bramble-ideation-sol/build/export-dry-run-8-1110-1214.0202BX/README.txt`.

## Throwaway library

- Path: `build/fields/throwaway-512dc07e8ad0.json.gz`. It is ignored, uncommitted, and not installed in `content/fields/`.
- SHA-256: `6ca0dc2b191c53007dd2b8f2415305077b1e19fbd16b7310fe246030e0cda396`.
- Stored gzip: **1,647,789 bytes**; uncompressed JSON: **37,043,274 bytes**.
- **14 lines, 480 trajectories**, all source top-four finishers.
- Capture source: `512dc07e8ad0a26a5ebb20fd3d104121bb43aac8`; gameplay content matches the export source.
- 120 all-line lobbies, seeds 20262000–20262119; 875.5 seconds locally,
  through `GODOT_SLOT_CLASS=worker scripts/godot_slot.sh`. No outer lock.
- Builder: `tools/sim/field_library.py ... --source-commit 512dc07e --per-line 64 --strength top4`.
  The existing sampler's 64 cap is per line/lobby-rotation/top-four stratum;
  it retains at least eight winners for every source lobby rotation. No synthetic
  fixture or v1 harness field supplied these measurements.
- Capture logs: `build/fields/capture-512dc07e/`; sampling provenance is in the library.

## Linux export peak RSS

These are `/usr/bin/time -v` measurements of the actual exported
`linux/bramble.x86_64`, not the Godot editor. Every run starts a fresh process with
isolated saved settings, clicks New game, chooses a hero and reaches the first
recruit screen at 1920×1080. Xvfb, xdotool and `/usr/bin/time` run outside the
measured game process. Rendering is GL Compatibility on llvmpipe with
`LP_NUM_THREADS=6`, Dummy audio and a 30 fps cap; the game exits after 600 frames.
The ordinary and field runs use the same binary and pack. The normal run leaves
the bundled library unloaded; the field run loads it and deals replay rivals.

The dry-run snapshot explicitly enables the `strong_field` feature for this test.
Its default remains Bots. Field starts set the saved opponent choice to field;
normal starts set it to bots. This feature override exists only in the dry-run
snapshot. All six screenshots show the first recruit screen; field screenshots
show numbered Rival replay identities. All six time records have exit status 0
and game logs contain no script errors.

Peak RSS, in KiB as reported by `/usr/bin/time -v`:

| Run | Normal | Field |
|---|---:|---:|
| 1 | 379,060 | 1,036,080 |
| 2 | 393,132 | 1,035,820 |
| 3 | 386,008 | 1,027,864 |
| **Median** | **386,008** | **1,035,820** |

Normal median: 395.272 MB.
Field median: 1060.680 MB.
Difference of medians: **665,407,488 bytes = 665.407 MB**
(decimal MB; also above 300 MiB). The criterion is at most 300 MB.

Reproduce with `build/measure_memory.sh <dry-run-folder>`; optional `field 3`
repeats only that run. Raw `time.txt`, `start.log`, `start.png`, `contact-sheet.png`
and `results.json` are under the artifact's `memory/` folder. An initial window-title
lookup timeout and an interrupted third attempt produced no accepted samples;
they were repeated. All numbers above are from completed runs.

## Pack presence, loading and failure

The `windows.files` and `android_apk.files` listings each contain exactly one
`content/fields/baseline.json.gz`; Linux does too. Three positive startup probes
validate gameplay hashes, create a field session and report the exact library SHA
above. The Windows probe mounts the real Windows PCK; the APK probe mounts a ZIP
containing only the APK's original `assets/` bytes, with that prefix removed.
This proves packed-resource loading, not Android device execution.

`build/verify_field_packs.sh <dry-run-folder>` makes a Windows PCK and an APK-asset
ZIP with only the bundled library removed. Both probes exit **1**, print exactly
`export-field: Field library does not exist: res://content/fields/baseline.json.gz`,
and never report a loaded field or fall back to bots. Negative packs and logs
are under the artifact's `negative/` directory. The Windows copy uses
`tools/sim/strip_field_pack.gd`; all remaining original pack entries are retained.

`content/tutorial/*` and `content/rules/*` are now in every preset's inclusion
filter. The runtime field validator also no longer depends on excluded tool code.
No real device was tested. Build 8 still needs its final recapture and the plan's
remaining gameplay, soak and UI gates.
