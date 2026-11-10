# Build 8 memory budget — 10 Nov 2026

**PASS: median added peak RSS is 157.311 MB, below 300 MB.**

Command: `build/measure_memory.sh /home/alex/code/Bramble-ideation-build8/build/export-dry-run-8-1110-1828.n6b4PO`.
Actual Linux export source: `48fbedd0dd3f674fc00aa1141771424915b87ecf`.
Library: `content/fields/baseline.json.gz`, **1,652,109 stored bytes**,
SHA-256 `3653057c0127bd55ab32bdbb09bf7f95b8831ad8764b7d6c5f63f8fb7ca711fa`.

The unchanged six-run protocol from [memory-lazy.md](memory-lazy.md) measures
fresh GUI first-recruit starts, normal and field, with `/usr/bin/time -v`,
1920×1080, GL Compatibility/llvmpipe, six LP threads, 600 frames at a maximum
30 FPS, fresh settings per sample, the shared Godot slot and 3 GB systemd cap.
All six time records exit 0 and logs have no script/engine error lines.

| Peak RSS, KiB | Normal | Field |
|---|---:|---:|
| 1 | 382,904 | 538,840 |
| 2 | 385,216 | 535,976 |
| 3 | 390,028 | 539,860 |
| **Median** | **385,216** | **538,840** |

Difference of medians: **157,310,976 bytes = 157.310976 decimal MB**.
The [machine-readable result](memory-8.json) retains the exact samples.
Raw times, logs, settings and first-recruit screenshots are in `/home/alex/code/Bramble-ideation-build8/build/export-dry-run-8-1110-1828.n6b4PO/memory/`.
The field settings select `opponents="field"`; the dry-run snapshot enables the
field feature and the positive pack probes load the same library SHA.
This is the actual committed library, not the earlier lazy-loader throwaway.

Earlier measurements on superseded dry-run snapshots remain under `build/`;
this receipt uses the final game-code export and its own six fresh samples.
All six screenshots were visually inspected and show first recruit. The final
combat-return timing refinement affects only fight results, leaving this startup
path unchanged. No real device memory measurement was made.
