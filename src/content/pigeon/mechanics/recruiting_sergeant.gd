extends Mechanic
## Recruiting Sergeant: when a slot in front of this is empty in a fight, summon a Private there
## (`limit` a fight). Checked in the Start of fight set-up pass and after each round of deaths
## (after Reserve units and waiting summons, SHARED-RULES 6), the Guard post first. A Private is
## a 2/2; a golden Sergeant's Privates are `private_stats`/`private_stats` (4/4).

const GuardPost := preload("res://src/content/pigeon/mechanics/guard_post.gd")
const SUMMONED: StringName = &"pigeon_recruiting_sergeant_summoned"
const PRIVATE: StringName = &"private"
const PRIVATE_STATS: int = 2


func param_kinds() -> Dictionary:
	return {"private_stats": MechanicParams.Kind.NUMBER, "limit": MechanicParams.Kind.THRESHOLD}


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	_fill(combat, unit, params)


func after_death_round(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	_fill(combat, unit, params)


func _fill(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if unit == null or unit.gone or combat.halted():
		return
	var open: Array[int] = []
	for slot: int in combat.geometry.in_front_of(unit.slot):
		if combat.unit_at(unit.side, slot) == null:
			open.append(slot)
	var post: int = GuardPost.post_of(combat.bridge(unit.side).slots)
	if open.has(post):
		open.erase(post)
		open.push_front(post)
	for slot: int in open:
		if unit.state_int(SUMMONED) >= params.num(&"limit"):
			return
		if not combat.trigger(unit, &"pigeon_recruiting_sergeant"):
			return
		unit.set_state(SUMMONED, unit.state_int(SUMMONED) + 1)
		var private: CombatUnit = combat.summon(unit.side, PRIVATE, slot, true, unit)
		var extra: int = params.num(&"private_stats") - PRIVATE_STATS
		if private != null and extra > 0:
			combat.buff(private, extra, extra, unit)
