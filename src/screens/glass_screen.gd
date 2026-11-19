class_name GlassScreen
extends Control
## What the recruit and fight screens share: the 1920 x 1080 stage letterboxed in its window, the
## card nodes kept by key between states (CardKeeper), the hero in the left light, the leaderboard,
## the message area, the hover detail, and the pointer targets. A screen draws one plain view-state
## Dictionary (show_state) and holds no rules. Input here is only what both screens use: hover,
## Tab and a click on your portrait for the leaderboard.
##
## The stage has four layers: Back (the stone window, buttons), Slots (permanent backings),
## Cards (the kept card nodes) and Front (heroes, labels, leaderboard, vignette, hover detail).

const BOARD_SLOTS: int = 7
## How long a hover detail takes to fade when a card is pressed (6 frames).
const TIP_FADE_TIME: float = 6.0 / 60.0
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
var _slots: SlotLayer
var _cards: Control
var _front: Control
var _keeper: CardKeeper
## The hover detail (GlassTips) and the counter plates (GlassCounters).
var _tips: GlassTips
var _counters: GlassCounters
var _compost: CompostPanel
var _compost_layer: CanvasLayer
## Everything the pointer can act on, topmost last: {kind, index, poly, node, card, id}; a card's
## entry names its keeper key until the cards are placed.
var _targets: Array[Dictionary] = []
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
	if _compost != null:
		var entries: Array = _compost_entries()
		if entries != _compost.entries:
			var offset: int = _compost.scroll.scroll_vertical if _compost.scroll != null else 0
			_compost.entries = entries.duplicate(true)
			_compost.show_state({"display": _display_table()})
			if _compost.scroll != null:
				_compost.scroll.set_deferred("scroll_vertical", offset)


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


## A unit card's (and a board slot's) width and height on the stage.
func card_box() -> Vector2:
	return Vector2(_w(), _h())


## A number from the page's geom() ("shopBot", "handTop", ...), on the stage.
func geom(key: String) -> float:
	return _f(_g[key])


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


## The hover detail this screen shows (a screen with its own kinds of detail extends GlassTips).
func _make_tips() -> GlassTips:
	return GlassTips.new(self)


## A new state has come: drop anything the old one was in the middle of.
func _on_new_state() -> void:
	pass


## Builds the screen's layers: want() cards in the keeper, then _place_cards().
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
	for layer_name: String in ["Back", "Slots", "Cards", "Front"]:
		var layer: Control = SlotLayer.new() if layer_name == "Slots" else Control.new()
		layer.name = layer_name
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.size = _stage.size
		_stage.add_child(layer)
	_back = _stage.get_node("Back")
	_slots = _stage.get_node("Slots") as SlotLayer
	_cards = _stage.get_node("Cards")
	_front = _stage.get_node("Front")
	_keeper = CardKeeper.new(_cards)
	_tips = _make_tips()
	_counters = GlassCounters.new(self)
	_stage.add_child(_counters)
	tree_exiting.connect(_close_compost)
	_fit()


## Redraws the background and foreground. Slots persist; kept cards move to the state's places.
func _layout() -> void:
	_tips.set_hot(null)
	for layer: Control in [_back, _front]:
		for child: Node in layer.get_children():
			layer.remove_child(child)
			child.queue_free()
	_targets.clear()
	_build()
	_tips.make_tip()
	if pinned_hover != "":
		_tips.pin(pinned_hover)
	elif _pointer.x >= 0.0:
		_tips.hover(_pointer)


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
	card.card_height = height
	card.golden = _b(unit.get("golden", false))
	# STAND-IN (polish.html .num.up): a number above what the card prints in green, below in red
	card.base_attack = _i(unit.get("base_attack", -1))
	card.base_health = _i(unit.get("base_health", -1))
	card.max_health = _i(unit.get("max_health", -1))
	card.set_numbers(card.attack, _i(unit.get("health", 0)))
	var whole: Vector2 = GlassCard.card_size(height)
	var places: int = maxi(
		1,
		floori(
			(
				(whole.x * KeywordStyle.CARD_ROOM + KeywordStyle.CARD_GAP)
				/ (KeywordStyle.CARD_MIN_SIDE + KeywordStyle.CARD_GAP)
			)
		)
	)
	var marks: Array[Dictionary] = CardTerms.pills(unit, _display_table(), places)
	var side: float = minf(
		maxf(height * KeywordStyle.CARD_DIAMETER, KeywordStyle.CARD_MIN_SIDE),
		(
			(whole.x * KeywordStyle.CARD_ROOM - KeywordStyle.CARD_GAP * (marks.size() - 1))
			/ maxf(1, marks.size())
		)
	)
	var row_w: float = side * marks.size() + KeywordStyle.CARD_GAP * (marks.size() - 1)
	for i: int in marks.size():
		var mark: KeywordMark = KeywordMark.make(marks[i], true, side)
		mark.name = "Pill_%d" % i
		if _b(marks[i].get("spent", false)):
			mark.name += "_spent"
		mark.position = Vector2(
			(whole.x - row_w) / 2.0 + i * (side + KeywordStyle.CARD_GAP),
			height * KeywordStyle.CARD_Y - side / 2.0
		)
		card.add_child(mark)
	var pips: CardPips = CardPips.make(CardTerms.pips(unit, _display_table()), height, card.tier)
	if pips != null:
		card.add_child(pips)
	return card


## The words on a unit's pills (CardTerms.pills: keywords with their numbers, then counters).
func _pill_words(unit: Dictionary) -> PackedStringArray:
	var words: PackedStringArray = PackedStringArray()
	for shown: Dictionary in CardTerms.pills(unit, _display_table()):
		words.append(str(shown["words"]))
	return words


