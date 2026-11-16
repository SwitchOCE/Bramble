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
## STAND-IN dimmed look (stand-ins.html .btn.short): a button or ability that can't be used now.
const SHORT_DIM: Color = Color(0.55, 0.55, 0.55)
## STAND-IN (polish.html): a hovered hand card stands up unturned, its foot this far above the
## stage's bottom, its words beside it this far to its right.
const HAND_LIFT_FOOT: float = 8.0
const HAND_TIP_GAP: float = 16.0
## A slot's bonus pill is drawn over the cards resting on the board, under a hovered or carried one.
const SLOT_BUFF_Z: int = 1
## A carried card is drawn above everything on the table, slot bonus pills and the vignette too
## (the Discover veil is 8; the hovered card 5). Let go, it is put down at once (CardKeeper.land).
const CARRIED_Z: int = 7

## For comparing with recruit-play.html?aim=unit: the hand card whose target is being chosen when
## the screen opens (-1 for none).
@export var pinned_aim: int = -1

var _press: Dictionary = {}
var _press_at: Vector2 = Vector2.ZERO
var _dragging: bool = false
## The card being carried, while one is.
var _carry: CardCarry
## While a card that left (sold) flies to where it went: the gold and counters from before, so
## they change as it arrives ({gold, counters}; empty: the state's).
var _counts_held: Dictionary = {}
## How many states have been shown, so a drop can tell whether its handler drew a new one.
var _shown: int = 0
## A target being chosen: {want, kind, targets, key (the card held), at (where it is held)}.
var _aim: Dictionary = {}
## The hand card standing up while hovered, and where it rests: Vector3(x, y, turn in radians).
var _lifted: Control
var _lifted_rest: Vector3 = Vector3.ZERO


func _ready() -> void:
	super()
	var hand: Array = state.get("hand", [])
	if pinned_aim >= 0 and pinned_aim < hand.size():
		var card: Dictionary = hand[pinned_aim]
		var want: Dictionary = {"type": "play", "hand": pinned_aim}
		_aim_hand(pinned_aim, card, want, RecruitActions.targets(state, want))


func _ready_line() -> String:
	return READY_LINE


## No hover detail while the button is held on a card or a card is carried.
func _hover_allowed() -> bool:
	return not _dragging and _press.is_empty()


## STAND-IN (polish.html, m=recruit): a hovered hand card stands up, unturned, wholly on the screen,
## and its hover is the words alone, beside it (the card is already big enough to read).
func _show_tip(target: Dictionary, at: Vector2) -> void:
	if str(target["kind"]) == "discover":
		RecruitDiscover.show_tip(self, target)
		return
	if str(target["kind"]) in ["ability", "ability_off"]:
		_show_ability_tip(target)
		return
	if str(target["kind"]) != "hand" or is_aiming():
		super(target, at)
		return
	var node: Control = target["node"]
	if _hot != node:
		for child: Node in _tip.get_children():
			_tip.remove_child(child)
			child.queue_free()
		var card: Dictionary = target["card"]
		var text: GlassBox = GlassParts.tip_text(card, _is_spell(card), _reminders(card))
		text.position = Vector2(0, GlassPieces.rule_number("stage", "#tip .txt", "margin-top"))
		_tip.add_child(text)
	_set_hot(node)
	_lift(node)
	# kept on the screen: a long list of reminders rises above the card's top
	var text_box: GlassBox = _tip.get_child(_tip.get_child_count() - 1)
	var bottom: float = 1080.0 - HAND_LIFT_FOOT - text_box.position.y - text_box.box_size.y
	_tip.position = Vector2(
		node.position.x + node.size.x + HAND_TIP_GAP, minf(node.position.y, bottom)
	)
	_tip.visible = true


## STAND-IN (recruit-play.html ?abil=2): an ability button's hover is the words alone (its name,
## its cost, what it does), beside its card on the right, clear of every button on that card.
func _show_ability_tip(target: Dictionary) -> void:
	var node: Control = target["node"]
	if _hot != node:
		for child: Node in _tip.get_children():
			_tip.remove_child(child)
			child.queue_free()
		var words: Dictionary = target["card"]
		_tip.add_child(GlassParts.tip_text(words, false))
	var card: Control = node.get_parent()
	var box: GlassBox = _tip.get_child(_tip.get_child_count() - 1)
	var x: float = card.position.x + card.size.x + HAND_TIP_GAP
	if x + box.box_size.x > GlassPieces.number("stage.tip.flip_edge"):
		x = card.position.x - HAND_TIP_GAP - box.box_size.x
	_tip.position = Vector2(x, card.position.y + node.position.y)
	_tip.visible = true
	_set_hot(node)


