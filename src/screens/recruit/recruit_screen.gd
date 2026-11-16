class_name RecruitScreen
extends Control
## The recruit screen in lead and stained glass, rebuilt from the chosen mock-up (recruit.html at
## its defaults: 250 px cards, spells above the shop). It draws one plain view-state Dictionary
## (show_state) and reports what the player asks for as signals; it holds no rules. Every place,
## size and colour comes from the mock-up through GlassPieces: recruit.html's geom() for the
## geometry, stage.css's rules for the look, stage.js's numbers for the rest.
##
## The view state (tests/screens/fixtures/recruit_mockup.json is a full example):
##   turn, gold, tier, refresh_cost, frozen, health, hand_limit: numbers and a flag
##   upgrade_cost: the tier button's price; absent or null at the top tier (no button then)
##   hero: {name, portrait}; counters: [{icon or label, value}] beside the hero (icon names a
##   tribe emblem, assets/glass/ui/tr-<icon>.png); none listed, none drawn
##   next_opponent: {name, portrait, health}; message: a refusal or notice to show, or ""
##   shop_units: [unit or null] and shop_spells: [spell or null]: a bought card leaves a hole
##   hand: [unit]; board: 7 entries, unit or null, slots 0-6 (F1-F4 are 0-3, B1-B3 are 4-6, as
##   the rules core numbers them); slots: 7 {buff, buff_name} or {}
##   players: [{name, portrait, health, tier, you?, next?}] for the leaderboard
##   unit: {id, uid, name, tier, art, attack, health, text, golden, keywords: [String],
##   counters: [{label, value}], price, sell_value}; spell: {id, name, art, cost, text}

## What the player asks for, in the rules core's own action format (src/core/README.md): buy,
## sell, play, move, refresh, freeze, upgrade, pick, ability, end_turn. Each is the matching entry
## of the state's legal_actions, or, when the state lists none like it, the action as built, so
## the core can say why it is refused. Buying is by drag (a click only shows a card's detail).
signal action_requested(action: Dictionary)

const BOARD_SLOTS: int = 7
const FRONT_SLOTS: int = 4
## How far the pointer moves, in px, before a press becomes a drag.
const DRAG_START: float = 8.0
const READY_LINE: String = "recruit_screen: ready"
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
var _tip: Control
## Everything the pointer can act on, topmost last: {kind, index, poly, node, card, id}.
var _targets: Array[Dictionary] = []
var _press: Dictionary = {}
var _press_at: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _hot: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_g = _geom()
	if state.is_empty() and fixture != "":
		state = RecruitScreen.load_state(fixture)
	show_state(state)
	get_viewport().size_changed.connect(_fit)
	print(_ready_line())


static func load_state(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "%s is not a JSON object" % path)
	var out: Dictionary = parsed
	return out


## Draws a new view state, replacing everything shown.
func show_state(new_state: Dictionary) -> void:
	state = new_state
	if _g.is_empty():
		_g = _geom()
	_rebuild()


## The page's geom() this screen is laid out by; a screen built on this one gives its own.
func _geom() -> Dictionary:
	return GlassPieces.recruit_geom()


func _ready_line() -> String:
	return READY_LINE


## Where this page puts the leaderboard: its layout.json prefix for top and step.
func _leaderboard_key() -> String:
	return "stage.recruit.leaderboard"


func _rebuild() -> void:
	_new_stage()
	var window: StoneWindow = StoneWindow.new()
	window.name = "Window"
	_stage.add_child(window)
	window.build(_g)
	_build_shop()
	_build_buttons()
	_build_board()
	_build_hand()
	_build_hero()
	_build_end_turn()
	if show_leaderboard:
		_build_leaderboard()
	var vig: GlassBox = GlassBox.new()
	vig.name = "Vignette"
	vig.box_size = _stage.size
	vig.use_css("stage", "#vig").refresh()
	_stage.add_child(vig)
	_build_message()
	_tip = Control.new()
	_tip.name = "Tip"
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.z_index = _i(GlassPieces.rule("stage", "#tip", "z-index"))
	_tip.visible = false
	_stage.add_child(_tip)
	if pinned_hover != "":
		_pin_hover(pinned_hover)


