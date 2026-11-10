# Declutter batch 2 — implementation and evidence checkpoints

**Current checkpoint:** the recruit label gate now passes at both sizes: overview
40, lobby 39, scout 30, natural Birds 30. See [main integration and verified cuts](followup-main.md)
and [refreshed native evidence](focus-followup/README.md). The remainder below
preserves the original checkpoint and its historical limitations.

Started at d400831e on ideation/declutter-b2. Batch 1's requested follow-ups were
committed through cea9d0e2 and merged back at 593e0740. Nothing was pushed.

**The batch does not pass its deciding label criterion.** The gate counts every
visible nonempty text control, including stats, names and action captions, and
fails above 40. It passes the small recruit fixture and natural Birds but catches
the dense evidence states. No exclusions were added to make them pass. The layout
choice for a scout focus view is pending; no shop or lobby state has been hidden.

## Implemented

- Shop, hand, board and scout cards share the wordless face: stats, trigger glyph,
  targeting/defence marks and current numeric pips. Tier/tribe/rules/chip text,
  created edge, Egg glow, golden star and frozen caption are removed. Spells/items
  retain their cost. Shared portraits and Brock/Old Brock/Sable/Russet retain one
  short name; Agnes's name sits above the beads instead of underneath them.
- Board name strips, slot codes, grooves, Pass mark/preview and standing relation
  highlights are gone. Reader opening and spatial links pulse reach once; dragging
  leans recipients. Scout forecasts include native lent quarries and draw no
  standing links. Ring counts remain only for stacks on your own board; Nests are
  wordless and empty Eggs retain their stat beads.
- Recruit source glyphs, contiguous Touching hops, Pass seeds and bead rolls run on
  one deterministic clock. Pass is presented last while preserving actual applied
  deltas and final stats. Start-of-Turn queued gains roll the displayed beads with
  no +X pop and without mutating the canonical view. Frost wipes across offers;
  reduce motion uses flashes. Ring/paint changes sprout/wipe. Reel-Mistress's Ring
  move currently re-sprouts at its destination rather than travelling between slots.
- Reader keeps rules and exact state, folds Golden/Created into linked type text,
  moves examples to Details, removes action guidance and duplicate price notes,
  and floats on PC. Gold remains visible on phone with the reader open.
- Necessary early HUD cuts remove lobby names, default-income words, Gold's word
  and acorn pile, leaf captions, hero name, duplicate Scout/Who tokens and the
  End-turn subtitle. The standing numeric state remains counted.

## Documentation changes and reasons

- Rulebook 12.1.6 says **rightmost** and no longer promises a permanent Pass mark or
  selection preview. The recipient rule is unchanged; geometry supplies the read.
- Wording guide lines 12–13 puts rules in the reader/Discover rather than always
  on a tile. Line 73 makes reader opening/spatial-link taps pulse reached slots,
  replacing a held selection highlight. This follows 09e's experienced-player rule.
- `keyword_rules.gd` Behind/Touching reminders describe physical geometry without
  slot codes. The authoritative schema Pass reminder says "your rightmost unit,
  other than this". Reminder precision stays in the reader, not on the board.

## Evidence and limitations

`pairs.json` has ten pairs at 1688×780 and 1920×1080, full counted-node lists,
identical serialized-state hashes, pocket dimensions and native-pixel calm masks.
The six original before PNGs are preserved byte for byte. Overview, golden
Reel-Mistress and natural Birds use the saved wave1 states. The historical
strong-field v1 library is unavailable at d400831e: lobby/scout are explicitly
labelled reconstructions from the recorded seed-72 fight/standings and saved
shop shell, replayed exactly before/after. They are not claimed to reproduce the
original historical full screen.

Current native still counts, at both sizes:

| Scenario | Before phone / desktop | After | Cap 40 |
| --- | ---: | ---: | --- |
| Overview | 134 / 135 | 59 | FAIL |
| Natural Birds | 103 / 103 | 39 | PASS |
| Reconstructed lobby | 127 / 128 | 55 | FAIL |
| Reconstructed scout | 136 / 136 | 64 | FAIL |
| Golden Reel-Mistress reader open | 145 / 135 | 68 | Report only |

Pockets keep their width and spend the freed vertical strips on height:
209×189 → 209×229, or 180×163 → 180×203 beside the phone reader. Both rows gain
40 px each; widening the pockets instead caused desktop overlap and was corrected.

The calm-space report is an auditable **free-surface proxy**, not a perceptual
score: it unions visible card, text, art, badge and control rectangles and counts
remaining native pixels. It includes quiet tray surfaces, excludes no text, and
records its limitations in `pairs.json`. It does not establish the perceptual
35–40% target or reproduce the earlier audit's subjective 20% estimate.

Final strips/contact sheet and targeted run results are recorded below as they finish.
A fresh cold reader of batch 2 is still required. The 40-node gate remains failing
on dense states, so this is not a completed or merge-ready batch.

## Final capture packet (production 8ef164b5)

