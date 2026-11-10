# S3 lazy field loading — 10 Nov 2026

**The budget passes: median added peak RSS is 166.1 MB, below 300 MB.**

The original bundle remains byte-for-byte unchanged:
`build/fields/throwaway-512dc07e8ad0.json.gz`, SHA-256
`6ca0dc2b191c53007dd2b8f2415305077b1e19fbd16b7310fe246030e0cda396`.
It contains 14 lines, 480 trajectories, 1,647,789 stored bytes and 37,043,274 JSON bytes.

## Profile before changing the loader

Three fresh headless allocation profiles against the frozen eager export gave
identical live allocation deltas:

| Component | Decimal MB |
|---|---:|
| Full parsed tree | 446.447 |
| UTF-32 JSON string | 148.173 |
| Dealing/session scaffolding | 2.588 |
| First-round frame/recruit copies | 0.150 |

The tree and string overlap at peak. The 48.428 MB decompression buffer is freed
before parsing. These are engine allocation deltas, not an additive RSS breakdown;
allocator overhead and retained pages explain the remaining process footprint.
The profile tool is `tools/sim/profile_field_memory.gd`; frozen raw runs are under
`build/field-memory-profile-00ed62b9/`. Profiling mounts the eager Linux PCK in the
editor and does not substitute for the actual Linux-export RSS protocol.

## Change and behavioral validation

The gzip format, bytes, SHA, and gameplay manifest are unchanged. The reader
indexes trajectory slices in the original text and validates bodies one at a time.
Only small headers, round availability and exact board sizes stay parsed globally.
At most eight full trajectory bodies are cached, covering seven rivals and the
ghost. Replacement candidates retain their original ordering, line/tribe fallback,
closest-board-size comparison and ID tie break. All undealt frames are validated
before play. Missing/corrupt libraries still fail explicitly.

`tools/sim/field_lazy_equivalence.gd` plays full eager and lazy field games on the
real bundle and compares every round's boards, every captured fight input,
trajectory history/switches and final standings. All three fixed seeds match:

| Seed | Rounds | Fights | Switches | Complete trace SHA-256 |
|---|---:|---:|---:|---|
| 71 | 15 | 57 | 0 | b1a82c6ce70b05f535e68b353effd68b957041267b3485b0d752a0ff4b51bf4e |
| 191 | 17 | 61 | 2 | 2630c3ca3d637e2379e6b150b25eb23b201c5adbdd78c05d3aecacecb469224c |
| 280001 | 18 | 58 | 2 | 7da0b9bd2b06bdce7c8ffb0b31d00289cf85989d02088867d211e18fade3db9b |

The targeted GUT files `test_field_lazy`, `test_field_library_v2`,
`test_field_launch` and `test_field_mode` pass 31 tests. The new tests also cover
escaped quotes/braces and Unicode, unrelated provenance arrays, bounded caching,
invalid undealt frames and truncated JSON. Logs: `build/lazy-field-check/`.

Outside S3's listed ownership: `src/core/field_rivals.gd` must fetch selected frames
and candidate sizes through the lazy reader rather than indexing full bodies.
`tests/core/test_field_lazy.gd` tests that boundary. No selection policy changes.

## Actual Linux export RSS

The unchanged six-run `build/measure_memory.sh` protocol passes on the actual
Linux export, using `/usr/bin/time -v`, the same 1920×1080 first-recruit startup,
GL Compatibility/llvmpipe, 6 LP threads, fresh per-run settings and 600 frames.
The throwaway library is still the exact original 6ca0dc2b… bundle above.

| Peak RSS, KiB | Normal | Field |
|---|---:|---:|
| 1 | 387,516 | 557,136 |
| 2 | 388,696 | 549,920 |
| 3 | 387,732 | 541,092 |
| **Median** | **387,732** | **549,920** |

Difference of medians: **166,080,512 bytes = 166.081 MB**.
The earlier eager result was +665.407 MB. All six time records exit 0, and all six
screenshots show first recruit; field shots show numbered replay Rivals. An
interrupted final sample was discarded and repeated using the existing `field 3`
option. No timing, frame count, resolution or measurement protocol was changed.

Export source: `8da374c9` (the final memory commit amendment changes evidence only).
Folder: `/home/alex/code/Bramble-ideation-sol/build/export-dry-run-8-1110-1247.Me7bkD/`.
README: `/home/alex/code/Bramble-ideation-sol/build/export-dry-run-8-1110-1247.Me7bkD/README.txt`.
Raw times/logs/screenshots and contact sheet: that folder's `memory/` directory.

The complete dry run also passed Linux/Wine boots, signing, all pack listings and
positive Linux/Windows/APK field loads with the original SHA. Removing just the
library from both Windows and APK packs gives exit 1 and the explicit missing-
library error; logs are in the artifact's `negative/` folder and
`build/lazy-field-check/negative.log`. `latest` still names build 7 and no tag was
created. No real device was tested.

This meets the memory condition on today's throwaway library without changing
what the rivals play. The shipped library is still recaptured last before build 8
and needs the same pack/runtime checks. No shipped default setting was changed.
