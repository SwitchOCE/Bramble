class_name GlassScreen
extends Control
## What the recruit and fight screens share: the 1920 x 1080 stage letterboxed in its window, the
## card nodes kept by key between states (CardKeeper), the hero in the left light, the leaderboard,
## the message area, the hover detail, and the pointer targets. A screen draws one plain view-state
## Dictionary (show_state) and holds no rules. Input here is only what both screens use: hover,
## Tab and a click on your portrait for the leaderboard.
##
## The stage has three layers: Back (the stone window, empty slots, buttons), Cards (the kept
## card nodes) and Front (heroes, labels, the leaderboard, the vignette, the hover detail).

const BOARD_SLOTS: int = 7
const FRONT_SLOTS: int = 4
## STAND-IN: the dark round the stage when the window is not 16:9 (the stone's own shade).
const SURROUND: Color = Color("0b0907")

## The leaderboard in the right light, as the mock-up's "Leaderboard: Shown" switch.
@export var show_leaderboard: bool = false
## A card id to show the hover detail for without a pointer, as the mock-up's "Hover" switch.
@export var pinned_hover: String = ""
## A view state file to show on entering the tree, for the compare scenes; with none and no
## state given, the screen shows an empty table.
@export_file("*.json") var fixture: String = ""

var state: Dictionary = {}

var _g: Dictionary = {}
## The 1920 x 1080 stage's clip, centred in the window; outside it the screen is dark.
var _frame: Control
var _stage: Control
var _back: Control
var _cards: Control
var _front: Control
var _tip: Control
var _keeper: CardKeeper
## Everything the pointer can act on, topmost last: {kind, index, poly, node, card, id}; a card's
## entry names its keeper key until the cards are placed.
var _targets: Array[Dictionary] = []
var _hot: Control
## Where the pointer is on the stage, for keeping the hover detail across states.
var _pointer: Vector2 = Vector2(-1, -1)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_g = _geom()
	if state.is_empty() and fixture != "":
		state = GlassScreen.load_state(fixture)
	show_state(state)
	get_viewport().size_changed.connect(_fit)
	print(_ready_line())


static func load_state(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "%s is not a JSON object" % path)
	var out: Dictionary = parsed
	return out


## Draws a new view state: cards it shares with the last one move, the rest is redrawn.
func show_state(new_state: Dictionary) -> void:
	state = new_state
	if _g.is_empty():
		_g = _geom()
	_ensure_stage()
	_on_new_state()
	_layout()


## Lands every card where it is going at once (tests; a skip).
func settle() -> void:
	if _keeper != null:
		_keeper.settle()


## The node drawn for a pointer target of a kind ("shop", "spell", "hand", "board", "slot",
## "button", ...) at an index, or null.
func node_for(kind: String, index: int) -> Control:
	for target: Dictionary in _targets:
		if target["kind"] == kind and target["index"] == index:
			return target["node"]
	return null


