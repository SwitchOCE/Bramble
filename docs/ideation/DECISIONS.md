# Decisions in force (look-and-feel phase)

One line per call that still holds. Newest calls go at the bottom of their group, with a short entry under "Entries" only if the line can't carry the reason. A reversed call is deleted from this page. Run 1's full log (235 entries, 6–10 Nov) is `archive/run1/DECISIONS.md`: history, read only when a step needs a specific past call. **Only the lines on this page are in force;** run 1's calls bind only where a line here carries them over.

## Phase rules (owner, 10 Nov: notes 10j and the plan)

- This phase is UI, UX and look and feel only. Rules, numbers, card behaviour, bots, sims and content are out, and the gate's scope-fence check enforces it. (`PLAN.md`, "Scope fence")
- A loop ends when the owner has played its build, or 3 days after its day-1 gallery went out, whichever comes first. (`PLAN.md`, "Done for a loop")
- At most two or three focus items per loop, picked by the owner from the day-1 gallery.
- Each step: the gate plus one scope review. No numeric scores for looks; reviewers answer plain questions beside reference shots. No new bars or measurement plans unless the owner asks.
- Defaults until the owner says otherwise: sound out; tutorial and Rules reference in; PC landscape first, portrait later.
- Reference frames live outside git in `/data/bramble-reference/<game>/`, shared by every worktree and the gallery; the manifest and re-fetch README are in `docs/ideation/ui/reference/`. (orchestrator, 10 Nov: an in-repo folder isn't shared across worktrees)
- Step 0b's capture, backdrops and layout options are one step: one scope review over their branches together. (orchestrator, 10 Nov)
- The scope fence also covers `tests/sim/` and, once step 0 has merged, `scripts/check.sh`, so one edit can't switch the fence off. (orchestrator, 10 Nov, step 0 review ask)
- Loop 1's day-1 gallery went out 10 Nov 23:22 AEDT; loop 1 ends when the owner plays its build, or 13 Nov 23:22. (orchestrator, 10 Nov)
- Loop 1's layout is Bazaar Stack, and the focus items are the orchestrator's: "I'm happy to just kind of let you cook for a bit and see where we end up. The Bazaar stack seems like a reasonable approach." Focus items: A (Bazaar Stack in its painted world), B (recruit feel), and the units brought toward the world (below). C, D and E wait for loop 2. (owner and orchestrator, 11 Nov)
- The orchestrator has full authority over the look: cards, in-game assets and the art style itself, "even using different art if you choose. I want to see this brought to its conclusion." (owner, 11 Nov, note `2026-11-11a`). The portrait question is no longer the owner's. Loop 1 explores four unit-art styles on 8 units (scene-kept Ink-B, a colour grade of today's art, a painted storybook style, ink with wash and glow), picks one with an advisor check-in, then repaints every unit, hero and card to it. Never a mixed set in a merged build. (orchestrator, 11 Nov)
- Loop 1 merges A (Bazaar Stack) first; B and the unit-art branch rebase onto it, and A alone rewrites old layout tests in `tests/ui/`. Merges freeze on the evening of 12 Nov; 13 Nov is integration and the build checks only. No setting pair ships this loop. (orchestrator, 11 Nov; advisor check-in)
- The design-critique skill isn't used on the game's screens: it's a product-UI checklist ("is the purpose immediately clear?", "are interactive elements obvious?") that pushes toward labels and hints, against the declutter rule, and has nothing on motion, weight or sense of place. Reviewers answer the plan's plain questions beside reference shots instead. The owner (11 Nov): "If the agents are going to give bad results because I've recommended a skill, let me know." (owner and orchestrator, 11 Nov; advisor check-in)
- The layout mockups' tile-size pass/fail (150 px phone, 270 px PC shop) is dropped: it was a one-off brief direction, and the owner said no new bars. (orchestrator, 10 Nov, step 0b review ask)
- Look clips keep the GIF and contact sheet and delete their raw frames unless `--keep-frames` is given; look sessions older than 7 days are pruned. (orchestrator, 10 Nov, step 0 review ask)

## Look

- Units are drawn in "Ink + flat B" (owner, 1 Nov: `docs/design/owner-notes/2026-11-01-art-style-decision.md`).
- Every pool unit has its own portrait in that style; no fallback names on tiles. (archive, 10 Nov, "Declutter batch 2 WIP")

## Screen and declutter

- The main screen assumes a player who knows the rules: no tutorial text, rule reminders or static pointers on it; fights read through motion, not labels, arrows or a log. (owner 09e; archive, 9 Nov, "The owner's declutter direction")
- Every element passes the spec's three tests: would a hundredth-game player use it now; does it show changing state rather than restate a rule; is it an event (make it motion) or a standing image. (`ui-declutter-spec.md` §1; archive, 9 Nov, "The declutter spec")
- Opponent tiers show as numerals, not pips. (archive, 10 Nov, "opponent tiers come back as numerals")
- The Ring frame shows presence on the board; exact counts and totals live in the one-tap reader. (archive, 10 Nov, "the Ring count stays in the reader")
- Scouting shows both boards and collapses the shop and lobby. (archive, 10 Nov, "Declutter batch 2 WIP")
- The layout and label-budget tests are regression guards, not goals. A focus worker may rewrite or delete `tests/ui/` tests that assert the old layout, listed in its step note; that needs no line here.

## Entries

*(none yet)*
