# Port interfaces and ownership

The GDScript source at `c0d7db795bcb63ff38de8a5da941f96fb00aeba3` is authoritative.
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
already calls that facade. Record writing and FightSnapshot restore bodies are marked TODO
for the record/harness integration, independent of the phase implementation files.
Mechanic workers own their tribe's `src/content/<tribe>/mechanics/` and `lib/`, plus the
separately assigned core keywords/effects. Common trait/registry/parameter signatures are set.

Content helpers mirror these source files: badger `badger_rules`, locust `locust`, mouse
`mouse_rules`, pigeon `medals`, thorn `compost_rules` and its mechanic base `bury_base`.
The BuryFeed/Gold implementations explicitly repeat inherited metadata; their gameplay
workers can call the BuryBase helper without changing hook signatures.

## Acceptance conflict in the brief

A loaded card's attack is absent from an empty initial session: the library is skipped,
pools contain only ids/counts/tiers/order, and there are no units yet. Both engines therefore
keep the same initial hash after an in-memory attack change. `gd/prove_planted.gd` and
`tests/initial_states.rs` prove this, then show attack changes detected once a real unit
exists, and a changed card tier detected by the initial hash. The state schema stays exact.