## Every pointer target of a kind, in drawing order.
func targets_of(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for target: Dictionary in _targets:
		if target["kind"] == kind:
			out.append(target)
	return out


## Shows or hides the leaderboard (Tab, or a click on your portrait).
func toggle_leaderboard() -> void:
	show_leaderboard = not show_leaderboard
	_layout()


# ---- for the screens built on this one ----


## The page's geom() this screen is laid out by.
func _geom() -> Dictionary:
	return GlassPieces.recruit_geom()


func _ready_line() -> String:
	return ""


## Where this page puts the leaderboard: its layout.json prefix for top and step.
func _leaderboard_key() -> String:
	return "stage.recruit.leaderboard"


## A new state has come: drop anything the old one was in the middle of.
func _on_new_state() -> void:
	pass


## Builds the screen into the three layers: want() cards in the keeper, then _place_cards().
func _build() -> void:
	pass


func _ensure_stage() -> void:
	if _frame != null:
		return
	_frame = Control.new()
	_frame.name = "Frame"
	_frame.clip_contents = true
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = Vector2(GlassPieces.number("stage.width"), GlassPieces.number("stage.height"))
	add_child(_frame)
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size = _frame.size
	_frame.add_child(_stage)
	for layer_name: String in ["Back", "Cards", "Front"]:
		var layer: Control = Control.new()
		layer.name = layer_name
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.size = _stage.size
		_stage.add_child(layer)
	_back = _stage.get_node("Back")
	_cards = _stage.get_node("Cards")
	_front = _stage.get_node("Front")
	_keeper = CardKeeper.new(_cards)
	_fit()


## Redraws everything but the kept cards, which move to the state's places.
func _layout() -> void:
	_set_hot(null)
	for layer: Control in [_back, _front]:
		for child: Node in layer.get_children():
			layer.remove_child(child)
			child.queue_free()
	_targets.clear()
	_build()
	_tip = Control.new()
	_tip.name = "Tip"
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.z_index = _i(GlassPieces.rule("stage", "#tip", "z-index"))
	_tip.visible = false
	_front.add_child(_tip)
	if pinned_hover != "":
		_pin_hover(pinned_hover)
	elif _pointer.x >= 0.0:
		_hover(_pointer)


## Places the wanted cards and fills their pointer targets in.
func _place_cards() -> void:
	var nodes: Dictionary = _keeper.commit()
	for target: Dictionary in _targets:
		if target.has("key"):
			target["node"] = nodes[target["key"]]
			target.erase("key")


## A card in the keeper and a pointer target for it. extra goes into the look (frost, a slot's
## buff...), and dress(node) adds it after building.
func _want_card(
	key: String,
	kind: String,
	index: int,
	data: Dictionary,
	at: Vector2,
	turn: float = 0.0,
	extra: Dictionary = {},
	time: float = -1.0
) -> void:
	var look: String = JSON.stringify([data, extra, kind == "spell" or _is_spell(data)])
	var numbers: Vector2i = Vector2i(_i(data.get("attack", 0)), _i(data.get("health", 0)))
	var make: Callable = func() -> Control: return _make_card(kind, data, extra)
	_keeper.want(key, str(data.get("id", "")), look, numbers, at, turn, make, time)
	var outline: PackedVector2Array
	if kind == "spell" or _is_spell(data):
		outline = GlassBox.hexagon(Rect2(Vector2.ZERO, _spell_size()), _f(_g["SS"]))
	else:
		outline = GlassBox.hexagon(Rect2(Vector2.ZERO, Vector2(_w(), _h())), _slot_shoulder())
	_targets.append(
		{"kind": kind, "index": index, "key": key, "poly": outline, "card": data, "extra": extra}
	)


## Builds one card node for _want_card; a screen adds its own extras.
func _make_card(kind: String, data: Dictionary, _extra: Dictionary) -> Control:
	var node: Control
	if kind == "spell" or _is_spell(data):
		node = _spell_card(data, _spell_size())
	else:
		node = _unit_card(data, _h())
	node.name = "Card_" + str(data.get("id", ""))
	return node


## A card's key: the core's uid when it has one, else where it is.
static func card_key(kind: String, index: int, data: Dictionary) -> String:
	if data.has("uid") and data["uid"] != null and _i(data["uid"]) >= 0:
		return "u%d" % _i(data["uid"])
	return "%s%d:%s" % [kind, index, str(data.get("id", ""))]


static func _is_spell(data: Dictionary) -> bool:
	return _b(data.get("spell", false))


func _spell_size() -> Vector2:
	return Vector2(_f(_g["SW"]), _f(_g["SH"]))


## The stage stays 1920 x 1080; a window of another shape centres it on a dark surround.
func _fit() -> void:
	if _frame != null:
		_frame.position = ((size - _frame.size) / 2.0).floor()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SURROUND)


# ---- geometry ----


func _h() -> float:
	return _f(_g["H"])


func _w() -> float:
	return _f(_g["W"])


func _gap() -> float:
	return _f(_g["g"])


func _slot_shoulder() -> float:
	var clip: Array = GlassPieces.rule("stage", ".slot", "clip-path")
	var shoulder: Array = clip[1]
	return _f(shoulder[1]) / 100.0


# ---- pieces ----


