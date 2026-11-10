@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_property_access")
extends Control
## Short recruit consequences share one clock. Only an unexplained failure gets prose.

const Events := preload("res://src/core/combat/combat_events.gd")

const Data := preload("res://src/ui/view_data.gd")
const Settings := preload("res://src/ui/settings.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Layout := preload("res://src/ui/screens/recruit_layout.gd")
const View := preload("res://src/ui/screens/recruit_view.gd")

var tracks: Array[Dictionary] = []
var elapsed: float = 0.0
var duration: float = 0.0
var _reduced: bool = false
var _rate: float = 1.0
var _claimed: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 15
	set_process(false)


static func new_events(before: Dictionary, after: Dictionary) -> Array[Dictionary]:
	var entries: Array = Data.a(after, "recruit_log")
	var start: int = (
		Data.a(before, "recruit_log").size()
		if Data.i(before, "round", -1) == Data.i(after, "round", 0)
		else 0
	)
	var events: Array[Dictionary] = []
	for index: int in range(start, entries.size()):
		events.append(entries[index])
	return events


## The state is already committed and rendered. Old card pictures come from the action snapshot.
func present(ui: Layout, before: Dictionary, events: Array = []) -> String:
	finish()
	_reduced = Settings.reduce_motion
	_rate = maxf(1.0, Settings.fight_speed)
	var old_state: Dictionary = Data.d(before, "state")
	if events.is_empty():
		events = new_events(old_state, ui.state)
	var failures: PackedStringArray = []
	for entry: Dictionary in events:
		var kind: String = Data.s(entry, "type")
		match kind:
			"discover_empty", "no_room":
				failures.append(View.event_note(entry))
				if kind == "no_room":
					_failed_summon(ui, entry)
			"kiss", "transform":
				var card: Card = _iid_card(ui, Data.i(entry, "iid", -1))
				if card != null:
					_cue(kind, card, 0.3 if kind == "kiss" else 0.4)
					if kind == "kiss":
						_icon("heart", _rect(card).get_center(), "heart", 0.3)
			"poached":
				_poached(ui, entry)
			"poach_returned", "walk_out":
				_departure(ui, before, entry)
			"nest_replaced":
				_nest(ui, Data.i(entry, "slot", -1))
	if Data.i(ui.state, "buys_left", -1) == 0 and Data.i(old_state, "buys_left", -1) != 0:
		_cue("spent", _spent_target(ui), 0.3)
	_combine(ui, before)
	if not failures.is_empty():
		duration = maxf(duration, 0.9)
	set_process(duration > 0.0)
	advance(0.0)
	return "\n".join(failures)


func refuse(target: Control) -> void:
	finish()
	_reduced = Settings.reduce_motion
	_rate = maxf(1.0, Settings.fight_speed)
	_cue("refused", target, 0.25)
	set_process(not tracks.is_empty())
	advance(0.0)


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	elapsed += delta
	for track: Dictionary in tracks:
		var node: Control = Data.control(track["node"])
		if not is_instance_valid(node):
			continue
		var phase: float = clampf(elapsed / track.seconds, 0.0, 1.0)
		var beat: float = sin(phase * PI)
		var origin: Vector2 = track.position
		var base_scale: Vector2 = track.scale
		var colour: Color = track.colour
		var kind: String = track.kind
		var target: Control = Data.control(track.get("target"))
		if kind == "poached" and is_instance_valid(target):
			track["to"] = _rect(target).position
		if track.overlay:
			node.visible = phase < 1.0
		if _reduced:
			if track.has("to") and phase >= 0.5:
				node.position = track.to
			node.modulate = colour.lerp(Color(1.65, 1.4, 1.1, colour.a), 1.0 - phase)
			if track.overlay:
				node.modulate.a = 1.0 - phase
		else:
			match kind:
				"refused":
					node.position = (
						origin + Vector2(sin(phase * TAU * 3.0) * 9.0 * (1.0 - phase), 0)
					)
				"transform", "spent":
					node.pivot_offset = node.size / 2.0
					node.scale.x = base_scale.x * absf(cos(phase * PI))
				"kiss":
					node.pivot_offset = node.size / 2.0
					node.scale = base_scale * (1.0 + beat * 0.08)
				"walk_out":
					var leaving: float = clampf((phase - 0.27) / 0.73, 0.0, 1.0)
					node.rotation = sin(minf(phase / 0.27, 1.0) * PI) * 0.12
					node.position = origin.lerp(track.to, leaving)
					node.modulate.a = 1.0 - leaving
				"poached", "poach_returned", "queued", "combine":
					node.position = origin.lerp(track.to, phase) - Vector2(0, beat * 28.0)
					if kind == "poach_returned":
						node.modulate.a = 1.0 - phase
				"nest_old":
					node.position = origin + Vector2(phase * 72.0, 0)
					node.rotation = phase * PI
					node.modulate.a = 1.0 - phase
				"nest_new":
					node.position = origin - Vector2(0, (1.0 - phase) * 48.0)
					node.scale = base_scale * (1.0 + beat * 0.15)
				"no_room":
					node.position = origin + Vector2(sin(phase * PI) * 32.0, -beat * 12.0)
					node.modulate = colour.lerp(UiTheme.MUTE, phase)
					node.modulate.a = 1.0 - phase
				"heart":
					node.position = origin - Vector2(0, phase * 38.0)
					node.scale = base_scale * (0.5 + beat * 0.7)
					node.modulate.a = 1.0 - phase
		if is_instance_valid(target):
			target.modulate.a = 1.0 if phase >= 1.0 else 0.0
	if duration > 0.0 and elapsed >= duration:
		finish()


func finish() -> void:
	for track: Dictionary in tracks:
		var node: Control = Data.control(track["node"])
		if is_instance_valid(node):
			if track.overlay:
				node.hide()
				node.queue_free()
			else:
				node.position = track.position
				node.scale = track.scale
				node.rotation = track.rotation
				node.modulate = track.colour
				node.pivot_offset = track.pivot
		var target: Control = Data.control(track.get("target"))
		if is_instance_valid(target):
			target.modulate.a = 1.0
	tracks.clear()
	_claimed.clear()
	elapsed = 0.0
	duration = 0.0
	set_process(false)


func _cue(kind: String, node: Control, seconds: float, overlay: bool = false) -> Dictionary:
	if not is_instance_valid(node):
		return {}
	var track: Dictionary = {
		"kind": kind,
		"node": node,
		"seconds": 0.15 if _reduced else seconds / _rate,
		"position": node.position,
		"scale": node.scale,
		"rotation": node.rotation,
		"colour": node.modulate,
		"pivot": node.pivot_offset,
		"overlay": overlay,
	}
	tracks.append(track)
	duration = maxf(duration, track.seconds)
	return track


func _rect(node: Control) -> Rect2:
	return get_global_transform().affine_inverse() * node.get_global_rect()


func _picture(view: Dictionary, rect: Rect2) -> Card:
	var card := Card.new()
	card.show_unit(view, Card.Mode.MINI)
	card.set_card_size(rect.size)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	card.position = rect.position
	return card


func _icon(icon_name: String, at: Vector2, kind: String, seconds: float) -> Dictionary:
	var icon := TextureRect.new()
	icon.texture = Icons.icon(icon_name, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2.ONE * 48
	icon.pivot_offset = icon.size / 2.0
	icon.position = at - icon.size / 2.0
	add_child(icon)
	return _cue(kind, icon, seconds, true)


func _iid_card(ui: Layout, iid: int) -> Card:
	for card: Card in ui._board.cards:
		if card != null and Data.i(card.unit, "iid", -2) == iid:
			return card
	return null


func _spent_target(ui: Layout) -> Control:
	if ui._hero.power.is_visible_in_tree():
		return ui._hero.power
	for plaque: Control in ui._lobby.plaques:
		var standing: Dictionary = plaque.get("_standing")
		var portrait: Control = plaque.get("_portrait")
		if Data.b(standing, "is_human") and portrait.is_visible_in_tree():
			return portrait
	return ui._gold.get("_big")


func _rival_point(ui: Layout) -> Vector2:
	# The most recent combat records the actual rival, including a ghost owner.
	var fight: Dictionary = ui.port.get_last_combat()
	var ids: Array = Data.a(Events.start(Data.a(fight, "events")), "player_ids")
	if ids.is_empty():
		ids = Data.a(fight, "player_ids")
	for plaque: Control in ui._lobby.plaques:
		var standing: Dictionary = plaque.get("_standing")
		if not Data.b(standing, "is_human") and ids.has(Data.i(standing, "player_id", -9)):
			return _rect(plaque).get_center()
	return _rect(ui._lobby).get_center()


func _poached(ui: Layout, event: Dictionary) -> void:
	for child: Node in ui._shop_cards.get_children():
		var card: Card = child as Card
		if card == null or not Data.b(card.unit, "poached"):
			continue
		if Data.s(card.unit, "def_id") != Data.s(event, "card"):
			continue
		var key: String = "poached:%d" % card.index
		if _claimed.has(key):
			continue
		_claimed[key] = true
		var destination: Rect2 = _rect(card)
		var ghost: Card = _picture(
			card.unit, Rect2(_rival_point(ui) - destination.size / 2.0, destination.size)
		)
		var track: Dictionary = _cue("poached", ghost, 0.5, true)
		track["to"] = destination.position
		track["target"] = card
		return


func _departure(ui: Layout, before: Dictionary, event: Dictionary) -> void:
	var kind: String = Data.s(event, "type")
	for old: Dictionary in Data.a(before, "cards"):
		var zone: String = Data.s(old, "zone")
		if zone != ("board" if kind == "walk_out" else "shop"):
			continue
		if kind == "walk_out" and Data.i(old, "index", -2) != Data.i(event, "slot", -1):
			continue
		var unit: Dictionary = Data.d(old, "unit")
		if Data.s(unit, "name") != Data.s(event, "name"):
			continue
		var key: String = "%s:%d" % [zone, Data.i(old, "index", -1)]
		if _claimed.has(key):
			continue
		_claimed[key] = true
		var rect: Rect2 = old["rect"]
		var ghost: Card = _picture(unit, rect)
		var track: Dictionary = _cue(kind, ghost, 0.55 if kind == "walk_out" else 0.3, true)
		track["to"] = (
			Vector2(_rect(ui._board).end.x + 32.0, rect.position.y)
			if kind == "walk_out"
			else _rival_point(ui)
		)
		if kind == "walk_out":
			var coin: Dictionary = _icon("acorn", rect.get_center(), "queued", 0.55)
			var income: Control = ui._gold.get("_income_icon")
			coin["to"] = _rect(income).get_center() - Vector2.ONE * 24
		return


func _nest(ui: Layout, slot: int) -> void:
	if not BoardGeometry.is_valid(slot):
		return
	var at: Vector2 = get_global_transform().affine_inverse() * ui._board.slot_global_center(slot)
	for kind: String in ["nest_old", "nest_new"]:
		var egg := TextureRect.new()
		egg.texture = load("res://assets/portraits/nest_egg.jpg")
		egg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		egg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		egg.size = Vector2(64, 64)
		egg.position = at - egg.size / 2.0
		egg.pivot_offset = egg.size / 2.0
		add_child(egg)
		_cue(kind, egg, 0.4, true)


func _failed_summon(ui: Layout, event: Dictionary) -> void:
	var rect: Rect2 = _rect(ui._board)
	var ghost: Card = _picture(
		{"def_id": Data.s(event, "unit", "mouse"), "name": Data.s(event, "name")},
		Rect2(Vector2(rect.end.x - 90, rect.position.y + 24), Vector2(68, 68))
	)
	_cue("no_room", ghost, 0.3, true)


func _combine(ui: Layout, before: Dictionary) -> void:
	if View.combine_note(Data.d(before, "state"), ui.state).is_empty():
		return
	for old: Dictionary in Data.a(before, "cards"):
		var unit: Dictionary = Data.d(old, "unit")
		var into: String = Data.s(unit, "combines_into")
		if Data.s(old, "zone") != "hand" or into.is_empty():
			continue
		var retained: bool = false
		for current: Dictionary in Data.a(ui.state, "hand"):
			if Data.i(unit, "iid", -1) > 0 and Data.i(current, "iid") == Data.i(unit, "iid"):
				retained = true
		if retained:
			continue
		for child: Node in ui._hand_cards.get_children():
			var target: Card = child as Card
			if target == null or Data.s(target.unit, "def_id") != into:
				continue
			var ghost: Card = _picture(unit, old["rect"])
			var track: Dictionary = _cue("combine", ghost, 0.4, true)
			track["to"] = _rect(target).position
			track["target"] = target
			break
