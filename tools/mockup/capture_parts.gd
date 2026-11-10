extends "res://tests/ui/shots/screenshot.gd"
## Dev-only: run the build-8 screenshot states, then capture their actual widgets on alpha.
## No shipped scene is changed. See README.md for the slotted invocation.

const MockCard := preload("res://src/ui/widgets/card_view.gd")
const MockDetail := preload("res://src/ui/widgets/card_detail.gd")
const MockViews := preload("res://src/ui/unit_views.gd")
const MockTheme := preload("res://src/ui/ui_theme.gd")
const MockBoard := preload("res://src/ui/widgets/board_view.gd")

var _capture_dir: String
var _capture_view: SubViewport
var _capture_host: Control
var _capture_manifest: Dictionary = {}


func _shoot(_window_size: Vector2i, out_path: String) -> void:
	_capture_dir = out_path
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	var source_app: App = root.get_child(0) as App
	var screen: Control = source_app.current
	if screen is CombatScreen:
		(screen as CombatScreen).playing = false
		for tween: Tween in get_processed_tweens():
			tween.pause()
	source_app.process_mode = Node.PROCESS_MODE_DISABLED
	for frame: int in 3:
		await process_frame
	_capture_view = SubViewport.new()
	_capture_view.transparent_bg = true
	_capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_capture_view)
	_capture_host = Control.new()
	_capture_host.theme = MockTheme.get_theme()
	_capture_view.add_child(_capture_host)
	if screen is RecruitScreen:
		await _recruit_parts(screen as RecruitScreen, source_app)
	else:
		await _fight_parts(screen as CombatScreen)
	var manifest_file: FileAccess = FileAccess.open(_capture_dir.path_join("parts.json"), FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(_capture_manifest, "\t"))
	print("mockup: exported %d real widgets to %s" % [_capture_manifest.size(), _capture_dir])
	quit(0)


func _card_part(key: String, original: MockCard, mode: MockCard.Mode) -> void:
	var card: MockCard = MockCard.new()
	card.show_unit(original.unit.duplicate(true), mode)
	card.combat_face = original.combat_face
	card.outline = original.outline
	card.set_card_size(Vector2(240, 264 if mode == MockCard.Mode.SHOP else 220))
	await _part(key, card, card.card_size, false)
	_capture_manifest[key]["unit"] = original.unit


func _part(key: String, widget: Control, dimensions: Vector2, move_original: bool = true) -> void:
	var previous: Node = widget.get_parent()
	var previous_position: Vector2 = widget.position
	var previous_size: Vector2 = widget.size
	if move_original and previous != null:
		previous.remove_child(widget)
	_capture_host.add_child(widget)
	widget.set_anchors_preset(Control.PRESET_TOP_LEFT)
	widget.position = Vector2(32, 32)
	widget.rotation = 0
	widget.scale = Vector2.ONE
	widget.size = dimensions
	widget.show()
	_capture_view.size = Vector2i(dimensions.ceil()) + Vector2i(64, 64)
	_capture_host.size = Vector2(_capture_view.size)
	for frame: int in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var captured: Image = _capture_view.get_texture().get_image()
	var path: String = _capture_dir.path_join(key + ".png")
	assert(captured.save_png(path) == OK)
	_capture_manifest[key] = {"file": key + ".png", "size": dimensions, "padding": 32}
	_capture_host.remove_child(widget)
	if move_original and previous != null:
		previous.add_child(widget)
		widget.position = previous_position
		widget.size = previous_size
	else:
		widget.queue_free()


func _recruit_parts(screen: RecruitScreen, source_app: App) -> void:
	var shop: Array[MockCard] = []
	for child: Node in screen._shop_cards.get_children():
		if child is MockCard:
			shop.append(child as MockCard)
	var unit_index: int = 0
	var spell_index: int = 0
	for card: MockCard in shop:
		if MockCard.is_spell(card.unit):
			await _card_part("spell_%d" % spell_index, card, MockCard.Mode.SHOP)
			spell_index += 1
		else:
			await _card_part("shop_%d" % unit_index, card, MockCard.Mode.SHOP)
			unit_index += 1
	# The old deterministic state has only three offers. Fill the requested five-unit shop with
	# actual pool definitions rendered through the same widget; this is a staged visual proposal.
	var pool_ids: PackedStringArray = ["field_vole", "mr_crumb", "garden_snail", "chiffchaff", "mrs_jay"]
	var pool: CorePort = source_app.port as CorePort
	while unit_index < 5:
		var extra: MockCard = MockCard.new()
		extra.show_unit(MockViews.from_def(pool.library.get_unit(pool_ids[unit_index])), MockCard.Mode.SHOP)
		await _card_part("shop_%d" % unit_index, extra, MockCard.Mode.SHOP)
		extra.free()
		unit_index += 1
	for slot: int in screen._board.cards.size():
		var card: MockCard = screen._board.cards[slot]
		if card != null:
			await _card_part("board_%d" % slot, card, MockCard.Mode.BOARD)
	for index: int in screen._hand_cards.cards.size():
		await _card_part("hand_%d" % index, screen._hand_cards.cards[index], MockCard.Mode.BOARD)
	for index: int in screen._lobby.plaques.size():
		await _part("lobby_%d" % index, screen._lobby.plaques[index], Vector2(140, 94))
	await _part("gold", screen._gold, Vector2(430, 152))
	await _part("hero", screen._hero, Vector2(140, 240))
	await _part("tier", screen._tier_label, Vector2(100, 54))
	await _part("round", screen._round_label, Vector2(180, 54))
	await _part("tier_up", screen._tier_button, Vector2(240, 100))
	await _part("refresh", screen._refresh_button, Vector2(180, 100))
	await _part("freeze", screen._freeze_button, Vector2(180, 100))
	screen._end_button.set_label_size(36)
	await _part("end_turn", screen._end_button, Vector2(260, 110))
	await _part("gear", screen._menu_token, Vector2(88, 96))
	var reader: MockDetail = MockDetail.new()
	reader.show_unit(screen._board.cards[1].unit)
	await _part("reader", reader, Vector2(500, 740), false)


func _fight_parts(screen: CombatScreen) -> void:
	_capture_manifest["event_index"] = screen.next_index
	for side: int in screen._boards.size():
		var board: MockBoard = screen._boards[side]
		for slot: int in board.cards.size():
			var card: MockCard = board.cards[slot]
			if card != null:
				await _card_part("side_%d_slot_%d" % [side, slot], card, MockCard.Mode.BOARD)
				if card == screen._cards.get(screen._attacker_uid):
					_capture_manifest["attacker_key"] = "side_%d_slot_%d" % [side, slot]
		var model_side: int = screen.bottom_side if side == 1 else 1 - screen.bottom_side
		await _part("hero_%d" % side, screen._plaques[model_side], Vector2(150, 165))
	await _part("pause", screen._play_button, Vector2(88, 96))
	await _part("speed", screen._speed_button, Vector2(88, 96))
	await _part("step", screen._step_button, Vector2(88, 96))
	await _part("gear", screen._gear, Vector2(88, 96))