func _add_window() -> void:
	var window: StoneWindow = StoneWindow.new()
	window.name = "Window"
	_back.add_child(window)
	window.build(_g)


func _add_vignette() -> void:
	var vig: GlassBox = GlassBox.new()
	vig.name = "Vignette"
	vig.box_size = _stage.size
	vig.use_css("stage", "#vig").refresh()
	_front.add_child(vig)


func _unit_card(unit: Dictionary, height: float) -> GlassCard:
	var card: GlassCard = GlassCard.new()
	card.name = "Card_" + str(unit.get("id", ""))
	card.tier = _i(unit.get("tier", 1))
	card.art = GlassPieces.art(str(unit.get("art", "")))
	card.attack = _i(unit.get("attack", 0))
	card.health = _i(unit.get("health", 0))
	card.card_height = height
	card.golden = _b(unit.get("golden", false))
	card.hurt = unit.has("max_health") and _i(unit["health"]) < _i(unit["max_health"])
	var y: float = height * 0.2
	var whole: Vector2 = GlassCard.card_size(height)
	var words: PackedStringArray = _pill_words(unit)
	for i: int in words.size():
		# STAND-IN (stand-ins.html): keywords and counters as cream pills down the art
		var pill: GlassBox = GlassParts.make_pill(words[i])
		pill.name = "Pill_%d" % i
		pill.scale = Vector2.ONE * height / _h()
		pill.position = Vector2((whole.x - pill.box_size.x * pill.scale.x) / 2.0, y)
		card.add_child(pill)
		y += (pill.box_size.y + 4.0) * pill.scale.y
	return card


## The words on a unit's pills: each shown keyword by its display name, each shown counter as its
## name and value.
func _pill_words(unit: Dictionary) -> PackedStringArray:
	var words: PackedStringArray = PackedStringArray()
	for shown: Dictionary in _shown_marks(unit):
		words.append(str(shown["words"]))
	return words


