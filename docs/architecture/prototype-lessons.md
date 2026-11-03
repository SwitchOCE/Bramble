# Prototype lessons for the architecture

The overnight prototype (4 Nov 2026, branch `proto/core`) built a playable rules core in strict GDScript: recruit phase, pool, triples, bots, a 4–3 board, and 16 library units with 19 mechanic scripts. This note compares it with [architecture-notes.md](../design/architecture-notes.md) and [engine-language.md](../research/engine-language.md), and says what real development should keep, change or avoid. It is written from the code. The prototype was built to a deadline, not to the architecture notes, so most gaps below are deliberate shortcuts, not failures of the recommendation.

**Numbers used below:**
- Code size: `src/core` is 3,271 lines. `combat/combat.gd` is 731 of them. The 19 mechanic scripts are 6–39 lines each, 325 in all. Tests are 2,640 lines.
- Tests: about 200 GUT tests run in about 1.5 s.
- Soak (`tools/checks/soak.sh`): 200 bot-only games played 8,667 fights in 19 s on one core. That is about 95 ms per game including recruit turns and bots, and about 2 ms per fight.

## Summary

| Recommendation | What the prototype did | Held up? | Keep / change |
|---|---|---|---|
| 1. Rules are named queries | Plain functions and config tables (`refresh_cost`, `sell_value`, `_damage_cap`) | Partly | Keep the functions, add the query layer before the first modifier |
| 2. Modifiers wrap queries in layers | Not built | — | Build it; see "Where rule modifiers would plug in" |
| 3. One event queue for triggers | Hooks called in fixed code order, explicit death passes, one thorns queue | Mostly | Keep explicit phases; write the order down in one place |
| 4. Stats in layers | Stats mutated in place; auras applied as deltas | Weakest point | Change: compute stats from layers |
| 5. Board geometry in one module | `board_geometry.gd` | Yes | Keep; remove the one leak |
| 6. Effects as data primitives | Hook scripts with JSON parameters | Yes, for now | Keep scripts for mechanics, data for numbers |
| 7. One randomness service, named streams | Named streams per purpose outside combat; one stream inside combat | Partly | Split the combat stream; own the hash |
| 8. Pure, headless simulation | `RefCounted` only, no Nodes | Yes, clearly | Keep without exception |

## The recommendations, one by one

### 1. Rules are named queries

**What was built.**
- `RecruitRules` has one function per economic rule: `refresh_cost`, `sell_value`, `shop_size`, `base_upgrade_cost`, and the Triple Reward tier in `_triple_reward`.
- `GameSession._damage_cap` covers damage.
- Every number comes from `GameConfig`, mostly as per-turn tables (`income_by_turn`, `damage_cap_by_turn`, `upgrade_costs`).
- Combat has the same kind of single points: `_first_side`, `_choose_attacker`, `_choose_target`, `_is_quick` and `_split` (all in `combat/combat.gd`).

**Did it hold up?** The single place for each rule held up: no other code computes a refresh cost. The query names exist but have no wrapping: nothing can register "rerolls cost 1 less".

**Keep, change, avoid.**
- Keep one function per rule, and let `GameConfig` hold the base numbers.
- Before the first anomaly or hero power, turn these functions into queries that walk a handler list.
- Avoid modifiers that edit `GameConfig` at run time. It is tempting, because an anomaly then becomes "set `hand_limit` to 8", but order and undo become invisible.

### 2. Modifiers wrap queries in layers

**Not built**, because no unit changes a game rule. The nearest thing is golden doubling in `MechanicRegistry.params_for`, a tiny layer that worked without a bug. What's missing is a modifier owner above the unit; see "Where rule modifiers would plug in".

### 3. Triggers go through one event queue

