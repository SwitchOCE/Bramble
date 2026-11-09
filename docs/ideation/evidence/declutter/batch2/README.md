# Declutter batch 2 — work in progress

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
