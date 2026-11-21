# Project rules for Claude agents

**Bramble** is a code name. It is a Hearthstone Battlegrounds-style auto-battler with some Once Upon a Galaxy influence, set in an idealized European woodland of animal folk, fairies and oozes. It is in **pre-production**. `main` holds design documents, research, the build toolchain (`docs/CLOUD_SETUP.md`) and a playable build from the second ideation track: a whole game against bots, with five tribes, in the glass look. The owner accepted its card art, the mechanics so far and the UI on 17 Nov 2026, and did not accept its unit numbers and balance (`docs/STATUS.md`).

Start here:
- Current state and open decisions: `docs/STATUS.md`.
- The owner's direction: `docs/design/direction-summary.md`, plus the owner's instructions in `docs/design/owner-notes/`.
- Architecture thinking: `docs/design/architecture-notes.md`.

## Owner notes

Owner notes in `docs/design/owner-notes/` hold the owner's instructions: rules and "do this" statements to agents. They are not for the owner thinking out loud or talking a design through. That stays in chat, or in the doc it shapes. A design decision goes in the doc it changes, quoting the owner's words.

**When to write one:**
- The owner gives a rule, or a big "do this" that agents outside this conversation must follow. A small ask inside a task goes in that task's brief, quoted.
- The owner asks for something to be recorded as a note.
- **Propose one:** the agent talking to the owner proposes a note when the owner says something important that will pass through workers or a long session, where it could get diluted or lost after compaction. Write it only on the owner's yes.

Commit a new note on the working branch and give workers its path. A rule whose wording the owner approved in `CLAUDE.md` needs no separate note.

**When to remove one:** when the work a note was written for is done, or the owner says the session is over, the agent lists the notes written for it, one line each, and asks the owner which still hold. Delete the ones that don't. An agent that later finds a note that is finished or contradicted tells the owner and asks. Before deleting a note, fix the docs that link to it: quote the owner's words there, or drop the link. Git history keeps deleted notes.

**While a note exists,** it's the owner's words. Never reword, summarize over or "improve" it. If the owner says a note misheard them, fix it. A changed instruction gets a new note that says what it replaces. The old note is removed if none of it holds.

**Transcribing:** remove filler words, repeats and clear dictation errors, and add punctuation. Reordering into sections is allowed. Keep a word you aren't sure of as heard and add your guess as *[probably "…"]*. Before committing, show the owner any guess that would change what agents do. Mark any other interpretation of yours as *[italic bracketed editor notes]*.

## Layout

