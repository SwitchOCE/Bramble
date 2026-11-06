class_name EffectConditions
extends RefCounted
## The "if" list of a data effect: every entry must hold. Numbers here are thresholds, so golden
## never doubles them (7.3.5). {"kind", "at_least"?, "at_most"?, "not"?, ...}.


static func all_hold(params: Dictionary, world: EffectWorld) -> bool:
	var list: Array = params.get("if", [])
	for value: Variant in list:
		var entry: Dictionary = value
		if _holds(entry, world) == CoreUtil.to_bool(entry.get("not", false)):
			return false
	return true


static func _holds(entry: Dictionary, world: EffectWorld) -> bool:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"count":
			var spec: Dictionary = entry.get("target", {})
			return _in_range(TargetSelect.pick(spec, world).size(), entry)
		"gold":
			return _in_range(world.gold_now(), entry)
		"tier":
			return _in_range(world.tier_now(), entry)
		"round":
			return _in_range(world.round_now(), entry)
		"hand":
			return _in_range(world.hand_cards(), entry)
		"amount":
			return _in_range(world.amount, entry)
		"paid_refreshes":
			return _in_range(world.paid_refreshes_now(), entry)
		"chance":
			return world.rng.randi_range(1, 100) <= CoreUtil.to_int(entry.get("percent", 100))
	return _holds_flag(kind, entry, world)


static func _holds_flag(kind: String, entry: Dictionary, world: EffectWorld) -> bool:
	match kind:
		"in_row":
			var slot: int = world.source_slot
			if not BoardGeometry.is_valid(slot):
				return false
			return BoardGeometry.is_front(slot) == (str(entry.get("row", "front")) == "front")
		"at_row_end":
			return (
				BoardGeometry.is_valid(world.source_slot)
				and BoardGeometry.is_row_end(world.source_slot)
			)
		"undamaged":
			var fighter: CombatUnit = world.source as CombatUnit
			return fighter != null and fighter.is_undamaged()
		"golden":
			return world.source != null and world.source.golden
		"subject_in_row":
			return (
				BoardGeometry.is_front(world.subject_slot)
				== (str(entry.get("row", "front")) == "front")
			)
	return _holds_state(kind, entry, world)


static func _holds_state(kind: String, entry: Dictionary, world: EffectWorld) -> bool:
	match kind:
		"won_last_combat":
			return world.won_last_combat()
		"lost_last_combat":
			return world.lost_last_combat()
		"paid":
			return world.paid_now()
		"turns_in_slot":
			var unit: RecruitUnit = world.source as RecruitUnit
			return unit != null and _in_range(unit.turns_in_slot, entry)
		"holds_item":
			return world.holds_item(str(entry.get("card", "")))
	push_error("Unknown condition '%s'" % kind)
	return false


static func _in_range(value: int, entry: Dictionary) -> bool:
	if entry.has("at_least") and value < CoreUtil.to_int(entry["at_least"]):
		return false
	return not entry.has("at_most") or value <= CoreUtil.to_int(entry["at_most"])
