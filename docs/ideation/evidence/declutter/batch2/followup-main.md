# Batch 2: main integration and the remaining label cuts

This follows the orchestrator's 10 November call. `75318ec0` merges main through
`ce50d9d7`; `778f572a` adds its later review records through `326b4103`.
DECISIONS is taken exactly from that main revision. `ideation/declutter` remains
at `330ed2cd`; this work changes batch 2 only. No pushes.

## Changes and reasons

- Every shipped unit has its own portrait. Dead `SHORT_NAMES` entries are removed.
  Only Brother Wolf and Grizel retain names while their portraits remain the
  unresolved pair on the merged tree. The requested name policy is updated in
  spec §2.1 and its critique-call table. A later Grizel art merge removes both.
- Opponent tier knots no longer occupy the resting lobby. Every portrait opens
  an exact hero reader in one tap, including tier, Health and Last Stand state.
  Tapping Next still scouts first and then opens that reader inside focus.
- The away paragraph becomes a scrollable row of Bird portraits. Each travelling
  Bird has only a moon/countdown; a doorstep Bird has a closed-door mark. A tap
  opens its own exact current/homecoming stats, turns and Nest, and pulses that
  Nest. Every Bird remains available; no journey state is discarded.
- Ring pile digits move into the existing occupied/empty slot reader. Their frame
  still shows presence and sprout/shimmer motion still shows a change. Seven
  standing pile labels in the dense overview duplicated state already readable
  in one tap; removing them makes room for useful Bird countdowns.
- A standard spell/item cost or Acorn value of 1 moves to its reader/Buy action.
  Free and nonstandard prices, larger Acorn values and Poached prices remain
  visible. Variable tier-up prices, gold and End turn remain visible.
- Ooze ladle art repeats the largest-Ooze rule; Soup pots repeat already-buffed
  stat beads; held meal portraits repeat the held count and inside reader.
  These standing marks are removed. Exact state and resolved Nell/Aspic recipient
  names stay in the reader. New Elder shares pop beads and Soup bonus changes
  roll them on RecruitMotion's clock, without +X text. First paint and unchanged
  renders stay quiet. Reach pulses only when a reader opens, not on pointer entry.
- Tray construction lives with layout; recruit economy population is in the
  cohesive `recruit_hud.gd` helper. `recruit_screen.gd` is 986 lines and no longer
  disables the 1,000-line lint cap. The merge's orphan `_engine` assignment in
  TribeBonuses was removed; the incoming reference Gem chip remains supported.

## Verification at the implementation checkpoint

The unchanged gate counts every visible text node, including stats, hero Health,
names and controls. Original measured counts are overview 57, lobby 54, scout 35.
Final five-kind splits and actual counts await the queued Godot run; none are
inferred or claimed as passes. Both shared host Godot slots are occupied, so no
post-cut runtime result is available yet. An optional main-only baseline was
cancelled after finding the merge parse error; its failed import is not evidence.

Prepared targeted regressions cover portraits, exact reader state after each cut,
Ring piles, free/nonstandard prices, Bird token navigation, Ooze event motion and
initial-paint quietness. The old Ring test now requires exact counts in the reader
instead of a standing digit; the two old away paragraph tests require token
readers and access to the full scroll row. No fixture or budget exemption changed.

At this checkpoint: `ruff check tools`, `ruff format --check tools`,
`gdlint src tools`, `(cd tests && gdlint .)`, and
`gdformat --check src tools tests` pass (643 GDScript files unchanged by format).
Runtime and refreshed evidence results will be appended after the slot is free.
