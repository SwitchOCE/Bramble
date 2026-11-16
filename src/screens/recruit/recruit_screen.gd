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
## STAND-IN: how far a spell waiting for its target stands up out of the hand.
const AIM_LIFT: float = 70.0
## The words while a target is being chosen (STAND-IN wording, in the message area).
const AIM_PROMPT: String = "Choose a target"
## STAND-IN: where an ability button sits on its card, as a share of the card's height.
const ABILITY_DOWN: float = 0.62
## STAND-IN Discover picker, as recruit-play.html draws it: the veil, the cards 1.4 x the table's,
## their gap and middle line, the prompt's size and how far above the cards it stands.
const DISCOVER_VEIL: Color = Color(0.03, 0.02, 0.015, 0.62)
const DISCOVER_SCALE: float = 1.4
const DISCOVER_GAP: float = 40.0
const DISCOVER_MIDDLE: float = 540.0
const DISCOVER_PROMPT_PX: float = 40.0
const DISCOVER_PROMPT_UP: float = 76.0
const DISCOVER_Z: int = 8
## STAND-IN dimmed look (stand-ins.html .btn.short): a button or ability that can't be used now.
const SHORT_DIM: Color = Color(0.55, 0.55, 0.55)

## For comparing with recruit-play.html?aim=unit: the hand card whose target is being chosen when
## the screen opens (-1 for none).
@export var pinned_aim: int = -1

var _press: Dictionary = {}
var _press_at: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
## How many states have been shown, so a drop can tell whether its handler drew a new one.
var _shown: int = 0
## A target being chosen: {want, kind, targets, key (the card held), at (where it is held)}.
var _aim: Dictionary = {}


func _ready() -> void:
	super()
	var hand: Array = state.get("hand", [])
	if pinned_aim >= 0 and pinned_aim < hand.size():
		var card: Dictionary = hand[pinned_aim]
		var want: Dictionary = {"type": "play", "hand": pinned_aim}
		_aim_hand(pinned_aim, card, want, RecruitActions.targets(state, want))


func _ready_line() -> String:
	return READY_LINE


func _on_new_state() -> void:
	_shown += 1
	_press = {}
	_dragging = false
	_aim = {}


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
	_add_ability_targets()
	_unlight()
	if is_aiming():
		var lit: Array[int] = _aim["targets"]
		_light(str(_aim["kind"]), lit, _held_card())
	_build_hand_count()
	_build_hero()
	_build_end_turn()
	if show_leaderboard:
		_build_leaderboard()
	_add_vignette()
	_build_message(AIM_PROMPT if is_aiming() else str(state.get("message", "")))
	if _discovering():
		_build_discover()


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
		GlassParts.add_frost(
			node,
			GlassBox.hexagon(
				Rect2(
					Vector2.ZERO, _spell_size() if node is GlassSpell else GlassCard.card_size(_h())
				),
				shoulder
			)
		)
	if extra.has("buff") and node is GlassCard:
		_slot_buff_pill(node as GlassCard, str(extra["buff"]))
	var abilities: Array = extra.get("abilities", [])
	for k: int in abilities.size():
		var ability: Dictionary = abilities[k]
		var name_words: String = str(ability.get("name", ""))
		if name_words == "":
			name_words = _display_name(str(ability["mechanic"]))
		var button: GlassBox = GlassParts.ability_button(name_words)
		button.name = "Ability_" + str(ability["mechanic"])
		if not _b(ability["usable"]):
			# STAND-IN (stand-ins.html): dimmed like a button whose action is not legal
			button.modulate = SHORT_DIM
		button.position = Vector2(
			(_w() - button.box_size.x) / 2.0, _h() * ABILITY_DOWN - k * (button.box_size.y + 4.0)
		)
		node.add_child(button)
	return node


## The ability buttons a board unit shows: [{mechanic, target, name, usable}]. An ability in the
## contract's shape ({id, name, cost, uses_left, usable, target_kind}) always shows, dimmed when
## not usable or not in legal_actions; an older one ({mechanic, target}) shows only when legal.
func _usable_abilities(unit: Dictionary) -> Array:
	var out: Array = []
	for value: Variant in unit.get("abilities", []):
		if not value is Dictionary:
			continue
		var ability: Dictionary = value
		var mechanic: String = str(ability.get("id", ability.get("mechanic", "")))
		var want: Dictionary = {"type": "ability", "uid": unit.get("uid", -1), "mechanic": mechanic}
		var legal: bool = RecruitActions.allows(state, want)
		if not legal and not ability.has("usable"):
			continue
		(
			out
			. append(
				{
					"mechanic": mechanic,
					"target": target_kind(ability),
					"name": str(ability.get("name", "")),
					"usable": legal and _b(ability.get("usable", true)),
				}
			)
		)
	return out


