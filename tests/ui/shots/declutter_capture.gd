extends RefCounted
## Shared evidence counter. Counts nonempty, visible text controls rather than drawn digits.


static func text_nodes(node: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var draws_self: bool = true
	if node is CanvasItem:
		var item: CanvasItem = node as CanvasItem
		if not item.is_visible_in_tree() or item.modulate.a < 0.05:
			return found
		draws_self = item.self_modulate.a >= 0.05
	var words: String = ""
	if node is Label:
		words = (node as Label).text
	elif node is RichTextLabel:
		words = (node as RichTextLabel).get_parsed_text()
	elif node is Button and not node.has_meta("drawn_face"):
		words = (node as Button).text
	if draws_self and not words.strip_edges().is_empty():
		found.append({"path": str(node.get_path()), "text": words})
	for child: Node in node.get_children():
		found.append_array(text_nodes(child))
	return found


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
	var nodes: Array[Dictionary] = text_nodes(combat)
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
	print("declutter baseline: %s visible_text=%d" % [image_path, nodes.size()])


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
