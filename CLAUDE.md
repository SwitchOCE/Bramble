# Project rules for Claude agents

**Bramble** is a code name. It is a Hearthstone Battlegrounds-style auto-battler with some Once Upon a Galaxy influence, set in an idealized European woodland of animal folk, fairies and oozes. It is in **pre-production**: there is no game code yet, only design documents, research and the build toolchain (`docs/CLOUD_SETUP.md`).

## This is the ideation branch: the look-and-feel phase (owner, 10 Nov 2026)

This checkout is `ideation/main` or one of its `ideation/*` branches. The owner handed ideation's decisions to the agents on 6 Nov (`docs/design/owner-notes/2026-11-06a-ideation-branch.md`). Since 10 Nov (note `2026-11-10j`) it runs a **look-and-feel phase**: UI, UX and how the game looks and feels on screen, and nothing on rules, numbers, bots or content. On `ideation/*` only:

- **The plan is `docs/ideation/PLAN.md`;** its reading list says what to read first. The calls in force are the one-page `docs/ideation/DECISIONS.md`.
- **Agents decide; they don't wait on the owner,** except where the plan asks the owner to pick (the focus items and the layout from the day-1 gallery). Each call is one line in DECISIONS. Where this file or `~/.claude/CLAUDE.md` says to ask the owner, the orchestrator decides instead, unless the plan says the owner picks.
- **Each step:** the test gate plus one fresh scope review. No numeric scores for looks, and no new bars or measurement plans unless the owner asks.
- **Who runs where:** Codex workers on the Optiplex do the building; Claude keeps the judgment; the gate runs on Actions (owner notes 7 Nov and `2026-11-10b`).
- **Run 1's process is archived** in `docs/ideation/archive/run1/`. It's history, not instructions: don't follow its plans, briefs, review rounds or "Done means".
- **What still holds:** never merging into `main` (below); owner notes are records; the owner's direction outranks the agents' taste; other branches and worktrees belong to other sessions, so read them but don't change them; the portal inbox is read each session, and the owner's messages are direction to follow.