## Replaces the stage with an empty one, dropping any press or drag on the old one.
func _new_stage() -> void:
	if _frame != null:
		remove_child(_frame)
		_frame.queue_free()
	_targets.clear()
	_hot = null
	_press = {}
	_dragging = false
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
	_fit()


## The stage stays 1920 x 1080; a window of another shape centres it on a dark surround.
func _fit() -> void:
	if _frame != null:
		_frame.position = ((size - _frame.size) / 2.0).floor()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SURROUND)


# ---- geometry (recruit.html render()) ----


func _h() -> float:
	return _f(_g["H"])


func _w() -> float:
	return _f(_g["W"])


func _gap() -> float:
	return _f(_g["g"])


## Where shop unit i goes: the row of geom()'s width, centred, from shopL.
func shop_xy(i: int) -> Vector2:
	return Vector2(_f(_g["shopL"]) + i * (_w() + _gap()), _f(_g["shopTop"]))


## Where shop spell k goes: over the gap beside the middle unit, its lower point in the notch.
func spell_xy(k: int) -> Vector2:
	var gx: float = (
		_f(_g["shopL"])
		+ (k + GlassPieces.number("stage.recruit.spell.first_gap")) * (_w() + _gap())
		- _gap() / 2.0
	)
	var bottom: float = (
		_f(_g["shopTop"])
		+ GlassPieces.number("stage.recruit.spell.drop_per_h") * _h()
		- GlassPieces.number("stage.recruit.spell.lift")
	)
	return Vector2(gx - _f(_g["SW"]) / 2.0, bottom - _f(_g["SH"]))


## Board slot i (0-3 the front row F1-F4, 4-6 the back row B1-B3, offset half a slot).
func slot_xy(i: int) -> Vector2:
	var fw: float = FRONT_SLOTS * _w() + (FRONT_SLOTS - 1) * _gap()
	var fx: float = 960.0 - fw / 2.0
	var by: float = _f(_g["boardTop"])
	if i < FRONT_SLOTS:
		return Vector2(fx + i * (_w() + _gap()), by)
	var back_y: float = (
		by
		+ GlassPieces.number("stage.recruit.board.back_drop_per_h") * _h()
		+ GlassPieces.number("stage.recruit.board.back_gap")
	)
	return Vector2(fx + (_w() + _gap()) / 2.0 + (i - FRONT_SLOTS) * (_w() + _gap()), back_y)


## Hand card i of n: its unturned top left, and its turn in degrees about its bottom middle.
func hand_place(i: int, n: int) -> Vector3:
	var step: float = _w() * GlassPieces.number("stage.recruit.hand.step_per_w")
	var k: float = i - (n - 1) / 2.0
	var x: float = 960.0 - _w() / 2.0 + k * step
	var y: float = _f(_g["handTop"]) + k * k * GlassPieces.number("stage.recruit.hand.drop_per_k2")
	return Vector3(x, y, k * GlassPieces.number("stage.recruit.hand.turn_deg_per_k"))


# ---- building ----


