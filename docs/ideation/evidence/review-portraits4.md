## Scope review: `ideation/portraits4` (`91a5e443..0c3fd133`), re-rolled look-alike portraits

*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov. Calls: DECISIONS (ideation/main) "Look-alike portraits and gate shards: review calls".]*

**Counts:** 7 keep, 0 cut, 1 simplify, 2 ask.

**Does it move the original problem?** Partly. Brock, Old Brock, Sable and Russet now have portraits you can tell apart at 96 px. The last review counted five names in the dense states, and those names belong to exactly these units, so their names can now leave the tiles. This commit doesn't remove any names itself: that happens in w4's short-name list. Brother Wolf and Grizel still look alike. DECISIONS already says the 40-label gate also needs the other batch 2 pieces.

**Ask items:**
- **Brother Wolf and Grizel:** they were left unchanged and still look alike at 96 px. They have the same grey head, the same three-quarter view and the same tree-and-sky background; only the cloak colour and the hand differ. The approved plan says all four wolves "each get a silhouette or palette of their own". Re-roll one of them (probably Grizel), or keep both short names and log it?
- **Grey Agnes:** the new portrait reads as a white bear more than a wolf at 96 px. That misses her own prompt ("retain unmistakable wolf face, not a cat, bear or badger") and weakens the Pack-wolf link. Accept it, or ask the cold reader planned in open question 2 "what animal is this?" and re-roll if the answer is a bear?

All three inputs were in the brief: the target, the owner's words and the approved plan text.

---

## 1. What changed (PR report)

There is one commit, "art: distinguish look-alike unit portraits at board size", with no body. It changes 6 files: 5 JPEGs replaced and one 19-line prompt record added. The five JPEGs together grow by about 3 KB.

**Features** (all portraits are loaded by unit id through `src/ui/ui_theme.gd:78` `UNIT_PORTRAIT_DIR`, on tiles and in the reader. `tests/ui/test_portraits.gd` only checks that each file exists.)
- **`assets/portraits/young_brock.jpg`:** a badger cub facing front, in a big teal cap and a mustard tunic. A departing Hunter silhouette passes a gold spark into his paw. Stated reason: plan, "Brock and Old Brock … each get a silhouette or palette of their own at 96 px."
- **`assets/portraits/sable.jpg`:** a dark chocolate pine marten in a teal cape, holding a gold quarry token with a stag on it. A spark runs from the token to her shoulder. Stated reason: plan, "Sable and Russet".
- **`assets/portraits/grey_agnes.jpg`:** a pale, front-facing, round-headed figure in a green mantle. She shelters a small grey wolf, and an ochre blow splits against her forearm. Stated reason: plan, "the four grey wolves".
- **`assets/portraits/old_isegrim.jpg`:** a black wolf in right profile, in an ochre coat and navy cape, pointing at a far boar. A hare and a badger Hunter stand below. Stated reason: the same plan line.
- **`assets/portraits/squire_lollop.jpg`:** a hare in a plum coat, joining hands with two neighbours at the lower corners. The row of seven medallions is gone. Stated reason: plan, "Lollop's seven medallions go, since the new text no longer counts to seven."
- **Units left as they were** (prompt record line 6): Old Brock, Mistress Russet, Brother Wolf and Grizel. Nobody gave a reason for keeping the wolves, and the plan names all four.

**Internal machinery**
- There is no code change.
- **`tools/art/prompts/pool-portraits-lookalikes-10nov.txt`** is the prompt record: a header, a shared brief and five numbered items. No code reads it, and it follows the project's practice of keeping one prompt record per batch.
- **Export rule, line 4:** "lowest quality in 82–95 yielding at least 45,000 bytes". Nobody asked for this.

**Deleted:** Lollop's seven-medallion motif.

**None:** Schema, Scheduled, External, Config, Public interfaces.

**Unrequested:** keeping Brother Wolf and Grizel unchanged; the 45 KB size floor.

