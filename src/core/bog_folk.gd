class_name BogFolk
extends RefCounted
## The Prince's cross-phase rules: a lasting quest, a transformation, and a price for an action.


static func spell_cost(player: PlayerState, item: HandItem) -> int:
	if player.spells_bought_turn > 0 or not item.is_spell():
		return item.cost()
	var discount: int = 0
	for unit: RecruitUnit in player.board:
		if unit != null:
			discount += unit.mechanic_number("spell_discount", "gold")
	return maxi(0, item.cost() - discount)


## The same fighter identity remains: damage, buffs, flags, quarry and slot all stay.
## Its new Mire missed the bell, so it does not lay a late patch.
static func restore_prince(combat: Combat, unit: CombatUnit) -> void:
	var into: Dictionary = combat.library.get_unit("prince_restored")
	if into.is_empty():
		return
	unit.set_base(into, unit.golden)
	unit.scripts = []
	unit.params = []
	unit.mechanic_ids = []
	unit.board_aura_sources = []
	unit.ally_listeners = []
	unit.acts_without_attack = false
	for value: Variant in MechanicRegistry.compiled(into):
		var compiled: CompiledMechanic = value
		unit.add_mechanic(compiled.id, compiled.mechanic, compiled.params_for(unit.golden))
	var granted: Array[Dictionary] = unit.grants
	unit.grants = []
	for grant: Dictionary in granted:
		unit.add_grant(grant)
	combat.emit_event("transform", {"target": unit.uid, "unit": unit.view()})
	combat.carry_back(unit.side, {"op": "transform", "iid": unit.iid, "into": "prince_restored"})
	combat._recalc_auras(true)


static func answer(
	combat: Combat, unit: CombatUnit, attacker: CombatUnit, neighbour: bool, bonus: int
) -> void:
	if (
		CombatLanes.maker_of(combat, attacker) != unit
		or attacker.is_dead()
		or combat.reactions.kind != ""
	):
		return
	var answerer: CombatUnit = unit
	if neighbour:
		var world := CombatWorld.make(combat, unit, unit.side, {}, "counter")
		var targets: Array[BoardUnit] = TargetSelect.pick(
			{"select": "adjacent", "pick": "highest_attack"}, world
		)
		if targets.is_empty():
			return
		answerer = targets[0] as CombatUnit
	elif unit.is_dead():
		return
	combat.trigger(unit, "bog_answer")
	combat.queue_attack(answerer, attacker, "counter", bonus)