## What a hand card or ability aims at: "unit", "enemy", "slot", "shop", or "" for nothing
## (the contract's target_kind, or the older target).
static func target_kind(card: Dictionary) -> String:
	var kind: String = str(card.get("target_kind", card.get("target", "")))
	return "" if kind == "none" else kind


## Each ability button on the board is a pointer target over its card.
func _add_ability_targets() -> void:
	for target: Dictionary in targets_of("board"):
		var extra: Dictionary = target["extra"]
		var card: Dictionary = target["card"]
		var node: Control = target["node"]
		for value: Variant in extra.get("abilities", []):
			var ability: Dictionary = value
			if not _b(ability["usable"]):
				continue
			var button: GlassBox = node.get_node("Ability_" + str(ability["mechanic"]))
			(
				_targets
				. append(
					{
						"kind": "ability",
						"index": target["index"],
						"id": str(ability["mechanic"]),
						"uid": _i(card.get("uid", -1)),
						"target": str(ability["target"]),
						"node": button,
						"poly": GlassParts.rect_poly(button.box_size),
					}
				)
			)


## The card held while its target is chosen, if any.
func _held_card() -> Control:
	for target: Dictionary in targets_of("hand"):
		var card: Dictionary = target["card"]
		if card_key("hand", _i(target["index"]), card) == _aim["key"]:
			return target["node"]
	return null


## The name the display table gives an id (a keyword, counter or ability), or the id itself.
func _display_name(id: String) -> String:
	var table: Dictionary = state.get("display", {})
	var entry: Dictionary = table.get(id, {})
	return str(entry.get("name", id.replace("_", " ").capitalize()))


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
		_add_button("tier", Vector2(x_left, y2), "", tier_words, str(upgrade), _barred("upgrade"))
	var refresh: int = _i(state.get("refresh_cost", 0))
	_add_button("refresh", Vector2(x_right, y1), "", "", str(refresh), _barred("refresh"))
	_add_button("freeze", Vector2(x_right, y2), "freeze", "", "", _barred("freeze"))


## Whether a button's action is missing from the state's legal_actions, so it is drawn dimmed.
## A state with no legal_actions dims nothing: the screen never judges a move itself.
func _barred(type: String) -> bool:
	return state.has("legal_actions") and not RecruitActions.allows(state, {"type": type})


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
		box.modulate = SHORT_DIM
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
		var raw: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		var info: Dictionary = slot_info(raw)
		if unit is Dictionary:
			var held: Dictionary = unit
			var extra: Dictionary = {}
			if info.has("buff"):
				extra["buff"] = str(info["buff"])
			var usable: Array = _usable_abilities(held)
			if not usable.is_empty():
				extra["abilities"] = usable
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
		var turn: float = snappedf(place.z, 0.01)
		var key: String = card_key("hand", i, card)
		if is_aiming() and _aim["key"] == key:
			at = _aim["at"]
			turn = 0.0
		_want_card(key, "hand", i, card, at, turn)


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


## Whether the screen is waiting for the player to choose a target.
func is_aiming() -> bool:
	return not _aim.is_empty()


## Drops the target choice, putting the card back where the state has it.
func cancel_aim() -> void:
	if _aim.is_empty():
		return
	_aim = {}
	_layout()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		if is_aiming():
			cancel_aim()
			get_viewport().set_input_as_handled()
		return
	super(event)


func _gui_input(event: InputEvent) -> void:
	if _frame == null:
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
		cancel_aim()
		accept_event()
		return
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
	# a Discover or a target choice takes clicks only
	if not _press.has("card") or is_aiming() or _discovering():
		return
	if not ["shop", "spell", "hand", "board"].has(str(_press["kind"])):
		return
	_dragging = true
	_hide_tip()
	var node: Control = _press["node"]
	_keeper.stop(node)
	node.rotation = 0.0
	node.z_index = 10
	_drag_offset = _press_at - node.position
	# a spell that aims shows its targets while it is carried
	var card: Dictionary = _press["card"]
	if _press["kind"] == "hand" and _is_spell(card):
		var index: int = _press["index"]
		var want: Dictionary = {"type": "play", "hand": index}
		_light(target_kind(card), RecruitActions.targets(state, want), node)


