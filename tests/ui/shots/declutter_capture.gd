extends RefCounted
## Shared evidence counter. Counts nonempty, visible text controls rather than drawn digits.
## Categories explain every counted node; they never exempt a node from the raw budget.

const LABEL_CATEGORIES: PackedStringArray = [
	"unit_stats", "hero_health", "fallback_names", "costs_and_controls", "other"
]


static func text_nodes(node: Node, exclude_primary_stats: bool = false) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var draws_self: bool = true
	if node is CanvasItem:
		var item: CanvasItem = node as CanvasItem
		if not item.is_visible_in_tree() or item.modulate.a < 0.05:
			return found
		draws_self = item.self_modulate.a >= 0.05
	var primary: bool = node.get_meta("combat_primary_stat", false)
	var words: String = ""
	if node is Label:
		words = (node as Label).text
	elif node is RichTextLabel:
		words = (node as RichTextLabel).get_parsed_text()
	elif node is Button and not node.has_meta("drawn_face"):
		words = (node as Button).text
	if (
		draws_self
		and not words.strip_edges().is_empty()
		and not (exclude_primary_stats and primary)
	):
		var record: Dictionary = {
			"path": str(node.get_path()), "text": words, "primary_stat": primary
		}
		record.merge(classify_text_node(node))
		found.append(record)
	for child: Node in node.get_children():
		found.append_array(text_nodes(child, exclude_primary_stats))
	return found


## Ownership, field identity and unit identity supply categories; displayed digits never do.
static func classify_text_node(node: Node) -> Dictionary:
	var owner_node: Node = node
	var button: BaseButton = null
	while owner_node != null:
		if button == null and owner_node is BaseButton:
			button = owner_node
		var script: Script = owner_node.get_script()
		var script_path: String = script.resource_path if script != null else ""
		if (
			script_path
			in [
				"res://src/ui/widgets/tribe_bonuses.gd",
				"res://src/ui/widgets/combat_face.gd",
				"res://src/ui/widgets/away_tray.gd"
			]
		):
			var state_field: String = _owned_field(
				owner_node, node, ["counter", "_heading", "_notes"]
			)
			if node.has_meta("away_countdown"):
				state_field = "away_countdown"
			return _category_record(
				"other",
				owner_node,
				script_path,
				state_field if not state_field.is_empty() else str(node.name)
			)
		var field: String = ""
		var category: String = "other"
		var reason: String = ""
		match script_path:
			"res://src/ui/widgets/card_view.gd", "res://src/ui/widgets/card_detail.gd":
				field = _owned_field(
					owner_node,
					node,
					[
						"_attack_label",
						"_health_label",
						"_name_label",
						"_tier_label",
						"_type_label",
						"_rules",
						"_pending_label",
						"_status_label",
						"_turns",
						"_type",
						"_notes",
						"_hint"
					]
				)
				if field in ["_attack_label", "_health_label"]:
					category = "unit_stats"
				elif field == "_name_label" and script_path.ends_with("card_view.gd"):
					var view: Dictionary = owner_node.get("unit")
					reason = _fallback_reason(view)
					if not reason.is_empty():
						category = "fallback_names"
				elif field == "_tier_label":
					var view: Dictionary = owner_node.get(
						"unit" if script_path.ends_with("card_view.gd") else "shown"
					)
					if (
						str(view.get("kind", "")) in ["spell", "item"]
						or CoreUtil.to_bool(view.get("poached", false))
					):
						category = "costs_and_controls"
				if not field.is_empty():
					return _category_record(category, owner_node, script_path, field, reason)
			"res://src/ui/screens/recruit_screen.gd":
				field = _owned_field(
					owner_node, node, ["_tier_label", "_round_label", "_hand_count", "_toast"]
				)
				if not field.is_empty():
					return _category_record("other", owner_node, script_path, field)
			"res://src/ui/widgets/slot_marks.gd":
				field = _owned_field(
					owner_node,
					node,
					[
						"_egg_attack",
						"_egg_health",
						"_ring_labels",
						"_hex_labels",
						"_trap_labels",
						"_nest_labels",
						"_pass_label"
					]
				)
				if field in ["_egg_attack", "_egg_health"]:
					category = "unit_stats"
				return _category_record(category, owner_node, script_path, field)
			"res://src/ui/widgets/lobby_plaque.gd":
				field = _owned_field(owner_node, node.get_parent(), ["_hip", "_knot"])
				if field == "_hip":
					category = "hero_health"
				return _category_record(category, owner_node, script_path, field)
			"res://src/ui/widgets/gold_plaque.gd":
				field = _owned_field(owner_node, node, ["_value", "_income", "_word"])
				if field in ["_value", "_income"]:
					category = "costs_and_controls"
				return _category_record(category, owner_node, script_path, field)
			"res://src/ui/widgets/hero_plaque.gd":
				field = _owned_field(owner_node, node, ["_cost_label", "_name"])
				if field == "_cost_label":
					category = "costs_and_controls"
				if not field.is_empty():
					return _category_record(category, owner_node, script_path, field)
		owner_node = owner_node.get_parent()
	if button != null:
		var script: Script = button.get_script()
		return _category_record(
			"costs_and_controls",
			button,
			script.resource_path if script != null else "",
			"button text or rendered button descendant"
		)
	return _category_record("other", node, "", "unclassified text control")


