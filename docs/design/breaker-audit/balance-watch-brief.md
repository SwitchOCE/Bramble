# Flag check brief (one fresh Opus per batch of new or changed cards)

Bramble is a Battlegrounds-style auto-battler (board of 7, tiers 1–6, triples make golden). You are a top player of it.

The game is in the repo /home/alex/code/Bramble-ideation-rules. Read-only: never edit, never run Godot or any script. Read only:
- `content/` (units, spells, heroes; `content/pass3/rates.json` under `presets.B` holds the live numbers and overrides card JSON);
- `src/core/` (how cards really behave; trust the code over a card's text or keyword line, and say where they differ);
- `docs/design/rulebook.md` (system rules).
Nothing else in `docs/`, no git history, no other folders or worktrees, no web, so the check stays fresh.

Cards: <the batch>. The whole of `content/` is the pool.

**Flag each card BROKEN, WATCH or CLEAR.** Missing a real runaway is worse than flagging one that turns out fine.
- **BROKEN:** you can name a line, with pieces that exist in the pool, that works as written (check every step against the card text, and the code where you have it), in which some number grows by a share of itself turn after turn with no cap (about ×1.3 a turn or more, sustained), or grows without limit inside one turn or one fight. Rare pieces, a gold cost, a period ("every 3 turns") or needing several cards do **not** make it WATCH: Battlegrounds had to remove rare loops too. Put how rare it is in the note.
- **WATCH:** a line like that exists, but a step rests on something you couldn't confirm (a rules question, a random target, whether a limit applies), or it may be capped; or the loop has no cap but grows slower than about ×1.3 a turn. Say exactly what would decide it.
- **CLEAR:** no such line. Linear growth, and two linear things multiplied together (units × buff per unit), are CLEAR.

**Pin the loop on the card that closes it:** the one whose gain raises its own source. Flag the card you're checking only if the loop can't run without it. A card that only makes someone else's loop bigger is CLEAR; name the loop's closer in the note. If you find a loop that none of your cards is in, list it at the end.

**How to look, per card, working backwards:** name what would have to be true for it to loop, then search the pool for those pieces by mechanic, not by name. Try each:
- Does it read a number that its own gain, or another card, can raise?
- Two copies, or a card doing the reverse, feeding each other?
- A combat-only or temporary effect that something makes trigger outside combat or stick?
- Repeaters (twice, extra triggers, hero powers) on the same chain: multiply them.
- Something that turns one copy into many (discover, generators, hero powers, triples)?
- A "once" limit that something resets?
- A step that gives the same stats to two places, which can be merged back?
- A cycle that pays its own gold cost?

**Output, under 900 words:** a table: card | BROKEN, WATCH or CLEAR | the line (pieces) | growth per turn or per fight, as a ratio | the card that closes the loop | for WATCH, what would decide it; for BROKEN, how rare it is. Then one line per card on confidence.
