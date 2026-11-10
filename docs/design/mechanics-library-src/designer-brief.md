# Brief: mechanics library designer (batch N)

You are a card designer for Bramble, a Battlegrounds-style auto-battler set in a European woodland (repo C:\Users\keech\Documents\Bramble; its CLAUDE.md applies). You turn one batch of mechanic ideas into concrete, playable designs the owner can picture. Costing happens later, in a separate review: you design by feel.

## Your input

- Your batch: `scratchpad/library/batchN.md` (path below). Each entry has rules, the system rule it bends, a creature, an archetype, example units and a rules review. Budget lines were removed on purpose.
- The owner's reactions to 15 shortlisted mechanics: `scratchpad/library/owner-reactions.md`.
- The owner's words: `docs/design/owner-notes/archive/2026-11-02h-checkpoint-read-through.md` and `2026-11-02i-reactions-are-directions.md` (read both), plus `2026-11-02e` and `2026-11-02f` for why Bramble invents its own mechanics.
- Rules: `docs/design/rulebook.md` (v0.4). Board: front row F1–F4, back row B1–B3, fixed slots, free moves in the Recruit Phase, no turn timer, snapshot fights.
- Tribes (draft, for type lines and flavour): `docs/design/archetypes.md` section 4.1. Archetype IDs: ECO, WIDE, TALL, MEDIUM, STICKY, spices SCAM and BURST (section 1.2). Neutral units also exist.
- Flavour, optional: `docs/folio/woodland-folio.html`.

**Don't open** `docs/design/power-budget.md`, `power-budget-review.md`, `economy-bounding.md`, `effect-taxonomy.md` or its CSV, `docs/design/mechanics-ideas.md`, or anything under `docs/research/` that prices cards. Ignore any budget figures you meet elsewhere. Purpose: costing too early narrows designs to what Battlegrounds already does.

## What to make for every mechanic in your batch

Follow the working rule "Pitch ideas concretely" in CLAUDE.md. For each mechanic:

1. **summary**: one plain sentence a new player would understand.
2. **rules**: the exact keyword text. Keep the idea; tighten wording where the rules review found a gap.
3. **units**: two or three example units that play together, each with name, tier (1–7), Attack, Health, tribe (or Neutral) and full card text. At least one should be low tier unless the mechanic only works late.
4. **how_they_play**: how those units interact with each other and with other cards (2–4 sentences).
5. **why_run_it**: why a player would want this on their board.
6. **scene**: a short situation from the player's side where it is good, turn by turn ("Turn 3, you buy... In the fight, ...").
7. **good_against** and **weak_against**: one line each.
8. **variations**: two or three other versions, each with a name and its text.
9. **similar_to**: optional. One line if it resembles a design the owner may know from any game; leave empty otherwise.
10. **owner_direction** and **designer_response**: where the owner reacted (owner-reactions.md, 02h, 02i), copy the reaction and say how you took it. The owner's design reactions are directions, not decisions: follow them, or push back with an example where the original works, or propose a version that does. Nothing is cut. Where the owner didn't follow an idea (Whistle, Thicket, Mark, Both Ends, Dig Down), the example cards and scene must make it clear. Fast stays: explore what it teaches, including time-bound versions (pillar 13 in `docs/design/pillars.md`).
11. **open_questions**: rules or design questions left open, if any.

You may add up to three **new mechanics** that your batch inspires, in the same format, with `num` set to `"new"`.

Keep each mechanic's number, name (unless a variation is clearly better; then give the old name in `old_name`), label (NEW, VARIANT of X, RESKIN) and group. Write in plain English: short sentences, no jargon beyond the game's own terms.

## Output

Write one JSON file: `scratchpad/library/design-batchN.json`, an array of objects with exactly these keys:

`num` (int, or "new"), `name`, `old_name` ("" if unchanged), `label`, `group`, `summary`, `rules`, `bends`, `creatures`, `archetypes` (array of IDs), `units` (array of {`name`, `tier`, `attack`, `health`, `tribe`, `text`}), `how_they_play`, `why_run_it`, `scene`, `good_against`, `weak_against`, `variations` (array of {`name`, `text`}), `similar_to`, `owner_direction`, `designer_response`, `open_questions` (array of strings), `source` (the entry's "From" line).

Check that the file parses as JSON (for example `python -I -c "import json,sys;json.load(open(sys.argv[1],encoding='utf-8'))" <file>`). Don't edit any repo file. Return one line: the file path and how many mechanics it holds, including new ones.
