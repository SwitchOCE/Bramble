class_name CombatWorld
extends EffectWorld
## A data effect firing in a fight. Rules for who, when and what's logged stay in Combat.

var combat: Combat
var side: int = 0
var hit_amount: int = 0
var _combat_source: CombatUnit = null
var _no_store: Dictionary = {}
var _mouse_notice: bool = false


static func make(
	fight: Combat, unit: CombatUnit, unit_side: int, entry: Dictionary, event: String
) -> CombatWorld:
	var world := CombatWorld.new()
	world.combat = fight
	world.side = unit_side
	world.trigger = event
	world.params = entry
	world.own = fight.sides[unit_side]
	world.enemy = fight.sides[1 - unit_side]
	world.rng = fight.effect_rng
	world.source = unit
	world._combat_source = unit
	if unit != null:
		world.source_slot = unit.slot
	return world


func set_subject(unit: CombatUnit) -> void:
	subject = unit
	subject_slot = unit.slot


func default_duration() -> String:
	return "combat"


func tier_now() -> int:
	return combat.tier_of(side)


func announce(name: String) -> void:
	if _combat_source != null:
		combat.trigger(_combat_source, name)
	else:
		_mouse_notice = name == "mice"
		# Count every attempted firing, but describe Mousewife's actual result below.
		combat.side_trigger(side, name, not _mouse_notice)


func limit_store() -> Dictionary:
	return source.limits if source != null else combat.hero_limits[side]


func counter_store() -> Dictionary:
	return source.counters if source != null else _no_store


func buff(target: BoardUnit, attack: int, health: int, duration: String) -> void:
	var fighter: CombatUnit = target
	combat.buff(fighter, attack, health, _combat_source, duration == "permanent")


func summon(def_id: String, count: int, golden: bool) -> void:
	for _index: int in count:
		combat.summon(def_id, golden, side, source_slot, _combat_source)


## 8.4.6 and Spill in a fight: the Acorn waits until the fight is over.
func summon_placed(step: Dictionary, count: int, golden: bool) -> void:
	var def_id: String = str(step.get("unit", ""))
	var stats: int = combat.tier_of(side) if str(step.get("stats", "")) == "tier" else 0
	var at: String = str(step.get("at", ""))
	if at == "empty_rings":
		var slots: Array[int] = CombatMoves.empty_ring_slots(combat, side)
		if slots.is_empty():
			combat.emit_event(
				"no_room",
				{
					"uid": CombatMoves.uid_or_null(_combat_source),
					"side": side,
					"def_id": def_id,
					"place": at
				}
			)
		for slot: int in slots:
			combat.summon_into(def_id, golden, side, slot, _combat_source, stats)
		return
	var anchor: int = subject_slot if str(step.get("of", "")) == "subject" else source_slot
	for _index: int in count:
		var slot: int = combat.named_slot(side, at, anchor)
		if slot >= 0:
			if _mouse_notice:
				if not combat.hero_limits[side].has("mice_notice"):
					combat.hero_limits[side]["mice_notice"] = true
					combat.emit_event("side_trigger", {"side": side, "mechanic": "mice"})
				_mouse_notice = false
			combat.summon_into(def_id, golden, side, slot, _combat_source, stats)
		else:
			if _mouse_notice:
				# Only successful Mouse replacements spend the twice-a-fight limit.
				combat.hero_limits[side]["mice"] = (
					CoreUtil.to_int(combat.hero_limits[side].get("mice", 0)) - 1
				)
				combat.emit_event("no_room", {"side": side, "mechanic": "mice", "def_id": def_id})
			else:
				combat.emit_event(
					"no_room",
					{"uid": CombatMoves.uid_or_null(_combat_source), "side": side, "def_id": def_id}
				)
			if CoreUtil.to_bool(step.get("spill", false)):
				combat.spill(side, _combat_source)


func borrow_attack(target: BoardUnit) -> void:
	var fighter: CombatUnit = target
	combat.set_status(fighter, "borrowed_attack", true, _combat_source)


func damage(target: BoardUnit, damage_amount: int) -> void:
	var fighter: CombatUnit = target
	combat.deal_effect_damage(_combat_source, fighter, damage_amount, side)


func no_target(spec: Dictionary) -> void:
	(
		combat
		. emit_event(
			"no_target",
			{
				"uid": CombatMoves.uid_or_null(_combat_source),
				"side": side,
				"reason":
				"no enemy across" if str(spec.get("select", "")) == "across" else "no target",
			}
		)
	)


func grant(target: BoardUnit, entry: Dictionary, keyword: String, duration: String) -> void:
	var is_golden: bool = source != null and source.golden
	var fighter: CombatUnit = target
	fighter.add_grant({"entry": entry, "golden": is_golden})
	combat.emit_event(
		"keyword", {"target": fighter.uid, "keyword": keyword, "permanent": duration == "permanent"}
	)
	if duration == "permanent" and fighter.iid != 0:
		combat.carry_back(
			side,
			{
				"op": "grant",
				"iid": fighter.iid,
				"entry": entry,
				"keyword": keyword,
				"golden": is_golden
			}
		)


func apply_status(target: BoardUnit, status: String) -> void:
	var fighter: CombatUnit = target
	combat.set_status(fighter, status, true, _combat_source)


## Gold gained in a fight arrives next turn (a fight has no recruit gold to add to).
func gain_gold(gold_amount: int, _when: String) -> void:
	combat.carry_back(side, {"op": "gold_next_turn", "amount": gold_amount})


func add_card(card: String, count: int, from_pool: bool) -> void:
	combat.carry_back(
		side, {"op": "add_card", "card": card, "count": count, "from_pool": from_pool}
	)