func _release(at: Vector2) -> void:
	var pressed: Dictionary = _press
	var was_drag: bool = _dragging
	_press = {}
	_dragging = false
	if pressed.is_empty():
		return
	if not was_drag:
		var before: int = _shown
		_click(pressed, at)
		# a click that drew a new state has its hover detail drawn already
		var same: bool = before == _shown
		if same and pressed.has("card") and is_instance_valid(pressed["node"]) and not is_aiming():
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
		var card: Dictionary = pressed["card"]
		if _is_spell(card):
			if at.y < _f(_g["sill"]):
				_cast(index, card, at)
		elif slot >= 0:
			_play(index, card, slot)
	elif kind == "board":
		if slot >= 0 and slot != index:
			_request({"type": "move", "from": index, "to": slot})
		elif at.y < _f(_g["T0"]):
			_request({"type": "sell", "slot": index})


## A unit from the hand into a slot: sent at once, or a target to choose first.
func _play(index: int, card: Dictionary, slot: int) -> void:
	var want: Dictionary = {"type": "play", "hand": index, "slot": slot}
	var targets: Array[int] = RecruitActions.targets(state, want)
	if targets.is_empty():
		_request(want, {"target": -1})
		return
	_start_aim(want, target_kind(card), targets, card_key("hand", index, card), slot_xy(slot))


## A spell let go over the table: on a target it names, cast there; with no target to choose, cast;
## otherwise choose one.
func _cast(index: int, card: Dictionary, at: Vector2) -> void:
	var want: Dictionary = {"type": "play", "hand": index}
	var targets: Array[int] = RecruitActions.targets(state, want)
	if targets.is_empty():
		_request(want, {"slot": -1, "target": -1})
		return
	var kind: String = target_kind(card)
	var on: int = _target_value_at(at, kind)
	if targets.has(on):
		var aimed: Dictionary = want.duplicate()
		aimed["target"] = on
		_request(aimed)
		return
	_aim_hand(index, card, want, targets)


## Holds hand card index up out of the hand while its target is chosen.
func _aim_hand(index: int, card: Dictionary, want: Dictionary, targets: Array[int]) -> void:
	var key: String = card_key("hand", index, card)
	var hand: Array = state.get("hand", [])
	var place: Vector3 = hand_place(index, hand.size())
	var kind: String = target_kind(card)
	_start_aim(want, kind, targets, key, Vector2(place.x, place.y - AIM_LIFT))


## An ability button: used at once, or a target to choose first.
func _use_ability(uid: int, mechanic: String, kind: String) -> void:
	var want: Dictionary = {"type": "ability", "uid": uid, "mechanic": mechanic}
	var targets: Array[int] = RecruitActions.targets(state, want)
	if targets.is_empty():
		_request(want, {"target": -1})
		return
	_start_aim(want, kind, targets, "", Vector2.ZERO)


## Waits for a target: the valid ones lit, the card held where it was played.
func _start_aim(
	want: Dictionary, kind: String, targets: Array[int], key: String, at: Vector2
) -> void:
	_aim = {"want": want, "kind": kind, "targets": targets, "key": key, "at": at}
	_layout()


func _click(pressed: Dictionary, at: Vector2) -> void:
	if _target_at(at, false) != pressed:
		return
	if _discovering():
		if pressed["kind"] == "discover":
			_request({"type": "pick", "index": pressed["index"]})
		return
	if is_aiming():
		var value: int = _target_value_at(at, str(_aim["kind"]))
		var targets: Array[int] = _aim["targets"]
		if targets.has(value):
			var want: Dictionary = _aim["want"]
			var aimed: Dictionary = want.duplicate()
			aimed["target"] = value
			_aim = {}
			_request(aimed)
		return
	match str(pressed["kind"]):
		"ability":
			_use_ability(_i(pressed["uid"]), str(pressed["id"]), str(pressed["target"]))
		"button":
			match str(pressed["id"]):
				"hero":
					toggle_leaderboard()
				"tier":
					_request({"type": "upgrade"})
				"refresh", "freeze", "end_turn":
					_request({"type": str(pressed["id"])})