## 2. Verdicts

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Young Brock re-roll | keep | The cap makes a wide flat head outline. The view (front instead of three-quarter), the cub proportions and the teal/mustard palette all differ from Old Brock's maroon, so it isn't costume alone. Mechanic cue: a sold Hunter's spark passes into his paw ("When a Hunter beside this is sold: gain its stats permanently"). | None. He is the simplest, most cartoonish face in the Hunters set, and the round ears lean panda. Acceptable for a "Young" unit. |
| Sable re-roll | keep | A near-black marten with round ears, against Russet's orange fox with pointed ears. Mechanic cue: the quarry token plus a spark (Quarry, gains stats). | None |
| Grey Agnes re-roll | **ask** | Clearly distinct from the other wolves: pale and front-facing. But the broad round head, small folded ears and short muzzle read as a bear at 96 px, against prompt line 15. Mechanic cue fits "Your pack leaders take half the hit back". | Add the species question to the cold reader in open question 2 |
| Old Isegrim re-roll | keep | Black, in profile, with a long muzzle: unlike every other wolf. Mechanic cue: pointing at the far boar with two Hunters below ("hunt the biggest enemy, wherever it stands"). He reads more like a jackal but is still clearly a dog-like animal. At 96 px his head blends into the dark tree trunks behind him. | None |
| Lollop re-roll | keep | The medallions are gone, and the joined hands show "touching". At `0c3fd133` and on ideation/main his rules text still says "if all 7 touch"; the new text is only on `ideation/wave2b`. The plan ordered the removal anyway, and prompt line 7 flags the mismatch. The sparkle sits on his coat, not "at a joined hand" as line 19 says. | None. When to merge relative to wave2b's Lollop text is the orchestrator's call. |
| Old Brock and Russet left unchanged | keep | Each pair is now distinct because the other unit was re-rolled. | None |
| Brother Wolf and Grizel left unchanged | **ask** | The plan says all four wolves get their own look. `evidence/review-portraits3.md:40` already said they are "told apart mainly by cloak colour and pose", and that is still true. | Re-roll one, or keep both names and log it |
| Prompt record | keep | Matches the earlier records (e.g. `pool-portraits-10nov.txt`). It honestly records the second-pass Sable edit and the Lollop text gap. | None |
| 45 KB export floor | simplify | `tools/art/portraits.py:14` sets `QUALITY = 82`. Measured: Young Brock was saved at quality 86 and Sable at 88; the other three at 82. A minimum byte count does nothing visible. | Use `tools/art/portraits.py export` next time. Re-exporting these two is optional (a few KB each). |
| `.import` files and UIDs unchanged | keep | The diff touches no `.import` file. `sable.jpg.import` refers to the file by its path, so the existing `.import` files still match the new images. | None |

**Gap:** the plan's "four grey wolves" is only half done: Brother Wolf against Grizel.

## 3. Probes

1. **Told apart at 96 px:**
   - Brock and Old Brock: yes.
   - Sable and Russet: yes, by main colour and ear shape.
   - Grey Agnes and Old Isegrim: yes, against each other and against the other two wolves.
   - **Brother Wolf and Grizel: no.** Nothing changed for them.
   - Sheets: `/home/alex/code/Bramble-ideation-sol/build/art/pool-portraits-lookalikes/*-before-after-96.png`, and my own 2x view at `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/wolves96x2.png`.
2. **Identity:** all five match their unit's name, tribe and rules text in `content/units/<id>.json` at `0c3fd133`, and each has one mechanic cue. The exceptions are Grey Agnes reading as a bear (ask), and Lollop no longer showing the "7" that his current text names.
3. **Style:** all five use flat fills and bold outlines, with no fur strokes and no text. Contrast-stretched crops show only JPEG block noise, no airbrush gradients. They are as flat as the rest of the tribe or flatter. Young Brock is the simplest face in the set, and Old Isegrim the darkest.
4. **Files:** only the five JPEGs and the prompt record changed. All five are 512×512 and 45.5–53.3 KB. I didn't run Godot. The worker's log (`test-portraits-focused.log`) shows 6 of 6 tests passing with 325 assertions, but that test only checks each file exists, not what it shows.
5. **Owner misattribution:** none. The commit has no body, and the prompt record's "as requested" (line 7) doesn't name anyone.

## Open questions for the orchestrator
- Brother Wolf and Grizel: re-roll one in this step or in a follow-up, or keep both short names?
- Grey Agnes's species read: add it to the cold reader's check?
- Merge order against wave2b's new Lollop text.
