extends GutTest

const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_long_shop_rules_keep_the_portrait_at_phone_and_desktop_sizes() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for window: Vector2 in [Vector2(1920, 1080), Vector2(1688, 780)]:
		CardView.window_override = window
		for id: String in ["hedge_witch", "sexton_beetle", "natterjack_chorus"]:
			var card: CardView = CardView.new()
			card.show_unit(UnitViews.from_def(library.get_unit(id)), CardView.Mode.SHOP)
			card.set_card_width(210.0)
			add_child_autofree(card)
			await wait_process_frames(1)
			var art: Control = card.get("_art")
			var name_label: Label = card.get("_name_label")
			var rules: Label = card.get("_rules")
			assert_true(art.visible, id)
			assert_gte(art.size.y, CardView.ART_MIN, id)
			assert_eq(name_label.get_visible_line_count(), name_label.get_line_count(), id)
			if rules.visible:
				assert_lte(name_label.position.y + name_label.size.y, rules.position.y, id)
			else:
				assert_false(card.chip_shown.is_empty(), id)


func test_fight_begins_with_wordless_start_of_combat_cue() -> void:
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	screen.manual_playback = true
	screen.setup({"events": []}, PackedStringArray(["You", "Opponent"]), 0, "Round 1")
	var overlay: Control = screen.get("_overlay")
	var before: int = overlay.get_child_count()
	screen._play_event({"type": "phase", "name": "start_of_combat"}, true)
	assert_gt(overlay.get_child_count(), before, "Start of Combat has a visual cue")
	assert_false(screen._log.visible, "the opening narration stays in Log")
	assert_false(screen._reader.visible, "no automatic reminder opens")


func test_default_play_text_shows_stable_handles_before_legacy_numbers() -> void:
	var lines: PackedStringArray = []
	PlayView._hand(
		{
			"hand":
			[{"iid": 123, "name": "Test unit", "attack": 1, "health": 2, "tribes": [], "tier": 1}],
			"hand_items": [],
			"hand_limit": 10
		},
		lines
	)
	assert_string_contains(lines[0], "play @handle")
	assert_true(lines[1].begins_with("  @123 "))


func test_mire_and_hex_slips_clear_slot_names_in_recruit_scout_and_guide() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for zone: String in ["board", "scout", "guide"]:
		var board: BoardView = BoardView.new()
		board.configure(zone, 130.0 if zone != "board" else 209.0, true, zone == "board")
		add_child_autofree(board)
		var overlay: LaneOverlay = LaneOverlay.new()
		overlay.boards = [board, board]
		add_child_autofree(overlay)
		for slot: int in BoardView.SLOTS:
			var card: CardView = CardView.new()
			card.show_unit(UnitViews.from_def(library.get_unit("field_vole")), CardView.Mode.BOARD)
			board.place_card(card, slot)
			board.set_hex(slot, 2)
		await wait_process_frames(1)
		var chips: Array[Label] = board.get("_chips")
		var marks: Control = board.get("_marks")
		var hexes: Dictionary = marks.get("_hex_labels")
		for slot: int in BoardView.SLOTS:
			var name_rect: Rect2 = (
				board.label_rect(slot) if zone == "board" else chips[slot].get_rect()
			)
			if zone == "scout":
				assert_true(
					overlay.patch_rect(0, slot).encloses(name_rect),
					"Mire replaces the scout caption"
				)
			else:
				assert_false(
					overlay.patch_rect(0, slot).intersects(name_rect), "%s %d Mire" % [zone, slot]
				)
			var hex_label: Label = hexes[slot]
			assert_false(hex_label.get_rect().intersects(name_rect), "%s %d Hex" % [zone, slot])
