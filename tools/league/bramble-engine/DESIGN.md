# Port interfaces and ownership

The GDScript source fingerprint in [`league/build.json`](../league/build.json) is authoritative.
Rust modules mirror its files. Script fields retain their names, including private fields.
`todo!("port <source>:<function>")` marks gameplay for the later workers; mechanics also mark
unported hook overrides. Constructors named `_init` become `new` because Rust reserves no
constructor name. Default arguments are explicit at Rust call sites.

## Shared values

Stateful objects use `type FooRef = Rc<RefCell<Foo>>`. Nullable objects are `Option<FooRef>`.
`Array<T>` and `Dictionary<T = Variant, K = String>` share container storage through
`Rc<RefCell<_>>`; cloning them aliases, and `duplicate()` copies the container shallowly.
Dictionary uses insertion-ordered `IndexMap`; removal must use `shift_remove`.
Dictionary generic arguments put values first so `Dictionary<CardHeapRef>` is convenient.
Godot integers and enum values are `i64`. Strings and StringNames both use `String`.
Board slots are `Array<Option<UnitRef>>` (combat uses `CombatUnitRef`).

`Variant` represents JSON-shaped actions, results, events and raw mechanic parameters.
It does not erase typed object references: typed object maps remain typed dictionaries.
`ToState` produces `RecordState.value` output; `field_names` lists all script variables.
UnitDef serializes as its id and BoundMechanic as `{id, params, granted}` even though their
script field lists include additional fields. WeakRef objects serialize as `{}`.

## Hooks and borrowing

A mechanic instance is stateless and shared as `Rc<dyn Mechanic>`. Hooks borrow it with
`&self`, take an explicit `&mut Combat` or `&mut RecruitContext`, and receive unit handles.
Standing hooks receive `None` for the owning unit. Parameters use `&MechanicParamsRef`.
Aura hooks receive `&mut AuraContext` because stat queries set its `read_stats` flag.
Never keep a unit's `Ref`/`RefMut`, a board borrow, or a bound mechanic borrow alive across
a hook: clone the next handle, release the container borrow, then invoke the hook.
When GDScript iterates a mutable array, use a live index loop and re-read its length.
Do not turn these into snapshots: removals and appends affect which entries are visited.

`Hook` and typed `HookArgs` replace `_notify(side, hook, args)` string dispatch. Combat
helpers receive `combat: &mut Combat` explicitly before the source arguments: their
GDScript WeakRef getters cannot safely reborrow a running Rust engine. Recruit notifications
similarly pass explicit context rather than holding a Recruit RefCell borrow through callbacks.
Pure unit queries which invoke mechanics use the unit handle as an associated-function
argument so the unit can be reborrowed safely by the hook.

GameSession is allocated first, then Recruit receives a weak session reference. Helpers keep
their source weak-reference fields for state fidelity; engine calls use explicit context.
A mechanic reaches registry, library, rules and session through its combat/recruit context.
Avoid upgrading and borrowing the owning session while it is already mutably borrowed; copy
the needed dependency handles into the context before invoking callbacks.

Recruit methods use associated functions with `recruit: &RecruitRef` as an explicit first
argument, and mutating GameSession flow methods likewise take `game: &GameSessionRef`.
This lets implementations release every RefCell borrow before callbacks. Calls are
`Recruit::act(&recruit, &player, &action)` and `GameSession::act(&game, id, &action)`.
Short operations without callbacks (new_unit, log_event, give_standing, damage) retain mutable
receivers. Combat hooks receive the live `&mut Combat`; helper methods forward that context.
`Combat::new()` returns `CombatRef` and constructs the source WeakRef helper links cyclically.

Replay results are a typed `ReplayResult`, because the source's result dictionaries can hold
a session object and Variant deliberately covers only JSON-shaped values. `_create` returns
`Result<GameSessionRef, ReplayResult>` and `_step` returns a validated next phase or failure.
Filesystem operations take an explicit repository root before the source arguments.

## Serialization and checks

Every sort uses `util::godot_sort`, including comparator sorts with ties. RNG streams are
the exact source streams, and their four words are included in state. `godot_json` emits
Godot JSON text; its parser converts numbers to floats. serde_json is a test-only dependency.
`RecordState::session_state` applies SESSION_SKIP and adds Recruit fields with its session
references skipped. Rule data is loaded at runtime from the supplied repository root.
No card numbers are embedded, except the source's system Triple Reward definition.

The replay binary supports header checks and state dumps now; full replay follows source
phase validation and calls the gameplay methods filled by later workers.

## Next worker file boundaries

