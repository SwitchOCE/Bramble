# Project rules for Claude agents

**Bramble** is a code name. It is a Hearthstone Battlegrounds-style auto-battler with some Once Upon a Galaxy influence, set in an idealized European woodland of animal folk, fairies and oozes. It is in **pre-production**: there is no code yet, only design documents and research.

Start here:
- Current state and open decisions: `docs/STATUS.md`.
- The owner's direction: `docs/design/direction-summary.md`, plus the full record in `docs/design/owner-notes/`.
- Architecture thinking: `docs/design/architecture-notes.md`.

## Owner notes are records

Files in `docs/design/owner-notes/` are the owner's dictated words. Never reword, summarize over or "improve" them. Corrections go in a new dated note or in the summary.

When transcribing a new dictation:
- Remove dictation errors, filler words and repeats, and add punctuation.
- Reordering into sections is allowed.
- Mark any interpretation of yours as *[italic bracketed editor notes]*.

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
- **Status blocks (owner-approved 4 Nov).** Each workstream's plan file starts with a status block: status (active, waiting on you, paused or done), last step done, next step, and waiting on you. The orchestrator updates it whenever a step merges, so the portal shows the truth. When a question in a workstream's questions file is answered, the agent that acts on it adds `**Answered (date):**` and the answer under the item, so the portal's open-question count stays true. Each block also has an **In short** line: one plain sentence about where things are, which the portal's home page shows. Agents keep it current. Format: `docs/workstreams/README.md`.
- **Portal inbox (owner-approved 4 Nov).** At the start of each session, read new messages in the portal inbox. Act on the ones for your work, quote the owner's words where they change a doc, and mark each one handled so the portal shows it. Where the inbox is and how to mark a message handled: `docs/workstreams/README.md`.
- **Portal wording (owner-approved 4 Nov).** Everything the portal shows, including decision cards and status lines, follows `docs/portal/WORDING.md` (on `portal/main`): frame it first, talk like a person, show it, then ask.
- **The board is the fight's HP.** As in Battlegrounds, the player has no in-fight health. Don't carry over the Autobattler repo's in-fight player-HP model or its other design assumptions.
- The owner wants quality and adaptability over speed: clear layers, flexible building blocks, solid docs.
- Commit to a branch and open a PR; don't push to `main` directly.
- **Ideation never reaches main without the owner (owner's rule, 6 Nov).** Nothing from `ideation/main` or any other `ideation/*` branch is merged into `main` without the owner's say-so for that merge. That covers merges, cherry-picks and copying its files or code into a branch headed for `main`. Reading ideation work, and pitching its ideas to the owner, is fine. Purpose: agents on the ideation branch decide without the owner, so their choices must never become the real game by accident. The owner's words: `docs/design/owner-notes/2026-11-06a-ideation-branch.md` (on `design/tribes-and-budget`).