## Reminder lines for the hover detail: one per shown keyword and counter that has one.
func _reminders(card: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for shown: Dictionary in _shown_marks(card):
		var reminder: String = str(shown["reminder"])
		if reminder != "":
			lines.append("%s: %s" % [shown["name"], reminder])
	return lines


## A card's keywords and counters that are drawn, in order: [{name, words, reminder}].
func _shown_marks(card: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for keyword: Variant in card.get("keywords", []):
		var entry: Dictionary = display_entry(str(keyword))
		if not entry.is_empty():
			out.append(
				{"name": entry["name"], "words": entry["name"], "reminder": entry["reminder"]}
			)
	for value: Variant in card.get("counters", []):
		if value is Dictionary:
			var counter: Dictionary = value
			var entry: Dictionary = counter_entry(counter)
			if not entry.is_empty():
				out.append(entry)
	return out


## A slot entry as drawn: {buff, buff_name}, or {} for a slot with nothing on it. Reads the
## contract's {attack, health, keywords [{id} or id], label} (the words "+2/+2", or the first
## shown keyword's name; named by label, else that keyword, else "Slot") and the older
## {buff, buff_name} as given.
func slot_info(raw: Dictionary) -> Dictionary:
	if raw.has("buff"):
		return raw
	var attack: int = _i(raw.get("attack", 0))
	var health: int = _i(raw.get("health", 0))
	var named: String = ""
	for value: Variant in raw.get("keywords", []):
		var id: String = str(value)
		if value is Dictionary:
			var keyword: Dictionary = value
			id = str(keyword.get("id", ""))
		var entry: Dictionary = display_entry(id)
		if not entry.is_empty():
			named = str(entry["name"])
			break
	var words: String = "%+d/%+d" % [attack, health] if attack != 0 or health != 0 else named
	if words == "":
		return {}
	var label: String = str(raw.get("label", ""))
	return {
		"buff": words, "buff_name": label if label != "" else (named if named != "" else "Slot")
	}


## A keyword's (or counter's, or ability's) entry in the state's display table, found by its id or
## by the name the flow put in its place: {name, reminder}. Empty when the entry is hidden
## ("shown": false or "hidden": true) or the table does not have it. With no table in the state,
## the word is shown as it is given, an id title-cased ("divine_shield": "Divine Shield").
func display_entry(word: String) -> Dictionary:
	if word == "":
		return {}
	if _display_table().is_empty():
		return {"name": word.replace("_", " ").capitalize(), "reminder": ""}
	return _shown_entry(_table_entry(word))


## The table's raw entry for word, by id or by name; empty when it has none.
func _table_entry(word: String) -> Dictionary:
	var table: Dictionary = _display_table()
	var direct: Variant = table.get(word)
	if direct is Dictionary:
		return direct
	for key: Variant in table:
		var value: Variant = table[key]
		if value is Dictionary:
			var entry: Dictionary = value
			if str(entry.get("name", "")) == word:
				return entry
	return {}


static func _shown_entry(entry: Dictionary) -> Dictionary:
	var name_words: String = str(entry.get("name", ""))
	if name_words == "" or not _b(entry.get("shown", true)) or _b(entry.get("hidden", false)):
		return {}
	return {"name": name_words, "reminder": str(entry.get("reminder", ""))}


## A counter {key or label, value} as drawn: {name, words ("Name value"), reminder}, or empty
## when hidden. A key is looked up like a keyword. A label is the flow's display name already: it
## is shown unless the table hides it, with the table's reminder when it has one.
func counter_entry(counter: Dictionary) -> Dictionary:
	var entry: Dictionary
	if counter.has("key") or counter.has("id"):
		entry = display_entry(str(counter.get("id", counter.get("key", ""))))
	else:
		var label: String = str(counter.get("label", str(counter.get("icon", "")).capitalize()))
		var found: Dictionary = _table_entry(label)
		entry = _shown_entry(found) if not found.is_empty() else {"name": label, "reminder": ""}
		if label == "":
			entry = {}
	if entry.is_empty():
		return {}
	var words: String = (
		("%s %s" % [entry["name"], number_words(counter.get("value", ""))]).strip_edges()
	)
	return {"name": entry["name"], "words": words, "reminder": entry["reminder"]}


func _display_table() -> Dictionary:
	var table: Variant = state.get("display", {})
	return table if table is Dictionary else {}


## STAND-IN: a slot's lasting bonus under a unit standing on it, as a pill at the card's foot.
func _slot_buff_pill(card: GlassCard, buff: String) -> void:
	var pill: GlassBox = GlassParts.make_pill(buff)
	pill.name = "SlotBuff"
	var whole: Vector2 = GlassCard.card_size(card.card_height)
	pill.position = Vector2((whole.x - pill.box_size.x) / 2.0, whole.y - pill.box_size.y)
	card.add_child(pill)


func _spell_card(spell: Dictionary, spell_size: Vector2) -> GlassSpell:
	var node: GlassSpell = GlassSpell.new()
	node.name = "Card_" + str(spell.get("id", ""))
	node.art = GlassPieces.art(str(spell.get("art", "")))
	node.cost = _i(spell.get("cost", 0))
	node.spell_size = spell_size
	node.shoulder = _f(_g["SS"])
	node.build()
	return node


## An empty board slot (stage.css .slot and .slot::after): a dim pane in a lead outline, or the
## Ring slot (.slot.ring::after) with its bonus written on it when the slot carries one.
func _slot(raw: Dictionary) -> GlassBox:
	var info: Dictionary = slot_info(raw)
	var box: GlassBox = GlassBox.new()
	box.box_size = Vector2(_w(), _h())
	var whole: Rect2 = Rect2(Vector2.ZERO, box.box_size)
	var inset: Array = GlassPieces.rule("stage", ".slot::after", "inset")
	var inner: Rect2 = whole.grow_individual(
		-_f(inset[1]), -_f(inset[0]), -_f(inset[1]), -_f(inset[0])
	)
	var outer_clip: Array = GlassPieces.rule("stage", ".slot", "clip-path")
	var inner_clip: Array = GlassPieces.rule("stage", ".slot::after", "clip-path")
	box.polygon_outer = GlassBox.css_polygon(outer_clip, whole)
	box.polygon_inner = GlassBox.css_polygon(inner_clip, inner)
	var lead: Array = GlassPieces.rule("stage", ".slot", "background")
	var lead_layer: Dictionary = lead[0]
	box.border_colour = Color.html(str(lead_layer["colour"]))
	box.border_width = _f(inset[0])
	box.padding_override = inner
	var ring: bool = info.has("buff")
	box.layers = GlassPieces.rule(
		"stage", ".slot.ring::after" if ring else ".slot::after", "background"
	)
	box.blend_modes = GlassPieces.rule(
		"stage", ".slot.ring::after" if ring else ".slot::after", "background-blend-mode"
	)
	box.refresh()
	if ring:
		_slot_words(box, str(info.get("buff", "")), str(info.get("buff_name", "")))
	return box


## .slot .rt: the bonus over its name, a column centred on the slot, line-height 1.
func _slot_words(box: GlassBox, buff: String, buff_name: String) -> void:
	var em: float = roundf(_h() * GlassPieces.number("stage.slot.ring_text_per_h"))
	var big: GlassText = GlassText.from_rule("stage", ".slot .rt", buff)
	big.font_px = em
	big.line_height = _f(GlassPieces.rule("stage", ".slot .rt", "line-height"))
	big.refresh()
	var small: GlassText = GlassText.from_rule("stage", ".slot .rt small", buff_name.to_upper())
	small.font_px = (
		em
		* GlassParts.em_px(
			(GlassPieces.rule_font("stage", ".slot .rt small") as Dictionary)["size"], 1.0
		)
	)
	small.line_height = big.line_height
	small.spacing = GlassParts.em_px(
		GlassPieces.rule("stage", ".slot .rt small", "letter-spacing"), small.font_px
	)
	var shadows: Array = GlassPieces.rule("stage", ".slot .rt small", "text-shadow")
	small.shadow = shadows[0]
	small.refresh()
	var gap: float = GlassParts.em_px(
		GlassPieces.rule("stage", ".slot .rt small", "margin-top"), small.font_px
	)
	var total: float = big.size.y + gap + small.size.y
	var top: float = (box.box_size.y - total) / 2.0
	big.position = Vector2((box.box_size.x - big.size.x) / 2.0, top)
	# letter-spacing adds space after the last letter too, so the word sits a little left
	small.position = Vector2((box.box_size.x - small.size.x) / 2.0, top + big.size.y + gap)
	box.add_child(big)
	box.add_child(small)


## stage.js leftLight(): the turn at the top; on the sill the hero's name, portrait, Health and
## the player's counters on the chips.
func _build_hero() -> void:
	var height: float = _stage.size.y
	var turn: GlassText = GlassText.from_rule("stage", ".lbl", "Turn %d" % _i(state.get("turn", 1)))
	turn.name = "Turn"
	turn.refresh()
	turn.position = Vector2(
		GlassPieces.number("stage.hero.turn_x"), GlassPieces.number("stage.hero.turn_y")
	)
	_front.add_child(turn)
	var hero: Dictionary = state.get("hero", {})
	var hero_name: GlassText = GlassText.from_rule("stage", ".lbl", str(hero.get("name", "")))
	hero_name.font_px = GlassPieces.number("stage.hero.name_size")
	hero_name.refresh()
	hero_name.position = Vector2(
		GlassPieces.number("stage.hero.name_x"), height - GlassPieces.number("stage.hero.name_up")
	)
	_front.add_child(hero_name)
	var port: GlassBox = GlassParts.make_portrait(
		str(hero.get("portrait", "")), GlassPieces.number("stage.hero.port"), [".hero"]
	)
	port.name = "Hero"
	port.position = Vector2(
		GlassPieces.number("stage.hero.port_x"), height - GlassPieces.number("stage.hero.port_up")
	)
	_front.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(_i(state.get("health", 0)), [".hp"])
	hp.name = "HeroHealth"
	hp.position = Vector2(
		GlassPieces.number("stage.hero.hp_x"), height - GlassPieces.number("stage.hero.hp_up")
	)
	_front.add_child(hp)
	_targets.append(
		{"kind": "button", "index": 0, "id": "hero", "node": port, "poly": _circle(port.box_size)}
	)
	_build_counters()


## The player's counters (a tribe's count, a Compost number...) on the mock-up's two chips.
func _build_counters() -> void:
	var height: float = _stage.size.y
	var counters: Array = []
	for value: Variant in state.get("counters", []):
		var counter_value: Dictionary = value if value is Dictionary else {}
		if not counter_entry(counter_value).is_empty():
			counters.append(counter_value)
	var step: float = GlassPieces.number("stage.hero.chip.step")
	for i: int in counters.size():
		var counter: Dictionary = counters[i]
		var shown: Dictionary = counter_entry(counter)
		var tip_card: Dictionary = {
			"name": shown["name"], "text": shown["reminder"], "kind_line": "Counter"
		}
		if not counter.has("icon"):
			# STAND-IN (stand-ins.html): a counter with no emblem is one pill, its name and value
			var pill: GlassBox = GlassParts.make_pill(str(shown["words"]))
			pill.name = "Chip_%d" % i
			pill.position = Vector2(
				GlassPieces.number("stage.hero.chip.x"),
				height - GlassPieces.number("stage.hero.chip.count_up") + i * step
			)
			_front.add_child(pill)
			_add_counter_target(pill, tip_card)
			continue
		var emblem: GlassBox = GlassBox.new()
		emblem.name = "Chip_%d" % i
		var side: float = GlassPieces.rule_number("stage", ".chip", "width")
		emblem.box_size = Vector2(side, side)
		emblem.use_css("stage", ".chip")
		if counter.has("icon"):
			emblem.image_texture = GlassPieces.texture("ui/tr-%s.png" % str(counter["icon"]))
			emblem.layers = [{"kind": "image", "size": "cover", "position": [50.0, 50.0]}]
		emblem.refresh()
		emblem.position = Vector2(
			GlassPieces.number("stage.hero.chip.x"),
			height - GlassPieces.number("stage.hero.chip.up") + i * step
		)
		_front.add_child(emblem)
		_add_counter_target(emblem, tip_card)
		var count: GlassBox = GlassParts.make_pill(number_words(counter.get("value", "")))
		count.position = Vector2(
			GlassPieces.number("stage.hero.chip.count_x"),
			height - GlassPieces.number("stage.hero.chip.count_up") + i * step
		)
		_front.add_child(count)


static func _circle(box: Vector2) -> PackedVector2Array:
	var outline: PackedVector2Array = PackedVector2Array()
	for i: int in 24:
		outline.append(box / 2.0 + Vector2.from_angle(TAU * i / 24.0) * box.x / 2.0)
	return outline


## stage.js leaderboard(): a slim pane of portraits in the right light, each with its place and
## Health; the next opponent glows, you have a pale ring.
func _build_leaderboard() -> void:
	var players: Array = state.get("players", [])
	var top: float = GlassPieces.number(_leaderboard_key() + ".top")
	var step: float = GlassPieces.number(_leaderboard_key() + ".step")
	var px: float = 1904.0 - _f(_g["sideW"]) / 2.0
	var pane: GlassBox = GlassBox.new()
	pane.name = "Leaderboard"
	pane.box_size = Vector2(
		GlassPieces.number("stage.leaderboard.pane_w"),
		players.size() * step + GlassPieces.number("stage.leaderboard.pane_extra")
	)
	pane.use_css("stage", "#lbpane")
	pane.position = Vector2(
		px - GlassPieces.number("stage.leaderboard.pane_left"),
		top - GlassPieces.number("stage.leaderboard.pane_up")
	)
	pane.refresh()
	_front.add_child(pane)
	var side: float = GlassPieces.number("stage.leaderboard.port")
	for i: int in players.size():
		var player: Dictionary = players[i]
		var y: float = top + GlassPieces.number("stage.leaderboard.row_down") + i * step
		var rules: Array = [".lb .port"]
		if player.get("next", false):
			rules.append(".lb .next .port")
		elif player.get("you", false):
			rules.append(".lb .you .port")
		var port: GlassBox = GlassParts.make_portrait(str(player.get("portrait", "")), side, rules)
		port.position = Vector2(px - GlassPieces.number("stage.leaderboard.port_left"), y)
		_front.add_child(port)
		var hp: GlassBox = GlassParts.health_badge(_i(player.get("health", 0)), [".hp", ".lb .hp"])
		hp.name = "LeaderHealth_%d" % i
		hp.position = Vector2(
			px + GlassPieces.number("stage.leaderboard.hp_right"),
			y + GlassPieces.number("stage.leaderboard.hp_down")
		)
		_front.add_child(hp)
		var place: GlassText = GlassText.from_rule("stage", ".lb .pl", str(i + 1))
		place.refresh()
		place.position = Vector2(
			px - GlassPieces.number("stage.leaderboard.place_left"),
			y + GlassPieces.number("stage.leaderboard.place_down")
		)
		_front.add_child(place)


## STAND-IN message area (no mock-up): words centred on the transom.
func _build_message(words: String) -> void:
	if words == "":
		return
	var label: GlassText = GlassText.from_rule("stage", ".lbl", words)
	label.name = "Message"
	label.font_px = GlassPieces.number("stage.hero.name_size")
	label.refresh()
	label.z_index = 7
	label.position = (
		Vector2(
			960.0 - label.size.x / 2.0, (_f(_g["T0"]) + _f(_g["T1"])) / 2.0 - label.size.y / 2.0
		)
		. round()
	)
	_front.add_child(label)


# ---- hover detail (stage.js hoverDetail) ----


func _pin_hover(card_id: String) -> void:
	for target: Dictionary in _targets:
		var card: Dictionary = target.get("card", {})
		if str(card.get("id", "")) == card_id:
			var node: Control = target["node"]
			var at: Vector2 = (
				_rest(target)
				+ Vector2(
					_w() * GlassPieces.number("stage.tip.pin_x_per_w"),
					_h() * GlassPieces.number("stage.tip.pin_y_per_h")
				)
			)
			if node != null:
				_show_tip(target, at)
			return


## Where a target's node is going (a kept card may still be moving there).
func _rest(target: Dictionary) -> Vector2:
	var node: Control = target["node"]
	return node.position


## The hover detail for whatever card is under a stage point, or none.
func _hover(here: Vector2) -> void:
	var over: Dictionary = _target_at(here, true)
	if over.is_empty():
		if pinned_hover == "":
			_hide_tip()
	else:
		_show_tip(over, here)


## The card's detail beside the pointer: the card at 1.6 x, and a pane with its name, its kind and
## its rules text. It flips to the left near the right edge and stays on the screen.
func _show_tip(target: Dictionary, at: Vector2) -> void:
	var card: Dictionary = target["card"]
	if str(target["kind"]) == "counter":
		_show_words_tip(target, at)
		return
	var big: float = GlassPieces.number("stage.tip.big_per_h") * _h()
	var big_w: float = big * GlassPieces.card_units().x / GlassPieces.card_units().y
	if _hot != target["node"]:
		for child: Node in _tip.get_children():
			_tip.remove_child(child)
			child.queue_free()
		var shown: Control
		var spell: bool = str(target["kind"]) == "spell" or _is_spell(card)
		if spell:
			var spell_h: float = big * _f(_g["SH"]) / _h()
			shown = _spell_card(card, Vector2(spell_h * _f(_g["SW"]) / _f(_g["SH"]), spell_h))
		else:
			shown = _unit_card(card, big)
		shown.name = "Card"
		_tip.add_child(shown)
		var text: GlassBox = GlassParts.tip_text(card, spell, _reminders(card))
		text.position = Vector2(
			shown.size.x + GlassPieces.rule_number("stage", "#tip", "gap"),
			GlassPieces.rule_number("stage", "#tip .txt", "margin-top")
		)
		_tip.add_child(text)
	var gap: float = GlassPieces.number("stage.tip.gap")
	var tx: float = at.x + gap
	var ty: float = at.y - big / 2.0
	if (
		tx + big_w + GlassPieces.number("stage.tip.flip_room")
		> GlassPieces.number("stage.tip.flip_edge")
	):
		tx = at.x - gap - big_w - GlassPieces.number("stage.tip.flip_back")
	ty = maxf(
		GlassPieces.number("stage.tip.top_min"),
		minf(GlassPieces.number("stage.tip.bottom_max") - big, ty)
	)
	_tip.position = Vector2(tx, ty)
	_tip.visible = true
	var node: Control = target["node"]
	_set_hot(node)


## STAND-IN (stand-ins.html): a counter's hover is the detail pane alone (its name and reminder),
## beside the pointer and above it, kept on the screen.
func _show_words_tip(target: Dictionary, at: Vector2) -> void:
	if _hot != target["node"]:
		for child: Node in _tip.get_children():
			_tip.remove_child(child)
			child.queue_free()
		var words: Dictionary = target["card"]
		_tip.add_child(GlassParts.tip_text(words, false))
	var text: GlassBox = _tip.get_child(_tip.get_child_count() - 1)
	var gap: float = GlassPieces.number("stage.tip.gap")
	var ty: float = minf(at.y, GlassPieces.number("stage.tip.bottom_max")) - text.box_size.y
	_tip.position = Vector2(at.x + gap, maxf(GlassPieces.number("stage.tip.top_min"), ty))
	_tip.visible = true
	var node: Control = target["node"]
	_set_hot(node)


## A player's counter as a pointer target, for its hover.
func _add_counter_target(node: Control, tip_card: Dictionary) -> void:
	var box: Vector2 = (node as GlassBox).box_size
	(
		_targets
		. append(
			{
				"kind": "counter",
				"index": _targets.size(),
				"node": node,
				"poly":
				PackedVector2Array([Vector2.ZERO, Vector2(box.x, 0), box, Vector2(0, box.y)]),
				"card": tip_card,
			}
		)
	)


func _hide_tip() -> void:
	if _tip != null:
		_tip.visible = false
	_set_hot(null)


## .card.hot: the hovered card brightened, glowing, above the vignette.
func _set_hot(node: Control) -> void:
	if _hot == node:
		return
	if is_instance_valid(_hot):
		if _hot is GlassCard:
			(_hot as GlassCard).set_hot(false)
		_hot.z_index = 0
	_hot = node
	if _hot is GlassCard:
		(_hot as GlassCard).set_hot(true)
	if _hot != null and (_hot is GlassCard or _hot is GlassSpell):
		_hot.z_index = _i(GlassPieces.rule("stage", ".card.hot", "z-index"))


# ---- input: hover and the leaderboard ----


## Keys go to the screen that is showing: a hidden screen in the same tree takes none.
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_TAB:
		toggle_leaderboard()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if _frame == null:
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		var hit: Dictionary = _target_at(button.position - _frame.position, false)
		if hit.get("id", "") == "hero":
			toggle_leaderboard()
		accept_event()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_pointer = motion.position - _frame.position
		_hover(_pointer)


## The topmost target under a stage point; cards_only for the hover detail.
func _target_at(at: Vector2, cards_only: bool) -> Dictionary:
	for i: int in range(_targets.size() - 1, -1, -1):
		var target: Dictionary = _targets[i]
		if cards_only and not target.has("card"):
			continue
		var node: Control = target.get("node")
		if node == null or not is_instance_valid(node):
			continue
		var poly: PackedVector2Array = target["poly"]
		if Geometry2D.is_point_in_polygon(_to_local_of(node, at), poly):
			return target
	return {}


## A stage point in a node's own space, through every parent up to the stage.
func _to_local_of(node: Control, at: Vector2) -> Vector2:
	var xf: Transform2D = Transform2D.IDENTITY
	var walk: Node = node
	while walk != null and walk != _stage:
		xf = (walk as CanvasItem).get_transform() * xf
		walk = walk.get_parent()
	return xf.affine_inverse() * at


## A value as words: a whole number without its ".0" (JSON gives every number as a float).
static func number_words(v: Variant) -> String:
	if v is float:
		var value: float = v
		if is_equal_approx(value, roundf(value)):
			return str(roundi(value))
	return str(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _b(v: Variant) -> bool:
	return GlassPieces.as_bool(v)