The combat worker owns `src/core/combat/`. The recruit worker owns `src/core/recruit/`,
`src/core/rules/` and the remaining round-flow bodies in `src/core/session/`; that session
facade calls Combat without requiring edits in combat modules. The record read/replay driver
already calls that facade. Record writing bodies remain marked TODO for the record/harness integration.
FightSnapshot restore is implemented by the combat worker.
Mechanic workers own their tribe's `src/content/<tribe>/mechanics/` and `lib/`, plus the
separately assigned core keywords/effects. Common trait/registry/parameter signatures are set.

Content helpers mirror these source files: badger `badger_rules`, locust `locust`, mouse
`mouse_rules`, pigeon `medals`, thorn `compost_rules` and its mechanic base `bury_base`.
The BuryFeed/Gold implementations explicitly repeat inherited metadata; their gameplay
workers can call the BuryBase helper without changing hook signatures.

## Card-data changes and the state hash

The initial state hash skips the library and the fixed `ShopOdds` tables. A change to a
loaded card's Attack or tier first appears in the hash when it affects gameplay.
`gd/prove_planted.gd` and `tests/initial_states.rs` show the Attack change in an instantiated
unit's stats and the tier change in the first shops. Both engines keep the same initial hash
after either in-memory change. Format 3 records save the config's two weight rows, and
replay rebuilds the tables in library order for the recorded lobby.

## Recruit

The recruit phase, rules queries, legal-action enumeration and session round flow are ported.
Calls keep the skeleton signatures: `Recruit::act(&recruit, &player, &action)` and
`GameSession::act(&game, player_id, &action)`. `GameSession::_fight` calls the existing Combat
API; the combat implementation is integrated for stand-in full-game replays.

Mechanic workers use `&mut RecruitContext` for recruit mutations. `session`, `player`, `rng`
and `_recruit` retain the skeleton's optional shared handles; constructed contexts populate
all four. Clone a handle before a context mutation, and drop every `Ref`/`RefMut` before
calling a context operation or another hook. Context operations may log, refresh auras,
open Discover choices, notify listeners, or gain cards; any of these may reborrow units,
players or the session. In particular, do not call through `game.borrow_mut()` or keep
`unit.borrow()` alive while invoking a hook.

- `target_index` is the slot or shop index for those target kinds, the friendly uid for a
  friendly-unit target, and -1 for no target. Units call `on_recruited` on gain, with a friendly
  unit from hand or board as the target. A buy or pick with target -1 aims at the gained unit.
  A raw buy or pick that omits the target queues a choice when needed. The typed bot API maps
  the original `Buy` and `Pick` variants to target -1, the first choice in the GDScript legal
  list. Spells call `on_played` when cast. An ability cannot target its own unit.
- Call `ctx.trigger(unit, id)` before acting, in the same order as the source. A single
  context counts all nested triggers for that action. Separate start/end/after-fight contexts
  have independent limits. Notification itself does not spend a trigger.
- `ctx.select` returns a new board selection in reading order. `random_of` draws from the
  player's `recruit_effect:<id>` stream, and draws nothing for an empty selection. Shop and
  Discover use separate `shop:<id>` and `discover:<id>` streams.
- Use `ctx.buff`, `gain_gold`, counter/heap operations, slot operations, `give_card`,
  `give_keyword`, `give_effect`, `take_from_shop`, `summon`, `discover`, `run_death_effects`
  and `add_standing` exactly as their GDScript counterparts. Permanent grants preserve their
  original parameter values when the target later becomes golden.
- Listener dispatch uses `Hook` and `HookArgs`: start/end turn, any sold, heap added and
  after fight. It visits a new `board_units()` array, each unit's live `hooks()` array, then
  the live standing array with `unit = None`. Hooks appended to an aliased live array are
  visited. A board selection already made remains the source selection if the board changes.
- Discover requests queue behind an open choice. End turn resolves pending Recruit targets
  to their own units and Discover with option zero before and after End of Turn hooks.
  Gain-card helpers leave triple settling to the enclosing action. A finishing copy of a
  triple skips its Recruit effect and the golden recruits. The Triple Reward goes through
  the hand-limit check at formation, after the golden has entered hand or board.
- Selling from either zone uses the same hooks. A board sale preserves the last slot through
  those hooks. A free return to hand moves the existing unit and refreshes auras. It declines
  units that worked this turn. `RecruitContext::invoke` scopes the source and rule contributors
  to the hook. An actual mutation commits the contributing board units. A successful ability
  commits its owner, and triples inherit the work flag from any copy.
- Ghost board snapshots copy containers shallowly. `ghost_player` is the eliminated player's
  actual object; `ghost_hand` keeps the pre-retirement hand handles. Combat receives no
  writeback permission for the ghost.

`GameRecord::configure(repo_root, directory)` supplies filesystem settings outside the hashed
rules state; `begin(game)` is unchanged. Set it before creating recorded Rust games.
The GDScript generator is run from the repository root with a time limit:

