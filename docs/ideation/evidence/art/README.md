# Slice portraits: how they were made

52 portraits: 25 units, 5 tokens (Kit, Shrewlet, Wisp, Nymph, Mouse), 10 spells, Acorn, Stash, Great Hoard, 9 heroes. `slice-contact-sheet.jpg` shows them all at 180 px, the size they have to read at.

**Prompts.** `tools/art/prompts/slice-*.txt`: one fixed header with the owner's Ink + flat B rules and their NO rules, one family block, then numbered `filename -- description` items from the art direction lines in `docs/ideation/content/`. Run with `tools/art/run-codex-image.sh <prompt> <outdir> <reference images>`. The Ink B trials of the marmot and otter (`docs/folio/art/web/trials/`) go in as style references.

**What held the style and kept cards apart:**
- A per-family palette and background: hedge and cream for Hedgerow folk, dusk violet and teal for Fairies, each hero one saturated colour of its own.
- Telling the model each creature's true anatomy. It overshoots: the shrew went from anteater to weasel before "snout longer than its head, tiny eyes, no visible ears" held.
- Naming a different colour or prop when two cards share a species, as the two dormice do (golden Alderman, grey Partner).
- Art direction lines written under old names or old text were updated to the current card: Old Moth Annis is old, Hungry Gap shows 2 coins, Last Orders has a pub bell.

**Regenerated after review (`slice-regen-*.txt`):** Earwig Mother (looked like a scorpion), Nymph, Mrs Sorrel, Shrewlet, Sleeping Partner, Belladonna, Spore Cloud (looked like an explosion), Pinch of Dust, Brother Bracken (too small), Pipkin (not hedgehog enough), Old Mother Mousewife (too like Dame Farthing), Jill (face too low to survive the crop).

**Delivery.** `tools/art/portraits.py export <masters> assets/portraits` writes 512 px JPEGs at quality 82: 2.6 MB in all. Godot's import is lossless, so these and the tribe portraits take about 18 MB in `.godot/imported`. Masters stay in `docs/folio/art/masters/slice/`, not in git.

**UI changes.** Units, spells, heroes and tokens already looked in `assets/portraits/`. Acorn items now use theirs too, with the nut icon as the fallback. The crop starts higher (0.2 of the spare height, was 0.3) so faces survive wide windows. The hero's Power leaf is 22 units shorter so an activated hero's portrait isn't a thin band.
