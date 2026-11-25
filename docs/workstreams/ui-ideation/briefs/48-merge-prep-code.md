# Merge prep, code: remove what the old card left behind

From the orchestrator of the UI work (an agent, not the owner). This brief is the orchestrator's **proposal**; the owner's own words are quoted below and outrank it.

## The job in one paragraph

Bramble's card and buy screen have been rebuilt to a new look on the branch you start from. The card is now drawn by code; the six tier frame pictures and the per-tier disc data that the old card needed are still shipped, still pulled by a script and still hash-checked by a test, but nothing draws or reads them. Before this branch goes to `dev`, take the old card's leftovers out, cleanly, so that the game, the pull script and the tests agree with each other again. Two small fixes ride along. Nothing about how the game looks or plays may change, apart from those two fixes.

## The owner's words

25 Nov 2026:

> "What are the obstacles of merging with main? What processes need to change to adopt the new things?"

> "We'll just replace the borders for now."

The owner's standing rule on leftovers is the note `docs/design/owner-notes/2026-11-18a-clean-up-superseded.md` in your checkout: read it; it is the owner's words.

## Where you work

- Your checkout: `/data/worktrees/ui-l1-step1`, already on branch `ui/l1-prep-code`. Work only there. Do not switch branches, merge, rebase or push. Commit in a few clear commits.
- Scratch: `TMPDIR=/data/ui-ideation/tmp/prep-code`. Pictures for the report: `/data/ui-ideation/build/prep/`.
- Godot is `/usr/local/bin/godot`. The quality gate is `./scripts/check.sh`. It is long: run it with a time limit, in the way your harness prefers for long commands.

## What is known (verify each before you act on it)

- `assets/glass/frames/` (six tier frame pictures): drawn by nothing. `GlassPieces.frame()` has no callers.
- `assets/glass/card_data.json`'s per-tier disc data: read by nothing. `GlassPieces.disc()` and `art_polygon()` have no callers.
- `tools/glass/pull_mockups.py` still writes the frames and that data from the old mock-ups branch (pinned in `assets/glass/source.json`), and `tests/glass/test_glass_pieces.gd` checks every pulled file against its recorded hash. So a removal has to change the pull, `source.json` and that test together, or the next pull brings the files back and the test fails.
- The fight screen, the card library, Compost and other screens still read the generated `assets/glass/layout.json`. That path must keep working exactly as it does.
- Another session's branch (fight animation) has been checked: it no longer uses any of the above.
- Two emblem pictures in `assets/glass/ui/` (`tr-bog.png`, `tr-fairies.png`) and two roundels (`rd-cream.png`, `rd-ruby.png`) may be unreferenced. Not established.

## What to do

1. Remove the old card's leftovers: the frame pictures, the unread disc data, and the dead functions, with the pull script, `source.json` and the hash test changed to match, so that running the pull again would not bring them back. Remove a file only when you have shown that nothing in `src/`, `tests/`, `tools/` or `scripts/` reads it and the pull will not rewrite it; anything you are unsure of, leave and list.
2. The buy screen's empty board slots still take their outline and hit area from the old layout's slot shape (17% shoulders, `_slot_shoulder()` in `src/screens/recruit/recruit_board.gd`), while the card that sits in them has 40.4 px shoulders. On the buy screen only, make a slot's outline and hit area the card's own outline. The fight screen keeps its own.
3. A golden card's glint and twinkle dim less than the card does: with the card node's `modulate` at `Color(0.25, 0.25, 0.25, 1)` they keep 45% and 32% of their light, where the halo keeps about 16 to 18%. Make every card light dim in proportion with its card (about a quarter of its light at 0.25, about half at 0.5, none at alpha 0), and tighten the rendered test `light_fade_pixels` to check the proportions for each light.

## What not to do

- Do not change `GlassCard.stat_disc` or `GlassCard._draw_stat`, or anything under `src/screens/fight/` or `tests/screens/feel/fight_compare/`: another session's work depends on them.
- Do not hand-edit the generated `assets/glass/layout.json` in a way the pull would overwrite or the hash test would reject. If a wrong line lives there (the card sheet's caption still speaks of each tier's own frame), fix it at its source or list it.
- No change to documents under `docs/` (another worker is doing those), to rules, balance or input, or to how anything looks beyond items 2 and 3.
- Do not read token or `auth.json` files.

## Done means

- `./scripts/check.sh` passes in your checkout. Quote its last summary lines.
- You have shown, with the searches you ran, that nothing reads what you removed.
- Screenshots made with `tools/look` in `/data/ui-ideation/build/prep/`: the buy screen with an empty board slot beside a card, the fight screen, and the card library. Each should look as it did before your change, apart from the slot outline; say so only after comparing with `/data/ui-ideation/build/step6/buy-lit.png` and `/data/ui-ideation/build/step4/fight.png`.
- The new numbers from `light_fade_pixels`, as a small table.

## Report

Under 250 words: what you removed (files and sizes), what you left and why, how the pull, `source.json` and the test now agree, the two fixes, the checks' result.

Never run `rm -rf`, or any other delete of files outside what this brief asks you to remove from the repository with git, anywhere, inside your checkout or outside it: Codex stops for the owner's approval on it, and the run stalls for hours. Remove repository files with `git rm`. For scratch, list every file and folder you made that you think should be removed afterwards, each with its path and size; the orchestrator removes them. End your report with a Disk section: every folder you created or wrote into outside your checkout, each with its `du -sh` size, whether it is still needed, and which ones the orchestrator can delete; and `df -h` for each disk you used, at the start and at the end.
