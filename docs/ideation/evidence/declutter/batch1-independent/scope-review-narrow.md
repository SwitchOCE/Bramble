**Scope check: declutter batch 1, merge and four fixes (`8ded22c2..d400831e` on `ideation/declutter`)**

*[Saved by the orchestrator from the reviewer's final message, verbatim. The reviewer couldn't write the file itself.]*

The brief gave all three inputs: the target range, the owner's words (09e) and the approved plan text (plan v3 step 3 plus the two DECISIONS entries). I made no edits, ran no checkout and did not run Godot.

**Counts:** 20 keep, 1 cut, 0 simplify, 3 ask.

**Does it serve 09e? Mostly yes, with one step back.** The merge kept the combat screen wordless: no word chips and no result-panel text came back. The four fixes are motion cues that land and fade, which is what 09e asks for ("Animations should… capture how a game is and how it plays"). The wave 2a state was ported as marks instead of words. The step back is the kept-gain reserve: a portrait with a number that stays beside the board for the rest of the fight. That is a "static image that indicates where things are", the kind of thing 09e asks to reduce.

**Cut**
- **Kept-gain reserve stays on screen.** `combat_special_motion.gd:18-80` keeps a panel (portrait, fold mark and a "+A/+H" number) beside the board until the fight ends. Let the gain travel there, land and fade. Nobody asked for a standing reserve: DECISIONS only asked that the gain be seen going somewhere.

**Ask**
- **Every attack now lunges deeper, not just Pack attacks.** `combat_motion.gd:225` changes the overlap from 15% to 65% of the target for all attacks. The worker's note says only "both Pack partners make a deeper lunge". This touches attacker reads that already passed 57/57.
- **Bog Toll is now a standing number on the hero plaque all fight.** `combat_wave_motion.gd:57-101`. Wave 2a showed it only in end-of-fight text, and the recruit screen already shows Toll on the tribe portrait. Keep a live badge, or let the cue travel to the hero, pulse, and leave the total in the hero reader?
- **No screenshot shows any wave 2a port** (hourglass, kiss dots, Toll badge, Bog transfers). Neither reshot fight has gain_pending, bog_toll or kiss events, so the fresh reader will not see them. Plan step 3 asks for before/after screenshots for each batch.

---

## 1. PR report (facts)

**Schema / data.** None.

**Scheduled / background.** None.

**Features**

- **F1. Merge resolution (`55e0d8b0`).** Four files were hand-resolved: `combat_lanes_view.gd`, `combat_screen.gd`, `card_view.gd` and `test_review_tribes56_log.gd`. Wave 2a's chip block and `show_note` were dropped. Its helpers `card_for_uid`, `clear_dying_cards`, `sync_bog_state` and `bog_summary` were kept. The result-panel Bog Toll text was dropped.
  - Used by: `combat_screen.gd:445, 561, 566, 771`.
  - Stated reason: DECISIONS merge order, "wave 2a lands first, then declutter".
- **F2. Aura direction.** After an animated summon, stats events wait 0.3 s (`combat_screen.gd:462`, plus a settle check in `advance_playback`). Every sourced stat change also gets a landing ring that shows for 0.55 s, fades and is freed (`combat_motion.gd:345-355`).
  - Used by: the playback loop.
  - Stated reason: DECISIONS, "the Aura line has no direction".
- **F3. Joint attack.** A Pack attack now has a flight of at least 0.38 s and a contact of at least 0.48 s (`combat_motion.gd:33-56`). With reduce motion on, each partner holds a 42 px attack pose and then returns (`:195-204`).
  - Stated reason: DECISIONS, "a joint attacker doesn't lunge".
- **F4. Deeper lunge for every attacker** (`combat_motion.gd:225`, factor 0.85 changed to 0.35).
  - Stated reason: none for non-Pack attacks. The code comment cites only "the leading Pack unit".
- **F5. Kept-gain reserve.** This is an overlay Panel named `KeptGain_<uid>` with a portrait, a fold line and a number label. It sits left of the board in two columns, one per dead unit. It is never hidden or faded, and is freed only by `_kill_tweens` on restart or exit (`combat_special_motion.gd:18-80`).
  - Used by: `_permanent_reward` (`combat_motion.gd:521`) and `WaveMotion._pending` for dead targets (`combat_wave_motion.gd:34-54`).
  - Stated reason: DECISIONS, "a kept gain vanishes with the dead card". The persistence itself has no stated reason.
- **F6. Counter answer.** A counter's immediate_attack stores the target (`combat_motion.gd:833`). On that unit's next self-sourced stat change, a red sword travels to the target 0.7 s later (`:382-385`, `:537-545`).
  - Stated reason: DECISIONS, "Counter's cue was removed".
