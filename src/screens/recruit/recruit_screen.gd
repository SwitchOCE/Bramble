class_name RecruitScreen
extends GlassScreen
## The recruit screen in lead and stained glass, rebuilt from the chosen mock-up (recruit.html at
## its defaults: 250 px cards, spells above the shop). It draws one plain view-state Dictionary
## (show_state) and reports what the player asks for as action_requested; it holds no rules.
## Every place, size and colour comes from the mock-up through GlassPieces: recruit.html's geom()
## for the geometry, stage.css's rules for the look, stage.js's numbers for the rest. The view
## state is described in docs/ideation-track-2/SCREEN-CONTRACT.md;
## tests/screens/fixtures/recruit_mockup.json is a full example.
##
## This file lays the screen out, holds the state and wires its parts: RecruitInput (press, drag,
## drop, click, target choice), RecruitBoard (slots, pills, lit targets), RecruitButtons,
## RecruitCounts (gold, counters, hand count), RecruitTips (hover detail) and RecruitDiscover.

## What the player asks for, in the rules core's own action format (src/core/README.md): buy,
## sell, play, move, refresh, freeze, upgrade, pick, ability, end_turn. Each is the matching entry
## of the state's legal_actions, or, when the state lists none like it, the action as built, so
## the core can say why it is refused. Buying is by drag (a click only shows a card's detail).
## Answer it with show_state from the handler: the dropped card then moves from where it was let go.
signal action_requested(action: Dictionary)
signal cards_requested

const READY_LINE: String = "recruit_screen: ready"
## The words while a target is being chosen (STAND-IN wording, in the message area).
const AIM_PROMPT: String = "Choose a target"
## STAND-IN dimmed look (stand-ins.html .btn.short): a button or ability that can't be used now.
const SHORT_DIM: Color = Color(0.55, 0.55, 0.55)

## For comparing with recruit-play.html?aim=unit: the hand card whose target is being chosen when
## the screen opens (-1 for none).
@export var pinned_aim: int = -1

## How many states have been shown, so a drop can tell whether its handler drew a new one.
var _shown: int = 0
var _duplicate_time: float = 0.0
var _board: RecruitBoard
var _buttons: RecruitButtons
var _counts: RecruitCounts
var _input: RecruitInput
var _triple: RecruitTripleMotion
var _turn_start: RecruitTurnStart
var _waiting: RecruitWaitingPile
var _motion: RecruitMotion
var _last_turn: int = -1


func _ready() -> void:
	super()
	var hand: Array = state.get("hand", [])
	if pinned_aim >= 0 and pinned_aim < hand.size():
		var card: Dictionary = hand[pinned_aim]
		var want: Dictionary = {"type": "play", "hand": pinned_aim}
		_input.aim_hand(pinned_aim, card, want, RecruitActions.targets(state, want))


func _ensure_stage() -> void:
	var fresh: bool = _frame == null
	super()
	if fresh:
		_board = RecruitBoard.new(self)
		_buttons = RecruitButtons.new(self)
		_counts = RecruitCounts.new(self)
		_waiting = RecruitWaitingPile.new(self)
		_input = RecruitInput.new(self, _keeper, _board, _tips as RecruitTips)
		_triple = RecruitTripleMotion.new(self)
		_stage.add_child(_triple)
		_turn_start = RecruitTurnStart.new(self)
		_stage.add_child(_turn_start)
		_motion = RecruitMotion.new(self)
		_stage.add_child(_motion)
		_keeper.flown_out.connect(func(_node: Control) -> void: _counts.arrived())
		_keeper.flown.connect(func(_node: Control) -> void: _counts.flight_over())


func _make_tips() -> GlassTips:
	return RecruitTips.new(self)


func _ready_line() -> String:
	return READY_LINE


## No hover detail while the button is held on a card or a card is carried.
func _hover_allowed() -> bool:
	return (
		_input == null
		or (not _input.is_busy() and not _turn_start.active() and not _motion.moving_cards())
	)


## A hovered hand card stands up off its place in the fan: the pointer still over that place is
## still over it (no flicker between the two).
func _target_at(at: Vector2, cards_only: bool) -> Dictionary:
	var found: Dictionary = super(at, cards_only)
	var node: Control = found.get("node")
	if node != null and not node.visible:
		return {}
	var tips: RecruitTips = _tips as RecruitTips
	if not found.is_empty() or tips == null or not is_instance_valid(tips.standing):
		return found
	var standing: Control = tips.standing
	var stood: Vector3 = Vector3(standing.position.x, standing.position.y, standing.rotation)
	standing.position = Vector2(tips.rest.x, tips.rest.y)
	standing.rotation = tips.rest.z
	found = super(at, cards_only)
	standing.position = Vector2(stood.x, stood.y)
	standing.rotation = stood.z
	return found if found.get("node") == standing else {}


## The window lost (Alt+Tab mid-drag, say): a carried card goes back where the state has it.
func _notification(what: int) -> void:
	super(what)
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if _input != null:
			_input.focus_lost()


