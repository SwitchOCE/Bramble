extends "res://tests/ui/shots/screenshot.gd"
## Real rearranged build-8 nodes for the simplest recruit option, at both native sizes.
## The backdrop and table base are scripted in layouts.py; all readable UI is live Godot UI.

const LiveCard := preload("res://src/ui/widgets/card_view.gd")
const LiveTheme := preload("res://src/ui/ui_theme.gd")


func _shoot(window_size: Vector2i, out_path: String) -> void:
	var source_app: App = root.get_child(0) as App
	var screen: RecruitScreen = source_app.current as RecruitScreen
	source_app.process_mode = Node.PROCESS_MODE_DISABLED
	source_app.hide()
	var plan_path: String = OS.get_environment("LAYOUT_PLAN")
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	var asset_path: String = OS.get_environment("LAYOUT_ASSETS")
	var parts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(asset_path.path_join("recruit/parts.json")))
	root.content_scale_size = Vector2i.ZERO
	root.size = window_size
	var stage: Control = Control.new()
	stage.theme = LiveTheme.get_theme()
	var logical_size: Array = plan["logical_size"]
	stage.size = Vector2(_number(logical_size[0]), 1080)
	stage.scale = Vector2.ONE * (window_size.y / 1080.0)
	root.add_child(stage)
	var painting: Image = Image.new()
	assert(painting.load(plan_path.trim_suffix(".json") + "_base.png") == OK)
	var base: TextureRect = TextureRect.new()
	base.texture = ImageTexture.create_from_image(painting)
	base.size = stage.size
	stage.add_child(base)
	var widgets: Dictionary = {
		"gold": screen._gold, "hero": screen._hero, "tier": screen._tier_label,
		"round": screen._round_label, "tier_up": screen._tier_button,
		"refresh": screen._refresh_button, "freeze": screen._freeze_button,
		"end_turn": screen._end_button, "gear": screen._menu_token,
	}
	screen._end_button.set_label_size(36)
	for index: int in screen._lobby.plaques.size():
		widgets["lobby_%d" % index] = screen._lobby.plaques[index]
	for entry: Variant in plan["placements"]:
		var placement: Dictionary = entry
		var key: String = str(placement["key"])
		var native: Array = placement["native_size"]
		var dimensions: Vector2 = Vector2(_number(native[0]) - 64, _number(native[1]) - 64)
		var node: Control
		if key.begins_with("shop_") or key.begins_with("spell_") or key.begins_with("board_") or key.begins_with("hand_"):
			var card: LiveCard = LiveCard.new()
			var view: Dictionary = parts[key]["unit"]
			card.show_unit(view.duplicate(true), LiveCard.Mode.SHOP if key.begins_with("shop_") or key.begins_with("spell_") else LiveCard.Mode.BOARD)
			card.set_card_size(dimensions)
			node = card
		else:
			node = Data.control(widgets[key])
			node.get_parent().remove_child(node)
		stage.add_child(node)
		node.set_anchors_preset(Control.PRESET_TOP_LEFT)
		node.size = dimensions
		node.pivot_offset = Vector2.ZERO
		node.rotation = 0
		var ratio: float = _number(placement["ratio"])
		var xy: Array = placement["xy"]
		var crop: Array = placement["bbox"]
		node.position = Vector2(_number(xy[0]), _number(xy[1])) + Vector2(32 - _number(crop[0]), 32 - _number(crop[1])) * ratio
		node.scale = Vector2.ONE * ratio
		node.show()
	for frame: int in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var captured: Image = root.get_texture().get_image()
	assert(captured.get_size() == window_size)
	assert(captured.save_png(out_path) == OK)
	print("mockup: real nodes rearranged at %s: %s" % [window_size, out_path])
	quit(0)


func _number(value: Variant) -> float:
	if value is float:
		return value
	if value is int:
		var integer: int = value
		return float(integer)
	assert(false, "Expected a JSON number")
	return 0.0
