class_name RecruitBoard
extends RefCounted
## The recruit board's own drawing: its seven slots (each drawn whether a unit stands on it or not),
## the units wanted on them, a slot's bonus pill over the unit on it, the lit targets (STAND-IN:
## an amber rim, recruit-play.html's .lit), and which slot a stage point is over.
##
## A part of its screen: it configures the persistent Slots layer and the kept cards, and adds the
## slots and units to the screen's targets.

## A slot's bonus pill is drawn over the cards resting on the board, under a hovered or carried one.
const SLOT_BUFF_Z: int = 1

var _screen: RecruitScreen


func _init(screen: RecruitScreen) -> void:
	_screen = screen


## Every slot is drawn by the board, under the cards, whether a unit stands on it or not: a card
## picked up leaves its slot there, empty. A slot's bonus under a unit is the board's too: a pill
## at the slot's foot, over the unit, that stays with the slot when the unit is carried away.
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
			if info.has("buff"):
				_add_slot_buff(i, str(info["buff"]))
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


## STAND-IN: a slot's lasting bonus under the unit on it, as a pill at the slot's foot, drawn by
## the board above the cards resting on it (a carried card goes over it).
func _add_slot_buff(i: int, buff: String) -> void:
	var pill: GlassBox = GlassParts.make_pill(buff)
	pill.name = "SlotBuff_%d" % i
	pill.z_index = SLOT_BUFF_Z
	var box: Vector2 = _screen.card_box()
	pill.position = (
		_screen.slot_xy(i) + Vector2((box.x - pill.box_size.x) / 2.0, box.y - pill.box_size.y)
	)
	_screen._back.add_child(pill)


## The board slot (0-6) whose outline holds a point, or -1.
func slot_at(at: Vector2) -> int:
	var outline: PackedVector2Array = GlassBox.hexagon(
		Rect2(Vector2.ZERO, _screen.card_box()), _screen._slot_shoulder()
	)
	for i: int in GlassScreen.BOARD_SLOTS:
		if Geometry2D.is_point_in_polygon(at - _screen.slot_xy(i), outline):
			return i
	return -1


## A unit lifted off its slot: the slot's bonus stays with the slot (its pill, SlotBuff_<index>,
## gives way to the bonus written on the empty slot), and the unit shows its own numbers, without
## what the slot gives it (slot_attack, slot_health in its card), until it lands: Galaxy's slot
## that matters.
func leave_slot(unit: Control, card: Dictionary, index: int) -> void:
	var pill: CanvasItem = _screen._back.get_node_or_null("SlotBuff_%d" % index)
	if pill != null:
		pill.visible = false
	var glass: GlassCard = unit as GlassCard
	var given: Vector2i = Vector2i(
		GlassPieces.as_int(card.get("slot_attack", 0)),
		GlassPieces.as_int(card.get("slot_health", 0))
	)
	# from the unit's numbers in the state, not what it shows (it may be counting up as it lands)
	if glass != null and card.has("attack") and card.has("health"):
		var own_health: int = GlassPieces.as_int(card["health"]) - given.y
		glass.set_numbers(GlassPieces.as_int(card["attack"]) - given.x, own_health)
		# hurt only below its own most (the slot's Health is not its own)
		glass.hurt = (
			(glass.max_health >= 0 and own_health < glass.max_health - given.y)
			or (glass.base_health >= 0 and own_health < glass.base_health)
		)


## STAND-IN (stand-ins.html ?m=drag): while a unit is carried, every empty slot it can go to is
## lit (recruit-play.html's lit target), the one it left too (from, for a board unit); the units on
## the board do nothing.
func light_drop(kind: String, from: int) -> void:
	if (
		(kind == "shop" and _screen.is_barred("buy"))
		or (kind == "hand" and _screen.is_barred("play"))
	):
		return
	var outline: PackedVector2Array = GlassBox.hexagon(
		Rect2(Vector2.ZERO, _screen.card_box()), _screen._slot_shoulder()
	)
	for i: int in GlassScreen.BOARD_SLOTS:
		var slot: Control = _screen._slots.get_node_or_null("Slot_%d" % i)
		var empty: bool = _screen._targets.any(
			func(t: Dictionary) -> bool: return t["kind"] == "slot" and t["index"] == i
		)
		if slot != null and (empty or (kind == "board" and from == i)):
			GlassParts.add_lit(slot, outline)


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
