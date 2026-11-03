# Project rules for Claude agents

**Bramble** is a code name. It is a Hearthstone Battlegrounds-style auto-battler with some Once Upon a Galaxy influence, set in an idealized European woodland of animal folk, fairies and oozes. It is in **pre-production**: there is no game code yet, only design documents, research and the build toolchain (`docs/CLOUD_SETUP.md`).

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

Concept art is made by Codex workers using their built-in image tool, as in the Autobattler repo. `tools/art/run-codex-image.ps1 -PromptFile <file> -OutDir <dir>` runs one batch. The prompt files next to it show the format: a fixed header, then numbered `filename -- description` items.

Lessons so far:
- The image model drifts toward detailed painterly rendering. Flat styles need strict constraints in the prompt ("no gradients, no fur rendering, flat fills").
- Compress outputs to JPEG for the folio, and keep the PNGs as masters.

## Working rules

- **Fundamentals before content.** No content design (units, tribes, cards) until the rulebook and power budget exist. Content is costed bottom-up against the budget.
- **Supervised from the start.** The earlier Autobattler project went wrong by running unsupervised early. Check in with the owner at decision points instead of running ahead.
- **Status blocks (owner-approved 4 Nov).** Each workstream's plan file starts with a status block: status (active, waiting on you, paused or done), last step done, next step, and waiting on you. The orchestrator updates it whenever a step merges, so the portal shows the truth. Format: `docs/workstreams/README.md`.
- **The board is the fight's HP.** As in Battlegrounds, the player has no in-fight health. Don't carry over the Autobattler repo's in-fight player-HP model or its other design assumptions.
- The owner wants quality and adaptability over speed: clear layers, flexible building blocks, solid docs.
- Commit to a branch and open a PR; don't push to `main` directly.
- Budgets and taxonomy are guidelines. The power budget and the effect taxonomy are not exhaustive, and any agent may add an effect that isn't in them. Agents that design cards or mechanics are briefed without the power budget. A separate review agent then costs the designs, flags any that are well outside the budget, and proposes changes that keep the card's creative core. Purpose: costing too early narrows designs to what Battlegrounds already does.
- Heavy compute such as simulations may use up to half the CPU cores and up to half the free memory without asking. Other agents share this computer, so before starting, check its current load: CPU use, committed memory against the commit limit, and the working memory of other running processes. If the machine is already busy, or a run would clearly benefit from more, don't settle for half: ask the owner first. Say how much CPU and memory it would use and roughly how long it would take, ask whether the machine is free right now, and ask how much it may use.
- Pitch ideas concretely. Every mechanic or tribe idea shown to the owner comes with an example unit with full rules text, how it interacts with other cards, why a player would run it, a situation where it is good, and two or three variations. Where it resembles a design the owner may know from another game, say so in a line. Purpose: the owner can't judge an idea from a one-line summary (2 Nov).
- Design reactions are directions. When the owner reacts to a design, the reaction sets what to iterate on, not what changes. Never cut a design straight away: explore what it can teach, push back with an example where it works, or propose a version that does. This applies only to evaluating designs. Purpose: early cuts lose ideas, and the owner's comments on designs are mostly suggestions (2 Nov).
