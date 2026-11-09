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


static func present(screen: Control, event: Dictionary, _animate: bool) -> void:
	var lanes: LaneOverlay = screen.get("_lanes")
	var model: CombatModel = screen.get("model")
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