- **F7. Pending-gain hourglass.** On the combat face it is a folded tag with an hourglass and colored dots (`combat_face.gd:278-310`). The numeric tag is hidden in combat (`card_view.gd:742`).
  - Stated reason: DECISIONS, port "the pending-gain tag… without words".
- **F8. Kiss dots** use the configured period with modulo progress. They are drawn for any frog view (`combat_face.gd:56-76, 270-275`).
  - Stated reason: DECISIONS, port "Bog's kiss count".
- **F9. Bog Toll badge.** A moss Panel on the hero plaque with a splash glyph, a number, a transfer mote and a pulse (`combat_wave_motion.gd:57-101`). It is removed on restart (`combat_screen.gd:243-247`).
  - Stated reason: DECISIONS, port "Bog's Toll". The standing form has no stated reason.
- **F10. Hero reader shows the Bog Toll total** (`combat_screen.gd:673`). Same stated reason as F9.
- **F11. Unit reader kiss line** shows "Kisses n/period" (`combat_screen.gd` `_show_detail`, `card_detail.gd:364-371`). Same stated reason as F8.
- **F12. Source pulses and transfers.** Added for transform, the Mire maker, kissing frogs, and bog_pull, bog_bind and bog_hit_back (`combat_motion.gd:419-422, 795-796, 868`; `combat_wave_motion.gd:23-31`).
  - Stated reason: earlier DECISIONS, "every trigger starts at its source unit".

**External.** None.

**Config.** None.

**Public interfaces.** `CardView.pending_gain_point()` (`card_view.gd:731`), used by `WaveMotion._pending`.

**Internal machinery**

- **I1. New file `combat_wave_motion.gd`** (101 lines) routing gain_pending and the Bog events. Used by `combat_screen.gd:447, 449`.
- **I2. `restart()` creates a new CombatMotion** (`combat_screen.gd:238`), which resets per-fight cue state including `_counter_target`.
- **I3. Capture tooling.** `declutter_frames.gd` gains selected attack indices, a `reduce-all` option and a per-frame ancillary ≤ 10 assertion (`:345-347`). `declutter_strips.py` accepts partial manifests.

**Deleted.** The word chips and `show_note` from wave 2a's side of `combat_lanes_view.gd` (no callers remain). The expiring "+1" stat echo for dead units (`combat_motion.gd`, old `_permanent_reward`).

**Tests**
- `test_combat_wave2a.gd` is new, with 4 tests.
- `test_combat_face.gd` has 3 new tests.
- `test_pending_gains_ui.gd` has 2 tests changed from the numeric tag to the hourglass.
- `test_combat_declutter.gd`: the dead-reward test now requires persistence, and there are new Pack, Aura and Counter tests.
- `test_review_tribes56_log.gd` merge is the union of both sides.

**Evidence.** 15 strip sheets with manifests, the follow-up note and the README.

**Unrequested:** F4; F5's persistence; F9's standing form.

**Size**
- The merge has 4 hand-resolved files. The other wave 2a UI files match a clean 3-way merge byte for byte; I checked this with `git merge-file`.
- `ef32c119`: 1 file, +35.
- `7b7a5fb7`: 5 files, +259/−46.
- `8bc24d65`: 12 files, +506/−27.
- `d400831e`: 26 files, +10,493/−25, mostly manifests and JPEGs.