static func _owned_field(owner_node: Node, node: Node, fields: Array[String]) -> String:
	# Archived widgets can predate fields; inspect the property list before reading them.
	var available: Dictionary = {}
	for property: Dictionary in owner_node.get_property_list():
		available[str(property["name"])] = true
	for field: String in fields:
		if not available.has(field):
			continue
		var value: Variant = owner_node.get(field)
		if value is Node and value == node:
			return field
		if value is Array:
			var entries: Array = value
			if entries.has(node):
				return field
		if value is Dictionary:
			var entries: Dictionary = value
			if entries.values().has(node):
				return field
	return ""


static func _fallback_reason(view: Dictionary) -> String:
	if str(view.get("kind", "")) in ["spell", "item"]:
		return ""
	var id: String = str(view.get("portrait_id", view.get("def_id", "")))
	if not ResourceLoader.exists("res://assets/portraits/%s.jpg" % id):
		return "no individual portrait: " + id
	return ""


static func _category_record(
	category: String, owner_node: Node, script_path: String, field: String, reason: String = ""
) -> Dictionary:
	return {
		"category": category,
		"classification_owner": str(owner_node.get_path()),
		"classification_script": script_path,
		"classification_field": field,
		"fallback_reason": reason,
	}


static func label_breakdown(node: Node) -> Dictionary:
	return summarize_text_nodes(text_nodes(node))


