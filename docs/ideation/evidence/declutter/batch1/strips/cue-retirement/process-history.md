# Capture process history

Two failed final-capture attempts produced no accepted images:

- **10 Nov 2026 00:33:41 UTC:** new peak-observer code failed strict GDScript
  typing checks (Variant-to-float arguments and an untyped duplicate call).
  The inherited script then could not initialize. Its owned 90-second timeout
  ended at **00:35:11 UTC**, exit 124.
- **00:35:34 UTC:** the corrected script completed its timing passes, then a
  ternary array could not be assigned to Array[int]. Its owned timeout ended at
  **00:37:04 UTC**, exit 124. The selection now uses typed append calls.

Both process exits were confirmed before another Godot process was launched.
There was no overlap. The strict check-only preflight between attempts passed;
the second failure occurred during runtime assignment rather than parsing.

A subsequent capture completed all nine sheets and passed event, state, timing
and peak checks. Native visual inspection then found the pending +2/+2 receipt
under its spark. Root fixed the number's z-index and added a regression test;
Wave2a's nine targeted tests passed. Only the six Bog sheets were reshot, retaining
the three unaffected combat_mid sheets. No old packet or before PNG was reshot.

All Godot invocations used GODOT_SLOT_CLASS=worker scripts/godot_slot.sh, with
XDG data/config/state under /tmp. Logs are under build/declutter-retire/; the slot
CSV is /tmp/declutter-retire-state/bramble/godot-slots.csv. Capture logs and exact
source revisions are reported in the manifests. No process from the failed
attempts remains running.
