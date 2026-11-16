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

## Problems found while registering (a duplicate id), for the loader to report.
var errors: PackedStringArray = []
var _scripts: Dictionary = {}


static func with_built_ins() -> MechanicRegistry:
	var registry := MechanicRegistry.new()
	for mechanic_id: Variant in BUILT_IN:
		var script: GDScript = BUILT_IN[mechanic_id]
		var instance: Mechanic = script.new()
		registry.register(StringName(str(mechanic_id)), instance)
	return registry


## Registers a mechanic. A duplicate id is refused and recorded in `errors`: ids never
## silently replace each other (tribe ids carry the tribe's prefix).
func register(mechanic_id: StringName, mechanic: Mechanic) -> bool:
	if _scripts.has(mechanic_id):
		errors.append("mechanic id %s is registered twice" % mechanic_id)
		return false
	_scripts[mechanic_id] = mechanic
	return true


## Binds aura grants ({"mechanic": id, <param>: value}, Mechanic.aura_grants) as given
## mechanics. Grants of one id combine as the mechanic says (Mechanic.grant_combine: add up by
## default, or the biggest or smallest); a grant with bad parameters is skipped.
func bind_grants(grants: Array) -> Array[BoundMechanic]:
	var merged: Dictionary = {}
	for value: Variant in grants:
		var grant: Dictionary = value
		var mechanic_id := StringName(str(grant.get("mechanic", "")))
		if not has(mechanic_id):
			continue
		var raw: Dictionary = merged.get(mechanic_id, {})
		for key: Variant in grant:
			if str(key) == "mechanic":
				continue
			var amount: Variant = grant[key]
			if typeof(amount) == TYPE_INT and raw.has(key):
				var had: int = CoreUtil.to_int(raw[key])
				var now: int = CoreUtil.to_int(amount)
				match get_mechanic(mechanic_id).grant_combine(StringName(str(key))):
					Mechanic.Combine.MAX:
						raw[key] = maxi(had, now)
					Mechanic.Combine.MIN:
						raw[key] = mini(had, now)
					_:
						raw[key] = had + now
			else:
				raw[key] = amount
		merged[mechanic_id] = raw
	var out: Array[BoundMechanic] = []
	for key: Variant in merged:
		var mechanic_id := StringName(str(key))
		var problems: PackedStringArray = []
		var raw: Dictionary = merged[key]
		var params: MechanicParams = MechanicParams.parse(
			raw, get_mechanic(mechanic_id).param_kinds(), "aura grant", problems
		)
		if params != null:
			out.append(bind(MechanicSpec.new(mechanic_id, params), false, true))
	return out


## A mechanic with parameters an effect gives a unit ('Give a unit "+1 Fury"'): checked like card
## data and never doubled by the target's golden (the giver's numbers already are). Null when the
## mechanic is unknown or the parameters are wrong.
func bind_given(mechanic_id: StringName, raw: Dictionary) -> BoundMechanic:
	if not has(mechanic_id):
		return null
	var problems: PackedStringArray = []
	var params: MechanicParams = MechanicParams.parse(
		raw, kinds_of(mechanic_id), String(mechanic_id), problems
	)
	if params == null:
		return null
	return bind(MechanicSpec.new(mechanic_id, params), false, true)


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
