# Declutter batch 1 scope review (10 Nov 2026)

Fresh scope reviewer, range 1ecbce6..4f50d944 on ideation/declutter. Verbatim report.

# Scope review: `ideation/declutter` 1ecbce6..4f50d944 (declutter batch 1, "fights read by motion")

**Inputs:** I had all three: the owner's words (09e, 09f, 09i), the approved plan (`docs/ideation/ui-declutter-spec.md`) and the target range. Your call to judge batch 1 on source and effect only is an orchestrator call, so I treated it as one, not as owner direction.

**Counts:** 22 keep, 3 cut, 2 simplify, 3 ask.

**Does it move the original problem?** Partway, as planned.
- **Combat screen: fixed.** The targeting arrows, hunter lines, THIS HIT panel, captions, slips and result panel are gone. Combat labels went from 88–91 to 24–28, and all of them are numbers. The strips show lunges, hit pops, rolling numbers and deaths carrying each fight.
- **Recruit screen: not yet.** The "diagonals on the board" the owner named are the recruit grooves, which are batch 2 and still there. Recruit only got the free cuts.

**Cut:**
1. **Mud bar hides the numbers on Mired units.** `combat_face.gd:147-150` draws a mud bar across the Attack and Health numbers. You can see it on own F2 in `after/rival-fight_*.png`, and on own B1 and B2 in the `combat_mid` strips. The mud strip under the pocket (`lane_overlay.gd:97`) already shows the same state. Remove the bar or move it below the numbers.
2. **Nest twig ring drawn over units.** `slot_marks.gd:354` now draws the ring over an occupied pocket in combat, and SlotMarks sits on top of cards (z_index 3). In `after/homecoming-following-combat_*` it crosses the Swallow's 18 and 20. This is batch 2's row 2.2, done early, and the spec asks for a "rim inside the pocket edge", not a circle over the card face.
3. **The criterion is credited to the owner.** README.md:57, :62 and :413 and cold-reader-review.md:3 and :73 say the owner confirmed or approved the source/effect criterion. It was your call. Reword those lines and log the call in DECISIONS.md. Nothing there currently records that §6 item 7 was narrowed.

**Ask:**
1. **Label budget has no headroom.** A full board is 28 stat numbers plus 2 Health numbers, exactly 30, and `test_combat_declutter.gd:83` asserts exactly 30. Any held count, Hex or trap number on a full board makes it 31 or more. Batch 2's per-unit name rule adds more: 50 of 157 units still share a tribe portrait, and §7 counts their names. Raise the budget, exempt state numbers, or change the name rule before batch 2.
2. **Trigger glyph on units whose trigger can't fire in a fight.** `combat_face.gd:98-108` shows the spark for any trigger text. That includes End of Turn, Start of Turn and "after you cast" units, roughly 36 of 157 by my text match. In a fight these never pulse, so they're a standing rule mark. The spec says "spark for any trigger". Should combat show it only for triggers that can fire in a fight?
3. **Merge order with wave2a.** Wave2a conflicts with this branch in 4 files, and the conflicts are about substance, not just text. Wave2a adds "Kiss n/period" chips, a "+A/+H" pending-gain tag on combat tiles and "Bog Toll" text on the result panel, all on surfaces batch 1 removes. The new combat face also draws a fixed 3 kiss pips. Whichever branch lands second has to port these into the face and motion, without words. Decide the order and who does the port.

**Clear to merge into ideation/main at 4f50d944?** Not yet. The merge itself is clean. Fix the 3 cuts first: two are small drawing fixes, one is wording plus a DECISIONS entry. The asks are your calls and don't block this merge, but ask 3 must be settled before wave2a or this branch lands second.

---

## Q1. Batch 1 done-list

| Item | Result |
|---|---|
| No words and no lines at rest | **Pass.** None of the 8 after pairs has a label containing a letter. Links, grooves and the pack bracket are off in combat mode (`lane_overlay.gd:40`, `board_view.gd:332`). |
| Fights read by motion | **Pass** from the strips I viewed (combat_mid ×1, rival ×4, combat_mid reduce motion, homecoming ×1): travel, contact pops, rolling numbers, death fall, Belly release. Exception: in Mire fights the mud bar hides the numbers (cut 1). |
| Label budget ≤ 30 | **Pass** at 28/28/24/26. The full vole board in the test is exactly 30, so there's no room left (ask 1). |
| MIN_FONT and tap minimum | **Pass.** The layout check is clean on full boards at both sizes. My render probe found no layout problems for the reader, pause menu and log page at both sizes. Controls are 122 on phone and 90 on desktop (`combat_screen.gd:220`). See the gap on the reader covering controls. |
| Tests updated for removed strings | **Pass.** No test or source file still refers to the removed panels, tags, chips or the Continue button. |
| Full gate | **Pass.** I reran `./scripts/check.sh` on a `git archive 4f50d944` copy: all 11 steps pass, 1,901 of 1,901 tests. |

## Q2. §6 criteria