func _set_hot(node: Control) -> void:
	super(node)
	if node != _lifted:
		_set_down()


func _lift(node: Control) -> void:
	if _lifted == node:
		return
	_set_down()
	# a card still landing (a click puts a pressed card back) is at its place first
	_keeper.finish(node)
	_lifted = node
	_lifted_rest = Vector3(node.position.x, node.position.y, node.rotation)
	node.rotation = 0.0
	node.position.y = 1080.0 - node.size.y - HAND_LIFT_FOOT


## The lifted hand card back to its rest.
func _set_down() -> void:
	if is_instance_valid(_lifted):
		_lifted.position = Vector2(_lifted_rest.x, _lifted_rest.y)
		_lifted.rotation = _lifted_rest.z
	_lifted = null


## The window lost (Alt+Tab mid-drag, say): a carried card goes back where the state has it.
func _notification(what: int) -> void:
	super(what)
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		var held: Control = _carry.node if _carry != null else null
		if is_instance_valid(held):
			_keeper.land(held)
		var was_dragging: bool = _dragging or held != null
		_press = {}
		_dragging = false
		_carry = null
		if was_dragging and is_inside_tree():
			_layout()


## A carried card tilts and floats each frame, the pointer moving or not.
func _process(delta: float) -> void:
	if _carry != null:
		_carry.step(delta)
	super(delta)


func _shown_counters() -> Array:
	return _counts_held.get("counters", state.get("counters", []))


func show_state(new_state: Dictionary) -> void:
	var before: Dictionary = state
	_counts_held = {}
	var leaving: Dictionary = (
		new_state.get("leaving") if new_state.get("leaving") is Dictionary else {}
	)
	if not leaving.is_empty() and not before.is_empty():
		_counts_held = {"gold": before.get("gold", 0), "counters": before.get("counters", [])}
	super(new_state)
	if not _counts_held.is_empty() and is_inside_tree():
		var shown: int = _shown
		get_tree().create_timer(CardKeeper.FLY_TIME).timeout.connect(
			func() -> void: _show_counts(shown)
		)


## The held gold and counters let go as the card that left arrives (not mid-drag: the next
## drawing shows them).
func _show_counts(shown: int) -> void:
	if shown != _shown or _counts_held.is_empty():
		return
	_counts_held = {}
	if _carry == null and _press.is_empty() and is_inside_tree():
		_layout()


func _on_new_state() -> void:
	_shown += 1
	_press = {}
	_dragging = false
	_carry = null
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
	_keeper.leave_to = _leaving_places()
	_place_cards()
	_add_ability_targets()
	_unlight()
	if is_aiming():
		var lit: Array[int] = _aim["targets"]
		_light(str(_aim["kind"]), lit, _held_card())
	_build_hand_count()
	_build_hero()
	RecruitParts.build_end_turn(self)
	if show_leaderboard:
		_build_leaderboard()
	_add_vignette()
	_build_message(AIM_PROMPT if is_aiming() else str(state.get("message", "")))
	if _discovering():
		_build_discover()


## Where each card that left in the last action goes (the state's `leaving`): the centre of the
## unit that ate it, or of its heap's plate by the portrait.
func _leaving_places() -> Dictionary:
	var out: Dictionary = {}
	var gone: Dictionary = state.get("leaving", {}) if state.get("leaving") is Dictionary else {}
	var board: Array = state.get("board", [])
	for card_id: Variant in gone:
		var where: Dictionary = gone[card_id]
		if str(where.get("to", "")) == "unit":
			for i: int in board.size():
				var unit: Dictionary = board[i] if board[i] is Dictionary else {}
				if not unit.is_empty() and _i(unit.get("uid", -1)) == _i(where["uid"]):
					out[card_id] = slot_xy(i) + Vector2(_w(), _h()) / 2.0
		elif str(where.get("to", "")) == "heap":
			var shown: int = 0
			# where its plate is drawn once the card arrives (the counters wait for it)
			for value: Variant in state.get("counters", []):
				var counter: Dictionary = value if value is Dictionary else {}
				if counter_entry(counter).is_empty():
					continue
				if str(counter.get("id", "")) == str(where.get("id", "")):
					out[card_id] = Vector2(
						PLATE_X + 60.0, 1080.0 - PLATE_UP - shown * PLATE_STEP + 22.0
					)
				shown += 1
	return out


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
	var abilities: Array = extra.get("abilities", [])
	for k: int in abilities.size():
		var ability: Dictionary = abilities[k]
		var button: GlassBox = GlassParts.ability_button(str(ability["name"]))
		button.name = "Ability_" + str(ability["id"])
		if not _b(ability["usable"]):
			# STAND-IN (stand-ins.html): dimmed like a button whose action is not legal
			button.modulate = SHORT_DIM
		button.position = Vector2(
			(_w() - button.box_size.x) / 2.0, _h() * ABILITY_DOWN - k * (button.box_size.y + 4.0)
		)
		node.add_child(button)
	return node


