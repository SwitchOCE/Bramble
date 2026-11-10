**Scope review: `ideation/portraits3` (commit 99374707 on top of 5425c907), portraits for the last 13 pool units**

*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov. Calls: DECISIONS (ideation/main) "Portraits for the last 12 pool units: review calls".]*

**Counts:** keep 7, cut 2, simplify 0, ask 0.

**Does it move the original problem?** Partly.
- **Art on every unit:** done for the shipped game. Every shipped unit and every token it can create now has its own portrait. That meets Done means 5 for units.
- **The 40-label gate:** this step barely moves it. The plan says the portraits are "what's blocking the batch 2 gate". In batch 2's own counted states (`after/manifest-1688x780.json` at 344a5e75), this step removes one name per dense state ("Agnes"):
  - overview goes from 59 to 58
  - lobby goes from 55 to 54
  - scout goes from 64 to 63

  All three still fail the cap of 40. The other five names in lobby and scout (Brock, Brock, Old Brock, Sable, Russet) belong to four units that already have their own art. They keep their names only because reviewers confuse those portraits, and this step doesn't touch them. Also, 38 of the "54 of 157" fallback faces are old-library units that aren't in the shipped game.

**Cuts:**
1. **Revert the test-mechanism change in `tests/ui/test_portraits.gd`.** Restore the pending tribe-fallback path and `test_pending_portraits_name_only_real_cards`, drop `test_no_shipped_unit_portraits_are_pending`, and keep the list empty. No one asked for the change. It goes against the logged "Art sequencing" decision (DECISIONS:1671, "Remove completed entries in the art step"). It also wasn't needed: the old test already passes once the art exists.
2. **Drop the Slice copy:** `assets/portraits/slice.jpg` and its `.import`, `test_wave2b_slice_token_has_its_own_portrait`, and prompt item 13. Wave 2b already adds the identical file, and its own token test covers it (count 119 → 120). Leaving it is harmless (byte-identical, merges clean), but it is redundant.

**Asks:** none.

I didn't run Godot or the tests, and I didn't read the worker's `tests.log`.

---

## Probes

**1. Style: all 12 generated portraits pass.** I looked at the six 96 px contact sheets and every new asset at 512 px.
- All have flat fills, a bold black outer contour, a few hard flat shadows, no gradients or painterly texture, no text, and a clear silhouette.
- The fur and feathers are drawn only as jagged outline shapes, the same as the existing Brother Wolf and Grizel. That fits the owner's "solid fills, bold outlines and no fur/feather rendering".
- Small departures, none a failure:
  - The Lantern Man is the only dark background among the Bog folk, which suits a night spirit.
  - The Cuckoo's cream and grey sky is more muted than the blue skies of the other Birds.
  - The Lob-Lie's red brick hearth sits outside the Fairies' purple and teal backdrops.
- Size and import settings match the existing portraits: 512×512, 46–64 KB (median of the existing set 47 KB), import params identical to `aunt_aspic.jpg.import`, no duplicate uids among 219.

**2. Identity: each portrait shows the character plus one cue for its mechanic.**
- The cues: Lantern Man's light wedge on a mired silhouette, Ranocchio's tongue at mired prey, Agnes shielding a small wolf, Isegrim pointing at the biggest quarry, Pym passing an acorn, Clover's newborn, Mallow feeding a tiny mouse, Hayward pouring acorns into neighbours' paws, Lollop's chain of seven, Lob and Silky over mushroom rings. All 12 prompt rules texts match the shipped `text` fields.
- Near-twins at 96 px. These are watch points for the declutter reviewer, not failures:
  - Hunters now has four grey wolves (Brother Wolf, Grizel, Agnes, Isegrim), told apart mainly by cloak colour and pose.
  - Silky is the third grey-haired woman among the Fairies (with Queen of Elfland and Old Moth Annis) and the lowest-contrast face on the sheet.
  - The Cuckoo and Mother Goose are both grey birds with red scarves (Mother Goose has a witch hat).
  - Lob-Lie and Hob-in-the-Hearth are both hearth brownies, but their palettes differ.
- Wave 2b rewrites the text of Clover, Mallow, Hayward, Lollop and Pym. The pictures still broadly fit, except Lollop's seven-medallion motif: the new text no longer mentions 7.

**3. Inventory: the claim holds.**
- Slice-set cards with no `assets/portraits/<id>.jpg`, at 99374707: only `golden_egg` and `pelt`. Both are hand items with stated reasons: Golden Egg reuses `nest_egg` (`ui_theme.gd:212`), and Pelt wears its prey's art.
- All 119 slice-set units have portraits, including the token ids the code hard-codes: `prince_restored` (`bog_folk.gd:19`), `peatling`, `wisp` and `nest_egg`.
- Every token the cards reference has a portrait: acorn, stash, great_hoard, kit, nymph, shrewlet, drip.
- On `ideation/wave2b` (11:03, before this commit), the only new unit is `slice`. Combining this branch's portraits with wave2b's, nothing is missing. Quilboar was excluded as briefed.

**4. Slice: byte-identical.** Same blob on both branches for `slice.jpg` (`ad7b0f39…`) and `slice.jpg.import` (`1c424133…`, same uid). Wave 2b's only edit to `test_portraits.gd` is line 82 (119 → 120), which doesn't overlap this branch's hunks, and wave2b doesn't touch `portraits_pending.json`. The later merge is clean in either order.

