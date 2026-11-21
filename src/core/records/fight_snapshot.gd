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
	"renown",
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
	if card.copies != 1:
		out["copies"] = card.copies
	for key: String in ["bought_copies", "counters", "turn_counters"]:
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
	restored.copies = CoreUtil.to_int(saved.get("copies", restored.copies))
	restored.counters.merge(CoreUtil.to_dict(saved.get("counters", {})), true)
	if saved.has("bought_copies"):
		restored.set("bought_copies", saved["bought_copies"])
	if saved.has("turn_counters"):
		restored.turn_counters = CoreUtil.to_dict(saved["turn_counters"]).duplicate(true)
	var layers: Dictionary = CoreUtil.to_dict(saved.get("stats", {}))
	for key: String in LAYERS:
		if layers.has(key):
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


## Replaces the fight state on the destination player. The payload's id is the source seat.
## The destination keeps its own id. Unit.uid values in each card zone need the UID offset.
## UID/seat-id audit: unit/player counters (including turn counters), effect parameters in
## grants/aura grants and standing effects, slot state and heap state contain neither ID.
## Heap entry id is a card id, and n and _next_n are heap-local sequence numbers.
## The live game's stand-in payload also has an "of" seat id. It is outside the run format.
static func restore_player(
	saved: Dictionary, owner: PlayerState, game: GameSession, uid_offset: int
) -> void:
	owner.tier = CoreUtil.to_int(saved["tier"])
	var counters: Dictionary = saved["counters"]
	owner.counters = counters.duplicate(true)
	owner.board.fill(null)
	var board: Array = saved["board"]
	for slot: int in board.size():
		if board[slot] != null:
			var snapshot: Dictionary = board[slot]
			var card: Unit = _restore_player_unit(snapshot, game, uid_offset, slot)
			owner.board[slot] = card
	owner.hand.clear()
	var hand: Array = saved["hand"]
	for raw: Dictionary in hand:
		var card: Unit = _restore_player_unit(raw, game, uid_offset)
		owner.hand.append(card)
	owner.waiting_pile.clear()
	for raw: Dictionary in CoreUtil.to_array(saved.get("waiting_pile", [])):
		owner.waiting_pile.append(_restore_player_unit(raw, game, uid_offset))
	var slots: Array = saved["slots"]
	for i: int in slots.size():
		var raw: Dictionary = slots[i]
		owner.slots[i].renown = CoreUtil.to_int(raw.get("renown", 0))
		owner.slots[i].keywords.clear()
		for keyword: String in raw["keywords"]:
			owner.slots[i].keywords.append(StringName(keyword))
	owner.heaps.clear()
	var heaps: Dictionary = saved["heaps"]
	for key: String in heaps:
		var raw: Dictionary = heaps[key]
		var heap := CardHeap.new()
		heap._next_n = CoreUtil.to_int(raw["_next_n"])
		for entry: Dictionary in raw["entries"]:
			(
				heap
				. entries
				. append(
					{
						"id": StringName(str(entry["id"])),
						"tier": CoreUtil.to_int(entry["tier"]),
						"n": CoreUtil.to_int(entry["n"]),
					}
				)
			)
		owner.heaps[StringName(key)] = heap
	owner.standing.clear()
	for raw: Dictionary in saved["standing"]:
		var params := MechanicParams.new()
		var fields: Dictionary = raw["params"]
		params.golden = CoreUtil.to_bool(fields["golden"])
		for key: String in ["_ints", "_texts", "_kinds", "_golden_ints", "_golden_texts"]:
			var field: Dictionary = fields.get(key, {})
			params.set(key, field.duplicate(true))
		var mechanic_id := StringName(str(raw["id"]))
		owner.standing.append(
			BoundMechanic.new(
				mechanic_id,
				game.registry.get_mechanic(mechanic_id),
				params,
				CoreUtil.to_bool(raw["granted"])
			)
		)


static func _restore_player_unit(
	saved: Dictionary, game: GameSession, uid_offset: int, slot: int = -1
) -> Unit:
	var card: Unit = restore_unit(saved, game, slot)
	card.uid += uid_offset
	# The league runner's unshifted units share the game's allocator. Shifted IDs use a
	# separate range, so restoring one must never advance the live game's allocator.
	if uid_offset == 0:
		game._next_uid = maxi(game._next_uid, card.uid + 1)
	return card


static func _effect(effect: BoundMechanic) -> Array:
	var out: Array = [String(effect.id)]
	var applied: Dictionary = effect.params.to_dict()
	if not applied.is_empty():
		out.append(applied)
	return out
