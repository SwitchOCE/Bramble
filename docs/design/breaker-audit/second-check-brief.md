# Second check brief (one fresh Opus for the WATCH cards from a flag check)

Bramble is a Battlegrounds-style auto-battler (board of 7, tiers 1–6, triples make golden). You are a top player of it.

The game is in the repo /home/alex/code/Bramble-ideation-rules. Read-only: never edit, never run Godot or any script. Read only:
- `content/` (units, spells, heroes; `content/pass3/rates.json` under `presets.B` holds the live numbers and overrides card JSON);
- `src/core/` (how cards really behave; trust the code over a card's text or keyword line, and say where they differ);
- `docs/design/rulebook.md` (system rules).
Nothing else in `docs/`, no git history, no other folders or worktrees, no web, so the check stays fresh.

Cards: <each WATCH card, with the first check's line and its open question>. The whole of `content/` is the pool.

**You are the second check.** A first check flagged the cards below as WATCH: it found a line that might run away but couldn't confirm a step. Decide each one: BROKEN or KEEP. Missing a real runaway is worse than flagging one that turns out fine, but don't call a line BROKEN if a step fails.

For each card:
1. **Check every step** of the line against the card texts (and the code, where you have it). Name any step that fails, and why.
2. **If a step fails, look for a substitute:** another piece in the pool that does the same job. The first check may have picked the wrong piece for a loop that is real.
3. **Settle the open question** with the text or code. Where the text prints no limit, assume there is none: limits are printed where they apply.
4. **Script the best line for six turns** (or one fight, for an in-fight line) with numbers, and give the ratio between turns.
5. **Verdict.** BROKEN: the line works and some number grows by a share of itself turn after turn with no cap (about ×1.3 a turn or more, sustained), or without limit inside one turn or one fight. Rarity, cost, a period or needing several cards don't save it; say how rare it is. KEEP: a step fails with no substitute, or the growth is capped, linear, or two linear things multiplied. ASK OWNER only if one rules question decides it and the text or code can't settle it; state the question.

Pin a BROKEN on the card that closes the loop (the one whose gain raises its own source), which may not be the card being checked.

**Output, under 900 words:** a table: card | BROKEN, KEEP or ASK OWNER | the line as checked | the step that failed, if any | six-turn numbers and ratio | closer | how rare. Then one line per card on confidence.