func _build_shop() -> void:
	var units: Array = state.get("shop_units", [])
	var frozen: bool = _b(state.get("frozen", false))
	for i: int in units.size():
		if not units[i] is Dictionary:
			continue
		var unit: Dictionary = units[i]
		var card: GlassCard = _unit_card(unit, _h())
		card.position = shop_xy(i)
		_add_card(card, "shop", i, unit)
		if frozen:
			GlassParts.add_frost(
				card, GlassBox.hexagon(Rect2(Vector2.ZERO, card.size), _slot_shoulder())
			)
	var spells: Array = state.get("shop_spells", [])
	for k: int in spells.size():
		if not spells[k] is Dictionary:
			continue
		var spell: Dictionary = spells[k]
		var node: GlassSpell = _spell_card(spell, Vector2(_f(_g["SW"]), _f(_g["SH"])))
		node.position = spell_xy(k)
		_add_card(node, "spell", k, spell)
		if frozen:
			GlassParts.add_frost(
				node, GlassBox.hexagon(Rect2(Vector2.ZERO, node.size), _f(_g["SS"]))
			)


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
	var words: PackedStringArray = PackedStringArray()
	for keyword: Variant in unit.get("keywords", []):
		words.append(str(keyword).replace("_", " ").capitalize())
	for counter: Variant in unit.get("counters", []):
		if counter is Dictionary:
			var c: Dictionary = counter
			words.append(("%s %s" % [c.get("label", ""), c.get("value", "")]).strip_edges())
	var y: float = height * 0.2
	var whole: Vector2 = GlassCard.card_size(height)
	for text: String in words:
		# STAND-IN: keywords and counters as cream pills down the art; no design exists yet
		var pill: GlassBox = GlassParts.make_pill(text)
		pill.name = "Pill"
		pill.scale = Vector2.ONE * height / _h()
		pill.position = Vector2((whole.x - pill.box_size.x * pill.scale.x) / 2.0, y)
		card.add_child(pill)
		y += (pill.box_size.y + 4.0) * pill.scale.y
	return card


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


## Adds a card to the stage and makes it a pointer target with its hexagon outline.
func _add_card(node: Control, kind: String, index: int, data: Dictionary) -> void:
	_stage.add_child(node)
	var outline: PackedVector2Array = GlassBox.hexagon(
		Rect2(Vector2.ZERO, node.size), _f(_g["SS"]) if kind == "spell" else _slot_shoulder()
	)
	(
		_targets
		. append(
			{
				"kind": kind,
				"index": index,
				"node": node,
				"poly": outline,
				"card": data,
			}
		)
	)


func _slot_shoulder() -> float:
	var clip: Array = GlassPieces.rule("stage", ".slot", "clip-path")
	var shoulder: Array = clip[1]
	return _f(shoulder[1]) / 100.0


func _build_buttons() -> void:
	var bw: float = GlassPieces.number("stage.recruit.button.w")
	var gap: float = GlassPieces.number("stage.recruit.button.gap")
	var shop_l: float = _f(_g["shopL"])
	var x_left: float = shop_l - gap - bw
	var x_right: float = shop_l + _f(_g["shopW"]) + gap
	var y1: float = _f(_g["shopTop"]) + _h() / 2.0 - GlassPieces.number("stage.recruit.button.up")
	var y2: float = y1 + GlassPieces.number("stage.recruit.button.step")
	var tier: int = _i(state.get("tier", 1))
	var gold: int = _i(state.get("gold", 0))
	_add_button("gold", Vector2(x_left, y1), "gold", str(gold), "")
	# no upgrade cost in the state: the top tier, no button
	if state.get("upgrade_cost") != null:
		var upgrade: int = _i(state["upgrade_cost"])
		var tier_words: String = "%d→%d" % [tier, tier + 1]
		_add_button("tier", Vector2(x_left, y2), "", tier_words, str(upgrade), upgrade > gold)
	var refresh: int = _i(state.get("refresh_cost", 0))
	_add_button("refresh", Vector2(x_right, y1), "", "", str(refresh), refresh > gold)
	_add_button("freeze", Vector2(x_right, y2), "freeze", "", "")