## A carried card tilts and floats each frame, the pointer moving or not.
func _process(delta: float) -> void:
	_duplicate_time += delta
	for target: Dictionary in _targets:
		var node: Control = target.get("node")
		if is_instance_valid(node):
			var glow: GlassDuplicateGlow = node.get_node_or_null("DuplicateGlow")
			if glow != null:
				glow.set_phase(_duplicate_time)
	if _input != null:
		_input.step(delta)
	super(delta)


func _layout() -> void:
	_turn_start.finish()
	_motion.finish()
	_board.clear_drop_preview()
	super()
	_triple.present()
	# Triple/CardKeeper finishing can clear the held style; the pending aim still owns it.
	_input.light_aim(false)


func settle() -> void:
	if _turn_start != null:
		_turn_start.finish()
	if _motion != null:
		_motion.finish()
	super()
	if _triple != null:
		_triple.finish()
	_input.light_aim(false)


func _shown_counters() -> Array:
	return _counts.counters()


func show_state(new_state: Dictionary) -> void:
	if _triple != null:
		_triple.prepare(new_state)
	var before: Dictionary = state
	if _motion != null:
		_motion.before_state(before, new_state)
	if _counts != null:
		_counts.before_state(before, new_state)
	var turn: int = _i(new_state.get("turn", -1))
	var effects: Array = new_state.get("turn_start_effects", []) if turn != _last_turn else []
	if is_inside_tree():
		_last_turn = turn
	if _keeper != null:
		for effect: Dictionary in effects:
			if effect.has("slot"):
				var slot: int = effect["slot"]
				var card: Dictionary = new_state["board"][slot]
				_keeper.quiet_numbers[card_key("board", slot, card)] = true
	super(new_state)
	_counts.after_state(before)
	_motion.after_state(before)
	if not effects.is_empty() and is_inside_tree():
		_turn_start.play(effects)


func _on_new_state() -> void:
	_shown += 1
	_input.reset()


# ---- what the parts ask of the screen ----


## Reports what the player asks for (action_requested).
func ask(action: Dictionary) -> void:
	_motion.asked(action)
	action_requested.emit(action)


## Draws the state again as it is (the kept cards move to their places).
func redraw() -> void:
	_layout()


## How many states have been shown (a handler that drew a new one moved it on).
func shown_count() -> int:
	return _shown


## The topmost pointer target under a stage point; cards_only for the hover detail.
func target_at(at: Vector2, cards_only: bool) -> Dictionary:
	return _target_at(at, cards_only)


## The topmost card of these kinds under a stage point, or {}.
func card_target_at(at: Vector2, kinds: Array) -> Dictionary:
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


## No pointer on the stage until it moves again (a dropped card shows no detail on its way).
func forget_pointer() -> void:
	_pointer = Vector2(-1, -1)


## Whether a card is carried or pressed now.
func is_holding() -> bool:
	return _input.is_holding()


## Whether an action's type is missing from the state's legal_actions, so its button is drawn
## dimmed. A state with no legal_actions dims nothing: the screen never judges a move itself.
func is_barred(type: String) -> bool:
	return state.has("legal_actions") and not RecruitActions.allows(state, {"type": type})


func is_discovering() -> bool:
	return state.get("discover") is Dictionary and not state.has("recruit_choice")


# ---- geometry (recruit.html render()) ----


func _geom() -> Dictionary:
	return RecruitShop.geometry()


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
	RecruitShop.build_slots(self)
	_want_shop()
	_buttons.build_shop_buttons()
	_board.want()
	_want_hand()
	_waiting.want_cards()
	_keeper.leave_to = _leaving_places()
	_place_cards()
	_buttons.add_ability_targets()
	_board.unlight()
	_input.light_aim()
	_counts.build_hand_count()
	_counts.build_reserve_limit()
	_waiting.build_count()
	_build_hero()
	_buttons.build_end_turn()
	var cards_button: CardsButton = CardsButton.new()
	cards_button.name = "CardsEntry"
	cards_button.held = is_holding
	cards_button.pressed.connect(cards_requested.emit)
	_front.add_child(cards_button)
	if show_leaderboard:
		_build_leaderboard()
	_add_vignette()
	_build_message(AIM_PROMPT if is_aiming() else str(state.get("message", "")))
	if is_discovering():
		var discover: Dictionary = state["discover"]
		RecruitDiscover.build(self, discover)


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
					out[card_id] = GlassCounters.plate_xy(shown, 1080.0) + Vector2(60.0, 22.0)
				shown += 1
	return out