static func summarize_text_nodes(nodes: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {}
	for category: String in LABEL_CATEGORIES:
		counts[category] = 0
	for record: Dictionary in nodes:
		var category: String = str(record.get("category", "other"))
		assert(LABEL_CATEGORIES.has(category), "unknown label category")
		counts[category] = CoreUtil.to_int(counts[category]) + 1
	var total: int = 0
	for category: String in LABEL_CATEGORIES:
		total += CoreUtil.to_int(counts[category])
	assert(total == nodes.size(), "every visible text node must count exactly once")
	return {"raw_count": nodes.size(), "counts": counts, "visible_text_nodes": nodes}


## Separate from the raw label budget: inspect rendered text on tiles and their slot strips.
## Raster lettering and custom drawing still require an audit of the native screenshots.
static func tile_words(screen: Node) -> Dictionary:
	var labels: Array[Dictionary] = text_nodes(screen)
	var words: Array[Dictionary] = []
	var zones: Dictionary = {"shop": 0, "hand": 0, "own_board": 0, "scout_board": 0}
	var legacy: int = 0
	for record: Dictionary in labels:
		var node: Node = screen.get_node_or_null(NodePath(str(record["path"])))
		if node == null:
			continue
		var context: Dictionary = _tile_context(node)
		if context.is_empty():
			continue
		var allowed: bool = (
			str(record["category"]) == "fallback_names"
			and str(record["fallback_reason"]).begins_with("no individual portrait: ")
		)
		for word: String in word_tokens(str(record["text"])):
			var found: Dictionary = record.duplicate(true)
			found.merge(context)
			found["node"] = str(node.name)
			found["word"] = word
			found["allowed_legacy_fallback"] = allowed
			words.append(found)
			var zone: String = str(context["zone"])
			zones[zone] = CoreUtil.to_int(zones[zone]) + 1
			if allowed:
				legacy += 1
	return {
		"word_count": words.size(),
		"unexpected_word_count": words.size() - legacy,
		"legacy_fallback_word_count": legacy,
		"zone_counts": zones,
		"words": words,
		"raw_label_breakdown": summarize_text_nodes(labels),
	}


## Letter-containing tokens are words, including F1. Compact numeric stats (e.g. 9.5k) are not.
static func word_tokens(text: String) -> PackedStringArray:
	var tokens: PackedStringArray = []
	var token_pattern := RegEx.create_from_string(
		r"[\p{L}\p{M}\p{N}]+(?:['’\-][\p{L}\p{M}\p{N}]+)*"
	)
	var numeric_pattern := RegEx.create_from_string(r"^\p{N}+[kmbKMB]?$")
	var letter_pattern := RegEx.create_from_string(r"\p{L}")
	for result: RegExMatch in token_pattern.search_all(text):
		var token: String = result.get_string()
		if letter_pattern.search(token) != null and numeric_pattern.search(token) == null:
			tokens.append(token)
	return tokens


static func _tile_context(node: Node) -> Dictionary:
	var ancestor: Node = node
	var card: Node = null
	var zone: String = ""
	var tile_path: String = ""
	while ancestor != null:
		var script: Script = ancestor.get_script()
		var path: String = script.resource_path if script != null else ""
		if path == "res://src/ui/widgets/card_view.gd" and card == null:
			card = ancestor
			tile_path = str(card.get_path())
			zone = str(card.get("zone"))
		if path == "res://src/ui/widgets/board_view.gd":
			zone = str(ancestor.get("zone"))
			if tile_path.is_empty():
				tile_path = str(ancestor.get_path())
			break
		if path == "res://src/ui/widgets/hand_fan.gd":
			zone = "hand"
			if tile_path.is_empty():
				tile_path = str(ancestor.get_path())
			break
		ancestor = ancestor.get_parent()
	if zone not in ["shop", "hand", "board", "scout"]:
		return {}
	var view: Dictionary = card.get("unit") if card != null else {}
	return {
		"zone": "own_board" if zone == "board" else "scout_board" if zone == "scout" else zone,
		"tile_path": tile_path,
		"def_id": str(view.get("def_id", "")),
	}


## Budget only ancillary text; the unit Attack/Health and hero Health labels carry explicit tags.
static func budget_nodes(node: Node) -> Array[Dictionary]:
	return text_nodes(node, true)


## Archived UI predates the explicit tags; identify its stat labels by their actual owners.
static func tag_baseline_primary_stats(combat: Control) -> void:
	var cards: Dictionary = combat.get("_cards")
	for value: Variant in cards.values():
		var card: Control = value
		for property: String in ["_attack_label", "_health_label"]:
			var number: Label = card.get(property)
			number.set_meta("combat_primary_stat", true)
	var hero_health: Label = combat.get("_fight_health")
	hero_health.set_meta("combat_primary_stat", true)


static func combat_node(node: Node) -> Control:
	if node.get_script() == preload("res://src/ui/screens/combat_screen.gd"):
		return node as Control
	for child: Node in node.get_children():
		var found: Control = combat_node(child)
		if found != null:
			return found
	return null


static func baseline(viewport: Window, image_path: String, source_seed: int = -1) -> void:
	var combat: Control = combat_node(viewport)
	if combat == null:
		return
	var log_text: RefCounted = combat.get("_log_text")
	var model: RefCounted = combat.get("model")
	tag_baseline_primary_stats(combat)
	var nodes: Array[Dictionary] = text_nodes(combat)
	var ancillary: Array[Dictionary] = budget_nodes(combat)
	var reader_uid: int = -1
	var heading: Label = combat.get("_note_head")
	var units: Dictionary = model.get("units")
	for uid: int in units:
		var unit: Dictionary = units[uid]
		if str(unit.get("name", "")).to_upper() == heading.text.to_upper():
			reader_uid = uid
	var health: Label = combat.get("_fight_health")
	var names: PackedStringArray = log_text.get("side_names")
	var capture_seed: int = source_seed
	var source_state: Dictionary = {}
	var full_combat: Dictionary = {"events": combat.get("events")}
	var fight_input: Dictionary = {}
	var parent: Node = combat.get_parent()
	if parent.get_script() == preload("res://src/ui/app.gd"):
		var port: Object = parent.get("port")
		capture_seed = CoreUtil.to_int(port.call("get_seed"))
		source_state = port.call("get_state")
		full_combat = port.call("get_last_combat")
		var input: Dictionary = port.get("_declutter_input")
		fight_input = input.duplicate(true)
		full_combat["floor_marks"] = floor_marks(input)
		full_combat["hero_health_before"] = input.get("hero_health_before", [])
		var health_after: Array[int] = []
		var ids: Array = input.get("player_ids", [])
		var standings: Array = source_state.get("standings", [])
		for id: Variant in ids:
			var after: int = -1
			for standing: Dictionary in standings:
				if CoreUtil.to_int(standing.get("player_id", -2)) == CoreUtil.to_int(id):
					after = CoreUtil.to_int(standing.get("health", -1))
			health_after.append(after)
		full_combat["hero_health_after"] = health_after
	var report: Dictionary = {
		"source_revision": "1ecbce6",
		"seed": capture_seed,
		"image": image_path.get_file(),
		"pixels": [viewport.size.x, viewport.size.y],
		"visible_text_count": nodes.size(),
		"visible_text_nodes": nodes,
		"ancillary_count": ancillary.size(),
		"budgeted_text_nodes": ancillary,
		"combat": full_combat,
		"fight_input": fight_input,
		"state": source_state,
		"names": Array(names),
		"bottom_side": combat.get("bottom_side"),
		"opponent_health": health.text.to_int(),
		"next_index": combat.get("next_index"),
		"reader_uid": reader_uid,
	}
	var file := FileAccess.open(image_path.get_basename() + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t", true, true))
	file.close()
	print(
		(
			"declutter baseline: %s visible_text=%d ancillary=%d"
			% [image_path, nodes.size(), ancillary.size()]
		)
	)


## New plaques consume existing state that the old single opponent plaque did not draw.
static func presentation(screen: Control, fixture: Dictionary) -> void:
	var heroes: Array[Dictionary] = [{}, {}]
	var healths: Array[int] = [-1, -1]
	var saved_heroes: Array = fixture.get("hero_views", [])
	var saved_health: Array = fixture.get("hero_health", [])
	var state: Dictionary = fixture.get("state", {})
	var fight: Dictionary = fixture["combat"]
	var events: Array = fight["events"]
	var start: Dictionary = events[0]
	var ids: Array = start.get("player_ids", [0, 1])
	var standings: Array = state.get("standings", [])
	var library := UnitLibrary.load_dir()
	for side: int in 2:
		if saved_heroes.size() > side:
			heroes[side] = saved_heroes[side]
		if saved_health.size() > side:
			healths[side] = CoreUtil.to_int(saved_health[side])
		for standing: Dictionary in standings:
			if CoreUtil.to_int(standing.get("player_id", -2)) != CoreUtil.to_int(ids[side]):
				continue
			for hero: Dictionary in library.all_heroes():
				if str(hero.get("name", "")) == str(standing.get("hero", "")):
					heroes[side] = hero
			if CoreUtil.to_int(ids[side]) == CoreUtil.to_int(state.get("player_id", 0)):
				heroes[side] = state.get("hero", {})
			healths[side] = CoreUtil.to_int(standing.get("health", -1))
			if CoreUtil.to_int(fight.get("winner", -1)) == 1 - side:
				healths[side] += CoreUtil.to_int(fight.get("damage", 0))
	screen.set("hero_views", heroes)
	screen.set("hero_health", healths)


static func floor_marks(input: Dictionary) -> Array:
	var out: Array = []
	var slots: Array = input.get("slots", [])
	var rules: Array = input.get("fight_rules", [])
	for side: int in 2:
		var side_rules: Dictionary = rules[side] if rules.size() > side else {}
		var raw_bands: Array = side_rules.get("bands", [])
		var bands: Array[bool] = []
		for value: Variant in raw_bands:
			bands.append(CoreUtil.to_bool(value))
		var marks: Array = (
			preload("res://src/ui/screens/recruit_view.gd")
			. slot_marks(
				{
					"slot_effects": slots[side] if slots.size() > side else [],
					"bands": bands,
				}
			)
		)
		var nests: Array = side_rules.get("nests", [])
		for nest: Dictionary in nests:
			var slot: int = CoreUtil.to_int(nest.get("slot", -1))
			if slot >= 0 and slot < marks.size():
				var mark: Dictionary = marks[slot]
				mark["nest"] = true
		out.append(marks)
	return out


## The saved seed-72 field proof includes post-round Health, unlike its fight boundary.
## Verify the replay result against that history before attaching exact plaque values.
static func recorded_hero_health(
	source: Dictionary, input: Dictionary, fight: Dictionary
) -> Dictionary:
	var game_log: Dictionary = source.get("game_log", {})
	var players: Array = game_log.get("players", [])
	var ids: Array = input.get("player_ids", [])
	var round_number: int = CoreUtil.to_int(input.get("round", -1))
	var before: Array[int] = []
	var after: Array[int] = []
	var armor: Array[int] = []
	for id: Variant in ids:
		var previous: Dictionary = {}
		var current: Dictionary = {}
		for player: Dictionary in players:
			if CoreUtil.to_int(player.get("player_id", -2)) != CoreUtil.to_int(id):
				continue
			var records: Array = player.get("rounds", [])
			for record: Dictionary in records:
				var recorded_round: int = CoreUtil.to_int(record.get("round", -1))
				if recorded_round == round_number - 1:
					previous = record
				elif recorded_round == round_number:
					current = record
		assert(not previous.is_empty() and not current.is_empty(), "recorded Health exists")
		before.append(CoreUtil.to_int(previous.get("health", -1)))
		after.append(CoreUtil.to_int(current.get("health", -1)))
		armor.append(CoreUtil.to_int(previous.get("armor", 0)))
	assert(before.size() == 2 and after.size() == 2)
	var winner: int = CoreUtil.to_int(fight.get("winner", -1))
	var damage: int = CoreUtil.to_int(fight.get("damage", 0))
	for side: int in 2:
		assert(before[side] >= 0 and after[side] >= 0)
		assert(armor[side] == 0, "this replay requires no unrecorded armor transition")
		var expected: int = before[side]
		if winner != side:
			expected = maxi(0, expected - damage)
		assert(after[side] == expected, "current replay damage matches recorded round Health")
	return {
		"before": before,
		"after": after,
		"provenance":
		{
			"source": "docs/ideation/evidence/strong-field/ui-1688x780.json",
			"before_round": round_number - 1,
			"after_round": round_number,
			"field": "game_log.players[*].rounds[*].health",
			"armor_before": armor,
			"verified_replay_damage": damage,
			"observed_history": true,
		},
	}