## A .btn: its pane, then the icon, the words and the pip in a centred row (flex, gap 8).
func _add_button(
	icon: String, at: Vector2, variant: String, words: String, pip: String, short: bool = false
) -> void:
	var box: GlassBox = GlassBox.new()
	box.name = "Button_" + icon
	box.box_size = Vector2(
		GlassPieces.number("stage.recruit.button.w"),
		GlassPieces.rule_number("stage", ".btn", "height")
	)
	box.use_css("stage", ".btn")
	if variant == "gold":
		box.use_css("stage", ".btn.gold")
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".btn", "border-radius"), box.box_size)
	box.position = at
	box.refresh()
	_stage.add_child(box)
	if variant == "freeze" and _b(state.get("frozen", false)):
		GlassParts.add_frost(box, GlassParts.round_poly(box.box_size))
	if short:
		# STAND-IN can't-afford look: the button dimmed (no mock-up)
		box.name += "_short"
		box.modulate = Color(0.55, 0.55, 0.55)
	var font: Dictionary = GlassPieces.rule_font("stage", ".btn")
	var items: Array[Control] = []
	var stroke_rule: String = ".btn.%s svg" % variant if variant != "" else ".btn svg"
	var icon_colour: Color = GlassPieces.rule_colour("stage", stroke_rule, "stroke")
	var icon_px: int = _i(GlassPieces.rule_number("stage", ".btn svg", "width"))
	var icon_node: TextureRect = TextureRect.new()
	icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_node.texture = GlassPieces.icon(
		icon, icon_colour, icon_px, GlassPieces.rule_number("stage", ".btn svg", "stroke-width")
	)
	icon_node.size = Vector2(icon_px, icon_px)
	items.append(icon_node)
	if words != "":
		var label: GlassText
		if variant == "gold":
			label = GlassText.from_rule("stage", ".btn.gold b", words)
			label.use_font(font)
			label.weight = _i(GlassPieces.rule("stage", ".btn.gold b", "font-weight"))
		else:
			label = GlassText.new()
			label.words = words
			label.use_font(font)
			label.colour = GlassPieces.rule_colour("stage", ".btn", "color")
		items.append(label.refresh())
	if pip != "":
		items.append(GlassParts.make_pip(pip, _f(font["size"])))
	var content: Vector2 = box.padding_rect().size
	var gap: float = GlassPieces.rule_number("stage", ".btn", "gap")
	var total: float = -gap
	for item: Control in items:
		total += item.size.x + gap
	var x: float = box.border_width + (content.x - total) / 2.0
	for item: Control in items:
		item.position = Vector2(x, box.border_width + (content.y - item.size.y) / 2.0).round()
		box.add_child(item)
		x += item.size.x + gap
	_targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": icon,
			"node": box,
			"poly": GlassParts.rect_poly(box.box_size)
		}
	)


func _build_board() -> void:
	var board: Array = state.get("board", [])
	var slots: Array = state.get("slots", [])
	for i: int in BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var info: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		if unit is Dictionary:
			var held: Dictionary = unit
			var card: GlassCard = _unit_card(held, _h())
			card.position = slot_xy(i)
			_add_card(card, "board", i, held)
			if info.has("buff"):
				_slot_buff_pill(card, str(info["buff"]))
			continue
		var slot: GlassBox = _slot(info)
		slot.name = "Slot_%d" % i
		slot.position = slot_xy(i)
		_stage.add_child(slot)
		(
			_targets
			. append(
				{
					"kind": "slot",
					"index": i,
					"node": slot,
					"poly": GlassBox.hexagon(Rect2(Vector2.ZERO, slot.box_size), _slot_shoulder()),
				}
			)
		)


## An empty board slot (stage.css .slot and .slot::after): a dim pane in a lead outline, or the
## Ring slot (.slot.ring::after) with its bonus written on it when the slot carries one.
func _slot(info: Dictionary) -> GlassBox:
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


func _build_hand() -> void:
	var hand: Array = state.get("hand", [])
	var n: int = hand.size()
	for i: int in n:
		var unit: Dictionary = hand[i]
		var card: GlassCard = _unit_card(unit, _h())
		var place: Vector3 = hand_place(i, n)
		card.position = Vector2(place.x, place.y)
		card.pivot_offset = Vector2(_w() / 2.0, _h())
		card.rotation_degrees = snappedf(place.z, 0.01)
		_add_card(card, "hand", i, unit)
	var step: float = _w() * GlassPieces.number("stage.recruit.hand.step_per_w")
	var hw: float = step * (n - 1) + _w()
	var label: GlassText = GlassText.from_rule(
		"stage", ".lbl", "Hand %d/%d" % [n, _i(state.get("hand_limit", 7))]
	)
	label.name = "HandCount"
	label.font_px = GlassPieces.number("stage.recruit.hand_label.size")
	label.colour = GlassPieces.colour("stage.recruit.hand_label.colour")
	label.refresh()
	label.position = Vector2(
		960.0 - hw / 2.0 - GlassPieces.number("stage.recruit.hand_label.left"),
		_f(_g["handTop"]) + GlassPieces.number("stage.recruit.hand_label.down")
	)
	_stage.add_child(label)


