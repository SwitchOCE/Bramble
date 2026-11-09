extends RefCounted
## Extra combat feedback lives here to keep the playback screen small.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const Data := preload("res://src/ui/view_data.gd")
const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")


static func present(screen: Control, event: Dictionary, animate: bool) -> void:
	var lanes: LaneOverlay = screen.get("_lanes")
	var model: CombatModel = screen.get("model")
	_refresh_stat_detail(screen, model, event)
	lanes.bindings = LaneProjection.playback(model)
	match Data.s(event, "type"):
		"combat_start":
			screen.set("_mouse_no_room_shown", false)
			lanes.pack.clear()
		"phase", "combat_end":
			lanes.pack.clear()
		"bog_patch":
			screen.call("_float_chip", Data.i(event, "maker"), "Mire", UiTheme.MOSS, animate)
		"no_room":
			if (
				Data.s(event, "mechanic") == "mice"
				and animate
				and not screen.get("_mouse_no_room_shown")
			):
				screen.set("_mouse_no_room_shown", true)
				screen.call("_say", "Mousewife: no room for a Mouse", animate)
		"quarry_marked":
			screen.call("_float_chip", Data.i(event, "quarry"), "Marked", UiTheme.ACORN, animate)
		"take":
			screen.call("_float_chip", Data.i(event, "hunter"), "Take!", UiTheme.ACORN, animate)
		"poach":
			screen.call(
				"_float_chip", Data.i(event, "hunter"), "Poach claim", UiTheme.ACORN, animate
			)
		"immediate_attack":
			var word: String = "Pounce!" if Data.s(event, "kind") == "pounce" else "Counter!"
			screen.call("_float_chip", Data.i(event, "attacker"), word, UiTheme.ACORN, animate)
		"kiss":
			screen.call(
				"_float_chip",
				Data.i(event, "target"),
				"Kiss %d/3" % Data.i(event, "count"),
				UiTheme.ACORN,
				animate
			)
		"transform":
			screen.call("_sync_all")
			screen.call("_float_chip", Data.i(event, "target"), "A prince!", UiTheme.ACORN, animate)
		"attack":
			lanes.pack.clear()
			if Data.b(event, "pack"):
				var group: Array = [Data.i(event, "attacker")]
				group.append_array(Data.a(event, "joiners"))
				for uid: int in group:
					var unit: Dictionary = model.unit(uid)
					lanes.pack.append({"side": Data.i(unit, "side"), "slot": Data.i(unit, "slot")})
				screen.call(
					"_float_chip", Data.i(event, "attacker"), "Pack!", UiTheme.ACORN, animate
				)


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
static func show_hex(screen: Control, event: Dictionary, animate: bool) -> void:
	var board: BoardView = screen.call("board_for_side", Data.i(event, "side", 0))
	var slot: int = Data.i(event, "slot", 0)
	board.set_hex(slot, Data.i(event, "total", 0), Data.i(event, "percent", 0))
	if animate:
		screen.call("_float_at", board.slot_global_center(slot), "Hex!", UiTheme.BIRCH)
