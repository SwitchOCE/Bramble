# Architecture notes: rule modifiers without spaghetti

The owner asked how to make game-warping modifiers addable later without the breakage seen in Battlegrounds, and whether "chain of responsibility" is the right idea. This is a recommendation to decide on, not a decision.

## Why games like Battlegrounds break

This is inference, since their code isn't public. The usual cause is that each new system reaches into the game state its own way. Anomalies, trinkets, quests, hero powers and card text each patch the shop, combat or economy from a different place. Two problems follow:

- No single place answers "what is the reroll cost right now?"
- No single order decides which modifier applies first.

Every new system then interacts with every old one in ways nobody listed.

## The recommendation: rule queries, not rule code

Chain of responsibility is the right instinct, scoped tightly. Make every rule the game asks about a named **query** with one default answer, and let modifiers wrap that answer in a fixed, documented order.

**1. Rules are named queries.** Each one asks a question about the game state:

```
rerollCost(player)           -> gold
sellValue(unit)              -> gold
goldCarryOver(player)        -> gold
shopOffer(player, slots)     -> units
attackOrder(board)           -> units
validTargets(attacker, foe)  -> units
tripleReward(player)         -> reward
```

Each query has a base implementation, the "Battlegrounds plus our deltas" answer. Shop, combat and economy code call the query and never compute the rule themselves.

**2. Modifiers wrap queries.** An anomaly, trinket, quest, hero power or card registers handlers on the queries it changes. Each handler receives the current answer and returns a new one.

- Handlers run in a defined order: by **layer** first, then priority, then registration time.
- Example layers: base rules → game-wide modifiers (anomalies) → player modifiers (hero, quests, trinkets) → unit modifiers (card text) → hard caps.

Adding "rerolls cost 1 less but escalate twice as fast" is then one handler on one query. You can read every handler on a query in one list, so interactions can be listed and tested.

This is chain of responsibility, middleware or interceptors, applied per query instead of as one global chain. The per-query scope is what stops it turning into spaghetti.

**3. Triggers go through one event queue.** "When this attacks", "when the unit in front of this dies" and "start of combat" become events on a single queue, resolved in a fixed order with explicit death and cleanup phases, much like Hearthstone's death phases or Magic's stack. Cards never call each other directly.

**4. Stats use layers.** Attack and health are computed, not mutated:

- base value
- "set to" effects
- additions
- multipliers
- clamps

This is the idea behind Magic's layer system. "Set to 1" then "+2" always gives 3, whatever order the effects were cast in.

**5. Board geometry is one module.** The two-row staggered board is the part most likely to change during prototyping. Put all positional questions in one place:

- `inFrontOf(unit)`, `behind(unit)`, `adjacent(unit)`
- `leftmost(row)`, `row(unit)`, `attackOrder`

Cards ask the geometry module. They never do slot arithmetic. Then changing the board shape, or letting an anomaly change it, means changing one module.

**6. Effects are composed from small primitives in data.** A card is data: stats, types and a list of effects. Each effect is built from three kinds of piece:

- **Triggers**: on buy, on attack, on death, start of combat…
- **Selectors**: self, units behind this, random friendly Owl, leftmost enemy…
- **Actions**: buff, summon, damage, discover, gain gold…

New cards are mostly new data. New code is only needed for genuinely new primitives.

**7. Randomness and selection are one service.** This covers the "pick one of three" example:

```
pick({
  pool,                 // which pool: shop tier, tribe pool, created-only pool…
  count,                // 3
  weights,              // pool's own algorithm: uniform, tier-weighted, pity…
  include, exclude,     // rules for what may appear
  remove,               // take from the shared pool or not
  withReplacement,
  rng                   // named seeded stream: "shop", "discover", "combat"
})
```

- Each purpose gets its own seeded random stream, so a modifier that adds a random event can't shift every later shop roll.
- Replays stay reproducible, and balance simulations can rerun a game exactly.

**8. The simulation is pure and runs headless.** The rules engine has no rendering, input or platform code. That allows:

- thousands of simulated games for balance;
- golden-replay tests that catch when a new modifier changes old behavior;
- a presentation layer that just plays back combat logs.

## A precedent in your own work

The Autobattler repo already uses this kind of layering: a pure `core`, typed `content`, `app` use cases, ports for `infra` and `platform`, and a `presentation` layer, with the dependency rule enforced by a check script. That is a proven starting template here. The rule-query and modifier pipeline would live in `core`.

## Decisions this leaves open

- Engine and language. Godot with GDScript is the precedent; a pure TypeScript or C# rules core is also worth considering if a web or server-authoritative build matters.
- Whether queries are typed functions in code or declared in data.
- How much of the card language lives in data versus code. The usual rule: data for composition, code for primitives.
