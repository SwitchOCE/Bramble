extends "res://tests/ui/shots/screenshot.gd"
## Review-only replacement of visible sample portraits on an otherwise real recruit screen.
## UNIT_ART_STYLE=v2|v2b|inkglow BACKDROP=<painting> scripts/godot_slot.sh xvfb-run -a godot
## --rendering-driver opengl3 -s tools/render_unit_art_recruit.gd -- recruit 1920x1080 out.png
## UNIT_ART_SHOWCASE=1 places all eight artworks over the first eight visible unit tiles.
## This changes only textures; log records the real unit -> review artwork mapping.
## UNIT_ART_ALL_ASSETS=1 also primes the review process's portrait cache for exact-ID
## hero, spell, item and tribe fallback replacements before the real UI is built.

const ReviewCard := preload("res://src/ui/widgets/card_view.gd")
const PortraitReview := preload("res://tools/render_unit_art.gd")
const ReviewTheme := preload("res://src/ui/ui_theme.gd")

var _replaced: Dictionary[String, int] = {}
var _showcase_index: int = 0


func _initialize() -> void:
	if OS.get_environment("UNIT_ART_ALL_ASSETS") == "1":
		var style: String = OS.get_environment("UNIT_ART_STYLE")
		if style not in ["v2", "v2b", "inkglow"]:
			printerr("invalid review art style")
			quit(2)
			return
		if not _cache_review_folder("res://assets/portraits_%s" % style, "res://assets/portraits"):
			quit(2)
			return
		if not _cache_review_folder(
			"res://assets/ui/portraits_%s" % style, "res://assets/ui/portraits"
		):
			quit(2)
			return
	super._initialize()


func _cache_review_folder(folder: String, original_folder: String) -> bool:
	if not DirAccess.dir_exists_absolute(folder):
		return true
	for file: String in DirAccess.get_files_at(folder):
		if file.get_extension().to_lower() != "jpg":
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(folder.path_join(file)))
		if image == null:
			printerr("missing review portrait: ", file)
			return false
		var original: String = original_folder.path_join(file)
		ReviewTheme._portrait_cache[original] = ImageTexture.create_from_image(image)
		print("review exact-ID cache: ", original)
	return true


func _shoot(window_size: Vector2i, out_path: String) -> void:
	var style: String = OS.get_environment("UNIT_ART_STYLE")
	if style not in ["v2", "v2b", "inkglow"]:
		printerr("UNIT_ART_STYLE must be v2, v2b or inkglow")
		quit(2)
		return
	# Let initial layout settle before replacing art; model data and rules stay untouched.
	for frame: int in 20:
		await process_frame
	if not _replace_portraits(root, style) or _replaced.is_empty():
		printerr("review: could not substitute sample portraits")
		quit(2)
		return
	if (
		OS.get_environment("UNIT_ART_SHOWCASE") == "1"
		and _showcase_index != PortraitReview.IDS.size()
	):
		printerr("review: not enough visible unit tiles for all eight artworks")
		quit(2)
		return
	print("review portraits %s: %s" % [style, _replaced])
	await super._shoot(window_size, out_path)


func _replace_portraits(parent: Node, style: String) -> bool:
	for node: Node in parent.get_children():
		if node is ReviewCard:
			var card: ReviewCard = node as ReviewCard
			var id: String = str(card.unit.get("portrait_id", card.unit.get("def_id", "")))
			var original_id: String = id
			var showcase: bool = OS.get_environment("UNIT_ART_SHOWCASE") == "1"
			if showcase:
				if not card.is_visible_in_tree() or id.is_empty() or ReviewCard.is_spell(card.unit):
					continue
				if _showcase_index >= PortraitReview.IDS.size():
					continue
				id = PortraitReview.IDS[_showcase_index]
			if card.is_visible_in_tree() and id in PortraitReview.IDS:
				var path: String = "res://assets/portraits_%s/%s.jpg" % [style, id]
				var portrait := Image.load_from_file(ProjectSettings.globalize_path(path))
				if portrait == null:
					printerr("missing sample: ", path)
					return false
				card._art.texture = ImageTexture.create_from_image(portrait)
				_replaced[id] = _replaced.get(id, 0) + 1
				if showcase:
					print("review texture only: %s -> %s" % [original_id, id])
					_showcase_index += 1
		if not _replace_portraits(node, style):
			return false
	return true