**What was built.** There is no general queue; the order lives in code. `_attack` runs declaration hooks (defender's side first), deaths, Nightshade, the strikes and exchanges, thorns, deaths again, then "after" effects. `_resolve_deaths` removes every dying unit before any death effect runs. Thorns are the one real queue, and a trigger counter caps runaway chains.

**Did it hold up?** Yes, for these 16 units: the log reproduced the hand-written fixture `combat_nightshade.json` exactly, and the soak found no ordering crashes.

**Where it broke.** All three rules bugs the scope review found were ordering or definition bugs, not crashes:
- **Quick was computed once, before the declaration.** A Duellist pricked by Both Ends still struck first.
- **Swarm didn't check `mired`.** "Stopped" isn't a concept the engine has; each mechanic must remember it.
- **"Can attack" meant two things.** It meant "can be chosen in the order" and also "counts as able to attack for 9.9.1". Whistle needed them split (`can_act` vs `can_attack` in `combat_unit.gd`).

**Keep, change, avoid.**
- Keep explicit phases. They made the log easy to check against the rulebook.
- Write the phase order down as a list next to the code, and have each hook say which phase it runs in.
- Define shared states ("stopped", "can attack", "undamaged") once, as queries on the unit, not ad hoc in each script.
- Avoid evaluating state ahead of time and carrying it through a phase. Re-ask at each step.

### 4. Stats use layers

**What was built.** Stats are mutated in place: `buff()` adds and clamps, damage subtracts, auras are applied as the difference since the last recalculation (`_recalc_auras`), and permanent buffs are baked into `RecruitUnit.attack`/`health`.

**Did it hold up?** It held up because no unit sets a stat, and only one unit has an aura. Even so it needed a rule invented on the spot: "losing a Health aura never takes Health below 1". The golden triple rule ("keeps every buff, at least the golden base") had to subtract base stats to recover the buffs, because buffs aren't stored separately (`RecruitRules._combine`).

**Change.** This is the clearest "do it properly" item. Store base, "set to", additions and multipliers per unit, and compute Attack/Health on read. "This combat" buffs, permanent buffs, auras and golden doubling then each have their own layer, and triples can sum buffs directly.

### 5. Board geometry is one module

**Held up well.** `board_geometry.gd` holds:
- the slot labels and the relations table: in front of, behind, adjacent, neighbours, across;
- the summon order table.

Mechanics ask it (`in_front_of`, `behind`, `across`, `is_front`), and the bots and the UI use the same slot numbers.

**One leak.** `mechanics/both_ends.gd` has its own `OTHER_END` table ({F1↔F4, B1↔B3}). Add `row_end_partner(slot)` or "leftmost/rightmost in row" (rulebook 8.2.5) to the module.

**For modifiers:** the geometry is `const` tables. An anomaly that changes the board shape needs those tables to become instance data passed in, which is cheap now and expensive later.

### 6. Effects composed from data primitives

See "Hook model vs data-driven effects" below.

### 7. Randomness and selection as one service

**What was built.**
- `GameSession._derive(label)` seeds a separate `RandomNumberGenerator` per purpose from `"seed|label"`: pairing, placement, each player's shop, each bot, and each fight (`fight:round:a:b`).
- Nothing uses the global RNG.
- Same seed, same game: tested in `test_full_games.gd`.

**Did it hold up?** Between purposes, yes. A bot's choices can't shift a shop.

**Inside a fight it fell short.** One stream serves:
- who goes first and Start of Combat order;
- target choice;
- Whistle ties and Nightshade's tie-break.

So adding any random mechanic changes every later target in every fight that has it. The Triple Reward draws from the player's shop stream, so a triple shifts the next shop. There is no `pick()` service; `UnitPool.draw` grew a `min_tier` parameter instead.

**Keep, change, avoid.**
- Keep named streams.
- Give combat sub-streams: targeting, first side, and per-mechanic randomness. Give the Triple Reward and Discover their own stream.
- Own the hash. `String.hash()` is Godot's, and nothing guarantees it stays the same across engine versions. Seeds should survive an upgrade, so use a small fixed hash in the core, as Autobattler did.

### 8. Pure, headless simulation

**Held up without exception.** Every core class is `RefCounted`; there is no Node, scene or autoload. That is why all of these were cheap:
- 200 GUT tests in 1.5 s;
- a soak of 8,667 fights in 19 s;
- a sandbox that loads library scenes;
- a UI built in parallel against fixture JSON by a worker who never shared a file with the core.

**Speed.** About 2 ms per fight on a modest server core puts a 100k-fight batch at roughly a minute on four cores, well inside the "about 10 minutes on 4 cores" that engine-language §8 set for moving to a compiled core. It is not a phone measurement.

## Strict typing in practice

The project raises GDScript's typing warnings to errors in `project.godot`, compiles every script in the gate, runs gdlint, and bans tests without asserts. The prototype's experience:

**Where it cost time.** Almost all the cost was at the edges where untyped data enters:
- `int(x)` or `bool(x)` on a value from a Dictionary or JSON is an "unsafe call argument". The core has 49 calls to `CoreUtil.to_int`/`to_bool` to get around it.
- `null if a else b` with a typed `b` doesn't compile. Nullable fields need an `if` (`CoreUtil.int_or_null`).
- `x as Dictionary` on a Variant is an "unsafe cast". You have to declare a typed local first.
- An `Array` element passed where `Dictionary` is expected fails ("requires the subtype").
- Every GUT assert receives Variants. Every test file starts with `@warning_ignore_start("unsafe_call_argument")`.
- Integer division warns every time (`@warning_ignore("integer_division")` in 3 places).
- gdlint's limits (6 returns, 20 public methods, 100 columns) forced validation code into `elif` chains and split functions.

**What it caught.** Mostly real but small things before any test ran: wrong argument types, a parameter shadowing `seed()`, a variable redeclared in one scope. It never caught a rules bug; the tests and the scope review did that. Its biggest value was confidence that a green compile meant the typed core could be called safely.

**One trap.** Because warnings are errors, a stray unused variable is a parse error. The core then fails to load, and a tool that doesn't check for that silently runs nothing. The soak ran 0 fights and reported 0 violations until it learned to count fights.

**Typed classes vs Dictionaries at the core/UI boundary.**
- **Inside the core, typed classes worked** and should stay: `CombatUnit`, `RecruitUnit`, `PlayerState`, `Hit`, `Mechanic`. The friction was all around Dictionaries.
- **Mechanic parameters** are the worst spot. Each script calls `CoreUtil.to_int(params.get("attack", 0))`, and the parameter kinds live in three tables that must agree: `MechanicRegistry.BUILT`, `tools/checks/check_units.py` and SPEC §4.3. Typed parameter classes per mechanic, or one typed `Params` object with `get_int`/`get_string` and its kinds declared once, would remove most of the 49 conversions and two of the three tables.
- **At the boundary to the UI**, Dictionaries worked well. Events and views are JSON-shaped, checked against fixture files by key, and were consumed by a UI worker in parallel without coordination. Typed Resources there would tie the UI to core classes and lose the "board in, log out" seam that engine-language §6 recommends for portability. Keep them, but generate or check them from one schema. Today the fixtures are that schema, and that was enough.

## Where rule modifiers would plug in today

| Kind of modifier | Plug-in point today | What's missing |
|---|---|---|
| Economy (reroll, sell, income, upgrade) | `RecruitRules.refresh_cost`, `sell_value`, `start_phase` income, `base_upgrade_cost` | A handler list per query, and a way to scope a handler to one player |
| Shop contents | `RecruitRules._fill_shop`, `UnitPool.draw` | A `pick()` service with include/exclude and weights |
| Hand and board size | `GameConfig` `hand_limit`; geometry `const` tables | Geometry as instance data |
| Damage and elimination | `GameSession._damage_cap`, `Combat._finish` | Query wrapping |
| Combat order and targeting | `Combat._first_side`, `_choose_attacker`, `_choose_target` | Hooks that aren't owned by a unit |
| Unit text | `Mechanic` hooks (15 combat hooks and queries, 1 recruit hook) | Recruit hooks beyond End of Turn: on buy, sell, play, start of turn |
| Golden and triple rules | `MechanicRegistry.params_for`, `RecruitRules._combine` | Stat layers (above) |

**The main gap is ownership.** A `Mechanic` today hangs off a unit. To add anomalies, hero powers or trinkets, give `GameSession` and each `PlayerState` their own list of rule sources. Each one implements the same hook and query interface. Run them in the architecture notes' layer order: base → game → player → unit → caps.

## Hook model vs a data-driven effects engine

**What was built.** Each mechanic is one stateless script extending `Mechanic` (`mechanics/mechanic.gd`, every hook a no-op). Units name it in JSON with numeric parameters. The registry loads scripts by id, and one shared instance serves every unit, so all state lives on the unit.

**Evidence from the 19 scripts.**
- **Small.** Median 16 lines. The largest are Bide (39) and Both Ends (36). Each was written, tested and committed on its own, several per hour.
- **Half were plain data in disguise.** Bristle, Fox Notary, Sett Warden, the Woodpecker's buff, death summon, Fast and Mark are each one trigger, one selector and one buff or damage. A triggers/selectors/actions engine would describe them directly.
- **The rest changed the engine, not the card.** Peck (strike count and split), Swarm (joiners), Quick (exchange order), Whistle (a turn that isn't an attack), Bide (skip and pass on), Hunker and Shell (damage modifiers), and Nightshade (Health loss that isn't damage). Each needed a new query or phase in `combat.gd`, and the script itself was a few lines. A data-driven engine would have needed the same new primitives. Data would not have saved that work.
- **Statuses leaked into the engine.** `combat.gd` names `nightshade`, `mired`, `first_bite`, `shell` and `warned` directly. It also maps each status to a unit file for its rules text (`STATUS_SOURCES`). That makes it the one file every new mechanic touches.

**Verdict.** For this stage the hook model was right. It is quick to add, easy to test one mechanic at a time, and readable next to its library entry. For real development:
- **Keep** scripts for new primitives and data for numbers.
- **Change:** move statuses into their own small scripts or classes, each owning its effect, so `combat.gd` stops growing per mechanic.
- **Add** a selector library. "Units behind", "other units of tribe X" and "highest-Attack enemy" are each written inline today, and Whistle and Nightshade each wrote their own tie-break.
- **Consider data for triggers** once there are 50+ units. The common pattern (trigger → selector → buff or damage) is clear from this set.
- **Avoid** a general data language before then. It would have slowed tonight down and still needed code for every new keyword.

## Testing and what made it trustworthy

**What was built:** GUT tests named by rule number, one file per mechanic citing its library entry, a replay of the hand-written fixture fight, bot-only full games with a pool-conservation check every round, the soak, and scenarios whose `expect` lists name the events each library scene must show.

**What made tests trustworthy:**
- **Fixtures as the contract.** The core and the UI were checked against the same JSON files, so drift showed up as a failed key comparison.
- **Asserting on the event log**, not on internal state. The log is what the player sees.
- **Planting faults in the soak.** A sell that loses its pool copy, goldens at 1 Health, and summons into a taken slot each turned it red. A clean result meant little until that was shown.
- **An independent review.** It found the three ordering bugs, plus a test whose `else` branch passed without checking anything.

**What made tests fragile:**
- **Randomness.** With equal unit counts, 9.2.1 picks the first attacker at random, so some tests passed or failed on the seed. A few tests loop over seeds to find one where a target is chosen, and any change in how much randomness a fight uses can break them. Giving the side that should go first an extra 0-Attack unit fixes the first; separate combat streams would fix the second.
- **Accidental passes.** One test compared absolute Attack where it meant the change, and passed because the base was 0. Boards of identical units started forming triples once triples were built; use goldens as filler.

## Gotchas, with file references

Most are covered above. The ones that aren't:

- `src/core/mechanics/mechanic_registry.gd`: one shared instance per mechanic. Scripts must never keep state on `self`.
- `src/core/combat/combat.gd` `_attack`: the `attack` event's `quick` field is the state at declaration; the damage order shows what actually happened.
- `docs/prototype/SPEC.md` §4.1: the planned hook list drifted from the built one, with renames and new queries. The "milestone B picks" in §9 record what was built.
- `export_presets.cfg`: `include_filter` is empty, so `content/units` and `content/scenarios` JSON aren't exported yet.
- **Committing mechanics:** every mechanic adds a line to the shared registry. Commit each with its own line, or some commits won't pass on their own (milestone B's first three don't).

## What to carry into real development

1. Keep the pure `RefCounted` core, the event log as the UI contract, fixture-checked JSON views, and named RNG streams.
2. Add, before content grows:
   - stat layers;
   - rule sources above the unit (game, player);
   - query handler lists for the roughly 15 rule functions;
   - status scripts;
   - a selector library;
   - combat sub-streams and an owned hash;
   - geometry as instance data.
3. Replace untyped mechanic parameters with typed ones, declared once.
4. Keep strict typing. Budget for its friction at JSON edges and in tests, not in the core.
5. Keep the soak, the planted-fault check and the library-scene scenarios as standing gates. Add a fight benchmark on a real phone before deciding anything about a compiled core.