## stage.js leftLight(): the turn at the top; on the sill the hero's name, portrait, Health and
## two chips (tribe emblems with a count).
func _build_hero() -> void:
	var height: float = _stage.size.y
	var turn: GlassText = GlassText.from_rule("stage", ".lbl", "Turn %d" % _i(state.get("turn", 1)))
	turn.name = "Turn"
	turn.refresh()
	turn.position = Vector2(
		GlassPieces.number("stage.hero.turn_x"), GlassPieces.number("stage.hero.turn_y")
	)
	_stage.add_child(turn)
	var hero: Dictionary = state.get("hero", {})
	var hero_name: GlassText = GlassText.from_rule("stage", ".lbl", str(hero.get("name", "")))
	hero_name.font_px = GlassPieces.number("stage.hero.name_size")
	hero_name.refresh()
	hero_name.position = Vector2(
		GlassPieces.number("stage.hero.name_x"), height - GlassPieces.number("stage.hero.name_up")
	)
	_stage.add_child(hero_name)
	var port: GlassBox = GlassParts.make_portrait(
		str(hero.get("portrait", "")), GlassPieces.number("stage.hero.port"), [".hero"]
	)
	port.name = "Hero"
	port.position = Vector2(
		GlassPieces.number("stage.hero.port_x"), height - GlassPieces.number("stage.hero.port_up")
	)
	_stage.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(_i(state.get("health", 0)), [".hp"])
	hp.position = Vector2(
		GlassPieces.number("stage.hero.hp_x"), height - GlassPieces.number("stage.hero.hp_up")
	)
	_stage.add_child(hp)
	var outline: PackedVector2Array = PackedVector2Array()
	for i: int in 24:
		outline.append(
			port.box_size / 2.0 + Vector2.from_angle(TAU * i / 24.0) * port.box_size.x / 2.0
		)
	_targets.append({"kind": "button", "index": 0, "id": "hero", "node": port, "poly": outline})
	# the player's counters (a tribe's count, a Compost number...) on the mock-up's two chips
	var counters: Array = state.get("counters", [])
	var step: float = GlassPieces.number("stage.hero.chip.step")
	for i: int in counters.size():
		var counter: Dictionary = counters[i]
		var emblem: GlassBox = GlassBox.new()
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
		_stage.add_child(emblem)
		if not counter.has("icon"):
			var label: GlassText = GlassText.from_rule(
				"stage", ".chipv", str(counter.get("label", ""))
			)
			label.colour = GlassPieces.rule_colour("stage", ".lbl", "color")
			label.refresh()
			label.position = (emblem.box_size - label.size) / 2.0
			emblem.add_child(label)
		var count: GlassBox = GlassParts.make_pill(str(counter.get("value", "")))
		count.position = Vector2(
			GlassPieces.number("stage.hero.chip.count_x"),
			height - GlassPieces.number("stage.hero.chip.count_up") + i * step
		)
		_stage.add_child(count)


