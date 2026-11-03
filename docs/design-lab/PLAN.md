# Design lab plan (overnight, 3–4 November 2026)

<!-- status -->
- **Status:** waiting on you
- **Last step done:** Round 3 (combat and settings for the top four directions), plus screenshots of three looks in the real game (4 Nov 2026).
- **Next step:** A round on the direction, or mix, you pick.
- **Waiting on you:** Which direction or mix to take further. The gallery has the evidence.
<!-- /status -->

Branch `design-lab/main` (from `design/tribes-and-budget`), worktree `~/code/Bramble-design`. Exploration only: nothing here is a decision, and nothing in `docs/design/` changes. It never merges into `main` without the owner.

## The owner's words (3 Nov, ~23:55)

> "I think you should make another separate bunch of work trees, etc., to have some design work occur, you know, mock UIs in a bunch of different styles, cards, you know, the kind of like design work, etc., that we haven't really been doing, design menus for a bunch of different things, mood boards, you know, potential cool color schemes, you know, have agents, you know, kind of like run things in a gauntlet and pick the best ideas. Stuff that's of different tastes as well, you know, is fine, you know. I'm not sure if there's another work stream that would work for another set of branches and work trees, but that one springs to mind at least. Maybe architectural stuff and Godot specific stuff. I'm not sure that, you know, wiring, etc., but the prototype will probably cover a lot of that."

## Fixed points

- The illustration style is decided: Ink + flat B ("Bold and clean"), 1 Nov (`docs/design/owner-notes/2026-11-01-art-style-decision.md`, prompt in `tools/art/prompts/trials-ink-b.txt`). UI, card frames, menus and colour are not decided. Most directions sit around the decided style. Two or three deliberately don't, to give a range of tastes.
- A mood board of reference artists made no visible difference to generated images (1 Nov). Here, mood boards are for UI feel and colour, not for steering the image model.
- The screens follow the rulebook's game: a shop, the 4–3 brick board, the hand, gold, tier, refresh, freeze, the lobby standings, combat. Landscape 16:9 for Windows and Android.

## Rounds

1. **Generate (about 8 directions, one agent each, in parallel).** Each direction makes:
   - a palette (named colours with hex, light and dark use) and a one-page mood board;
   - a unit card at shop size and at board size, with a real library unit's text;
   - the recruit screen, the combat screen, the main menu and one more menu (settings, collection or the lobby standings);
   - built as HTML/CSS and screenshotted with Playwright, plus at most 3 Codex images (portraits or textures) in the direction's style;
   - a short note: the idea, who it's for, what it costs to build in Godot, and its risks (readability, animation, small screens).
2. **Gauntlet.** A panel of 4 judge agents with different tastes scores every direction against one rubric from the screenshots alone: readability at phone size, the 4–3 board's clarity, fit with the woodland and Ink + flat B, distinctiveness, build cost in Godot, and their own taste. Scores and quotes are kept. Top 3 go on, plus one wildcard chosen by a single judge.
3. **Refine.** The winners get a second pass on the judges' notes, with ideas borrowed from the losers named.
4. **Gallery.** One page in the repo showing every direction, the scores, the judges' notes and the refined winners, also published as a private Artifact for the owner to look at in the morning.

## Side stream: Godot architecture notes (docs only)

Branch `arch/godot-notes`. One agent writes `docs/architecture/godot-notes.md`: how the architecture recommendation (`docs/design/architecture-notes.md`: rule modifiers and layering) maps onto Godot 4.7, with options and a recommendation for each of: project layout, a rules core with no scene dependencies, unit data (JSON or Resources), effect hooks and rule modifiers, a seeded RNG, async snapshot fights later, UI layout and theming for Windows and Android (so a design-lab style could become a Godot Theme), card rendering, animation, testing, and Android performance. Late in the night it compares its notes with what the prototype actually did and adds the lessons.

## Gates and limits

- The gauntlet and its judges are the quality gate for the visuals. The scope reviewer checks the gallery and the architecture notes against the owner's words before they're called done.
- Shares the machine with the prototype: Playwright and Codex are light, but at most 4 generators run at once.
- No new standing rules. Learnings go in `docs/prototype/LEARNINGS.md` on `proto/main`, which the orchestrator copies in.
