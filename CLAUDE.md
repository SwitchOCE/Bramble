# Project rules for Claude agents

**Bramble** is a code name. It is a Hearthstone Battlegrounds-style auto-battler with some Once Upon a Galaxy influence, set in an idealized European woodland of animal folk, fairies and oozes. It is in **pre-production**: there is no game code yet, only design documents, research and the build toolchain (`docs/CLOUD_SETUP.md`).

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
docs/design/power-budget.md      Costing method; content-guardrails.md holds content-level safeguards
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
docs/folio/                      The Woodland Folio: research and ideation page with art
tools/art/                       Codex image-generation runner and the prompts used so far
tools/research/                  Re-runnable scripts that build the card data libraries; tools/research/economy/ holds the economy sims
tools/assets/                    Large files (screenshots, video, masters) kept in Cloudflare R2; pull them with assets.py
tools/versions.env               Every toolchain version and checksum, in one place
tools/checks/                    The quality gate's own checks (version drift, compile, strict GUT hook)
scripts/                         Cloud setup, session hook, quality gate (check.sh), export smoke test
project.godot, src/, tests/      The Godot project: so far one placeholder scene and its test
addons/gut/                      GUT, the test framework (vendored)
docs/CLOUD_SETUP.md              How the toolchain is set up and proved, locally, in the cloud and in CI
docs/orchestration/              Protocols for cloud workers and their orchestrator on the track that lands on main
docs/archive/                    Finished or outdated docs kept as history; its README says what each was
.claude/skills/game-design-process/  A general game design process (routes, checks, briefing designers); used only when asked for
.claude/skills/bramble-design/       Design work on Bramble's units, tribes and mechanics: what to read, costing, pitching to the owner, acting on the owner's reactions
```

## The folio

`docs/folio/woodland-folio.html` is a single page that loads local images from `docs/folio/art/`. Serve it with the `folio` entry in `.claude/launch.json` (port 8765) and open `/woodland-folio.html`. Full-size PNG masters live in `docs/folio/art/masters/` and are not committed.

## Generating art

**The art direction is lead and stained glass** (owner, 15 Nov 2026): cards and the whole UI. It is authoritative and overrides any art or look instruction, on any branch, that contradicts it. See `docs/design/owner-notes/2026-11-15b-stained-glass-direction.md` and `docs/design/art-direction/README.md`, which also lists what is not decided yet.

Concept art is made by Codex workers using their built-in image tool, as in the Autobattler repo. `tools/art/run-codex-image.ps1 -PromptFile <file> -OutDir <dir>` runs one batch. The prompt files next to it show the format: a fixed header, then numbered `filename -- description` items.

Lessons so far:
- The image model drifts toward detailed painterly rendering. Flat styles need strict constraints in the prompt ("no gradients, no fur rendering, flat fills").
- Compress outputs to JPEG for the folio, and keep the PNGs as masters.

## Working rules

- **Supervised from the start.** The earlier Autobattler project went wrong by running unsupervised early. Check in with the owner at decision points instead of running ahead.
- **Art direction:** see "Generating art".
- **The board is the fight's HP.** As in Battlegrounds, the player has no in-fight health. Don't carry over the Autobattler repo's in-fight player-HP model or its other design assumptions.
- The owner wants quality and adaptability over speed: clear layers, flexible building blocks, solid docs.
- Commit to a branch and open a PR; don't push to `main` directly.
- **Main and its archive (owner's rule, 6 Nov; archive exception 12 Nov).** Nothing the owner hasn't decided enters `main` outside `docs/archive/` without the owner's say-so for that merge. That includes anything from `ideation/*` or other exploratory branches, and covers merges, cherry-picks and copying files or code. `docs/archive/` is the exception: finished or exploratory work can be archived there through a PR without asking, with a row in `docs/archive/README.md` saying what it was and that it isn't decided. Moving anything out of the archive into the rest of `main` needs the owner's say-so like any other merge. Purpose: agents on exploratory branches decide without the owner, so their choices must never become the real game by accident, while finished work still gets kept as history in one place. Where it doesn't apply: reading archived or ideation work, and pitching its ideas to the owner, is fine. The archive is never a source of decided rules or design. The owner's words: `docs/design/sources/2026-11-06a-ideation-branch.md`.
- Heavy compute such as simulations may use up to half the CPU cores and up to half the free memory without asking. Other agents share this computer, so before starting, check its current load: CPU use, committed memory against the commit limit, and the working memory of other running processes. If the machine is already busy, or a run would clearly benefit from more, don't settle for half: ask the owner first. Say how much CPU and memory it would use and roughly how long it would take, ask whether the machine is free right now, and ask how much it may use.
- **Clear, short wording in the game (owner, 8 Nov).** Card, keyword, tooltip and guide text says the main effect plainly, in as few words as it takes, and uses keywords to save sentences, as Battlegrounds does. It doesn't explain edge cases or anything the mechanic implies. Those go in a second layer (reminder text in smaller italics, on hover or tap; the guide; the rulebook) or stay implied. Purpose: build 6's text was "far too long, far too wordy", and the point of an explanation is to "make complicated things simple", not "to handle every use case". Where it doesn't apply: the rulebook and engine specs, which must stay exact because they are where the edge cases live.
- **Large files are rare (owner, 12 Nov).** Screenshots, video and other large files go in Cloudflare R2 through `tools/assets/`, not in Git. Use one only when it clearly improves the result, and shrink it first: JPEG or WebP, the smallest size that shows what matters, short re-encoded clips. Purpose: keep the repo and the bucket small and inside the free tier. In the owner's words, "300 megabytes for a file is crazy", but "when they're going to significantly improve the result, we should absolutely use them". Where it doesn't apply: a large file that is really needed is fine; push it with `--allow-large`. A small finished asset that a tool or the game reads can stay in Git, such as the six card frames in `docs/design/art-direction/frame-lab/final/` (owner, 16 Nov).
