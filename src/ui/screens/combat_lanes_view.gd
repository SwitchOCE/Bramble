extends RefCounted
## Extra combat feedback lives here to keep the playback screen small.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const Data := preload("res://src/ui/view_data.gd")
const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")


static func present(screen: Control, event: Dictionary, animate: bool) -> void:
	var lanes: LaneOverlay = screen.get("_lanes")
	var model: CombatModel = screen.get("model")
	if Data.s(event, "type") == "combat_start":
		reset_floor_state(screen)
	elif Data.s(event, "type") == "ring_dance":
		_ring_dance(screen, event, animate)
	_refresh_stat_detail(screen, model, event)
	lanes.bindings = LaneProjection.playback(model)


## An inspected unit's exact stats follow playback until a new combat note replaces it.
static func _refresh_stat_detail(screen: Control, model: CombatModel, event: Dictionary) -> void:
	var rich: RichTextLabel = screen.get("_note_text")
	var selected: Dictionary = rich.get_meta("card_detail_view", {})
	var uid: int = Data.i(selected, "uid", -1)
	if uid < 0 or Data.i(event, "target", Data.i(event, "uid", -2)) != uid:
		return
	var current: Dictionary = model.unit(uid)
	if not current.is_empty():
		CardDetail.show_rules(
			rich, current, Data.i(current, "side", -1) == CoreUtil.to_int(screen.get("bottom_side"))
		)


## Hex stays on its enemy slot, including when playback is rebuilt or the occupant changes.
static func show_hex(screen: Control, event: Dictionary, _animate: bool) -> void:
	var board: BoardView = screen.call("board_for_side", Data.i(event, "side", 0))
	var slot: int = Data.i(event, "slot", 0)
	board.set_hex(slot, Data.i(event, "total", 0), Data.i(event, "percent", 0))


## A unit can gain permanent stats while its death animation is still visible.
static func card_for_uid(screen: Control, uid: int) -> CardView:
	var cards: Dictionary = screen.get("_cards")
	if cards.has(uid) and is_instance_valid(cards[uid]):
		return cards[uid]
	var fading: Array = screen.get("_dying")
	for entry: Variant in fading:
		if not is_instance_valid(entry) or not entry is CardView:
			continue
		var card: CardView = entry
		if card != null and card.uid() == uid:
			return card
	return null


## Finished death animations leave freed references until playback cleanup.
static func clear_dying_cards(screen: Control) -> void:
	var fading: Array = screen.get("_dying")
	for entry: Variant in fading:
		if not is_instance_valid(entry) or not entry is CardView:
			continue
		var card: CardView = entry
		if card != null:
			card.queue_free()
	fading.clear()


static func sync_bog_state(card: CardView, view: Dictionary) -> void:
	card.set_pending_gains(Data.i(view, "pending_attack"), Data.i(view, "pending_health"))
	if view.has("bog_kiss_period"):
		card.set_kisses(
			Data.i(view, "kisses", Data.i(Data.d(view, "counters"), "kisses")),
			Data.i(view, "bog_kiss_period")
		)


static func bog_summary(model: CombatModel, side: int) -> String:
	return (
		"\nBog Toll: %s" % StatNumbers.exact(model.bog_toll[side])
		if model.bog_toll.has(side)
		else ""
	)


static func reset_floor_state(screen: Control) -> void:
	var initial: Array = screen.get("floor_marks")
	var copied: Array = initial.duplicate(true)
	screen.set_meta("ring_floor_state", copied)
	for side: int in 2:
		var board: BoardView = screen.call("board_for_side", side)
		var row: Array = copied[side] if side < copied.size() and copied[side] is Array else []
		if board != null:
			board.set_marks(row)


static func floor_state(screen: Control) -> Array:
	if not screen.has_meta("ring_floor_state"):
		reset_floor_state(screen)
	var current: Array = screen.get_meta("ring_floor_state")
	return current


static func _ring_dance(screen: Control, event: Dictionary, animate: bool) -> void:
	if not event.has("from_ring") or not event.has("to_ring"):
		return  # Historical event streams did not record exact Ring cohorts.
	var side: int = Data.i(event, "side")
	var from: int = Data.i(event, "from", -1)
	var to: int = Data.i(event, "to", -1)
	if side < 0 or side > 1 or not BoardGeometry.is_valid(from) or not BoardGeometry.is_valid(to):
		return
	var current: Array = floor_state(screen).duplicate(true)
	while current.size() < 2:
		current.append([])
	var row: Array = current[side]
	while row.size() < BoardGeometry.SLOTS:
		row.append({})
	var destination_before: Dictionary = row[to]
	var had_destination: bool = Data.b(destination_before, "has_ring")
	for endpoint: String in ["from", "to"]:
		var slot: int = Data.i(event, endpoint)
		var state: Dictionary = Data.d(event, endpoint + "_ring")
		var mark: Dictionary = row[slot]
		var count: int = Data.i(state, "count")
		mark["has_ring"] = count > 0
		mark["ring_count"] = count
		mark["slot_attack"] = Data.i(state, "slot_attack", Data.i(state, "attack"))
		mark["slot_health"] = Data.i(state, "slot_health", Data.i(state, "health"))
		mark["ring"] = (
			(
				"%s/%s"
				% [
					StatNumbers.signed(Data.i(state, "attack")),
					StatNumbers.signed(Data.i(state, "health"))
				]
			)
			if count > 0
			else ""
		)
		if count > 0:
			mark["ring"] = Data.s(mark, "ring") + " · %d" % count
	screen.set_meta("ring_floor_state", current)
	var board: BoardView = screen.call("board_for_side", side)
	board.set_marks(row)
	if animate:
		var marks: Control = board.get("_marks")
		var overlay: Control = screen.get("_overlay")
		marks.call(
			"travel_ring",
			from,
			to,
			overlay,
			Callable(screen, "_tween"),
			not had_destination,
			Data.i(event, "moved_count", 1),
			CoreUtil.to_float(screen.get("speed"))
		)
