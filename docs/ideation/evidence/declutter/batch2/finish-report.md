# Batch 2 finishing work

This follows the orchestrator's B2 plan-row call. No work is done on
`ideation/declutter`; it stays at `330ed2cd`. No pushes.

## Implementation

- The hand contains every card up to ten, without a picker replacing the rest.
  It keeps normal card sizes when Birds are away. Crowded columns fan so every
  stat numeral remains readable at rest; focus changes draw/input precedence,
  not the canonical hand index. Reader placement leaves the fan available.
  All hand stats remain visible, as the orchestrator explicitly requested.
- Exact Ring cohorts now travel between actual pockets rather than respawning.
  Both core emitters include moved count and exact source/destination Ring and
  slot totals in `ring_dance`; rules and RNG are unchanged. Playback copies the
  floor snapshot, updates the reader, preserves partial source piles/merges,
  restores on restart, settles on skip, and retires old travel at the next action.
  Recruit count transfers travel too; ordinary additions/growth retain sprouting.
  Reduce motion flashes the two endpoints without travelling between them.
- Shipped SHOP/BOARD/MINI portraits use 68% nominal face area, with fixed stat
  anchors and no new name/rule overlays. Legacy missing-art geometry is separate.
- Recruit actions now have a deterministic, nonblocking presentation clock for
  buying, selling, playing, three-copy merging, tier-up, swallowing and flying
  south. Core actions commit immediately. Unit/coin flights, receiver pulses and
  gold/tier rolls explain the action; no successful-action tutorial toast narrates
  the answer. Reduce motion uses source/destination changes without flight.

## Counts and tests at source freeze

The text-node word audit counts every letter-bearing visible tile token by zone,
including board/slot name strips; stat numbers are not words. All five packet
states and the shipped fan10 state have **0 shop/hand/board/scout tile words** at
**1688×780 and 1920×1080**. The new native packet adds every action's before/after
states. `tile-words.md` and JSON retain every word and its path; the legacy-only
fixture still reports its six/eight name words explicitly rather than hiding them.

The unchanged defined label-budget states remain overview 40, lobby 39, scout 30
and natural Birds 30. **The full ten-unit hand is the authorized edge case: 61
text nodes, zero tile words**, with all hand stat beads retained. No occlusion
filter or focus-only hiding was added to the counter.

Clean targeted run: **9 files, 59/59 tests, 6563 assertions, 34.997 s**, strict hook
clean, no script/runtime errors. It covers hand, Ring travel, actual seven recruit
actions in both motion modes, art geometry, words, the unchanged budget, phone
geometry, EOT motion and the migrated pass3 UI tests. Failed strict-test typing
attempts were repaired before that clean run. Native captures and final static
checks are recorded below when complete.

## Pending dependency

`hedgerow_marks.gd` is **pending until wave 2b merges into ideation/main**. That
file is absent from the integrated tree; it was neither copied from the other
worker's branch nor prematurely re-faced. The fresh cold reader remains external.
