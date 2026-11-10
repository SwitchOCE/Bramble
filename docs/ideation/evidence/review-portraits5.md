*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov. Calls: DECISIONS (ideation/main) "Portraits batch C and Golden Egg: review calls".]*

## Scope review: `ideation/portraits4` `0c3fd133..ba4bebe1` (cfe3bd10 + ba4bebe1)

I had all three inputs. Your "owner's words" are a paraphrase. The closest line in `2026-11-09e` is line 13: "the player is assumed to know how to play the game when they're in the game environment".

**Counts:** 9 keep, 0 cut, 1 simplify, 1 ask.

**Does it move the original problem?** Mostly yes.
- **Wolves:** all four now read apart at 96 px, and Agnes reads as a wolf. Their names can come off the tiles; w4's short-name list does that, and this range removes none.
- **Shieldbug and Click Beetle:** they get their own art before A3 adds them, so they won't add fallback names.
- **Golden Egg:** no change yet, because nothing shows its new picture.

**Ask:**
- **Golden Egg's art never appears.** `src/ui/ui_theme.gd:212` swaps `golden_egg` for `nest_egg` on every screen, and `tests/ui/test_portraits.gd:41-42` checks for the Nest Egg picture. Remove both on this branch, or name the step that does?

**Simplify:**
- **`shieldbug.jpg.import` has a uid Godot doesn't write: `uid://bicgj7i64hxiz`.**
  - Evidence: none of the other 265 uids in the tree contains a `z` or a `9`. Godot's uid alphabet is a–y and 0–8.
  - Effect: in the Godot source I know, `z` reads as the same value as `0`. The first import would then rewrite the line to `…hxi0`, leaving an unexplained diff in whoever's tree runs it.
  - Fix: use `uid://bicgj7i64hxi0`, or let `godot --headless --import` write the `.import` files.
  - The other two uids (`wrcgbpwtwac1`, `b205ktxw0l37t`) are fine.

| Item | Verdict | Evidence |
|---|---|---|
| Grizel re-roll | keep | Matches prompt item 1 and the decision: tawny-orange with a red back, notched ear, howling in right profile, moon on a night-blue sky, a boar at the bottom, two pack wolves with gold sparks. At 96 px she shares nothing with Brother Wolf (grey, three-quarter view, daytime trees). New overlap: she is now orange like Mistress Russet the fox, but the pose, night sky and lack of a coat keep them apart. |
| Grey Agnes re-roll | keep | Long pointed muzzle and tall ears: a wolf, not a bear. A blow splits in two on her forearm and she shelters a cub, which fits "pack leaders take half the hit back". |
| `shieldbug.jpg` | keep | Leaf-green shield plate with a cream triangle; a hedgehog and a rabbit shelter behind it under a cream arc. This fits "give the units behind this Shield". Shown through the general `portrait_for` (`ui_theme.gd:210`) once A3 adds the card. |
| `click_beetle.jpg` | keep | Spark at the hinge, two amber echoes. Minor: three beetles stand for "trigger twice", while the golden card triggers three times. The prompt asked for two echoes. |
| `golden_egg.jpg` | **ask** | See above. The image itself fits its text: a gold egg, and a robin drawn small and then twice the size. Gold on teal against speckled blue on cream, so it is clearly not the Nest Egg, though both show an egg in a nest. |
| `click_beetle` and `golden_egg` `.import` | keep | The imported file names use the md5 of each file's `res://` path and match. Settings are identical to `sable.jpg.import`. All uids are unique. |
| `shieldbug.jpg.import` | simplify | See above. |
| Prompt records `-c`, `-d` | keep | One record per batch, as before, each with a reason and a result. |
| Export with `portraits.py`, quality 82, no size floor | keep | My re-export from the masters is byte-identical. |

**Claims checked:**
- **Grizel and Brother Wolf read apart; Agnes reads as a wolf:** confirmed on my own sheets. The worker's sheet left out Isegrim; mine has all four wolves.
- **The `.import` files match what Godot would write:** true except the shieldbug uid.
- **An image with no card breaks no test:** confirmed. `test_portraits.gd` loops over the cards in the library, not over files, and `compile_all.gd` scans only `src`, `tests` and `tools`. The Golden Egg file changes no test either, because of the swap above.

**Probes:**
1. Ran `portraits.py export` (copied from cfe3bd10, run with `python3 -I`) on `build/art/batch-10nov-c` and `batch-10nov-d`. All five JPEGs are byte-identical to the committed ones.
2. md5 of `res://assets/portraits/{shieldbug,click_beetle,golden_egg}.jpg` matches each imported file's suffix.
3. Uid alphabet: 0 of 265 uids in the tree contain `z` or `9`.
4. 96 px sheets, shown at 3× (orchestrator's scratchpad, not committed): wolves96.png, wolves96_gray.png, beforeafter96.png, grizel_russet96.png, others96.png (Shieldbug, Click Beetle, Golden Egg, Nest Egg).
5. Godot was not run.

**Gap:** S7's Golden Egg image does nothing until the swap at `ui_theme.gd:212` and the test at `test_portraits.gd:41-42` are removed. With those gone, the existing test would expect `golden_egg.jpg` and cover it.
