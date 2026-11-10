# Uniform samples plus lunge peaks

Captured on production **4c5c2900**: Bog017/025 and combat_mid045 at ×1, ×4
and reduce motion after the follow-up combat repairs. All nine sheets have
**nine frames**, for **81 native frames** total: eight uniform samples plus one
unique observed peak in each interval.
No before image is reshot and the existing cue-retirement packet is read-only.

Every interval preserves all eight original uniform ticks. Each unique observed
actor peak is appended, including each Pack partner; none of those original
frames can be replaced. Sheets use four native 1688×780 frames per row and as
many rows as the frame count requires. Eight-frame historical manifests remain
readable with their original layout and interpretation.

The manifest records the original uniform ticks, appended peak ticks, each
actor's actual observed position and all captured text nodes. A separate content
audit requires a live post-hit DamagePop number in combat_mid045 at ×1 and
reduce motion, with recipient, amount, opacity, image filename and native bounds.
This prevents a lunge-peak addition from silently losing the damaged Health read.
Native review confirms the retained **−5** and **−4** post-hit numbers in frame 2
of both combat_mid ×1 and reduce motion. The reduced-motion receipt is fading
(opacity 0.389), and remains visible. The manifest rectangles are logical Godot
canvas coordinates before viewport stretch, not native pixel bounds.
[Native receipt crops](post-hit-number-audit.png) are direct crops of those frames.

The two copied timing-only baselines retain their own source heads. The cleanup
comparison remains isolated from later combat changes. Final full-stream event,
order, model-state and hero-Health equality passed the assembler;
within-head discovery/replay ticks must also agree. A fresh cold-reader pass is
not claimed by this packet.

## Timing and content checks

| Fight / speed | Before cleanup | Cleanup after | Final source |
| --- | --- | --- | --- |
| Bog ×1 | 9.833333s | 9.725000s | 9.725000s |
| Bog ×4 | 6.558333s | 5.641667s | 5.641667s |
| combat_mid ×1 | 27.333333s | 25.766667s | 25.766667s |
| combat_mid ×4 | 22.000000s | 20.200000s | 20.200000s |

Both timing passes match. Source events, order, final model and hero Health match
the independently recorded before and cleanup-only heads. Replay event ticks
and return ticks match discovery within this final head. Latest Mire/Take/number
layering changes add no measured fight duration in these fixtures.

Native Bog017 review shows the pending +2/+2 clear above the spark, with the Toll
path drawn behind stat chips. The selected combat frames retain the self pause
marks and post-hit receipt; no uniform frame was removed to show the lunge.
`report.json` contains per-sheet appended ticks and content witnesses. Pack-aware
sampling/validation remains available, although these nine intervals each have
one actor peak. The accepted d400831e before images and earlier packets remain
unchanged.

`process-history.json` records the one accepted 27.9-second engine invocation at
01:23:28 UTC. It exited 0 before runtime release; no failed or timed-out attempt
contributed to this packet. All accepted focus and combat captures ran sequentially.
