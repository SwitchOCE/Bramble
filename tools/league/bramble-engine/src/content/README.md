# Content mechanics skeleton

The 100 scripts in `src/content/*/mechanics` each have their own Rust module. The
runtime loader combines the source folder's `tribe.json` prefix with the filename;
`MechanicRegistry::content_mechanic` selects the corresponding Rust implementation.
The 20 core keywords/effects are registered in their source order by `with_built_ins`.

Parameter schemas, targeting and ability metadata, aura/death flags, Start of Combat
priority and return metadata are implemented. Gameplay hooks that the source overrides
panic with a source-specific `todo!("port <file>:<func>")`; inherited no-ops retain the
`Mechanic` trait's defaults. Rule comments remain beside each module.

Shared helpers mirror these GDScript files:

| Tribe | Helpers |
| --- | --- |
| Badger | `src/content/badger/lib/badger_rules.gd` (Fury and Knight checks) |
| Mouse | `src/content/mouse/lib/mouse_rules.gd` (pile-on, Cousins) |
| Locust | `src/content/locust/lib/locust.gd` (Tide, Hoppers, Molt, Eat) |
| Pigeon | `src/content/pigeon/lib/medals.gd` (Medals and Decorated) |
| Thorn | `src/content/thorn/lib/compost_rules.gd` (Compost) and `bury_base.gd` (Bury ability) |

Bury Feed and Bury Gold explicitly repeat BuryBase's inherited ability metadata and
provide its inherited `on_ability` TODO. Their `mechanic_id` and `bury_effect` methods
remain distinct, so the gameplay worker can implement one helper taking those operations
without altering the public hook signatures.

Aura hooks receive `&mut AuraContext`: reading a stat sets its `read_stats` script
variable, which the aura engine uses to decide whether to run its second pass.
