---
id: rulebook-defaults
group: plays
size: small
headline: About 45 small rulebook edge cases with defaults already filled in
source: design/tribes-and-budget:docs/design/review-queue.md#16
option: Accept them all
option: I'll flag the ones I disagree with
suggested: Accept them all
---
Our rulebook starts from Battlegrounds' rules. Wherever Bramble's differences leave a gap, we've filled in a sensible default: about 45 small rules in all. They're mostly edge cases, the kind you'd only notice when something odd happens. A few examples:

- What happens when you make a triple but your hand is full and all three copies are on the board: the golden unit goes into the first slot that frees up.
- Where a unit that comes back to life goes: its own slot if it's free, otherwise the nearest empty one.
- When a fight is declared a tie: after 200 attacks.
- When a game ends if it somehow runs that long: after round 50, placed by health and armour.

**What we need from you:** skim them and flag any you disagree with. Anything you don't flag counts as accepted.

**Why it matters:** none of these changes how the game feels on its own, but together they're the fine print the code will follow.

## Detail

- **Count:** the review queue says "the other ~45". The rulebook deltas list now counts 44 PROPOSED rules (v0.4, 2 Nov), plus 7 OPEN rules with no default, which are not part of this card. Three of them have their own cards (hero choices 2.2.3, which types are tribes 5.2.2, TFT-style traits 5.2.8). The other four, async lobby rules (2.1.5), tribes per lobby (5.2.5), a minimum front row (8.3.2) and effects that reach the back row (11.5.3), are left open for later and need nothing from you now.
- **Groups of defaults** (rule numbers from the rulebook):
  - Board order and stats: one reading order F1–F4 then B1–B3 (1.2.3); stats clamp at 1,000,000,000 (1.2.4).
  - Game length: game ends after round 50 (2.1.3).
  - Turn order: start of turn (3.2.1) and end of turn (3.4.1).
  - Gold and selling: "maximum gold" effects (4.1.4, which also has its own card, max-gold); a Created unit made golden stays Created (4.3.6); card effects that reroll the shop don't count toward the refresh price steps (4.4.6).
  - Tribes and the pool: type matching (5.2.3); pool returns when a golden is sold or a unit is destroyed (5.3.5, 5.3.7); how the shop draws, and empty slots when nothing is left (6.1.3, 6.1.4); Discover with fewer than 3 options (6.2.3).
  - Triples: full hand and all copies on board (7.3.7).
  - Board geometry: adjacent, neighbour, slot relations, "across from" (8.2.2–8.2.6); moving units (8.3.3, 8.3.5); summon placement (8.4.3–8.4.7); slot effects (8.5.1–8.5.3).
  - Combat: the attack pointer and empty slots (9.4.5, 9.4.7, 9.4.9); untargetable front rows and must-be-attacked (9.5.3, 9.5.4); death order (9.7.1, 9.7.3); returning units (9.8.3); runaway limits of 200 attacks, 10,000 triggers and 5 returns (9.10.1–9.10.3).
  - Placement and scope: same-round eliminations (10.2.2); "your units" means the board (12.2.2); death triggers use the last slot (12.2.3).
  - Seasonal systems not in v0, and no Tier 7 (13.1.1, 13.1.2).
- **The full list** with every default, its Battlegrounds equivalent and what it needs: `design/tribes-and-budget:docs/design/rulebook-deltas.md`. Full rule text: `docs/design/rulebook.md`.

**The original item (review queue, 16):**
> "The other ~45 proposed defaults in rulebook-deltas.md are mostly edge cases with sensible defaults: start and end-of-turn order, pool returns, triples with a full hand, and so on. Skim them and flag any you disagree with. Unflagged ones count as accepted."

Sources: `design/tribes-and-budget`: `docs/design/review-queue.md`, `docs/design/rulebook-deltas.md`, `docs/design/rulebook.md`.
