class_name RecruitScreen
extends GlassScreen
## The recruit screen in lead and stained glass, rebuilt from the chosen mock-up (recruit.html at
## its defaults: 250 px cards, spells above the shop). It draws one plain view-state Dictionary
## (show_state) and reports what the player asks for as action_requested; it holds no rules.
## Every place, size and colour comes from the mock-up through GlassPieces: recruit.html's geom()
## for the geometry, stage.css's rules for the look, stage.js's numbers for the rest. The view
## state is described in docs/ideation-track-2/SCREEN-CONTRACT.md;
## tests/screens/fixtures/recruit_mockup.json is a full example.

## What the player asks for, in the rules core's own action format (src/core/README.md): buy,
## sell, play, move, refresh, freeze, upgrade, pick, ability, end_turn. Each is the matching entry
## of the state's legal_actions, or, when the state lists none like it, the action as built, so
## the core can say why it is refused. Buying is by drag (a click only shows a card's detail).
## Answer it with show_state from the handler: the dropped card then moves from where it was let go.
signal action_requested(action: Dictionary)

## How far the pointer moves, in px, before a press becomes a drag.
const DRAG_START: float = 8.0
const READY_LINE: String = "recruit_screen: ready"

var _press: Dictionary = {}
var _press_at: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
## How many states have been shown, so a drop can tell whether its handler drew a new one.
var _shown: int = 0


func _ready_line() -> String:
	return READY_LINE


func _on_new_state() -> void:
	_shown += 1
	_press = {}
	_dragging = false


# ---- geometry (recruit.html render()) ----


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


func _build() -> void:
	_add_window()
	_want_shop()
	_build_buttons()
	_want_board()
	_want_hand()
	_place_cards()
	_build_hand_count()
	_build_hero()
	_build_end_turn()
	if show_leaderboard:
		_build_leaderboard()
	_add_vignette()
	_build_message(str(state.get("message", "")))


func _want_shop() -> void:
	var frozen: bool = _b(state.get("frozen", false))
	var units: Array = state.get("shop_units", [])
	for i: int in units.size():
		if units[i] is Dictionary:
			var unit: Dictionary = units[i]
			_want_card(
				card_key("shop", i, unit), "shop", i, unit, shop_xy(i), 0.0, {"frost": frozen}
			)
	var spells: Array = state.get("shop_spells", [])
	for k: int in spells.size():
		if spells[k] is Dictionary:
			var spell: Dictionary = spells[k]
			var key: String = card_key("spell", k, spell)
			_want_card(key, "spell", k, spell, spell_xy(k), 0.0, {"frost": frozen})


func _make_card(kind: String, data: Dictionary, extra: Dictionary) -> Control:
	var node: Control = super(kind, data, extra)
	if _b(extra.get("frost", false)):
		var shoulder: float = _f(_g["SS"]) if node is GlassSpell else _slot_shoulder()
		GlassParts.add_frost(node, GlassBox.hexagon(Rect2(Vector2.ZERO, node.size), shoulder))
	if extra.has("buff") and node is GlassCard:
		_slot_buff_pill(node as GlassCard, str(extra["buff"]))
	return node


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
	_back.add_child(box)
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


func _want_board() -> void:
	var board: Array = state.get("board", [])
	var slots: Array = state.get("slots", [])
	for i: int in BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var info: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		if unit is Dictionary:
			var held: Dictionary = unit
			var extra: Dictionary = {}
			if info.has("buff"):
				extra["buff"] = str(info["buff"])
			_want_card(card_key("board", i, held), "board", i, held, slot_xy(i), 0.0, extra)
			continue
		var slot: GlassBox = _slot(info)
		slot.name = "Slot_%d" % i
		slot.position = slot_xy(i)
		_back.add_child(slot)
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


func _want_hand() -> void:
	var hand: Array = state.get("hand", [])
	var n: int = hand.size()
	for i: int in n:
		var card: Dictionary = hand[i]
		var place: Vector3 = hand_place(i, n)
		var at: Vector2 = Vector2(place.x, place.y)
		_want_card(card_key("hand", i, card), "hand", i, card, at, snappedf(place.z, 0.01))


func _place_cards() -> void:
	super()
	for target: Dictionary in _targets:
		if target["kind"] == "hand":
			# hand cards turn about their bottom middle
			var node: Control = target["node"]
			node.pivot_offset = Vector2(node.size.x / 2.0, node.size.y)


func _build_hand_count() -> void:
	var hand: Array = state.get("hand", [])
	var n: int = hand.size()
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
	_front.add_child(label)


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
	_front.add_child(words)
	var next: Dictionary = state.get("next_opponent", {})
	var side: float = GlassPieces.number("stage.recruit.end.port")
	var port: GlassBox = GlassParts.make_portrait(str(next.get("portrait", "")), side, [".endturn"])
	port.name = "EndTurn"
	port.position = Vector2(x, height - GlassPieces.number("stage.recruit.end.port_up"))
	_front.add_child(port)
	var hp: GlassBox = GlassParts.health_badge(_i(next.get("health", 0)), [".hp"])
	hp.position = Vector2(
		x - GlassPieces.number("stage.recruit.end.hp_left"),
		height - GlassPieces.number("stage.recruit.end.hp_up")
	)
	_front.add_child(hp)
	_targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": "end_turn",
			"node": port,
			"poly": _circle(port.box_size)
		}
	)


# ---- input: action_requested only; the controller owns the rules ----


func _gui_input(event: InputEvent) -> void:
	if _frame == null:
		return
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
	_pointer = here
	if not _press.is_empty() and not _dragging and here.distance_to(_press_at) > DRAG_START:
		_start_drag()
	if _dragging:
		var node: Control = _press["node"]
		node.position = here - _drag_offset
		return
	_hover(here)


func _start_drag() -> void:
	if not _press.has("card"):
		return
	_dragging = true
	_hide_tip()
	var node: Control = _press["node"]
	_keeper.stop(node)
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
		if pressed.has("card") and is_instance_valid(pressed["node"]):
			_show_tip(pressed, at)
		return
	var shown: int = _shown
	var dropped: Control = pressed["node"]
	dropped.z_index = 0
	# no hover detail for the dropped card on its way to its new place
	_pointer = Vector2(-1, -1)
	_drop(pressed, at)
	# nothing new drawn: the card goes back where the state has it
	if shown == _shown and is_inside_tree():
		_layout()


func _drop(pressed: Dictionary, at: Vector2) -> void:
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


func _click(pressed: Dictionary, at: Vector2) -> void:
	if _target_at(at, false) != pressed:
		return
	if str(pressed["kind"]) != "button":
		return
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
