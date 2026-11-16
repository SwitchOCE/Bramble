class_name FightAuras
extends RefCounted
## 12.2.1 auras, standing auras and slot effects (8.5) in a fight, recalculated on both boards
## whenever a board, a player number or a heap changes (Combat.refresh). Each unit whose Attack,
## Health or keywords change gets a "stats" event, so a replay never shows stale numbers. Losing
## aura or slot Health never takes a unit below 1.

var _combat_ref: WeakRef
var _keyword_binds: Dictionary = {}


static func create(combat: Combat) -> FightAuras:
	var made := FightAuras.new()
	made._combat_ref = weakref(combat)
	return made


func refresh(log_changes: bool) -> void:
	var combat: Combat = _combat_ref.get_ref()
	for side_index: int in 2:
		var living: Array[CombatUnit] = combat.units(side_index)
		var side_bridge: FightSide = combat.bridge(side_index)
		var view: AuraContext = _view(combat, side_index, living)
		var percent: int = _slot_attack_percent(combat, side_index)
		var before: Array = []
		for unit: CombatUnit in living:
			before.append(shown(unit))
			unit.stats.aura_attack = 0
			unit.stats.aura_health = 0
			unit.aura_mechanics = []
			var here: SlotState = side_bridge.slots[unit.slot]
			unit.stats.slot_attack = int(here.attack * percent / 100.0)
			unit.stats.slot_health = here.health
			for keyword: StringName in here.keywords:
				_give_keyword(combat, unit, keyword)
		var grants: Dictionary = {}
		for source: CombatUnit in living:
			for bound: BoundMechanic in source.mechanics:
				if bound.mechanic.has_aura():
					_apply(combat, view, bound, source.slot, living, grants)
		for bound: BoundMechanic in side_bridge.standing:
			if bound.mechanic.has_aura():
				_apply(combat, view, bound, -1, living, grants)
		for unit: CombatUnit in living:
			var given: Array = grants.get(unit.uid, [])
			unit.aura_mechanics.append_array(combat.registry.bind_grants(given))
		for i: int in living.size():
			var unit: CombatUnit = living[i]
			var was: Array = before[i]
			if CoreUtil.to_int(was[1]) > 0 and unit.health() <= 0 and not unit.destroyed:
				unit.damage -= 1 - unit.health()
			if log_changes and shown(unit) != was:
				var event: Dictionary = unit.view(combat.geometry)
				event["type"] = "stats"
				combat._log(event)


## What a screen shows of a unit that auras and slots can change: Attack, Health, keywords.
static func shown(unit: CombatUnit) -> Array:
	var keywords: Array = []
	for bound: BoundMechanic in unit.aura_mechanics:
		keywords.append([bound.id, bound.params.to_dict()])
	return [unit.attack(), unit.health(), keywords]


## Q_SLOT_ATTACK_PERCENT for the side: the biggest answer of its units and standing mechanics.
func _slot_attack_percent(combat: Combat, side_index: int) -> int:
	var best: int = 100
	for unit: CombatUnit in combat.units(side_index):
		for bound: BoundMechanic in unit.hooks():
			best = maxi(
				best,
				bound.mechanic.side_query(
					combat, unit, Mechanic.Q_SLOT_ATTACK_PERCENT, 100, bound.params
				)
			)
	for bound: BoundMechanic in combat.bridge(side_index).standing:
		best = maxi(
			best,
			bound.mechanic.side_query(
				combat, null, Mechanic.Q_SLOT_ATTACK_PERCENT, 100, bound.params
			)
		)
	return best


func _view(combat: Combat, side_index: int, living: Array[CombatUnit]) -> AuraContext:
	var side_bridge: FightSide = combat.bridge(side_index)
	var view := AuraContext.new()
	view.geometry = combat.geometry
	view.in_combat = true
	view.enemy_count = combat.units(1 - side_index).size()
	view.outnumbered_by = combat.outnumbered_by(side_index)
	view.counters = side_bridge.counters
	view.heaps = side_bridge.heaps
	view.defs.resize(combat.geometry.slot_count)
	view.unit_counters.resize(combat.geometry.slot_count)
	for unit: CombatUnit in living:
		view.defs[unit.slot] = unit.def
		view.unit_counters[unit.slot] = unit.counters
	return view


func _apply(
	combat: Combat,
	view: AuraContext,
	bound: BoundMechanic,
	source_slot: int,
	living: Array[CombatUnit],
	grants: Dictionary
) -> void:
	for target: CombatUnit in living:
		var gain: Vector2i = bound.mechanic.aura(view, source_slot, target.slot, bound.params)
		target.stats.aura_attack += gain.x
		target.stats.aura_health += gain.y
		for keyword: StringName in bound.mechanic.aura_keywords(
			view, source_slot, target.slot, bound.params
		):
			_give_keyword(combat, target, keyword)
		var given: Array = bound.mechanic.aura_grants(view, source_slot, target.slot, bound.params)
		if not given.is_empty():
			var list: Array = grants.get(target.uid, [])
			list.append_array(given)
			grants[target.uid] = list


func _give_keyword(combat: Combat, unit: CombatUnit, keyword: StringName) -> void:
	if not combat.registry.has(keyword) or unit.has_mechanic(keyword):
		return
	if not _keyword_binds.has(keyword):
		_keyword_binds[keyword] = combat.registry.bind(MechanicSpec.new(keyword), false, true)
	var bound: BoundMechanic = _keyword_binds[keyword]
	unit.aura_mechanics.append(bound)