func _want_shop() -> void:
	var frozen: bool = _b(state.get("frozen", false))
	var units: Array = state.get("shop_units", [])
	for i: int in units.size():
		if units[i] is Dictionary:
			var unit: Dictionary = units[i]
			_want_card(
				card_key("shop", i, unit),
				"shop",
				i,
				unit,
				shop_xy(i),
				0.0,
				{
					"frost": frozen,
					"shop_price": true,
					"poor": _i(unit.get("price", 0)) > _counts.gold()
				}
			)
	var spells: Array = state.get("shop_spells", [])
	for k: int in spells.size():
		if spells[k] is Dictionary:
			var spell: Dictionary = spells[k]
			var key: String = card_key("spell", k, spell)
			_want_card(
				key,
				"spell",
				k,
				spell,
				spell_xy(k),
				0.0,
				{
					"frost": frozen,
					"shop_price": true,
					"poor": _i(spell.get("cost", 0)) > _counts.gold()
				}
			)


func _make_card(kind: String, data: Dictionary, extra: Dictionary) -> Control:
	var node: Control = super(kind, data, extra)
	if kind == "waiting_pile":
		var tint: float = _f(extra["waiting_tint"])
		node.modulate = Color(tint, tint, tint)
	if _b(extra.get("shop_price", false)):
		# Unit controls size themselves in _ready; tags also need the size before entering the tree.
		node.size = _spell_size() if node is GlassSpell else card_box()
		RecruitShop.dress_card(node, data, _b(extra["poor"]))
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
	if kind == "board" and _b(data.get("worked_this_turn", false)):
		var side: float = maxf(KeywordStyle.CARD_MIN_SIDE, _h() * KeywordStyle.CARD_DIAMETER)
		var mark: KeywordMark = KeywordMark.make({"name": "Worked", "words": "Worked"}, true, side)
		mark.name = "WorkedMark"
		mark.position = Vector2(_w() - side - 10.0, _h() * 0.13)
		mark.z_index = 2
		node.add_child(mark)
	var abilities: Array = extra.get("abilities", [])
	RecruitButtons.add_ability_buttons(node, abilities, Vector2(_w(), _h()))
	return node


## What a hand card or ability aims at: "unit", "enemy", "slot", "shop", or "" for nothing.
static func target_kind(card: Dictionary) -> String:
	var kind: String = str(card.get("target_kind", "none"))
	return "" if kind == "none" else kind


func _want_hand() -> void:
	var hand: Array = state.get("hand", [])
	var n: int = hand.size()
	for i: int in n:
		var card: Dictionary = hand[i]
		var place: Vector3 = hand_place(i, n)
		var at: Vector2 = Vector2(place.x, place.y)
		var turn: float = snappedf(place.z, 0.01)
		var key: String = card_key("hand", i, card)
		var held: Variant = _input.aim_place(key)
		if held != null:
			at = held
			turn = 0.0
		_want_card(key, "hand", i, card, at, turn)


func _place_cards() -> void:
	super()
	var marks: Dictionary = RecruitDuplicates.marks(state)
	for target: Dictionary in _targets:
		# a let-go card lands over the cards it passes; one going into the hand's fan lands in
		# its place in the fan, so its overlap never changes once it is still
		var landing: Control = target.get("node")
		var kind: String = str(target["kind"])
		if landing is GlassCard and marks.has(kind):
			var index: int = _i(target["index"])
			var glow: GlassDuplicateGlow = GlassDuplicateGlow.apply(
				landing as GlassCard, _i(marks[kind][index])
			)
			if glow != null:
				glow.set_phase(_duplicate_time)
		if landing != null:
			var tag: Control = landing.get_node_or_null("ShopTag")
			if tag != null:
				tag.show()
		if landing != null and _keeper.is_landing(landing) and target["kind"] != "hand":
			_cards.move_child(landing, -1)
		if target["kind"] in ["hand", "waiting_pile"]:
			# hand cards turn about their bottom middle: a new one is placed for that already, a
			# carried one keeps where it is drawn
			var node: Control = target["node"]
			var foot: Vector2 = Vector2(node.size.x / 2.0, node.size.y)
			if node.pivot_offset == Vector2.ZERO:
				node.pivot_offset = foot
			else:
				CardKeeper.set_pivot(node, foot)


# ---- input: action_requested only (RecruitInput); the controller owns the rules ----


## Whether the screen is waiting for the player to choose a target.
func is_aiming() -> bool:
	return _input != null and _input.is_aiming()


## Drops the target choice, putting the card back where the state has it.
func cancel_aim() -> void:
	_input.cancel_aim()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_pressed() and _triple != null and _triple.active():
		_triple.finish()
	if event.is_pressed() and _turn_start != null:
		_turn_start.finish()
		_motion.finish()
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
	if event.is_pressed() and _triple != null and _triple.active():
		_triple.finish()
	if event.is_pressed():
		_turn_start.finish()
		_motion.finish()
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
		cancel_aim()
		accept_event()
		return
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		var at: Vector2 = button.position - _frame.position
		_pointer = at
		if button.pressed:
			_input.press(at, button.double_click)
		else:
			_input.release(at)
		accept_event()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null:
		return
	var here: Vector2 = motion.position - _frame.position
	_pointer = here
	if _input.move(here):
		return
	if not _input.is_pressing() and not _turn_start.active():
		_tips.hover(here)
