---
id: architecture-lessons
group: code
size: big
headline: How the real game's code should be built, from the prototype's lessons
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#11
source: proto/core:docs/architecture/prototype-lessons.md
option: Move it, and use the proposals as the starting plan
option: Move it; I'll go through the proposals first
option: Leave it with the prototype
suggested: Move it, and use the proposals as the starting plan
---
Before the prototype, we wrote down eight recommendations for how the real game's code should be organised, so that new rules and odd card effects can be added later without a tangle. Building the prototype tested them against real code, and we wrote up what held up and what didn't. Keeping the game's rules separate from its screens worked well. The way unit stats are stored was the weakest part. The write-up also notes pitfalls in Godot, the game engine we're using.

It ends with proposals for the real game, which are yours to decide. In short: keep what worked, above all the rules running on their own, apart from the screens. Before there are many cards, add a few foundations: work out unit stats from layers instead of overwriting them, give each core rule a hook that other effects can change, and let whole-game and per-player rules plug in, not only rules on units. And keep the prototype's safety nets, such as the 200-game bot run, and time fights on a real phone before deciding anything about speed. The full list is in the details.

The prototype is kept apart from the main project, and its code never joins it, so this write-up would stay with the prototype unless we move it.

**What we need from you:** should it move into the main project's docs, next to the original recommendations? And do you want its proposals as the starting plan for the real game's code, or to go through them first?

**Why it matters:** these choices shape how easily new rules, card effects and game modes can be added for the rest of the project. They're cheap to make now and expensive to change once lots of cards exist.

We'd suggest moving it and starting from the proposals. They come from real code rather than a plan, and any of them can be revisited if it turns out differently when built.

## Detail

- **The doc:** `proto/core:docs/architecture/prototype-lessons.md` (same text on `proto/main`). It grades `docs/design/architecture-notes.md`'s eight recommendations against the prototype's code. Summary: pure headless simulation "Yes, clearly"; board geometry in one module "Yes"; effects as data primitives "Yes, for now"; named queries "Partly", one event queue "Mostly", one randomness service "Partly"; rule modifiers "Not built"; stats in layers "Weakest point".
- **The closing list, "What to carry into real development"** (labelled "proposals from prototype evidence, for the owner to decide"; they answer architecture-notes' open items 2 and 3):
  1. Keep the pure `RefCounted` core, the event log as the UI contract, fixture-checked JSON views, and named RNG streams.
  2. Add, before content grows: stat layers; rule sources above the unit (game, player); query handler lists for the roughly 15 rule functions; status scripts; a selector library; combat sub-streams and an owned hash; geometry as instance data.
  3. Replace untyped mechanic parameters with typed ones, declared once.
  4. Keep strict typing. Budget for its friction at JSON edges and in tests, not in the core.
  5. Keep the soak, the planted-fault check and the library-scene scenarios as standing gates. Add a fight benchmark on a real phone before deciding anything about a compiled core.
- **Related verdict in the doc:** keep scripts for new mechanics and data for numbers; consider data-driven triggers at about 50 units (a guess); avoid a general data language before then.
- **The same list in plain words** (our readings):
  1. Keep the rules running on their own, apart from the screens; keep the fight log as the one thing the screens read; keep checking the screens' data against saved examples; keep separate random-number streams for separate jobs.
  2. Before there are many cards, add: unit stats worked out from layers (base, buffs, auras, golden) instead of overwritten; whole-game and per-player rules (like hero powers) that plug in, not only rules on units; a hook on each of the game's 15 or so core rules that other effects can change; each status, like Nightshade, as its own small piece; one shared toolkit for picking units ("the units behind this", "the highest-Attack enemy"); separate randomness inside a fight, with our own way of mixing seeds; the board's shape described as data.
  3. Give each mechanic's settings declared types, so mistakes are caught.
  4. Keep the strict type checking, and expect its cost where data is loaded and in tests, not in the core.
  5. Keep the 200-game bot run, a test that plants a deliberate bug to prove the checks catch it, and the sandbox fights as standing checks; time fights on a real phone before deciding whether the core needs a faster language.
- **Where it would go** isn't specified in the question; "next to the original recommendations" is our proposal. The architecture workstream's next step reads "Bring the lessons to `main` if you agree." The suggestion is ours.
- `proto/*` never merges into `main`.

**The original question (prototype question 11):**
> "Where the architecture lessons live. `docs/architecture/prototype-lessons.md` grades architecture-notes' eight recommendations against the prototype code and lists Godot gotchas. It is written for real development, but `proto/*` never merges into `main`. Should it go to `main`, and where? Its closing list is a set of proposals for you (for example, scripts for new mechanics and data for numbers), not decisions."

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`; `proto/core:docs/architecture/prototype-lessons.md`; `portal/main:docs/workstreams/architecture.md`.
