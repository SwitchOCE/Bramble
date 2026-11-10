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


## Verified continuation (production 4c5c2900)

The gated portrait rerolls and main's gated batch 1 merge are now integrated,
through main `c6e554af`, at batch-2 merge `bb5b9e45`. Grizel's re-roll is present,
so both remaining name exceptions are removed. No shipped tile keeps a name.
DECISIONS exactly matches that main tree; the batch 1 branch stays `330ed2cd`.

The 40-node gate passes at **both 1688×780 and 1920×1080**:

| State | Unit stats | Hero Health | Names | Costs/controls | Other | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Overview | 24 | 8 | 0 | 3 | 5 | **40** |
| Lobby | 24 | 8 | 0 | 3 | 4 | **39** |
| Scout | 24 | 0 | 0 | 3 | 3 | **30** |
| Natural Birds | 14 | 8 | 0 | 4 | 4 | **30** |
| Reader open | 32 | 8 | 0 | 4 | 7 | 51 (reported separately) |

`budget-breakdown.md` and JSON retain all 16 rows and every node. All 14 resting
rows pass. The legacy slice includes 3/4 genuinely missing-art fixture names and
still counts them; no production portrait exception or text-node exemption was
added. Recruit tests pass 12/12 (255 assertions, 7.550 s); classifier 5/5
(263 assertions, 1.192 s). Refreshed native evidence is in `focus-followup/`.

### Sixth-reader additions on batch 2

- Mire's crossed-sword disc is replaced with two ink-rimmed pause bars above
  the attacker triangle, outside the portrait. Tests cover both sides and rows,
  normal and reduce motion, viewport bounds and cue lifetime.
- Take's two acorn reward legs now use the shared stat spark: rulebook 9.6.6
  pays queued stats, not gold. Motion timing is unchanged.
- Combat stat beads draw above transfer paths/motes, so a passing Toll head
  cannot cover another unit's Attack/Health chip. Damage pops draw above those
  beads and remain readable; a regression checks both ordering requirements.
- Strip capture preserves all eight original uniform frames and adds unique
  observed lunge peaks, instead of replacing a post-hit frame. The new packet
  is `../batch1/strips/uniform-plus-peaks/`; the accepted cue-retirement packet
  is unchanged. Each sample records visible text and actual damage-pop state.

`trigger-beat-timing.json` confirms the speed finding against recorded event
ticks and current source: Take→next event is **108 ticks / 0.9 s**, and Mire
wait→next attack **109 ticks / 0.9083 s**, at both ×1 and ×4. `_event_hold`
returns fixed 0.9 s for both; `_effect_barrier` also stores unscaled seconds
(Take 1.2, Mire 0.9). The new call requests a check; the earlier explicit call
leaves the speed-scheduling change for batch 3, so these waits were not changed.


## Final hand-off validation

Production and all new native captures are `4c5c2900`. The clean targeted pass
runs **14 files, 139/139 tests, 7837 assertions, 45.830 s**, strict hook clean,
with no script/runtime errors. Initial strict test typing and three old pinned
expectations were corrected before that final pass; their failed logs are not
claimed as clean checks. The newly created Away overflow test then gained one
cleanup frame to drain removed tokens; its standalone final run passes without
orphans. Older Card/Take/replay tests still emit GUT orphan warnings.

Current standalone timings for the new batch-2 test files:

| File | Passing | GUT seconds |
| --- | ---: | ---: |
| `test_recruit_declutter.gd` | 12/12 | 7.603 |
| `test_declutter_classifier.gd` | 5/5 | 1.228 |
| `test_recruit_motion.gd` | 5/5 | 0.486 |
| `test_scout_reach.gd` | 4/4 | 3.244 |
| `test_counter_layout.gd` | 1/1 | 0.460 |
| `test_away_tokens.gd` | 5/5 | 0.600 |

All required final static commands pass, including both full GDScript lint
commands and full gdformat. Ruff also checks the four changed Python capture
files explicitly. The latest main documentation merge is `ba464745` (main
`34d8397e`); DECISIONS matches it exactly. No core/production code changed after
the captures. No pushes or denied actions.

Final evidence: ten same-input before/after pairs at both requested sizes, six
recruit strips / 48 frames, the shipped 120-unit face sheet, and nine combat
sheets / 81 frames. All original eight combat samples survive plus each peak;
045 retains a live post-hit −5/−4 at ×1 and reduce. Source events, final states,
hero Health and fight timings match. Parent before/input hashes are unchanged.

This is a progress hand-off at the 45-minute limit. Fresh cold-reader scoring and
a new visual comparison/tier judgment remain external. The original batch's
full-hand fan, Ring travel between slots and uniform 65–70% art-share target
remain incomplete; current shipped art rectangles are about 77.4%. These were
reported rather than presented as passes.
