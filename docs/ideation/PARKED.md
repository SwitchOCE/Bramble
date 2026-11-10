# Parked work (10 Nov 2026)

*[Build 9 was shelved by the owner on 10 Nov (note 10j) for a look-and-feel phase. Its three branches are the `b9` rows.]*

The owner ended the ideation run at build 8 (owner note `2026-11-10g`). Work that build 8 doesn't need stays on its branch, one line each.

| Branch | Tip | State |
|---|---|---|
| `ideation/quilboar` | 25fc1576 | Quilboar reference-tribe benchmark (H1 harness). Its lessons are on main (`reference/quilboar/lessons.md`). Setups D1, D4 and D5 never ran. |
| `ideation/portraits3` | 99374707 | Every shipped portrait is on main; a small `tests/ui/test_portraits.gd` and prompt-file difference was never merged. |
| `ideation/ooze-cut` | 51cbf7f0 | The Ooze tail cut, stopped by note 10h. Its Soup-at-a-fifth arm shipped in build 8 at the owner's word; the rest is in the resume point below. |
| `ideation/declutter-b2` | b97d4644 | Batch 2's unsquashed history, kept only for its full evidence. Its content is on main as the squash 54d7fb78. |
| `ideation/b9-content` | 987d13ff | Build 9 steps 1–2. **Merged into ideation/main as ccdb79c6** (gate PASS): Ooze tail fixes (ceiling, Soak), Mallow feeds others, Sally spreads Rings. Open: the Fairy Ring line misses (R12 471 < 675). Resume from `evidence/b9-content/fairy-triage.md`. |
| `ideation/b9-measure` | 456b25e7 (WIP) | Build 9 step 3 plus A4, **not merged**. Holds: three Godot slots gated on free memory, provisional C, the A4 pipeline and its full 64-lobby B/C run (520edc73). B is healthy. C misses: Oozes 18,322, Hunters Open Season 4,463, Bog 90.9% field wins. The review's fixes are in (2a89e251, 00200291, 22310a62). The WIP commit holds the unfinished C repair (Ooze first fit, Hunters t 2.0, Bog Soak and Tiddy lowered); its C confirmation wasn't reported, and nothing past bcb8fcb1 is reviewed. Resume in `/home/alex/code/Bramble-ideation-b9measure` (Codex session 01a1c3f5-86b1-75e0-a50f-0525ea96809d): rerun the C confirmation, then one review and the gate of bcb8fcb1..456b25e7. |
| `ideation/b9-ui` | e8d2f1ab | Build 9 step 4, **no commits**: the worker hit Codex's output limit while reading code, before any edit. Not started: the Normal/Big preset setting and the strong field as default opponents (build 8 defaults to `"bots"`, and no export sets `strong_field`). Resume from `plan-build9.md` step 4, worktree `/home/alex/code/Bramble-ideation-b9ui`. |

Not started, and skipped for build 8 (from `plan-to-done.md`):
- **A4's full measurement** (150+ lobbies a preset), **A5's cuts** and **C's own fit.** Build 8 uses one smaller run that sets preset B.
- **Round 6 (A7)** and the checkpoint-1 cloud-tester round. Run alongside the owner's play, if at all.
- **Declutter batches 3 and 4,** B3, B4 and J1–J4.

## Resume point: the Ooze tail cut

**Why it started:** build 8's measurement run showed the Ooze engine line's R12 p90 at 116,519 (75.9× its median of 1,535), with R15 ÷ R12 at 22.0 against 2.4–13.6 for the other lines. Ooze tempo hit the 1-billion unit ceiling from R14 on seed 2911018. The probe's arm b, before A3 moved Stone Soup to tier 1, had a p90 of 4,367.

**Where it stopped (10 Nov, about 17:10):**
- Arm 1, Soup share 0.30 → 0.25 (sim `ooze-cut-soup-quarter-20261110`): engine R15 ÷ R12 fell from 22.0 to 3.92, with both Ooze R12 medians still over 900 (1,518 engine, 950 tempo). But the engine p90 stayed at 74,519, 49× the median.
- **The tail isn't mainly the Oozes' own dials.** A recruit trace (`ooze-cut-trace-20261110`) found two cross-tribe sources on the outlier seats. Hedgerow's Mrs Mallow, taken by Ooze seats, multiplies both bodies each turn (×9 growth). Bog's Soak brings gains in from an opponent: at R10 one Bridge Toad on an Ooze engine seat gained +127,941/+127,941 that way. In the worst seat, combat gains (2.2 million) far outweighed eating (0).
- Arm 2, Soup share 0.20 (sim `ooze-cut-soup-fifth-20261110`): its config is committed and its sim branch was pushed, but its result wasn't read.

**To resume:**
- Worktree `/home/alex/code/Bramble-ideation-oozecut`, branch `ideation/ooze-cut` (from `ideation/a35-run1` 480d2ee4).
- Evidence and its analyzer: `docs/ideation/evidence/ooze-cut/` on that branch (`analyze.py --baseline … --arm name=dir --trace …`).
- The Codex session that ran it: `01a1c3a0-4a33-7ed3-ae47-c44c04291831`. It also built the Ooze probe. Resume with `codex exec resume <id>` from that worktree.
- First question for whoever picks it up: is Mallow multiplying, or Soak importing an opponent's gains onto an off-tribe body, a rule doing what its text says? If either isn't, it's a bug, not balance. Only then decide whether the Oozes need a cut at all.