```
docs/STATUS.md                   What exists, what's decided, what's open
docs/design/direction-summary.md Plannable summary of the owner's direction + open questions
docs/design/architecture-notes.md Recommendation for rule modifiers and layering
docs/design/rulebook.md          The rules, tagged BG / BRAMBLE / PROPOSED / OPEN; rulebook-deltas.md lists differences
docs/design/content-guardrails.md Content-level safeguards: what units, spells and modifiers must not do
docs/design/tier-guide.md        What each shop tier is for, and rough number targets as ratios (12 Nov)
docs/design/review-queue.md      Decisions waiting on the owner
docs/design/art-direction/       The art direction (lead and stained glass): what is decided, what is open, examples
docs/design/owner-notes/         Dated owner instructions (don't reword)
docs/design/owner-ideas-log.md   The owner's design directions, logged as said; directions, not decisions
docs/design/sources/             The owner's words behind the rulebook and taste guide (not instructions)
docs/research/battlegrounds/     Battlegrounds rules, patch history, keywords, card data library
docs/research/battlegrounds/analysis/unit_values.json  310 Battlegrounds units valued by role and stats per turn; the tier guide's data
docs/research/galaxy/            Once Upon a Galaxy rules, patch history, card library, design notes
docs/research/economy/           Economy and tier-price research: findings, the full record, saved sim outputs
docs/folio/                      The Woodland Folio: research and ideation page with art; serve it with the folio entry in .claude/launch.json (port 8765)
tools/art/                       The prompts used for Codex image batches, the card art guide and assembly (glass-art/), and the frame tools
tools/research/                  Re-runnable scripts that build the card data libraries; tools/research/economy/ holds the economy sims
tools/assets/                    Large files (screenshots, video, masters) kept in Cloudflare R2; pull them with assets.py
tools/versions.env               Every toolchain version and checksum, in one place
tools/checks/                    The quality gate's own checks (version drift, compile, strict GUT hook)
tools/look/                      Run any scene on a virtual display: screenshots, clicks, keys and the game's errors; compare a scene with an HTML mock-up, region by region
tools/feel/                      Film any scene with a scripted pointer at a true 60 frames a second, to judge motion and feel
tools/glass/                     pull_mockups.py pulls the glass mock-ups' pieces into assets/glass; compare.py is the ideation build's whole-screen compare of a scene with its mock-up
scripts/                         Cloud setup, session hook, quality gate (check.sh), export smoke test, the Windows build (build_windows.sh), the macOS build (build_macos.sh, only when the owner asks for one), the bot soak (soak.sh)
project.godot, src/, tests/      The Godot project, the playable build: rules core (src/core), ghost store and matchmaker (src/ghosts), tribes and cards as data (src/content), screens (src/screens, src/glass), game flow and bots (src/game)
assets/glass/                    The glass mock-ups' frames, card data, layout numbers and fonts, pulled by tools/glass/pull_mockups.py
assets/units/                    Card art for the five tribes' units
addons/gut/                      GUT, the test framework (vendored)
docs/CLOUD_SETUP.md              How the toolchain is set up and proved, locally, in the cloud and in CI
docs/AGENT-BLIND-SPOTS.md        What agents can't see when they build and check the game (motion, real hardware, sound and more), found on the second ideation track
docs/ideation-track-2/           The playable build's own rules and notes (tribe designs, mechanics page, mock-ups, hand-over); not yet reconciled with the rulebook
docs/orchestration/              Protocols for cloud workers and their orchestrator on the track that lands on main
docs/archive/                    Finished or outdated docs kept as history; its README says what each was
.claude/skills/game-design-process/  A general game design process (routes, checks, briefing designers); used only when asked for
.claude/skills/bramble-design/       Design work on Bramble's units, tribes and mechanics: what to read, costing, pitching to the owner, acting on the owner's reactions
.claude/skills/bramble-art/          Art for Bramble: the card art recipe to follow, and how a picture batch is run
```

## Working rules

- **Supervised from the start.** The earlier Autobattler project went wrong by running unsupervised early. Check in with the owner at decision points instead of running ahead.
- **The art direction is lead and stained glass** (owner, 15 Nov 2026): cards and the whole UI. It is authoritative and overrides any art or look instruction, on any branch, that contradicts it. See `docs/design/owner-notes/2026-11-15b-stained-glass-direction.md` and `docs/design/art-direction/README.md`, which also lists what is not decided yet.
- Commit to a branch and open a PR; don't push to `main` directly.
- **Main and its archive (owner's rule, 6 Nov; archive exception 12 Nov).** Nothing the owner hasn't decided enters `main` outside `docs/archive/` without the owner's say-so for that merge. That includes anything from `ideation/*` or other exploratory branches, and covers merges, cherry-picks and copying files or code. `docs/archive/` is the exception: finished or exploratory work can be archived there through a PR without asking, with a row in `docs/archive/README.md` saying what it was and that it isn't decided. Moving anything out of the archive into the rest of `main` needs the owner's say-so like any other merge. Purpose: agents on exploratory branches decide without the owner, so their choices must never become the real game by accident, while finished work still gets kept as history in one place. Where it doesn't apply: reading archived or ideation work, and pitching its ideas to the owner, is fine. The archive is never a source of decided rules or design. The owner's words: `docs/design/sources/2026-11-06a-ideation-branch.md`.
- **Heavy compute.** On the Optiplex there is no limit to ask about: use what the job needs. If memory runs out, the machine stops the biggest process and logs it (see the `optiplex` skill). On the owner's main PC, heavy compute such as simulations may use up to half the CPU cores and half the free memory without asking; for more, ask the owner first.
- In-game text follows the wording rule in the `ux-copy` skill.
- **Large files** (screenshots, video, masters) go in Cloudflare R2 through `tools/assets/`, not in Git; see its README. A small finished asset that a tool or the game reads can stay in Git (owner, 16 Nov).
