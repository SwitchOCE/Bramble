class_name RecruitBoard
extends RefCounted
## The recruit board's own drawing: its seven slots (each drawn whether a unit stands on it or not),
## the units on them, slot keyword and Renown pills, lit targets (recruit-play.html's .lit),
## and which slot a stage point is over.
##
## A part of its screen: it configures the persistent Slots layer and the kept cards, and adds the
## slots and units to the screen's targets.

## Slot pills are drawn over the resting cards and under a hovered or carried card.
const SLOT_PILL_Z: int = 1
const DROP_AMBER: Color = Color("ffd590")
const SWAP_BLUE: Color = Color("bfe4ff")

var _screen: RecruitScreen
var _preview_slot: int = -1
var _drop_preview: Control
var _swap_unit: Control


func _init(screen: RecruitScreen) -> void:
	_screen = screen


## Every slot is drawn by the board, under the cards, whether a unit stands on it or not: a card
## picked up leaves its slot there, empty. The board also draws the slot's pills over the unit,
## so they stay with the slot when the unit is carried away.
func want() -> void:
	var state: Dictionary = _screen.state
	var board: Array = state.get("board", [])
	var slots: Array = state.get("slots", [])
	var places: Array[Vector2] = []
	var bonuses: Array[Dictionary] = []
	for i: int in GlassScreen.BOARD_SLOTS:
		places.append(_screen.slot_xy(i))
		var raw: Dictionary = slots[i] if i < slots.size() and slots[i] is Dictionary else {}
		bonuses.append(_screen.slot_info(raw))
	_screen._slots.set_row("Slot_", places, _screen.card_box(), bonuses)
	for i: int in GlassScreen.BOARD_SLOTS:
		var unit: Variant = board[i] if i < board.size() else null
		var info: Dictionary = bonuses[i]
		var slot: GlassBox = _screen._slots.get_node("Slot_%d" % i) as GlassBox
		if unit is Dictionary:
			var held: Dictionary = unit
			var extra: Dictionary = {}
			var usable: Array = RecruitActions.abilities(state, held)
			if not usable.is_empty():
				extra["abilities"] = usable
			_screen._want_card(
				GlassScreen.card_key("board", i, held),
				"board",
				i,
				held,
				_screen.slot_xy(i),
				0.0,
				extra
			)
			if info.has("keyword"):
				_add_slot_keyword(i, str(info["keyword"]))
			if info.has("renown"):
				_add_renown(i, GlassPieces.as_int(info["renown"]))
			continue
		(
			_screen
			. _targets
			. append(
				{
					"kind": "slot",
					"index": i,
					"node": slot,
					"poly":
					GlassBox.hexagon(Rect2(Vector2.ZERO, slot.box_size), _screen._slot_shoulder()),
				}
			)
		)


## A slot's keyword pill, drawn at the foot of its occupying unit's card.
func _add_slot_keyword(i: int, keyword: String) -> void:
	var pill: GlassBox = GlassParts.make_pill(keyword)
	pill.name = "SlotKeyword_%d" % i
	pill.z_index = SLOT_PILL_Z
	var box: Vector2 = _screen.card_box()
	pill.position = (
		_screen.slot_xy(i) + Vector2((box.x - pill.box_size.x) / 2.0, box.y - pill.box_size.y)
	)
	_screen._back.add_child(pill)


## STAND-IN: a slot's Renown over the unit on it, the slot's own banner drawn again above the
## cards resting on the board (a carried card goes over it), named Renown_<index>.
func _add_renown(i: int, renown: int) -> void:
	var banner: GlassBox = GlassSlot.renown_banner(renown, _screen.card_box())
	banner.name = "Renown_%d" % i
	banner.z_index = SLOT_PILL_Z
	banner.position += _screen.slot_xy(i)
	_screen._back.add_child(banner)


## The board slot (0-6) whose outline holds a point, or -1.
func slot_at(at: Vector2) -> int:
	var outline: PackedVector2Array = GlassBox.hexagon(
		Rect2(Vector2.ZERO, _screen.card_box()), _screen._slot_shoulder()
	)
	for i: int in GlassScreen.BOARD_SLOTS:
		if Geometry2D.is_point_in_polygon(at - _screen.slot_xy(i), outline):
			return i
	return -1


## A lifted unit shows its stats without Renown. Slot pills give way to the empty slot's labels.
func leave_slot(unit: Control, card: Dictionary, index: int) -> void:
	for pill_name: String in ["SlotKeyword_%d" % index, "Renown_%d" % index]:
		var pill: CanvasItem = _screen._back.get_node_or_null(pill_name)
		if pill != null:
			pill.visible = false
	var glass: GlassCard = unit as GlassCard
	var renown: int = GlassPieces.as_int(card.get("renown", 0))
	# from the unit's numbers in the state, not what it shows (it may be counting up as it lands)
	if glass != null and card.has("attack") and card.has("health"):
		var own_health: int = GlassPieces.as_int(card["health"]) - renown
		glass.set_numbers(GlassPieces.as_int(card["attack"]) - renown, own_health)
		# hurt only below its own most (the slot's Health is not its own)
		glass.hurt = (
			(glass.max_health >= 0 and own_health < glass.max_health - renown)
			or (glass.base_health >= 0 and own_health < glass.base_health)
		)


func has_unit(slot: int) -> bool:
	return _screen.node_for("board", slot) != null