## What a stage point names as a target of a kind: a board unit's uid, a slot, a shop place; -1.
func _target_value_at(at: Vector2, kind: String) -> int:
	match kind:
		"unit":
			var hit: Dictionary = _card_target_at(at, ["board"])
			if hit.is_empty():
				return -1
			var card: Dictionary = hit["card"]
			return _i(card.get("uid", -1))
		"slot":
			return _slot_at(at)
		"shop":
			var hit: Dictionary = _card_target_at(at, ["shop"])
			return _i(hit["index"]) if not hit.is_empty() else -1
	return -1


func _card_target_at(at: Vector2, kinds: Array) -> Dictionary:
	for i: int in range(_targets.size() - 1, -1, -1):
		var target: Dictionary = _targets[i]
		if not kinds.has(target["kind"]) or not target.has("card"):
			continue
		var node: Control = target.get("node")
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var poly: PackedVector2Array = target["poly"]
		if Geometry2D.is_point_in_polygon(_to_local_of(node, at), poly):
			return target
	return {}


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


# ---- lit targets ----


## Lights the valid targets of a kind (STAND-IN: an amber rim, recruit-play.html's .lit), on
## every card and slot they name; skip is the card being played.
func _light(kind: String, targets: Array[int], skip: Control = null) -> void:
	for target: Dictionary in _targets:
		var node: Control = target.get("node")
		if node == null or node == skip:
			continue
		var value: int = -1
		match [kind, str(target["kind"])]:
			["unit", "board"]:
				var card: Dictionary = target["card"]
				value = _i(card.get("uid", -1))
			["slot", "board"], ["slot", "slot"]:
				value = _i(target["index"])
			["shop", "shop"]:
				value = _i(target["index"])
			_:
				continue
		if targets.has(value):
			var shoulder: float = _f(_g["SS"]) if node is GlassSpell else _slot_shoulder()
			GlassParts.add_lit(node, GlassBox.hexagon(Rect2(Vector2.ZERO, node.size), shoulder))


func _unlight() -> void:
	for child: Node in _cards.get_children():
		for lit: Node in child.get_children():
			if lit.has_meta(&"lit"):
				child.remove_child(lit)
				lit.queue_free()


# ---- Discover (docs/ideation-track-2/mockups/recruit-play.html, ?discover=1) ----


func _discovering() -> bool:
	return state.get("discover") is Dictionary


## The picker over the table: a dark veil, the prompt, and the options as big cards in a row.
## Clicking one picks it; the hover detail reads it.
func _build_discover() -> void:
	var discover: Dictionary = state["discover"]
	var veil: ColorRect = ColorRect.new()
	veil.name = "DiscoverVeil"
	veil.color = DISCOVER_VEIL
	veil.size = _stage.size
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = DISCOVER_Z
	_front.add_child(veil)
	var options: Array = discover.get("options", [])
	var height: float = _h() * DISCOVER_SCALE
	var width: float = GlassCard.card_size(height).x
	var row: float = options.size() * width + maxf(0.0, options.size() - 1.0) * DISCOVER_GAP
	var top: float = DISCOVER_MIDDLE - height / 2.0
	var prompt: GlassText = GlassText.from_rule("stage", ".lbl", str(discover.get("prompt", "")))
	prompt.name = "DiscoverPrompt"
	prompt.font_px = DISCOVER_PROMPT_PX
	prompt.refresh()
	prompt.z_index = DISCOVER_Z + 1
	prompt.position = Vector2(960.0 - prompt.size.x / 2.0, top - DISCOVER_PROMPT_UP).round()
	_front.add_child(prompt)
	for i: int in options.size():
		var option: Dictionary = options[i]
		var node: Control
		var outline: PackedVector2Array
		if _is_spell(option):
			var spell_size: Vector2 = _spell_size() * DISCOVER_SCALE
			node = _spell_card(option, spell_size)
			outline = GlassBox.hexagon(Rect2(Vector2.ZERO, spell_size), _f(_g["SS"]))
		else:
			node = _unit_card(option, height)
			outline = GlassBox.hexagon(
				Rect2(Vector2.ZERO, Vector2(width, height)), _slot_shoulder()
			)
		node.name = "Discover_%d" % i
		node.z_index = DISCOVER_Z + 1
		node.position = Vector2(960.0 - row / 2.0 + i * (width + DISCOVER_GAP), top)
		_front.add_child(node)
		_targets.append(
			{"kind": "discover", "index": i, "node": node, "poly": outline, "card": option}
		)
