extends RefCounted
## Extra combat feedback lives here to keep the playback screen small.

const Data := preload("res://src/ui/view_data.gd")
const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")


static func present(screen: Control, event: Dictionary, animate: bool) -> void:
	var lanes: LaneOverlay = screen.get("_lanes")
	var model: CombatModel = screen.get("model")
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
	text.text = words
