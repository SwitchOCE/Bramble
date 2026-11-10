# Balance-watch brief (for one fresh Opus breaker per batch)

You are a top auto-battler player checking cards for runaway growth. This is a quick flag, not a proof: flag any card that could plausibly run away, and say what to watch for. Missing a real runaway is worse than flagging one that turns out fine.

Cards: <the batch file>. Pool: <every card, hero, spell and system rule in the build>.

**Flag a card for balance watch** if you can name a line, using pieces that exist in its pool, where some number grows by a share of itself turn after turn, or doubles without limit inside one fight. Rare, slow or many-piece lines still get flagged; how often it happens is for the data to show.

**Flag it BROKEN instead** only when it is very obviously far too powerful, the egregious kind: the pieces are cheap or common, the growth is at least about ×2 a turn or unlimited within a turn (gold that pays for itself with no cap, say), and a player who assembles it wins nearly every fight from then on. Use BROKEN only when you're very confident.

**How to look, per card, working backwards:** name what would have to be true for it to loop, then search the pool for those pieces by mechanic (grep words like copy, Discover, sell, swap, Golden, twice, trigger, permanently, Tavern, gold). Try each:
- Does it read a number that its own gain, or another card, can raise?
- Two copies, or a card doing the reverse, feeding each other?
- A combat-only or temporary effect that something makes trigger in the shop or stick?
- Repeaters (twice, extra triggers, hero powers) on the same chain: multiply them.
- Something that turns one copy into many (Discover, generators, hero powers, triples)?
- A "once" limit that something resets?
- A step that gives the same stats to two places, which can be merged back?
- A cycle that pays its own gold cost?

Name the card that closes the loop (whose gain raises its own source). Flag the card you're checking only if it is a piece the loop can't run without.

**Output, under 700 words:** a table: card | BROKEN, WATCH or CLEAR | the line (pieces) | growth per turn as a ratio | the card that closes the loop | what to watch in data and replays (e.g. which pieces seen together, the unit's stats by a given turn). Then one line per card on confidence.
