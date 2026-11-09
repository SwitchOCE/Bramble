extends RefCounted
## Extra combat feedback lives here to keep the playback screen small.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
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
	lanes.pack.clear()


static func show_note(screen: Control, keyword: String, words: String) -> void:
	var head: Label = screen.get("_note_head")
	var icon: TextureRect = screen.get("_note_icon")
	var text: RichTextLabel = screen.get("_note_text")
	head.text = keyword.to_upper()
	icon.visible = keyword == "Nightshade"
	head.position.x = 82.0 if icon.visible else 28.0
	text.remove_meta("card_detail_view")
	text.text = words


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
