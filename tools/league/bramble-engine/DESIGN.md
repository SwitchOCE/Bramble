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

## Serialization and checks

Every sort uses `util::godot_sort`, including comparator sorts with ties. RNG streams are
the exact source streams, and their four words are included in state. `godot_json` emits
Godot JSON text; serde_json is used only to parse valid JSON with numbers converted to floats.
`RecordState::session_state` applies SESSION_SKIP and adds Recruit fields with its session
references skipped. Rule data is loaded at runtime from the supplied repository root.
No card numbers are embedded, except the source's system Triple Reward definition.

The replay binary supports header checks and state dumps now; full replay follows source
phase validation and calls the gameplay methods filled by later workers.
