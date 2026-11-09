# Capture process history

The first fixture probe failed the assertion “Bog moments belong to actual attack
intervals” and stayed alive until its 60-second timeout. The worker treated the
shell's Ctrl-C exit as cancellation of its child. That assumption was wrong: the
slot log shows that the failed child overlapped the successful fixture regeneration
and before capture. This violated the one-Godot-process-at-a-time rule.

The CSV records UTC start times and elapsed hold times, rather than end timestamps.
The failed probe started **2026-11-09 23:20:55 UTC**, held the `bramble-godot` slot
for **60.0 seconds**, and exited **124**, placing its timeout at approximately
**23:21:55 UTC**. Successful regeneration started at **23:21:28 UTC** in the other
slot. Thus the unintended overlap began at 23:21:28 and could have lasted up to
approximately 27 seconds; the accepted before-render process ran inside that
interval. No evidence from the failed probe is included in this packet.

These are the recorded successful runs; each accepted run completed before the
next accepted run began. This statement describes the accepted runs only and does
not erase the failed child's overlap:

| UTC start, 9 Nov 2026 | Run | Hold | Exit |
| --- | --- | ---: | ---: |
| 23:21:28 | Native Bog fixture generation | 1.0 s | 0 |
| 23:21:29 | Bog before, ×1 / ×4 / reduce motion | 14.3 s | 0 |
| 23:31:23 | Bog after, ×1 / ×4 / reduce motion | 14.2 s | 0 |
| 23:31:40 | Rival attack 025 and adjacent 033, ×1 / reduce motion | 12.0 s | 0 |
| 23:31:52 | Combat attack 045, ×1 / reduce motion | 8.1 s | 0 |

All successful runs used `GODOT_SLOT_CLASS=worker scripts/godot_slot.sh` and the
`bramble-harness-godot` slot. The source record is
`/tmp/declutter-bog-state/bramble/godot-slots.csv`; relevant values are preserved
above because `/tmp` is temporary. The accepted captures passed their event-stream,
within-head timing, native-dimension and label-budget checks. Their final logs have
no script errors. No capture processes remain running.

Future cancellation must confirm that the child has terminated before another
Godot process starts. This note was added without rerunning Godot.
