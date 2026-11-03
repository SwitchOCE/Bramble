---
id: architecture-lessons
group: code
size: big
headline: Move the prototype's code lessons into the main project, or leave them?
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#11
option: Yes, add it to the main project docs
option: Leave it with the prototype
suggested: Yes, add it to the main project docs
---
Before the prototype, we wrote down eight recommendations for how the real game's code should be organised, so that new rules and odd card effects can be added later without a tangle. Building the prototype tested them against real code. We wrote up what held up and what didn't: for example, keeping the rules separate from the screens worked well, while the way unit stats are stored was the weakest part and should change. It also notes pitfalls in the game engine we're using, Godot.

The prototype is kept apart from the main project, and its code never joins it. So as things stand, this write-up would stay with the prototype too.

**What we need from you:** should it move into the main project's docs, next to the original recommendations, so the real build starts from it?

**Why it matters:** it's the most concrete guide we have for how the real game's code should be built, and it would be easy to lose if it stays with the prototype.

We'd suggest moving it. It ends with a list of proposals for the real code (like computing stats in layers, and keeping mechanics as small scripts with their numbers in data). Moving the write-up doesn't approve those.

## Detail

- **The doc:** `proto/main:docs/architecture/prototype-lessons.md` (written on `proto/core`). It grades `docs/design/architecture-notes.md`'s eight recommendations against the prototype's code. Summary: pure headless simulation "Yes, clearly"; board geometry in one module "Yes"; effects as data primitives "Yes, for now"; named queries, one event queue and one randomness service "Partly" or "Mostly"; rule modifiers "Not built"; stats in layers "Weakest point".
- **Closing list (proposals for you, not decisions):** keep the pure core, the event log as the UI contract and named RNG streams; add stat layers, rule sources above the unit, query handler lists, status scripts, a selector library, combat sub-streams and geometry as instance data before content grows; typed mechanic parameters; keep strict typing; keep the soak and scenario gates, and benchmark fights on a real phone.
- **Where it would go** isn't specified in the question; "next to the original recommendations" is our proposal. The architecture workstream's next step reads "Bring the lessons to `main` if you agree."
- `proto/*` never merges into `main`.

**The original question (prototype question 11):**
> "Where the architecture lessons live. `docs/architecture/prototype-lessons.md` grades architecture-notes' eight recommendations against the prototype code and lists Godot gotchas. It is written for real development, but `proto/*` never merges into `main`. Should it go to `main`, and where? Its closing list is a set of proposals for you (for example, scripts for new mechanics and data for numbers), not decisions."

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/architecture/prototype-lessons.md`; `portal/main:docs/workstreams/architecture.md`.