Six strips in `strips/` contain eight evenly spaced native 1688×780 frames each,
assembled into 6752×1640 sheets. The End-of-Turn fixture uses real RecruitRules,
a real Mr Crumb Pass and a clearly test-only End-of-Turn variant of Standing
Committee's Touching effect. It replays the same real event stream at all speeds
and verifies final displayed beads against core results. Scouting uses native
Old Brock lending a displaced quarry: the reached pocket is 5, while straight
across pocket 2 stays unlit. The pulse clears in all modes. These strips are WIP
with **49 End-of-Turn / 52 reader-reach labels**, so they do not cure the budget
failure and no fresh cold-reader pass is claimed.

| Cue | ×1 | ×4 | Reduce motion |
| --- | ---: | ---: | ---: |
| End of Turn | 0.76 s | 0.19 s | 0.45 s |
| Scout reach | 0.40 s | 0.10 s | 0.40 s |

`all-unit-board-faces.jpg` shows all 157 units using the actual CardView at
189×212 canvas px; 54 retain fallback names. Nominal art rectangles average
66.09% of the face, but the distribution misses the uniform target: named faces
average 44.47%, others 77.42%. Keeping names clear of stat beads takes space on
shared-portrait cards. This is reported rather than scored as a card-face pass.

Calm-space proxy percentages (definitions and masks are in `pairs.json`):

| Scenario | Phone before → after | Desktop before → after |
| --- | ---: | ---: |
| overview | 44.7% → 50.5% | 35.7% → 40.1% |
| natural-birds | 49.4% → 55.6% | 41.9% → 48.6% |
| lobby | 45.2% → 51.5% | 39.7% → 44.4% |
| scout | 52.1% → 63.2% | 44.8% → 52.5% |
| reader-reel_mistress-golden | 30.5% → 35.6% | 35.1% → 35.1% |

## Pinned-text test migration

Of the spec §5 list, `test_cards.gd` now checks reader rules, wordless art/cost,
fallback names and clear stat beads instead of tile rules/chips/name/type rows.
`test_polish.gd` checks real tile absence plus retained reader rules rather than
RULE_TAGS coverage and the Ability fallback. `test_engines.gd`, `test_full_game.gd`,
`test_look.gd`, `test_milestone_b.gd`, `layout_check.gd`, `shots/playthrough.gd` and
`tests/core/test_full_games.gd` were not changed in batch 2: their surviving
assertions do not require removed visible tile text. LayoutCheck's clipping
checks remain enabled. Its broader screen checks still need completion.

Additional migrated files cover Pass/slot wording, Ring/Nest state, pending gains,
Bog/lender pips and reader details: `test_clarity`, `test_slice_display`,
`test_content5_horseshoe`, `test_combat_face`, `test_pending_gains_ui`,
`test_pass2_ui`, `test_pass3_ui`, `test_pass3_bog_ui`, `test_round4_finish`,
`test_nest_tile`, `test_ring_badge_layout`, `test_phone_layout`, `test_lane_display`,
`test_followup_tribes56`, `test_review_lender_tags`, `test_review_bog_preview`,
`test_held_view` and `test_feedback5_details`. Several need a clean final rerun;
passing files and remaining failures are recorded in the run-results section.

Outstanding: the dense-state label cap; a fresh cold reader; uniform art share;
Ring travel between slots; completing clean targeted regressions and the surviving
reader/state interaction sweep. Batch 3 still owns the full away-token/hand/lobby
redesign. No external comparison-game images or fresh visual-tier score were made.

## Final targeted results

All final files below ran sequentially through the worker slot wrapper with the
strict hook. They produced **no script/runtime errors**. The red assertions remain
red; no budget exclusions or geometry assertions were weakened.

| File | Tests passing | Assertions | GUT time |
| --- | ---: | ---: | ---: |
| `test_recruit_declutter.gd` (new) | 4/6 | 60/68 | 4.623 s |
| `test_recruit_motion.gd` (new) | 5/5 | 55 | 0.508 s |
| `test_scout_reach.gd` (new) | 4/4 | 14 | 2.724 s |
| `test_cards.gd` | 15/15 | 3520 | 3.310 s |
| `test_phone_layout.gd` | 9/11 | 189/193 | 3.015 s |

Budget counts at both sizes: slice recruit 37, slice scout 49, seeded recruit 33,
overview 59, natural Birds 39, reconstructed lobby 55 and scout 64.
`budget-test-results.json` retains the exact counted-node lists;
`targeted-test-results.json` records the final file runs. Phone findings concern
reader/action-column bounds and Posset counter bounds/intersections with the stat
bead rectangles; these need geometric review rather than silently dropping the
assertions. An earlier broad targeted pass had compile-cascade failures while the
helper was being corrected, so it is not claimed as a clean gate. Several migrated
files passed individually (including polish, combat face, pending gains, Nest and
Ring checks), but the remaining broad files need a clean final rerun. The full gate
was not run, as directed.

Final production source is **8ef164b5**; subsequent edits are capture/report/test
evidence only. No code was pushed. The work remains on ideation/declutter-b2 for
continuation after this turn's time limit.