```
timeout -k 10 7200 godot --headless -s res://tools/league/gd/standin_records.gd -- games=500 seed=1 out=/home/alex/engine-data/dev-level/records/standin/ folders=
```

`folders=shared,badger` selects those `src/content` folders; an empty list uses stand-ins.
Headers carry the exact paths. Each game is replayed in GDScript and gets a `.legal.jsonl`
sidecar with the ordered legal actions before every turn-1 bot decision. Exclude these
sidecars when passing records to other replay tools. The batch checker uses the production
`RecordReplay` operations and compares the sidecars:

```
# From tools/league; prefix stops before combat, full checks every checkpoint.
CARGO_BUILD_JOBS=2 cargo run --offline --locked -p bramble-engine --example check_records -- /home/alex/engine-data/dev-level/records/standin prefix 500
```

Presentation-only `GameContent` TODOs remain outside this port's rules scope; content loading,
standing filters and session recipes already have complete bodies.

## Combat

`Combat::create` returns the shared combat handle; borrow it mutably only for the running
fight. Mechanics receive that live `&mut Combat`. `bridge(index)` returns a `FightSideRef`.
Release all combat-unit, bound-mechanic and container borrows before invoking a hook. Hooks
iterate their source Array by live index; the board cache is replaced when occupancy changes.
Start-of-combat snapshots, joined damage amounts, return offer ordering, death batches and
Reserve/waiting slot-fill order follow the source. With `keep_fight_events = true`, event logs
include held return events and aura `after` indices in the source order. With it false, the
session sets Combat's runtime-only `keep_events` flag and presentation events are not built.
No rule reads these events; trigger counts and the pre-aura living-health guard still run.
Session logs remain available because league round statistics read triple events.

Aura dispatch has conservative `aura_parts` metadata: custom mechanics default to all three
hooks. Existing mechanics identify their implemented hooks so the inherited zero/empty hooks
need no allocations. Adding an aura hook to one of these mechanics requires updating its mask.
Cached board arrays and private death batches use owning index iterators that release their
storage borrow before callbacks; source-required shallow snapshots remain explicit.

The speed pass's measurements, equivalence notes and complete proof results are in
[`proof/SPEED.md`](../proof/SPEED.md).

The skeleton's callback-producing FightSide receiver signatures were unworkable: holding
`bridge.borrow_mut()` through aura refresh reborrows the same bridge and panics. These APIs
are associated functions with `side: &FightSideRef, combat: &mut Combat` before the source
arguments, so each borrow ends before a callback:

- `add_counter`, `add_unit_counter`, `add_gold`;
- `heap_add`, `heap_spend`, `heap_use`, `heap_use_highest`, `_log_use`, `heap_take`, `_heap_removed`;
- `copy_renown`, `add_renown`, `slot_clear_keyword`, `_log_slot`;
- `give_keyword`, `give_effect`.

For example, get `let side = combat.bridge(unit_side);` then call
`FightSide::copy_renown(&side, combat, slot, amount, Some(unit));`.
Pure state helpers (`recruit_unit`, `real_unit`, `counter`, `heap`, `heap_unused`, `_mark`,
`slot`, `heap_sizes`, `state_int`, `set_state`) keep their receivers and explicit combat
argument where present. Do not retain those borrows around other combat API calls.

Death helpers carry only their source weak link; recursive resolution uses a local helper
without borrowing the shared helper RefCell across callbacks. Arrivals similarly use shallow
handles to the same reserve, waiting and called arrays. The aliases let recursive arrivals
share the hand Reserve count across the fight. Each death round temporarily owns its
officer witness map. Nested death rounds restore the outer map when they finish.
Starting units and reservists get their entry
slot's Renown while they stand there. `FightSide::add_renown` writes to the real player slot for
the next fight.
The session serializer never includes these temporary combat objects. Source Vector2i/Vector3i
boundaries narrow components to signed 32 bits while public tuple/array interfaces remain i64.

`FightSnapshot::units` preserves null board positions. `restore_unit` creates a unit without
allocating a session UID; the caller must update `_next_uid` after each restored board or hand
unit. Restore overlays saved counters on freshly initialized Supply. A triple clears the
golden's starting counters before adding the copies' remaining Supply. Parameterized grants
bind already-applied numbers without a second golden multiplier.
The isolated runner calls `GameSession::_fight` once; its real `after_fight` path must initialize
both players' recruit effect RNG streams even when every hook is inactive.

The fight runner accepts absent content (all five tribes), `"content":"standin"`, or ordered
`"content":{"folders":["shared","badger"]}` recipes. Folder names resolve under `src/content`;
empty folders load stand-ins. `standin_fights.gd folders=shared,badger` emits the ordered recipe
for each case; omitted/empty generator folders load stand-ins. Recipes are cached per process,
while each case receives a fresh session. See `../bramble-fight/README.md` for commands.