## Light every empty destination, and the slot a carried board unit left.
func light_drop(kind: String, from: int) -> void:
	var outline: PackedVector2Array = GlassBox.hexagon(
		Rect2(Vector2.ZERO, _screen.card_box()), _screen._slot_shoulder()
	)
	for i: int in GlassScreen.BOARD_SLOTS:
		var slot: Control = _screen._slots.get_node_or_null("Slot_%d" % i)
		var empty: bool = not has_unit(i)
		if (
			slot != null
			and ((empty and _can_drop(kind, from, i)) or (kind == "board" and from == i))
		):
			GlassParts.add_lit(slot, outline)


func _can_drop(kind: String, from: int, slot: int, swap: bool = false) -> bool:
	if kind == "board" or not _screen.state.has("legal_actions"):
		return true
	var action: Dictionary = {"type": "buy", "spell": false, "index": from, "slot": slot}
	if kind == "hand":
		action = {"type": "play", "hand": from, "slot": slot}
		if swap:
			action["swap"] = true
	return RecruitActions.allows(_screen.state, action)


## On the hovered destination, brighten the amber rim or show the blue swap and hand preview.
func preview_drop(kind: String, from: int, slot: int) -> void:
	if slot == _preview_slot:
		return
	clear_drop_preview()
	_preview_slot = slot
	if slot < 0:
		return
	var occupied: bool = has_unit(slot)
	if (occupied and kind != "hand") or not _can_drop(kind, from, slot, occupied):
		return
	_drop_preview = Control.new()
	_drop_preview.name = "DropPreview"
	_drop_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen._front.add_child(_drop_preview)
	var at: Vector2 = _screen.slot_xy(slot)
	var outline: PackedVector2Array = GlassBox.hexagon(
		Rect2(at, _screen.card_box()), _screen._slot_shoulder()
	)
	var edge: Color = SWAP_BLUE if occupied else DROP_AMBER
	_drop_preview.draw.connect(
		func() -> void:
			var rim: PackedVector2Array = outline.duplicate()
			rim.append(outline[0])
			_drop_preview.draw_colored_polygon(outline, Color(edge, 0.15))
			_drop_preview.draw_polyline(rim, Color(edge, 0.22), 23.0, true)
			_drop_preview.draw_polyline(rim, Color(edge, 0.55), 11.0, true)
			_drop_preview.draw_polyline(rim, edge, 4.0, true)
	)
	if occupied:
		_preview_swap(from, slot, at)


func _preview_swap(from: int, slot: int, at: Vector2) -> void:
	var card: Dictionary = _screen.state["board"][slot]
	var lifted: Control = _screen._make_card("board", card, {})
	lifted.name = "SwapLifted"
	lifted.position = at + Vector2(-6, 10)
	lifted.rotation_degrees = -2.0
	lifted.modulate = Color(0.67, 0.75, 0.83, 0.72)
	_drop_preview.add_child(lifted)
	_swap_unit = _screen.node_for("board", slot)
	_swap_unit.hide()
	var hand: Array = _screen.state["hand"]
	var place: Vector3 = _screen.hand_place(from, hand.size())
	var ghost: GlassCard = _screen._make_card("hand", card, {}) as GlassCard
	ghost.name = "SwapGhost"
	ghost.position = Vector2(place.x, place.y - 24.0)
	ghost.rotation_degrees = place.z
	ghost.modulate = Color(0.78, 0.88, 1.0, 0.48)
	_drop_preview.add_child(ghost)
	ghost.pivot_offset = Vector2(ghost.size.x / 2.0, ghost.size.y)
	var renown: int = GlassPieces.as_int(card.get("renown", 0))
	ghost.max_health -= renown
	ghost.set_numbers(ghost.attack - renown, ghost.health - renown)


func clear_drop_preview() -> void:
	if is_instance_valid(_swap_unit):
		_swap_unit.show()
	_swap_unit = null
	if is_instance_valid(_drop_preview):
		_drop_preview.get_parent().remove_child(_drop_preview)
		_drop_preview.queue_free()
	_drop_preview = null
	_preview_slot = -1


## Lights the valid targets of a kind on every card and slot they name; skip is the card being
## played.
func light(kind: String, targets: Array[int], skip: Control = null) -> void:
	for target: Dictionary in _screen._targets:
		var node: Control = target.get("node")
		if node == null or node == skip:
			continue
		var value: int = -1
		match [kind, str(target["kind"])]:
			["unit", "board"], ["unit", "hand"]:
				var card: Dictionary = target["card"]
				value = GlassPieces.as_int(card.get("uid", -1))
			["slot", "board"], ["slot", "slot"]:
				value = GlassPieces.as_int(target["index"])
			["shop", "shop"]:
				value = GlassPieces.as_int(target["index"])
			_:
				continue
		if targets.has(value):
			var shoulder: float = (
				GlassScreen._f(_screen._g["SS"]) if node is GlassSpell else _screen._slot_shoulder()
			)
			GlassParts.add_lit(node, GlassBox.hexagon(Rect2(Vector2.ZERO, node.size), shoulder))


## Every card's and persistent slot's lit rim taken off (each drawing lights afresh).
func unlight() -> void:
	for child: Node in _screen._cards.get_children() + _screen._slots.get_children():
		for lit: Node in child.get_children():
			if lit.has_meta(&"lit"):
				child.remove_child(lit)
				lit.queue_free()