## 2. Verdicts

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| F1 merge resolution | keep | All wave 2a UI needs are carried (probe 1 below) | none |
| `ef32c119` verify note | keep | Reports compile 596/0 and 14 targeted files passing; I could not verify without Godot | CI gate |
| F2 Aura | keep | Ring fades after 0.55 s (`combat_motion.gd:350-355`); test `test_aura_has_a_directed_transfer…` | none |
| F3 Pack timing and pose | keep | Pose resets (`:202-204`); test `test_pack_leader_and_joiner…` at ×1, ×4 and reduce | none |
| F4 deeper lunge for all attacks | **ask** | `combat_motion.gd:225` is unconditional; the note says Pack only | Limit to joint attacks, or confirm and tell the reader |
| F5 kept-gain reserve stays to fight end | **cut** | No hide or fade in `combat_special_motion.gd:18-80`; tests require it to stay (`test_combat_declutter.gd:424`, `test_combat_wave2a.gd:89`); strip `combat_mid-x1/attack-075` frame 8 still shows "+1/+1" two attacks later | Keep the travel and landing; fade after landing; drop the column stacking; flip the two assertions |
| F6 Counter sword | keep | Test `test_counter_answer_follows_its_self_gain…` | See the gap below |
| F7 hourglass | keep | Like-for-like wordless port of wave 2a's standing tag; adds 0 labels (`test_combat_wave2a.gd`) | none |
| F8 kiss dots | keep | Wordless port of the "Kiss n/m" chip | none |
| F9 Toll badge | **ask** | Standing all fight; counts 1 label per side (`test_combat_wave2a.gd:113`) | Orchestrator decides the form |
| F10 Toll in hero reader | keep | Shown only on tap | none |
| F11 kiss line in reader | keep | Shown only on tap | none |
| F12 source pulses and transfers | keep | All transient; test `test_dropped_action_chips_retain_a_held_source_cue…` | none |
| I1 `combat_wave_motion.gd` | keep | File split like the existing Special and LanesView files | none |
| I2 new CombatMotion on restart | keep | Clears stale cue state on replay | none |
| `pending_gain_point` | keep | Used by `_pending` | none |
| I3 capture tooling | keep | Needed for "a fresh reader checks only the reshot moments" | none |
| Reshot strips | keep | Cover Aura (rival event 30), Pack (mid 36), kept gain (mid 52) and Counter (mid 73-75) | none |
| `test_combat_wave2a.gd` | keep | — | Flip line 89 with F5 |
| `test_combat_face` additions | keep | — | none |
| `test_pending_gains_ui` word-to-cue changes | keep | Renamed and stated in the note. Overlap check dropped `_chip` and `_tier_badge`, both hidden in combat (`card_view.gd:492, 662`) | none |
| `test_combat_declutter` changes | keep | New Pack, Aura and Counter tests are sound | Persistence assertions follow F5 |
| Follow-up note and README | keep | One claim understated (F4) | Correct it |
| No screenshots of the wave 2a ports | **ask** | No gain_pending, bog_toll or kiss events in either reshot fight | Capture one Bog fight, or accept untested |

## 3. Gaps
- **Counter cue can go stale.** If a counter has no self-gain (bonus 0, e.g. the pass-2 `jenny` mechanic in `tests/core/data/pass2_bog_units.json`), `_counter_target` is never cleared. A later, unrelated self-gain then draws a red sword at the old target (`combat_motion.gd:382`). Fix: clear it on the next attack.
- **No test bounds the kept-gain labels.** There is one label per dead unit with a gain, so the count is unbounded and can pass the 10-label cap. Only the two pass-2 fights are checked. This goes away if F5 fades.
- **Skip to end is inconsistent.** A pending gain on a dead unit creates the reserve panel without animation (`combat_wave_motion.gd:54`), but a permanent reward does not (`cue()` returns before `_permanent_reward`).
- **Wrong portrait key.** `kept_gain` uses `def_id` and ignores wave 2a's `portrait_id` override (`card_view.gd` `_refresh`).

## 4. Probes
1. **The merge lost nothing wave 2a needed.**
   - The gain_pending sync, the dying-card lookup, the Bog state sync and the dying-card cleanup are all present (`combat_screen.gd:445, 561, 566, 771`).
   - Wave 2a's kiss sync is covered by the existing `"kiss"` branch (`:424`).
   - The Toll text came back in the hero reader (`:673`).
   - The removed helpers have no callers left.
   - Wave 2a's `_sync_unit` set_statuses and turns_shown calls were replaced by `show_unit`, the declutter's existing approach.
   - The merge message says it dropped "wave 2a's word chips", but most of those chips predate wave 2a. Wave 2a only changed the Kiss chip's format.
2. **The four fixes do what DECISIONS asked.** Only F5 leaves a mark at rest. F4 goes wider than asked.
3. **The ports are wordless.** The new text nodes are the Toll number (1 per side, counted and tested) and the kept-gain number (F5). The budget is still enforced at rest (`test_combat_declutter.gd:73-88`, 0 extra labels) and on every captured frame (`declutter_frames.gd:347`). It is not enforced for the many-kept-gains case.
4. **The kept gain is a new standing element on the combat screen.** It does not fit 09e (cut above).
5. **No test was quietly loosened.** Every word-to-cue change is named in the note and in renamed tests. The dropped overlap keys are for parts hidden in combat.
6. **No owner misattribution in the five commits.** The note credits the Rules-page call to "the orchestrator's DECISIONS call". Outside the range: the DECISIONS line from ideation/main (`df9ed13e`) puts a paraphrase in quotation marks: "the main screen assumes a player who knows the rules; teaching goes in the tutorial." The note's actual words are "the player is assumed to know how to play the game when they're in the game environment." It credits the owner with direction they did give, not with a call, so it is not a cut, but it should quote the real words.

## 5. Open questions (orchestrator's call)
- Should deeper lunges apply to every attack (F4)?
- Should Toll be a standing badge during the fight (F9)?
- Should the wave 2a ports be shot and read before merge, or accepted untested?