## What a hand card or ability aims at: "unit", "enemy", "slot", "shop", or "" for nothing.
static func target_kind(card: Dictionary) -> String:
	var kind: String = str(card.get("target_kind", "none"))
	return "" if kind == "none" else kind


## Each ability button on the board is a pointer target over its card: a usable one is pressed,
## a dimmed one only shows what it does. Its hover is its own (what it does and its cost), beside
## the card, so the card's enlarged copy never covers the button being reached for.
func _add_ability_targets() -> void:
	for target: Dictionary in targets_of("board"):
		var extra: Dictionary = target["extra"]
		var card: Dictionary = target["card"]
		var node: Control = target["node"]
		for value: Variant in extra.get("abilities", []):
			var ability: Dictionary = value
			var button: GlassBox = node.get_node("Ability_" + str(ability["id"]))
			var words: Dictionary = {
				"id": "ability:" + str(ability["id"]),
				"name": str(ability["name"]),
				"text": str(ability.get("reminder", "")),
				"kind_line":
				(
					"Ability · costs %d" % _i(ability.get("cost", 0))
					if _i(ability.get("cost", 0)) > 0
					else "Ability · free"
				),
			}
			(
				_targets
				. append(
					{
						"kind": "ability" if _b(ability["usable"]) else "ability_off",
						"card": words,
						"index": target["index"],
						"id": str(ability["id"]),
						"uid": _i(card.get("uid", -1)),
						"target": str(ability["target_kind"]),
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


func _build_buttons() -> void:
	var bw: float = GlassPieces.number("stage.recruit.button.w")
	var gap: float = GlassPieces.number("stage.recruit.button.gap")
	var shop_l: float = _f(_g["shopL"])
	var x_left: float = shop_l - gap - bw
	var x_right: float = shop_l + _f(_g["shopW"]) + gap
	var y1: float = _f(_g["shopTop"]) + _h() / 2.0 - GlassPieces.number("stage.recruit.button.up")
	var y2: float = y1 + GlassPieces.number("stage.recruit.button.step")
	var tier: int = _i(state.get("tier", 1))
	var gold: int = _i(_counts_held.get("gold", state.get("gold", 0)))
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


## Every slot is drawn by the board, under the cards, whether a unit stands on it or not: a card
## picked up leaves its slot there, empty. A slot's bonus under a unit is the board's too: a pill
## at the slot's foot, over the unit, that stays with the slot when the unit is carried away.
func _want_board() -> void:
	var board: Array = state.get("board", [])
	var slots: Array = state.get("slots", [])
	for i: int in BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var raw: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		var info: Dictionary = slot_info(raw)
		var slot: GlassBox = _slot(raw)
		slot.name = "Slot_%d" % i
		slot.position = slot_xy(i)
		_back.add_child(slot)
		if unit is Dictionary:
			var held: Dictionary = unit
			var extra: Dictionary = {}
			var usable: Array = RecruitActions.abilities(state, held)
			if not usable.is_empty():
				extra["abilities"] = usable
			_want_card(card_key("board", i, held), "board", i, held, slot_xy(i), 0.0, extra)
			if info.has("buff"):
				_add_slot_buff(i, str(info["buff"]))
			continue
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


## STAND-IN: a slot's lasting bonus under the unit on it, as a pill at the slot's foot, drawn by
## the board above the cards resting on it (a carried card goes over it).
func _add_slot_buff(i: int, buff: String) -> void:
	var pill: GlassBox = GlassParts.make_pill(buff)
	pill.name = "SlotBuff_%d" % i
	pill.z_index = SLOT_BUFF_Z
	pill.position = slot_xy(i) + Vector2((_w() - pill.box_size.x) / 2.0, _h() - pill.box_size.y)
	_back.add_child(pill)


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
		# a let-go card lands over the cards it passes; one going into the hand's fan lands in
		# its place in the fan, so its overlap never changes once it is still
		var landing: Control = target.get("node")
		if landing != null and _keeper.is_landing(landing) and target["kind"] != "hand":
			_cards.move_child(landing, -1)
		if target["kind"] == "hand":
			# hand cards turn about their bottom middle: a new one is placed for that already, a
			# carried one keeps where it is drawn
			var node: Control = target["node"]
			var foot: Vector2 = Vector2(node.size.x / 2.0, node.size.y)
			if node.pivot_offset == Vector2.ZERO:
				node.pivot_offset = foot
			else:
				CardKeeper.set_pivot(node, foot)


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
			if _press.has("card") and _tip != null:
				# a card pressed is about to be carried: its detail goes at once (a lifted hand
				# card stays up, to be carried from where it stands)
				_tip.visible = false
			if _can_carry(_press):
				_pick_up()
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
	if _carry != null:
		_carry.move(here)
		return
	if _press.is_empty():
		_hover(here)


func _start_drag() -> void:
	if not _press.is_empty() and str(_press["kind"]) in ["ability", "ability_off"]:
		# a drag that starts on a button carries its card
		_press = _card_target_at(_press_at, ["board"])
	if not _can_carry(_press):
		return
	if _carry == null:
		_pick_up()
	_dragging = true


## A card a press picks up: not during a Discover or a target choice, which take clicks only.
func _can_carry(pressed: Dictionary) -> bool:
	if not pressed.has("card") or is_aiming() or _discovering():
		return false
	return ["shop", "spell", "hand", "board"].has(str(pressed["kind"]))


## The pressed card lifted and carried, from the press on (it may yet be only a click).
func _pick_up() -> void:
	# a lifted hand card is carried from where it stands
	_lifted = null
	_hide_tip()
	var node: Control = _press["node"]
	_keeper.stop(node)
	node.z_index = CARRIED_Z
	_carry = CardCarry.new(node, _press_at)
	if node is GlassCard:
		(node as GlassCard).set_held(true)
	var card: Dictionary = _press["card"]
	if _press["kind"] == "board":
		CardCarry.leave_slot(_back, node, card, _i(_press["index"]))
	if not _is_spell(card):
		CardCarry.light_drop(self, str(_press["kind"]), _i(_press["index"]))
	# a spell that aims shows its targets while it is carried
	if _press["kind"] == "hand" and _is_spell(card):
		var index: int = _press["index"]
		var want: Dictionary = {"type": "play", "hand": index}
		_light(target_kind(card), RecruitActions.targets(state, want), node)


func _release(at: Vector2) -> void:
	var pressed: Dictionary = _press
	var was_drag: bool = _dragging
	var lifted: Control = _carry.node if _carry != null else null
	_press = {}
	_dragging = false
	_carry = null
	if pressed.is_empty():
		return
	if not was_drag:
		var before: int = _shown
		if is_instance_valid(lifted):
			_keeper.land(lifted)
		_click(pressed, at)
		if is_instance_valid(lifted) and before == _shown and is_inside_tree():
			_layout()
		# a click that drew a new state has its hover detail drawn already
		var same: bool = before == _shown
		if same and pressed.has("card") and is_instance_valid(pressed["node"]) and not is_aiming():
			_show_tip(pressed, at)
		return
	var shown: int = _shown
	var dropped: Control = pressed["node"]
	# put down: drawn as it will be when still, over the cards it passes (CardKeeper.land)
	_keeper.land(dropped)
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
			_buy(kind == "spell", index, slot)
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


## A shop card let go below the shop: bought. A unit let go on an empty slot is then played into
## that slot, so it goes straight there; on a unit or anywhere else it goes to the hand. Only the
## very card bought is played: a buy that made a golden (a triple) leaves the golden, and anything
## it brought, in the hand (until the owner decides otherwise).
func _buy(spell: bool, index: int, slot: int) -> void:
	var board: Array = state.get("board", [])
	var onto: bool = not spell and slot >= 0 and slot < board.size() and board[slot] == null
	var shop: Array = state.get("shop_units", [])
	var bought_id: String = ""
	if onto and index < shop.size() and shop[index] is Dictionary:
		var offered: Dictionary = shop[index]
		bought_id = str(offered.get("id", ""))
	var had: Dictionary = {}
	for card: Dictionary in state.get("hand", []):
		had[_i(card.get("uid", -1))] = true
	_request({"type": "buy", "spell": spell, "index": index})
	if bought_id == "" or not is_inside_tree():
		return
	var hand: Array = state.get("hand", [])
	var fresh: Array[int] = []
	for i: int in hand.size():
		var card: Dictionary = hand[i]
		if not had.has(_i(card.get("uid", -1))):
			fresh.append(i)
	if fresh.size() != 1:
		return
	var bought: Dictionary = hand[fresh[0]]
	if str(bought.get("id", "")) != bought_id or _b(bought.get("golden", false)):
		return
	_play(fresh[0], bought, slot)


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


## The picker over the table (RecruitDiscover).
func _build_discover() -> void:
	var discover: Dictionary = state["discover"]
	RecruitDiscover.build(self, discover)