Start here (on `ideation/*`, `docs/ideation/PLAN.md`'s reading list replaces this list):
- Current state and open decisions: `docs/STATUS.md`.
- The owner's direction: `docs/design/direction-summary.md`, plus the full record in `docs/design/owner-notes/`.
- Architecture thinking: `docs/design/architecture-notes.md`.
- Game design: Bramble's specifics in `docs/design/bramble-design-guidance.md`, and the general `game-design-process` skill (`.claude/skills/game-design-process/`), used only when the owner or an orchestrator says so.

## Owner notes are records, and the current set stays short (owner, 10 Nov 2026)

Files in `docs/design/owner-notes/` are the owner's dictated words. Never reword, summarize over or "improve" them.

**Only big direction becomes a note:** a change of goal, scope, phase or standing preference. A correction or remark inside a task goes into that task's brief, quoted, and nowhere else.

**The current set stays short.** `docs/design/owner-notes/README.md` lists the notes that bind now, one line each, and the folder holds only those: at most 15 notes and about 5,000 words. Everything else lives unchanged in `owner-notes/archive/`, listed in the README so it can be found.
- A new note says which notes it replaces, if any; the replaced ones move to the archive.
- A note older than two weeks stays current only if its README line says why it still binds. At each new note, check the oldest ones and archive any that can't justify their place.
- Moving a note never changes its text.

**Dictation is often misheard, so guard against recording garbage:**
- Clean up only what's certain: filler words, repeats and punctuation. Reordering into sections is allowed.
- Never silently "fix" a word you aren't sure of. Keep the words as heard and add your guess as *[probably "…"]*. Mark any other interpretation as *[italic bracketed editor notes]*.
- Before committing a note, show the owner the cleaned text with every guess listed, in one short message. A guess that would change what agents do needs the owner's yes; otherwise the note stands with its brackets.
- Agents never act on a bracketed guess that matters without checking it with the owner.
- A correction goes in a new dated note (or the README line), never into the old note.

## Layout

```
docs/STATUS.md                   What exists, what's decided, what's open
docs/design/direction-summary.md Plannable summary of the owner's direction + open questions
docs/design/architecture-notes.md Recommendation for rule modifiers and layering
docs/design/rulebook.md          The rules, tagged BG / BRAMBLE / PROPOSED / OPEN; rulebook-deltas.md lists differences
docs/design/power-budget.md      Costing method; content-guardrails.md holds content-level safeguards
docs/design/review-queue.md      Decisions waiting on the owner
docs/design/owner-notes/         Dated owner dictations (records; don't edit)
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
```

## The folio

`docs/folio/woodland-folio.html` is a single page that loads local images from `docs/folio/art/`. Serve it with the `folio` entry in `.claude/launch.json` (port 8765) and open `/woodland-folio.html`. Full-size PNG masters live in `docs/folio/art/masters/` and are not committed.

## Generating art

Concept art is made by Codex workers using their built-in image tool, as in the Autobattler repo. `tools/art/run-codex-image.ps1 -PromptFile <file> -OutDir <dir>` runs one batch. On Linux: `tools/art/run-codex-image.sh <file> <dir> [reference images]`. The prompt files next to it show the format: a fixed header, then numbered `filename -- description` items.

Lessons so far:
- The image model drifts toward detailed painterly rendering. Flat styles need strict constraints in the prompt ("no gradients, no fur rendering, flat fills").
- Compress outputs to JPEG for the folio, and keep the PNGs as masters.

## Working rules

- **Fundamentals before content.** No content design (units, tribes, cards) until the rulebook and power budget exist. Content is costed bottom-up against the budget.
- **Supervised from the start.** The earlier Autobattler project went wrong by running unsupervised early. Check in with the owner at decision points instead of running ahead.
- **Status blocks (owner-approved 4 Nov).** Each workstream's plan file starts with a status block: status (active, waiting on you, paused or done), last step done, next step, and waiting on you. The orchestrator updates it whenever a step merges, so the portal shows the truth. When a question in a workstream's questions file is answered, the agent that acts on it adds `**Answered (date):**` and the answer under the item, so the portal's open-question count stays true. Each block also has an **In short** line: one plain sentence about where things are, which the portal's home page shows. Agents keep it current. Format: `docs/workstreams/README.md`.
- **Portal inbox (owner-approved 4 Nov).** At the start of each session, read new messages in the portal inbox. Act on the ones for your work, quote the owner's words where they change a doc, and mark each one handled so the portal shows it. Where the inbox is and how to mark a message handled: `docs/workstreams/README.md`.
- **Portal wording (owner-approved 4 Nov).** Everything the portal shows, including decision cards and status lines, follows `docs/portal/WORDING.md` (on `portal/main`): frame it first, talk like a person, show it, then ask.
- **The board is the fight's HP.** As in Battlegrounds, the player has no in-fight health. Don't carry over the Autobattler repo's in-fight player-HP model or its other design assumptions.
- The owner wants quality and adaptability over speed: clear layers, flexible building blocks, solid docs.
- Commit to a branch and open a PR; don't push to `main` directly.
- **Ideation never reaches main without the owner (owner's rule, 6 Nov).** Nothing from `ideation/main` or any other `ideation/*` branch is merged into `main` without the owner's say-so for that merge. That covers merges, cherry-picks and copying its files or code into a branch headed for `main`. Reading ideation work, and pitching its ideas to the owner, is fine. Purpose: agents on the ideation branch decide without the owner, so their choices must never become the real game by accident. The owner's words: `docs/design/owner-notes/2026-11-06a-ideation-branch.md` (on `design/tribes-and-budget`).
- Budgets and taxonomy are guidelines. The power budget and the effect taxonomy are not exhaustive, and any agent may add an effect that isn't in them. Agents that design cards or mechanics are briefed without the power budget. A separate review agent then costs the designs, flags any that are well outside the budget, and proposes changes that keep the card's creative core. Purpose: costing too early narrows designs to what Battlegrounds already does.
- Compute on the Optiplex (this machine): no limit. Use as much of the resources as the work needs (owner, 8 Nov: `docs/design/owner-notes/2026-11-08d-optiplex-compute.md`). The earlier half-the-machine rule was meant for the owner's main computer.
- Pitch ideas concretely. Every mechanic or tribe idea shown to the owner comes with an example unit with full rules text, how it interacts with other cards, why a player would run it, a situation where it is good, and two or three variations. Where it resembles a design the owner may know from another game, say so in a line. Purpose: the owner can't judge an idea from a one-line summary (2 Nov).
- Design reactions are directions. When the owner reacts to a design, the reaction sets what to iterate on, not what changes. Never cut a design straight away: explore what it can teach, push back with an example where it works, or propose a version that does. This applies only to evaluating designs. Purpose: early cuts lose ideas, and the owner's comments on designs are mostly suggestions (2 Nov).
