class_name MechanicRegistry
extends RefCounted
## Mechanic id -> its one shared script instance. Keywords and effects register the same way;
## tribe mechanics will be added with register(). The core's own list is BUILT_IN.

const BUILT_IN: Dictionary = {
	&"taunt": preload("res://src/core/mechanics/keywords/taunt.gd"),
	&"divine_shield": preload("res://src/core/mechanics/keywords/divine_shield.gd"),
	&"windfury": preload("res://src/core/mechanics/keywords/windfury.gd"),
	&"reborn": preload("res://src/core/mechanics/keywords/reborn.gd"),
	&"venomous": preload("res://src/core/mechanics/keywords/venomous.gd"),
	&"stealth": preload("res://src/core/mechanics/keywords/stealth.gd"),
	&"cleave": preload("res://src/core/mechanics/keywords/cleave.gd"),
	&"play_buff": preload("res://src/core/mechanics/effects/play_buff.gd"),
	&"death_summon": preload("res://src/core/mechanics/effects/death_summon.gd"),
	&"end_turn_buff": preload("res://src/core/mechanics/effects/end_turn_buff.gd"),
	&"start_turn_gold": preload("res://src/core/mechanics/effects/start_turn_gold.gd"),
	&"sell_bonus": preload("res://src/core/mechanics/effects/sell_bonus.gd"),
	&"aura_attack": preload("res://src/core/mechanics/effects/aura_attack.gd"),
	&"rally_gain": preload("res://src/core/mechanics/effects/rally_gain.gd"),
	&"attacked_gain": preload("res://src/core/mechanics/effects/attacked_gain.gd"),
	&"kill_gain": preload("res://src/core/mechanics/effects/kill_gain.gd"),
	&"start_combat_damage": preload("res://src/core/mechanics/effects/start_combat_damage.gd"),
	&"avenge_buff": preload("res://src/core/mechanics/effects/avenge_buff.gd"),
	&"discover": preload("res://src/core/mechanics/effects/discover.gd"),
	&"triple_reward": preload("res://src/core/mechanics/effects/triple_reward.gd"),
}

var _scripts: Dictionary = {}


static func with_built_ins() -> MechanicRegistry:
	var registry := MechanicRegistry.new()
	for mechanic_id: Variant in BUILT_IN:
		var script: GDScript = BUILT_IN[mechanic_id]
		var instance: Mechanic = script.new()
		registry.register(StringName(str(mechanic_id)), instance)
	return registry


func register(mechanic_id: StringName, mechanic: Mechanic) -> void:
	_scripts[mechanic_id] = mechanic


func has(mechanic_id: StringName) -> bool:
	return _scripts.has(mechanic_id)


func get_mechanic(mechanic_id: StringName) -> Mechanic:
	var found: Mechanic = _scripts.get(mechanic_id, null)
	return found


func kinds_of(mechanic_id: StringName) -> Dictionary:
	var mechanic: Mechanic = get_mechanic(mechanic_id)
	return mechanic.param_kinds() if mechanic != null else {}


func bind(spec: MechanicSpec, golden: bool, granted: bool) -> BoundMechanic:
	return BoundMechanic.new(
		spec.id, get_mechanic(spec.id), spec.params.with_golden(golden), granted
	)
