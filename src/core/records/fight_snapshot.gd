class_name FightSnapshot
extends RefCounted
## Ghost unit data as deltas from Unit.create. Fixed card text, mechanic templates and
## parameter schemas come from the recorded build; zero layers and unset overrides are omitted.

const LAYERS: PackedStringArray = [
	"base_attack",
	"base_health",
	"set_attack",
	"set_health",
	"perm_attack",
	"perm_health",
	"turn_attack",
	"turn_health",
	"combat_attack",
	"combat_health",
	"aura_attack",
	"aura_health",
	"slot_attack",
	"slot_health",
]


static func units(cards: Array[Unit]) -> Array:
	var out: Array = []
	for card: Unit in cards:
		if card == null:
			out.append(null)
		else:
			out.append(unit(card))
	return out


static func unit(card: Unit) -> Dictionary:
	var out: Dictionary = {"def": String(card.def.id), "uid": card.uid, "golden": card.golden}
	var layers: Dictionary = {}
	for key: String in LAYERS:
		var default_value: int = 0
		if key.begins_with("base_"):
			default_value = (
				(card.def.attack if key == "base_attack" else card.def.health)
				* (2 if card.golden else 1)
			)
		elif key.begins_with("set_"):
			default_value = StatBlock.UNSET
		var actual: int = CoreUtil.to_int(card.stats.get(key))
		if actual != default_value:
			layers[key] = actual
	if not layers.is_empty():
		out["stats"] = layers
	for key: String in ["bought_copies", "pool_copies", "counters", "turn_counters"]:
		var actual: Variant = card.get(key)
		if actual:
			out[key] = RecordState.value(actual)
	var added: Array = []
	for effect: BoundMechanic in card.mechanics:
		if effect.granted:
			added.append(_effect(effect))
	if not added.is_empty():
		out["grants"] = added
	if not card.aura_mechanics.is_empty():
		out["aura_grants"] = card.aura_mechanics.map(_effect)
	return out


## Does not allocate a new game UID. The containing board's index supplies the slot.
static func restore_unit(saved: Dictionary, game: GameSession, slot: int = -1) -> Unit:
	var card: UnitDef = game.library.get_card(StringName(str(saved["def"])))
	var restored: Unit = Unit.create(
		card,
		CoreUtil.to_int(saved["uid"]),
		CoreUtil.to_bool(saved["golden"]),
		game.registry,
		game.config.stat_max
	)
	restored.slot = slot
	for key: String in ["bought_copies", "pool_copies", "counters", "turn_counters"]:
		if saved.has(key):
			restored.set(key, saved[key])
	var layers: Dictionary = CoreUtil.to_dict(saved.get("stats", {}))
	for key: String in layers:
		restored.stats.set(key, CoreUtil.to_int(layers[key]))
	for raw: Variant in CoreUtil.to_array(saved.get("grants", [])):
		var entry: Array = raw
		if entry.size() == 1:
			restored.grant(game.registry, StringName(str(entry[0])))
		else:
			restored.grant_effect(
				game.registry, StringName(str(entry[0])), CoreUtil.to_dict(entry[1])
			)
	for raw: Variant in CoreUtil.to_array(saved.get("aura_grants", [])):
		var entry: Array = raw
		var values: Dictionary = CoreUtil.to_dict(entry[1]) if entry.size() > 1 else {}
		restored.aura_mechanics.append(game.registry.bind_given(StringName(str(entry[0])), values))
	return restored


static func _effect(effect: BoundMechanic) -> Array:
	var out: Array = [String(effect.id)]
	var applied: Dictionary = effect.params.to_dict()
	if not applied.is_empty():
		out.append(applied)
	return out
