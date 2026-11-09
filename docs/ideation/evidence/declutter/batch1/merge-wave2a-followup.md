# Declutter follow-up after wave 2a integration

## Part 1: merged-tree soundness

Input merge: `55e0d8b0`. No source changes were required. The first local compile
used stale global-class metadata; a worker-slot editor import refreshed it. The
subsequent `tools/checks/compile_all.gd` run loads **596 files, zero failures**.
All fourteen targeted UI files below pass with the strict hook, no risky/pending
tests or script errors. No tests were loosened or word-chip assertions changed:
these wave 2a chip tests exercise recruit cards, whose chips remain available.

| Targeted UI test file | Tests passed | GUT time |
| --- | ---: | ---: |
| `test_combat_declutter.gd` | 28 | 4.222s |
| `test_combat_face.gd` | 8 | 0.396s |
| `test_combat_pockets.gd` | 2 | 0.378s |
| `test_combat_relocate.gd` | 4 | 1.952s |
| `test_cards.gd` | 16 | 3.381s |
| `test_lane_display.gd` | 9 | 6.488s |
| `test_nest_tile.gd` | 5 | 0.439s |
| `test_review_tribes56_log.gd` | 9 | 4.004s |
| `test_followup_tribes56.gd` | 7 | 0.586s |
| `test_pass3_ui.gd` | 10 | 2.722s |
| `test_pass3_bog_ui.gd` | 5 | 0.972s |
| `test_review_bog_preview.gd` | 5 | 9.566s |
| `test_pending_gains_ui.gd` | 7 | 2.505s |
| `test_review_lender_tags.gd` | 6 | 1.255s |

Each file ran in a separate Godot process, sequentially, under
`GODOT_SLOT_CLASS=worker scripts/godot_slot.sh godot --headless -s addons/gut/gut_cmdln.gd -gconfig=res://build/declutter/<file>.json`.
Each generated config has empty `dirs`, one `tests` path, `should_exit:true`, and
`post_run_script:res://tools/checks/gut_strict_hook.gd`. Compilation and tests ran
in detached `bramble-declutter-merge-targeted2.service`. Logs are
`build/declutter/merge2-{compile,<test-file>}.log`; the job log ends
`merge_targeted_complete`. No full gate or cold reader was run.

## Part 2: four visual fixes

- Aura now waits for the summoned recipient's arrival to settle before choosing its
  destination. Its travelling source-to-stat route has an arrival arrowhead and a
  held ring on the recipient's changed bead, rather than only a ring on its source.
- Both Pack partners make a deeper lunge. The joint attack has a 0.48-second minimum
  approach so both are visible before contact, including at ×4. Reduce motion uses
  an instantaneous, held 42-pixel attack pose for each partner instead of travel.
  Separate damage contributions and the real retaliation target are retained.
- A dead unit's permanent reward travels to a retained recruit portrait outside the
  fighting pockets. Its numeric pending pair persists after the dead source fades;
  it is not a resurrected unit and has no current combat stats. This replaces the
  vanished stat echo the reader found ambiguous.
- Counter's self-gain finishes before a red sword transfer goes from the answering
  unit to the attacker it answers. The attack then follows. The former simultaneous
  gold link stays removed, preserving the unambiguous self-source of the stat gain.

Changed files: `src/ui/screens/combat_motion.gd`, `combat_special_motion.gd`,
`combat_screen.gd`, `tests/ui/test_combat_declutter.gd`, and this evidence note.
The existing dead-reward test now requires a persistent reserve landing instead of
an expiring echo. New tests check both Pack poses at ×1/×4/reduce, directed Aura and
its recipient landing, and Counter's ordered self-gain/answer cue.
Targeted `test_combat_declutter.gd`: **31/31, 273 assertions, 5.06 s**;
strict hook passes (`build/declutter/motion4d-test_combat_declutter.log`). Source
formatting/lint pass. No rule text was added to the resting board.
