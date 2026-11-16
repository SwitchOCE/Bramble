class_name RuleSource
extends RefCounted
## A rule source above the unit: a game-wide modifier (anomaly) or a player-level one (trinket,
## quest; heroes are out of this track). It answers named rule queries (Rules), in the layer
## order game -> player -> unit -> caps. Subclasses override modify_int; the default changes
## nothing. Must keep no per-player state on self if shared between players.

## Shown in logs and tests.
var name: StringName = &"rule_source"


## Returns the new answer to `query`, given the answer so far. `player` and `unit` may be null.
func modify_int(_query: StringName, value: int, _player: PlayerState, _unit: Unit) -> int:
	return value