## The right light's sill: the next opponent's portrait, which ends the turn, under its words.
func _build_end_turn() -> void:
	var height: float = _stage.size.y
	var x: float = (
		1904.0
		- GlassPieces.number("stage.recruit.end.margin")
		- GlassPieces.number("stage.recruit.end.port_room")
		- GlassPieces.number("stage.recruit.end.inset")
	)
	var words: GlassText = GlassText.from_rule("stage", ".lbl", "End turn")
	words.name = "EndTurnWords"
	words.font_px = GlassPieces.number("stage.recruit.end.label_size")
	words.colour = GlassPieces.rule_colour("stage", ".endlbl", "color")
	words.refresh()
	words.position = Vector2(
		x - GlassPieces.number("stage.recruit.end.label_left"),
		height - GlassPieces.number("stage.recruit.end.label_up")
	)
	_stage.add_child(words)
	var next: Dictionary = state.get("next_opponent", {})
	var side: float = GlassPieces.number("stage.recruit.end.port")
	var port: GlassBox = GlassParts.make_portrait(str(next.get("portrait", "")), side, [".endturn"])
	port.name = "EndTurn"
	port.position = Vector2(x, height - GlassPieces.number("stage.recruit.end.port_up"))
	_stage.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(_i(next.get("health", 0)), [".hp"])
	hp.position = Vector2(
		x - GlassPieces.number("stage.recruit.end.hp_left"),
		height - GlassPieces.number("stage.recruit.end.hp_up")
	)
	_stage.add_child(hp)
	var outline: PackedVector2Array = PackedVector2Array()
	for i: int in 24:
		outline.append(Vector2(side, side) / 2.0 + Vector2.from_angle(TAU * i / 24.0) * side / 2.0)
	_targets.append({"kind": "button", "index": 0, "id": "end_turn", "node": port, "poly": outline})


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
	_stage.add_child(pane)
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
		_stage.add_child(port)
		var hp: GlassBox = GlassParts.health_badge(_i(player.get("health", 0)), [".hp", ".lb .hp"])
		hp.position = Vector2(
			px + GlassPieces.number("stage.leaderboard.hp_right"),
			y + GlassPieces.number("stage.leaderboard.hp_down")
		)
		_stage.add_child(hp)
		var place: GlassText = GlassText.from_rule("stage", ".lb .pl", str(i + 1))
		place.refresh()
		place.position = Vector2(
			px - GlassPieces.number("stage.leaderboard.place_left"),
			y + GlassPieces.number("stage.leaderboard.place_down")
		)
		_stage.add_child(place)


## STAND-IN message area (no mock-up): the reason the core gave for a refused action, or a
## notice, centred on the transom.
func _build_message() -> void:
	var words: String = str(state.get("message", ""))
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
	_stage.add_child(label)


# ---- hover detail (stage.js hoverDetail) ----


func _pin_hover(card_id: String) -> void:
	for target: Dictionary in _targets:
		var card: Dictionary = target.get("card", {})
		if str(card.get("id", "")) == card_id:
			var node: Control = target["node"]
			var at: Vector2 = (
				node.position
				+ Vector2(
					_w() * GlassPieces.number("stage.tip.pin_x_per_w"),
					_h() * GlassPieces.number("stage.tip.pin_y_per_h")
				)
			)
			_show_tip(target, at)
			return


## The card's detail beside the pointer: the card at 1.6 x, and a pane with its name, its kind and
## its rules text. It flips to the left near the right edge and stays on the screen.
func _show_tip(target: Dictionary, at: Vector2) -> void:
	var card: Dictionary = target["card"]
	var big: float = GlassPieces.number("stage.tip.big_per_h") * _h()
	var big_w: float = big * GlassPieces.card_units().x / GlassPieces.card_units().y
	if _hot != target["node"]:
		for child: Node in _tip.get_children():
			_tip.remove_child(child)
			child.queue_free()
		var shown: Control
		if target["kind"] == "spell":
			var spell_h: float = big * _f(_g["SH"]) / _h()
			shown = _spell_card(card, Vector2(spell_h * _f(_g["SW"]) / _f(_g["SH"]), spell_h))
		else:
			shown = _unit_card(card, big)
		shown.name = "Card"
		_tip.add_child(shown)
		var text: GlassBox = GlassParts.tip_text(card, str(target["kind"]) == "spell")
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


func _hide_tip() -> void:
	if _tip != null:
		_tip.visible = false
	_set_hot(null)


## .card.hot: the hovered card brightened, glowing, above the vignette.
func _set_hot(node: Control) -> void:
	if _hot == node:
		return
	if _hot is GlassCard:
		(_hot as GlassCard).set_hot(false)
	if _hot != null:
		_hot.z_index = 0
	_hot = node
	if _hot is GlassCard:
		(_hot as GlassCard).set_hot(true)
	if _hot != null and (_hot is GlassCard or _hot is GlassSpell):
		_hot.z_index = _i(GlassPieces.rule("stage", ".card.hot", "z-index"))


