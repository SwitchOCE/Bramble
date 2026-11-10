# Cue retirement and reader follow-up

This packet adds nine sheets / 72 native frames: Bog attacks 017 and 025 and
combat_mid attack 045, each at ×1, ×4 and reduce motion. Existing packets and the
accepted d400831e Bog before images are unchanged. No new before images were made.

Each sheet contains eight native 1688×780 frames assembled without scaling into
6752×1640. The initial uniform samples are adjusted to include every actor's
observed lunge peak; Pack partners are measured separately. Reduce motion pins
the held pose or strongest source flash. Manifests retain the uniform candidates,
replaced ticks, measured peaks and actual actor positions in each saved frame.
The assembler verifies each peak has a matching frame and visible actor position.
Old manifests without peak metadata keep their existing interpretation.

Bog was finally rendered from **22c5e9f3**, which raises the transient numeric
receipt above the spark. The three combat_mid sheets retain **d577853d**: that
fixture has no gain_pending or bog_toll events, so the later Wave numeric-layer
patch cannot affect its pixels. The sampling tooling was committed at dc38f8f3;
the final Bog-only filter and provenance edits follow that commit.

The full event streams are replayed, without rerunning combat rules or RNG.
Complete events, event order, final model state and final hero Health match all
recorded heads. Discovery and frame replay match within each head, including
event ticks and automatic return. Their ancillary text budget remains at most 10.
No fresh cold-reader or scoring pass is claimed.

## Isolated whole-fight timing comparison

Before timings were captured on **62c6cc76**, before the cleanup barrier changed.
After-cleanup timings were captured on **bda3f1d2**, before the later reader cue
repairs. Each has two identical fixed-120-Hz passes through automatic return.
The final reader repairs leave these durations unchanged.

| Complete fight | Before | Cleanup after | Saved |
| --- | ---: | ---: | ---: |
| Bog ×1 | 9.833333 s | 9.725000 s | 0.108333 s |
| Bog ×4 | 6.558333 s | 5.641667 s | 0.916667 s |
| combat_mid ×1 | 27.333333 s | 25.766667 s | 1.566667 s |
| combat_mid ×4 | 22.000000 s | 20.200000 s | 1.800000 s |

`before-timings.json`, `after-cleanup-timings.json` and `after-final-timings.json`
retain the exact tick counts, event lists and final states. `report.json` compares
them and inventories the nine sheets. Cross-head tick equality is deliberately
not required: the cleanup change shortens waits. Source events and end state
remain equal.

Native visual inspection found Toll +1 clearly in Bog017 frame 5 and pending
+2/+2 clearly in frame 6 after the layer repair. The initial pending receipt was
partly covered by its spark, so its Bog renders were superseded. See
`process-history.md` for the two harness failures and accepted run chronology.