## Reminder lines for the hover detail: every term the card uses (CardTerms.reminders).
func _reminders(card: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = CardTerms.reminders(card, _display_table())
	# where the numbers above or below its own come from, drawn green (GlassParts.SOURCE_MARK)
	for source: Variant in card.get("sources", []):
		lines.append(GlassParts.SOURCE_MARK + str(source))
	return lines


## A slot drawn with its keyword, keyword label and Renown when present.
func slot_info(raw: Dictionary) -> Dictionary:
	var named: String = ""
	for value: Variant in raw.get("keywords", []):
		var keyword: Dictionary = value if value is Dictionary else {}
		var entry: Dictionary = display_entry(str(keyword.get("id", "")))
		if not entry.is_empty():
			named = str(entry["name"])
			break
	var renown: int = _i(raw.get("renown", 0))
	var out: Dictionary = {}
	if renown != 0:
		out["renown"] = renown
	if named != "":
		out["keyword"] = named
		var label: String = str(raw.get("label", ""))
		out["keyword_label"] = label if label != "" else named
	return out


## A keyword's (or counter's, or ability's) entry in the state's display table, by its id:
## {name, reminder}. Empty when the entry is hidden or the table does not have it.
func display_entry(id: String) -> Dictionary:
	return CardTerms.lookup(id, _display_table())


## A counter {id, value} as drawn: {name, words ("Name value"), reminder}, or empty when hidden.
func counter_entry(counter: Dictionary) -> Dictionary:
	return CardTerms.counter(counter, _display_table())


func _display_table() -> Dictionary:
	var table: Variant = state.get("display", {})
	return table if table is Dictionary else {}


## A slot's keyword pill at the foot of its occupying unit's card.
func _slot_keyword_pill(card: GlassCard, keyword: String) -> void:
	var pill: GlassBox = GlassParts.make_pill(keyword)
	pill.name = "SlotKeyword"
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
	_counters.build(_shown_counters())


## The counters drawn now: the state's (a screen may hold the last ones a moment).
func _shown_counters() -> Array:
	return state.get("counters", [])


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
		var out: bool = not player.get("alive", true)
		var port: GlassBox = (
			GlassParts.out_portrait(str(player.get("portrait", "")), side, rules)
			if out
			else GlassParts.make_portrait(str(player.get("portrait", "")), side, rules)
		)
		port.name = "LeaderPortrait_%d" % i
		port.position = Vector2(px - GlassPieces.number("stage.leaderboard.port_left"), y)
		_front.add_child(port)
		var place: GlassText = GlassText.from_rule("stage", ".lb .pl", str(i + 1))
		if out:
			place.colour = GlassParts.OUT_PLACE
		place.refresh()
		place.position = Vector2(
			px - GlassPieces.number("stage.leaderboard.place_left"),
			y + GlassPieces.number("stage.leaderboard.place_down")
		)
		_front.add_child(place)
		if out:
			# STAND-IN (polish.html .lb .out): no Health for a player who is out
			continue
		var hp: GlassBox = GlassParts.health_badge(_i(player.get("health", 0)), [".hp", ".lb .hp"])
		hp.name = "LeaderHealth_%d" % i
		hp.position = Vector2(
			px + GlassPieces.number("stage.leaderboard.hp_right"),
			y + GlassPieces.number("stage.leaderboard.hp_down")
		)
		_front.add_child(hp)


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


# ---- input: hover and the leaderboard ----


## The hover follows what is under the pointer every frame (GlassTips.follow).
func _process(_delta: float) -> void:
	if _tips != null and _compost == null:
		_tips.follow(_pointer)


func _compost_entries() -> Array:
	for value: Variant in state.get("counters", []):
		var chip: Dictionary = value if value is Dictionary else {}
		if str(chip.get("id", "")) == "thorn_compost":
			return chip.get("entries", [])
	return []


func _close_compost() -> void:
	if _compost == null:
		return
	_compost_layer.get_parent().remove_child(_compost_layer)
	_compost_layer.queue_free()
	_compost_layer = null
	_compost = null
	_pointer = Vector2(-1, -1)


func _open_compost() -> void:
	if _compost != null:
		return
	_tips.hide()
	_compost = CompostPanel.new()
	_compost.name = "CompostPanel"
	_compost.entries = _compost_entries().duplicate(true)
	_compost.state = {"display": _display_table()}
	_compost.close_requested.connect(_close_compost)
	# As with the card browser, a canvas above raised cards and the settings cog. Appended
	# to the viewport so its outside-click handler also runs before the cog's _input.
	_compost_layer = CanvasLayer.new()
	_compost_layer.layer = 10
	get_viewport().add_child(_compost_layer)
	_compost_layer.add_child(_compost)


## Whether the hover detail may show now (not while a card is carried).
func _hover_allowed() -> bool:
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _compost != null and not is_visible_in_tree():
		_close_compost()
	if (
		what
		in [NOTIFICATION_MOUSE_EXIT, NOTIFICATION_WM_MOUSE_EXIT, NOTIFICATION_APPLICATION_FOCUS_OUT]
	):
		_pointer = Vector2(-1, -1)
		if _tips != null and _tips.tip != null and pinned_hover == "":
			_tips.hide()


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
		_tips.hover(_pointer)


## The topmost target under a stage point; cards_only for the hover detail.
func _target_at(at: Vector2, cards_only: bool) -> Dictionary:
	for i: int in range(_targets.size() - 1, -1, -1):
		var target: Dictionary = _targets[i]
		if cards_only and not target.has("card"):
			continue
		var node: Control = target.get("node")
		if node == null or not is_instance_valid(node) or not node.is_visible_in_tree():
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