**5. The test: the removal makes future pending art impossible without editing the test.**
- A future unit that lands without art now fails twice: in `test_every_unit_and_token_has_its_own_portrait` (fallback gone, old lines 50–52), and if it's listed as pending, in `test_no_shipped_unit_portraits_are_pending` (`test_portraits.gd:108`).
- `portraits_pending.json` stays and is read in `before_each` (lines 27–32), but its only legal value is now `[]`. That's a mechanism half removed.
- The logged decision keeps the list "while the requested engine → content → bots → UI → art order is in flight … This keeps art availability from blocking engine and content validation". Pass 3 is still in flight.
- The edit wasn't needed: the old path only falls back when the file is missing (`not ResourceLoader.exists(expected)`), so the old test passes with the new art and an empty list.

**6. Owner misattribution:** none in this diff. The commit message, test comments, JSON reason and prompt file credit no call to the owner.

---

## Report (what the change does)

29 files, +565 / −27: 13 JPEGs with 13 `.import` files, plus 3 text files.

**Schema / data**
- `content/portraits_pending.json:2-3`: `units` emptied (12 entries removed) and `reason` rewritten.
  - Used by: `tests/ui/test_portraits.gd:27-32` and `:108-109` only.
  - Stated reason: plan, "This removes the fallback names … (`portraits_pending.json` empty)".

**Features**
- 12 generated portraits, each with its `.import`, in `assets/portraits/`: cuckoo, lob_lie_by_the_fire, silky, lantern_man, signor_ranocchio, grey_agnes, old_isegrim, mr_pym, mrs_clover, mrs_mallow, goodman_hayward, squire_lollop.
  - Used by: `UiTheme.portrait_for` (`src/ui/ui_theme.gd:210-219`) on every tile, detail and plaque; also by `CardView.needs_name` on declutter-b2.
  - Stated reason: plan, "Portraits for every pool unit without its own art … built-in image tool, the existing flat style".
- `assets/portraits/slice.jpg` and `.import`, copied from wave2b.
  - Used by: `test_portraits.gd:112-116` only. No Slice unit exists on this branch.
  - Stated reason: none in the plan. Orchestrator brief (proposal): inventory includes "the pass 3 Oozes on `ideation/wave2b`".

**Internal machinery**
- `tools/art/prompts/pool-portraits-10nov.txt`: prompt record (header plus 13 items; item 13 describes Slice, which this prompt never generated).
  - Used by: nothing; it's a record.
  - Stated reason: none stated; it follows the CLAUDE.md convention of keeping prompts in `tools/art/`.
- `test_portraits.gd:108-109`: new emptiness assertion.
  - Used by: the test suite.
  - Stated reason: none stated.
- `test_portraits.gd:112-116`: new Slice test built on a hand-made def.
  - Used by: the test suite.
  - Stated reason: none stated.

**Deleted**
- The pending fallback in `_assert_own_art` (old lines 50–52). Stated reason: none.
- `test_pending_portraits_name_only_real_cards` (old 111–118). Stated reason: none.

**None:** scheduled/background, external, config, public interfaces.

**Unrequested:** the Slice copy and its test, the emptiness test, the two deletions, and the prompt file (a convention record).

---

## Interrogation

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Birds: Cuckoo | keep | Plan, "every pool unit"; PLAN.md Done means 5, "art on every unit" | none |
| Fairies: Lob-Lie, Silky | keep | same | none |
| Bog: Lantern Man, Ranocchio | keep | same | none |
| Hunters: Agnes, Isegrim | keep | same | none |
| Hedgerow: Pym, Clover, Mallow, Hayward, Lollop | keep | same | none |
| `portraits_pending.json` emptied | keep | DECISIONS:1674, "Remove completed entries in the art step" | none |
| Prompt record | keep | CLAUDE.md, prompts kept in `tools/art/` | drop item 13 with the Slice cut |
| Slice copy and its test | cut | Wave2b adds the identical blob `ad7b0f39`, and its test counts 120 units including Slice | remove `slice.jpg`, `slice.jpg.import`, test lines 112–116, prompt item 13 and the Slice clause on prompt line 5 |
| Fallback removal, emptiness test, header comment | cut | Goes against DECISIONS:1671-1675; old fallback only triggered when the file is missing | revert `test_portraits.gd` to 5425c907 (keep the empty list). If you want a hard gate instead, delete the JSON and `_pending` too, rather than keep a file whose only legal value is `[]` |

**Gaps (outside the diff):**
- `docs/ideation/content/pass3/hedgerow-pass3.md:791` still says five Hedgerow units "still use the tribe portrait".
- `ui-declutter-spec.md:45` still says "the 50 of 157 units still on a shared tribe portrait". For the shipped game it is now 0, plus the four look-alikes.
- On declutter-b2, the `SHORT_NAMES` entries for these units in `card_view.gd:32` become dead once this lands.

**Open questions (orchestrator's call):**
1. The gate still fails after this step. The only fallback names left in the dense states are Brock, Old Brock, Sable and Russet. Re-roll those four in this art stream, or leave the gate to the scout focus view and label cuts?
2. Should Agnes and Isegrim join the look-alike list beside Brother Wolf and Grizel? That would put "Agnes" back on the tile. It's the declutter reviewer's call at real tile size.

**Files:**
- `/home/alex/code/Bramble-ideation/tests/ui/test_portraits.gd` (at 99374707)
- `/home/alex/code/Bramble-ideation/content/portraits_pending.json`
- `/home/alex/code/Bramble-ideation/tools/art/prompts/pool-portraits-10nov.txt`
- `/home/alex/code/Bramble-ideation-sol/build/art/pool-portraits/` (contact sheets and PNG masters)
