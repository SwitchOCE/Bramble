extends "res://tests/ui/shots/screenshot.gd"
## Review-only replacement of visible sample portraits on an otherwise real recruit screen.
## UNIT_ART_STYLE=v2|v2b BACKDROP=<painting> scripts/godot_slot.sh xvfb-run -a godot
## --rendering-driver opengl3 -s tools/render_unit_art_recruit.gd -- recruit 1920x1080 out.png

const ReviewCard := preload("res://src/ui/widgets/card_view.gd")
const PortraitReview := preload("res://tools/render_unit_art.gd")

var _replaced: Dictionary[String, int] = {}


func _shoot(window_size: Vector2i, out_path: String) -> void:
	var style: String = OS.get_environment("UNIT_ART_STYLE")
	if style not in ["v2", "v2b"]:
		printerr("UNIT_ART_STYLE must be v2 or v2b")
		quit(2)
		return
	# Let initial layout settle before replacing art; model data and rules stay untouched.
	for frame: int in 20:
		await process_frame
	if not _replace_portraits(root, style) or _replaced.is_empty():
		printerr("review: could not substitute sample portraits")
		quit(2)
		return
	print("review portraits %s: %s" % [style, _replaced])
	await super._shoot(window_size, out_path)


func _replace_portraits(parent: Node, style: String) -> bool:
	for node: Node in parent.get_children():
		if node is ReviewCard:
			var card: ReviewCard = node as ReviewCard
			var id: String = str(card.unit.get("portrait_id", card.unit.get("def_id", "")))
			if card.is_visible_in_tree() and id in PortraitReview.IDS:
				var path: String = "res://assets/portraits_%s/%s.jpg" % [style, id]
				var portrait := Image.load_from_file(ProjectSettings.globalize_path(path))
				if portrait == null:
					printerr("missing sample: ", path)
					return false
				card._art.texture = ImageTexture.create_from_image(portrait)
				_replaced[id] = _replaced.get(id, 0) + 1
		if not _replace_portraits(node, style):
			return false
	return true
