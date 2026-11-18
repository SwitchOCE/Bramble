extends Control
## Real shop hover states for screenshots at both target window sizes.
const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
var screen: RecruitScreen
var most_details: int = 0


func _ready() -> void:
	screen = SCREEN.instantiate()
	var state: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	var mode: String = OS.get_environment("BRAMBLE_KEYWORD_SHOT")
	var content: GameContent = GameContent.load_default()
	state["display"] = content.display_table()
	if mode == "grenadier":
		state["shop_units"][2] = ViewAdapter.card_from_id(
			content, content.new_session(3), "grenadier-guard"
		)
	screen.state = state
	add_child(screen)
	screen.settle()
	if mode != "":
		await get_tree().process_frame
		await get_tree().process_frame
		var card: Control = screen.node_for("shop", 2)
		var at: Vector2 = card.position + card.size / 2.0
		if mode == "icon":
			at = _point(card.get_node("Pill_1") as KeywordMark)
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = screen._stage.get_global_transform_with_canvas() * at
		get_viewport().push_input(motion, true)
		var output: String = OS.get_environment("BRAMBLE_KEYWORD_OUT")
		if output != "":
			screen.process_mode = Node.PROCESS_MODE_DISABLED
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			# Capture the window's full display, including the aspect-fit pixel at 1366x768.
			var captured: Image = DisplayServer.screen_get_image(0)
			assert(captured.save_png(output) == OK)
			print(
				"keyword shot: ",
				output,
				" ",
				captured.get_size(),
				" panes=",
				screen._tips.details.size()
			)
			get_tree().quit()


func _process(_delta: float) -> void:
	if screen != null and screen._tips != null:
		most_details = maxi(most_details, screen._tips.details.size())


func _point(mark: KeywordMark) -> Vector2:
	return (
		screen._stage.get_global_transform().affine_inverse()
		* (mark.get_global_transform() * (mark.size / 2.0))
	)


func feel_point(target: String) -> Variant:
	var card: Control = screen.node_for("shop", 2)
	if target == "card":
		return card.position + card.size / 2.0
	if target == "icon":
		return _point(card.get_node("Pill_1") as KeywordMark)
	return null


func feel_report() -> Dictionary:
	return {"most_details": most_details, "visible": screen._tips.tip.visible}
