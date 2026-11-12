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

Commit a new note on the working branch and give workers its path. Answers typed in the portal inbox stay in the inbox and don't become notes.

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
docs/design/review-queue.md      Decisions waiting on the owner
docs/design/owner-notes/         Dated owner instructions (don't reword)
docs/research/battlegrounds/     Battlegrounds rules, patch history, keywords, card data library
docs/research/galaxy/            Once Upon a Galaxy rules, patch history, card library, design notes
docs/folio/                      The Woodland Folio: research and ideation page with art
tools/art/                       Codex image-generation runner and the prompts used so far
tools/research/                  Re-runnable scripts that build the card data libraries
tools/versions.env               Every toolchain version and checksum, in one place
tools/checks/                    The quality gate's own checks (version drift, compile, strict GUT hook)
scripts/                         Cloud setup, session hook, quality gate (check.sh), export smoke test
project.godot, src/, tests/      The Godot project: so far one placeholder scene and its test
addons/gut/                      GUT, the test framework (vendored)
docs/CLOUD_SETUP.md              How the toolchain is set up and proved, locally, in the cloud and in CI
docs/orchestration/              Protocols for cloud workers and their orchestrator on the track that lands on main
docs/archive/                    Finished or outdated docs kept as history; its README says what each was
```

## The folio

`docs/folio/woodland-folio.html` is a single page that loads local images from `docs/folio/art/`. Serve it with the `folio` entry in `.claude/launch.json` (port 8765) and open `/woodland-folio.html`. Full-size PNG masters live in `docs/folio/art/masters/` and are not committed.

## Generating art

Concept art is made by Codex workers using their built-in image tool, as in the Autobattler repo. `tools/art/run-codex-image.ps1 -PromptFile <file> -OutDir <dir>` runs one batch. The prompt files next to it show the format: a fixed header, then numbered `filename -- description` items.

Lessons so far:
- The image model drifts toward detailed painterly rendering. Flat styles need strict constraints in the prompt ("no gradients, no fur rendering, flat fills").
- Compress outputs to JPEG for the folio, and keep the PNGs as masters.

## Working rules

- **Fundamentals before content.** No content design (units, tribes, cards) until the rulebook and power budget exist. Content is costed bottom-up against the budget.
- **Supervised from the start.** The earlier Autobattler project went wrong by running unsupervised early. Check in with the owner at decision points instead of running ahead.
- **The board is the fight's HP.** As in Battlegrounds, the player has no in-fight health. Don't carry over the Autobattler repo's in-fight player-HP model or its other design assumptions.
- The owner wants quality and adaptability over speed: clear layers, flexible building blocks, solid docs.
- Commit to a branch and open a PR; don't push to `main` directly.