- **1. Words at rest:** 0 words. Counts went 88→28, 89→28, 82→24 and 91→26. Pass.
- **2. Lines at rest:** 0. Pass.
- **3. Every mark passes the three tests:** mostly.
  - These pass, each showing changing state or a spec-kept keyword: numbers, hurt rosehip, held-count pip, kiss pips, Mire reeds, Quarry claw, Swoop wing, quarry paw, pocket mud strip, Shield, Shell, Nightshade, Waiting, Warned, First Bite, gilding, Ring dots, Rainbow band, Hex sign with number, trap stake with number, hero portrait with Health, speed chevrons.
  - These fail: the Mired bar (repeats the pocket mud and hides the numbers), the Nest twig circle over the card face, and glyphs on triggers that can't fire in a fight (ask 2).
- **6. Phone floor:** pass.
- **8. Timing:**
  - Return to recruit within 1.6 s of the last death is tested (`test_combat_declutter.gd:244`). By the code it's about 1.3 s at ×1: 0.3 s death hold plus 1.0 s return.
  - Single cues are 0.4 s or less, except death at 0.5 s with the fall (the spec allows this) and the damage pop at 0.52 s (the spec's own number).
  - End of Turn and Start of Turn sequences are batch 2, so not applicable.
- **9. Reduce motion:** one fight (combat_mid, 11 attacks), as the checks ask. The source flashes, then the target, then the −N pops, with no words. The attacker's flash shows in one of eight frames, and both hit pops also show which two units traded. Pass, with the same mud-bar defect.

## Q3. Hidden information

- **More than one tap:** only the full log (gear, then Log), which is where the spec puts it.
- **One tap away:**
  - Quarry pairs: tap the quarry and the reader says "Quarry of: …".
  - Statuses, including Stalled, are listed in the reader.
  - Hex and trap amounts on empty pockets: tapping a marked pocket shows its note.
  - Opponent identity: tap the hero portrait.
- **Names:** combat tiles at the base had no names either (checked in the before label JSON), so nothing was lost there.
- **Dropped without a replacement on screen:** the damage formula, cap and toll note (still in the log) and "Skips: reason" (the reader shows the status but not the reason). Both are minor.
- **The real hidden information is a defect:** the numbers on Mired units are under the mud bar (cut 1), and on Nest units they're crossed by the twig ring (cut 2).

## Q4. Strong-field mode

- **What I could check:** no combat code reads the strong-field flag; the only differences are side names and the hero portrait lookup. The rival-fight still and strips were rendered with the flag on (`pairs.json`: `field_enabled: true`). Brother Bracken's portrait shows, the reader shows "Rival 4 · Brother Bracken" (`test_field_presentation.gd:33`), and auto-return works. It works, apart from cut 1 on own F2.
- **Not proven:** the whole app flow with the flag on. `tests/ui/shots/strong_field.gd` was edited for auto-return but can't run, because no field library is in the tree (the README says so). The own Health hidden on the rival still is an evidence limit, not a product bug.

## Q5. Scope

- **Core, content and sim:** the diff touches only `docs/ideation`, `src/ui` and `tests/ui`. Nothing under `src/core`, `content/` or `tools/`.
- **Outside batch 1:**
  - The Nest twig ring in combat (batch 2's row 2.2, cut 2).
  - The reduce-motion subtitle rewording (§2.7, batch 4). It's one line and keeps the setting truthful, so keep.
- **Gold-plating:** nothing significant. The evidence tooling is 818 lines across 10 scripts, all of them used to produce the spec's matched pairs and strips.

## Q6. Merge conflicts

- **Against ideation/main (7f07d0a0):** clean, result tree 2daacf2e. Main's changes since 1ecbce6 are bots, sim and core tests, with no UI.
- **Against ideation/wave2a (04b95d32):** conflicts in `combat_screen.gd`, `combat_lanes_view.gd`, `card_view.gd` and `tests/ui/test_review_tribes56_log.gd`. `recruit_layout.gd` and `recruit_view.gd` merge automatically. What the conflicts mean is in ask 3.

---

## Inventory (pr-report, condensed)

- **Schema/data:** none persistent. In memory:
  - CorePort keeps the floor marks and both heroes' Health before and after for the human's last fight (`core_port.gd:21-23, 182-214`), returned by `get_last_combat()`. Read by `combat_screen.setup` and `combat_motion.result`. Reason stated in the README ("no marks are guessed").
  - CombatModel now marks which units started the fight and on which side (`combat_model.gd:149-150`). Read by the end-of-fight sparks. Spec anim 31.
- **Scheduled/background:** none. There's a 0.2 s hover grace timer (`combat_screen.gd:119-129`), used by the PC hover reader (spec 2.6).
- **Features** (each is spec §2.6 or §5 batch 1 unless noted):
  - Wordless combat face (`combat_face.gd`, `card_view.gd` combat_face).
  - Combat screen rewrite: hero portraits, control row, reader on tap or hover, auto-return.
  - Motion for anims 1–32 (`combat_motion.gd`, `combat_special_motion.gd`). Adaptations are listed at README.md:138-230.
  - Log page (`fight_log_page.gd`), the pause menu's Log and Watch again (`pause_menu.gd:45`), and Last fight and Watch again in the hero reader in combat and in recruit (`recruit_screen.gd:689-690`, app.gd `open_last_fight`). Replay no longer records the round twice (app.gd:188-195; the README says why).
  - Slot codes in the log only for same-named units (`combat_log.gd:161-172`).
  - Free cuts in recruit and settings.
  - How to play page 1 sentence.
  - Speed token with chevrons (a logged adaptation).
  - Pocket marks for Hex and traps.
- **External:** none.
- **Config:** none new. The speed token writes the existing `Settings.fight_speed`.
- **Public interfaces:**
  - CombatScreen gains signals `attack_started` (read by the evidence frames script only), `guide_requested`, `settings_requested` and `menu_requested`. It also gains `manual_playback`, `advance_playback` and `auto_return`, used by tests and evidence; the real `_process` also calls `advance_playback`.
  - RecruitScreen gains `last_fight_requested` and `watch_fight_requested`.
  - New widget switches: BoardView `combat_mode` and `set_trap`, SlotView `wordless`, LaneOverlay `combat_mode`. CardView gains `combat_face` and accessors for the glyph and the two number badges.
- **Internal machinery:**
  - A fight-observer wrapper that chains to and restores any earlier observer.
  - All tweens are stepped by hand on one clock, so strips and tests are repeatable.
  - Pack damage pops merge into one.
  - Two motion helper classes that read screen fields by name.
  - Evidence tooling.
- **Deleted:** the old combat panels, row tags, hand title and hint, the Board chip, "Changes save", the ghost toast and the combat word chips. Left orphaned and not deleted: `hit_panel.gd`, `attack_yarn.gd`, `row_tag.gd`, and `CombatLanesView.show_note`.
- **Unrequested:** the replay round-log fix (it supports Watch again), the per-card portrait for "no room" (a logged adaptation), and the Nest ring in combat (batch 2).
- **Size:** 157 files, +40,140/−1,078. Code and tests: 63 files, +3,622/−1,078. Docs and evidence: 94 files, +36,518.

## Verdict table (items not already listed above)

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Wordless combat face | keep | `combat_face.gd`, spec §5 | none |
| Combat screen rewrite and controls | keep | spec 2.6 | none |
| Motion anims 1–32 with logged adaptations | keep | README.md:138-230 | none |
| Speed chevrons | keep | DECISIONS.md:1285+ | none |
| Tap and hover reader, pocket notes | keep | tests at `test_combat_declutter.gd:121-186` | none |
| Auto-return | keep | `combat_screen.gd:697-700`, test :244 | none |
| Log page, pause Log and Watch again, hero reader actions, replay dedupe | keep | spec 2.6 | none |
| Log slot codes only for duplicates | keep | spec 2.6 | none |
| Free cuts, subtitle, guide sentence | keep | spec §5 | none |
| Hex and trap pocket marks | keep | appendix "Hex amount" | none |
| Label budget test | keep | `test_combat_declutter.gd:72` | see ask 1 |
| CorePort fight observer and extra fight keys | keep | read by `combat_screen.setup` and `combat_motion.result` | none |
| Starting-side flags | keep | read by result sparks | none |
| Hand-stepped tween clock, `attack_started`, `auto_return` | keep | needed for strips and tests | none |
| Pack pop merge | keep | README adaptation | none |
| Evidence tooling | keep | spec §5 checks | none |
| DECISIONS entry | keep | — | fix the wording per cut 3 |
| Dead code | simplify | no users | delete `hit_panel.gd`, `attack_yarn.gd`, `row_tag.gd`, `CombatLanesView.show_note` (`combat_lanes_view.gd:20`; it would crash if called), and the unused combat `pack` handling |
| Hero lookup | simplify | `app.gd:213` reads every content JSON from disk inside the standings loop on every fight start | load the heroes once, or use the port's library |

## Gaps

- **Reader covers the controls.** On phone the reader (x 1629–2159, y 28–1028) covers the gear, step and play buttons while a fight is paused for reading; only Skip stays visible. Tapping the background closes it. On PC it covers the top half of all four buttons. Probe image: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-declutter/probe-out/reader_1688x780.png`
- **No skip reason in the fight reader** (spec 2.4). Minor.
- **Wrong ghost name on replay.** Watch again from recruit takes the ghost's name from the next pairing (`app.gd:182-184`), so a replayed ghost fight can be labelled wrongly. Minor.
- **Gate not run on the merged tree.** I ran it on 4f50d944, not on the merge with main; main's changes since the base touch no UI.
- **Not judged (item 7 belongs to the cold reader):** a damage number on an attacker stays where the hit landed. In the rival ×4 strip, attack 25, Dollop's −16 floats over own F2 after Dollop dies.

## Files

- **Gate log:** `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-declutter/gate.log`
- **Probe log:** `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-declutter/probe.log`
- **Crops showing the cuts:**
  - `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-declutter/rival_own_crop.png`
  - `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-declutter/strips/mid021-f0-backrow.jpg`
  - `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-declutter/home_f4.png`

I deleted the temporary project copy, and the worktree is untouched.