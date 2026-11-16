extends Mechanic
## Recruiting Sergeant: when a slot in front of this is empty in a fight, summon a Private there
## (`limit` a fight). Checked in the Start of fight set-up pass and after each round of deaths
## (after Reserve units and waiting summons, SHARED-RULES 6), the Guard post first. A golden
## Sergeant summons golden Privates (4/4), still `limit` a fight. The limit is a fight count, so
## it carries across a return (SHARED-RULES 21); the screen sees what is left (`uses`).

const GuardPost := preload("res://src/content/pigeon/mechanics/guard_post.gd")
const SUMMONED: StringName = &"pigeon_sergeant_privates"
const PRIVATE: StringName = &"private"


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.THRESHOLD}


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
	var limit: int = params.num(&"limit")
	for slot: int in open:
		if unit.fight_count(SUMMONED) >= limit:
			return
		if not combat.trigger(unit, &"pigeon_recruiting_sergeant"):
			return
		unit.add_fight_count(SUMMONED)
		combat.summon(unit.side, PRIVATE, slot, true, unit, false, {}, unit.golden)
		combat.show_uses(unit, SUMMONED, limit - unit.fight_count(SUMMONED), unit)