# ---- input: signals only; the controller owns the rules ----


## Shows or hides the leaderboard (Tab, or a click on your portrait).
func toggle_leaderboard() -> void:
	show_leaderboard = not show_leaderboard
	_rebuild()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_TAB:
		toggle_leaderboard()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		var at: Vector2 = button.position - _frame.position
		if button.pressed:
			_press = _target_at(at, false)
			_press_at = at
			_dragging = false
		else:
			_release(at)
		accept_event()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null:
		return
	var here: Vector2 = motion.position - _frame.position
	if not _press.is_empty() and not _dragging and here.distance_to(_press_at) > DRAG_START:
		_start_drag()
	if _dragging:
		var node: Control = _press["node"]
		node.position = here - _drag_offset
		return
	var over: Dictionary = _target_at(here, true)
	if over.is_empty():
		if pinned_hover == "":
			_hide_tip()
	else:
		_show_tip(over, here)


## The topmost target under a point; cards_only for the hover detail.
func _target_at(at: Vector2, cards_only: bool) -> Dictionary:
	for i: int in range(_targets.size() - 1, -1, -1):
		var target: Dictionary = _targets[i]
		if cards_only and not target.has("card"):
			continue
		var node: Control = target["node"]
		var local: Vector2 = node.get_transform().affine_inverse() * at
		var poly: PackedVector2Array = target["poly"]
		if Geometry2D.is_point_in_polygon(local, poly):
			return target
	return {}


func _start_drag() -> void:
	if not _press.has("card"):
		return
	_dragging = true
	_hide_tip()
	var node: Control = _press["node"]
	node.rotation = 0.0
	node.z_index = 10
	_drag_offset = _press_at - node.position


func _release(at: Vector2) -> void:
	var pressed: Dictionary = _press
	var was_drag: bool = _dragging
	_press = {}
	_dragging = false
	if pressed.is_empty():
		return
	if not was_drag:
		_click(pressed, at)
		if pressed.has("card"):
			_show_tip(pressed, at)
		return
	var kind: String = pressed["kind"]
	var index: int = pressed["index"]
	var slot: int = _slot_at(at)
	if kind == "shop" or kind == "spell":
		if at.y > _f(_g["shopBot"]):
			_request({"type": "buy", "spell": kind == "spell", "index": index})
	elif kind == "hand":
		if slot >= 0:
			_request({"type": "play", "hand": index, "slot": slot}, {"target": -1})
	elif kind == "board":
		if slot >= 0 and slot != index:
			_request({"type": "move", "from": index, "to": slot})
		elif at.y < _f(_g["T0"]):
			_request({"type": "sell", "slot": index})
	# put everything back where the state says; a controller that changed it has redrawn already
	if is_inside_tree():
		_rebuild()


func _click(pressed: Dictionary, at: Vector2) -> void:
	if _target_at(at, false) != pressed:
		return
	match str(pressed["kind"]):
		"button":
			match str(pressed["id"]):
				"hero":
					toggle_leaderboard()
				"tier":
					_request({"type": "upgrade"})
				"refresh", "freeze", "end_turn":
					_request({"type": str(pressed["id"])})


## Sends the legal action like want; when the state lists none, want with the extra fields.
func _request(want: Dictionary, extra: Dictionary = {}) -> void:
	var found: Array[Dictionary] = RecruitActions.matching(state, want)
	if not found.is_empty():
		action_requested.emit(found[0])
		return
	var built: Dictionary = want.duplicate()
	built.merge(extra)
	action_requested.emit(built)


## The board slot (0-6) whose outline holds a point, or -1.
func _slot_at(at: Vector2) -> int:
	var outline: PackedVector2Array = GlassBox.hexagon(
		Rect2(Vector2.ZERO, Vector2(_w(), _h())), _slot_shoulder()
	)
	for i: int in BOARD_SLOTS:
		if Geometry2D.is_point_in_polygon(at - slot_xy(i), outline):
			return i
	return -1


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _b(v: Variant) -> bool:
	return GlassPieces.as_bool(v)
