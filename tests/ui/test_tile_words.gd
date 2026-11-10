extends GutTest
## Text-node word audit, separate from the unchanged all-visible-label budget.

const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const TileStates := preload("res://tests/ui/shots/declutter_tile_states.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const HandFan := preload("res://src/ui/widgets/hand_fan.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")

var _captures: Array[Dictionary] = []
var _roster: Dictionary = {}
var _fan_state: Dictionary = {}


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func after_all() -> void:
	var output: String = OS.get_environment("BRAMBLE_TILE_WORDS")
	if output.is_empty():
		output = "res://build/declutter/b2-tests/tile-words-run.json"
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	assert_not_null(file, "word-audit evidence is writable")
	if file != null:
		file.store_string(
			JSON.stringify(
				{"schema": 1, "captures": _captures, "roster": _roster, "fan10_state": _fan_state},
				"\t",
				true,
				true
			)
		)
		file.close()


func _screen(state: Dictionary, pixels: Vector2i) -> RecruitScreen:
	CardView.window_override = Vector2(pixels)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(1080.0 * pixels.x / pixels.y), 1080)
	add_child_autofree(viewport)
	var port := FixturePort.new()
	port.set("_state", state.duplicate(true))
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	screen.set_meta("evidence_pixels", [pixels.x, pixels.y])
	return screen


func _record(screen: RecruitScreen, scenario: String, legacy: bool = false) -> void:
	var before: Array[Dictionary] = Capture.text_nodes(screen)
	var report: Dictionary = Capture.tile_words(screen)
	report["scenario"] = scenario
	report["pixels"] = screen.get_meta("evidence_pixels")
	report["legacy_fixture"] = legacy
	report["reader_open"] = scenario.begins_with("reader-")
	report["raw_visible_text_count"] = before.size()
	report["state_sha256"] = JSON.stringify(screen.port.get_state(), "", true, true).sha256_text()
	_captures.append(report)
	assert_eq(Capture.text_nodes(screen), before, "the word audit cannot alter raw label counting")
	assert_eq(
		CoreUtil.to_int(report["unexpected_word_count"]),
		0,
		"%s: %s" % [scenario, JSON.stringify(report["words"])]
	)
	if not legacy:
		assert_eq(CoreUtil.to_int(report["word_count"]), 0, "current tile text has no words")
	print(
		(
			"declutter tile words: %s %s = %d, legacy=%d, unexpected=%d, rawlabels=%d"
			% [
				scenario,
				str(report["pixels"]),
				CoreUtil.to_int(report["word_count"]),
				CoreUtil.to_int(report["legacy_fallback_word_count"]),
				CoreUtil.to_int(report["unexpected_word_count"]),
				before.size(),
			]
		)
	)


func test_word_tokens_keep_words_and_slot_tags_but_not_stat_numbers() -> void:
	assert_eq(
		Capture.word_tokens("Pass right +1/+1. Touching F1 Reel-Mistress O’Moss"),
		PackedStringArray(["Pass", "right", "Touching", "F1", "Reel-Mistress", "O’Moss"])
	)
	assert_eq(Capture.word_tokens("0 3/4 +1 −2 9.5k .1m 2b ×1.25"), PackedStringArray())
	assert_eq(Capture.word_tokens("3 turns"), PackedStringArray(["turns"]))


func test_tile_ownership_includes_strips_and_rejects_a_new_word_without_counting_hud_or_reader(
) -> void:
	var holder := Control.new()
	add_child_autofree(holder)
	var card := CardView.new()
	card.zone = "shop"
	holder.add_child(card)
	card.show_unit({"def_id": "one_swallow", "attack": 3, "health": 4}, CardView.Mode.SHOP)
	var hud := Label.new()
	hud.text = "HUD words"
	holder.add_child(hud)
	var reader := CardDetail.new()
	holder.add_child(reader)
	reader.show_unit({"name": "Reader name", "text": "Reader rules", "kind": "spell"})
	var clean: Dictionary = Capture.tile_words(holder)
	assert_eq(CoreUtil.to_int(clean["word_count"]), 0)
	var rule: Label = card.get("_attack_label")
	rule.text = "Pass right +1/+1."
	rule.visible = true
	var changed: Dictionary = Capture.tile_words(holder)
	assert_eq(CoreUtil.to_int(changed["unexpected_word_count"]), 2)
	assert_false(CoreUtil.to_int(changed["unexpected_word_count"]) == 0, "new words fail the gate")
	var board := BoardView.new()
	board.configure("board", 209, true)
	holder.add_child(board)
	var strips: Array = board.get("_labels")
	var names: Array = board.get("_label_names")
	var strip: Control = strips[0]
	var caption: Label = names[0]
	caption.text = "Unit name"
	strip.show()
	var with_strip: Dictionary = Capture.tile_words(holder)
	var zones: Dictionary = with_strip["zone_counts"]
	assert_eq(CoreUtil.to_int(zones["own_board"]), 3, "F1 and both name words count on strips")
	assert_eq(CoreUtil.to_int(with_strip["unexpected_word_count"]), 5)


func test_five_packet_states_and_the_full_hand_have_zero_tile_words_at_both_sizes() -> void:
	var states: Dictionary = FixturePort.load_json(
		"res://docs/ideation/evidence/declutter/batch2/states.json"
	)
	var overview: Dictionary = states["overview"]
	var overview_state: Dictionary = overview["state"]
	_fan_state = TileStates.fan10(overview_state)
	for scenario: String in [
		"overview", "natural-birds", "lobby", "scout", "reader-reel_mistress-golden", "fan10"
	]:
		var state: Dictionary = _fan_state
		if scenario != "fan10":
			var evidence: Dictionary = states[scenario]
			state = evidence["state"]
		for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
			var screen: RecruitScreen = _screen(state, pixels)
			if scenario == "scout":
				screen.toggle_scout()
			elif scenario == "reader-reel_mistress-golden":
				var hand: Array = screen.state["hand"]
				for index: int in hand.size():
					var view: Dictionary = hand[index]
					if str(view.get("def_id", "")) == "reel_mistress":
						screen._on_tapped("hand", index)
			await wait_process_frames(3)
			_record(screen, scenario)
			if scenario == "fan10":
				var fan: HandFan = screen.get("_hand_cards")
				assert_eq(
					fan.cards.size(), 10, "all ten real hand tiles participate in the word audit"
				)
				for card: CardView in fan.cards:
					assert_true(card.is_visible_in_tree())


func test_legacy_missing_portrait_names_are_reported_and_still_count() -> void:
	var state: Dictionary = FixturePort.load_json("res://tests/ui/data/recruit_slice.json")
	for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
		var screen: RecruitScreen = _screen(state, pixels)
		await wait_process_frames(3)
		_record(screen, "legacy-slice-recruit", true)
		assert_gt(CoreUtil.to_int(Capture.tile_words(screen)["legacy_fallback_word_count"]), 0)
		screen.toggle_scout()
		await wait_process_frames(3)
		_record(screen, "legacy-slice-scout", true)
		assert_gt(CoreUtil.to_int(Capture.tile_words(screen)["legacy_fallback_word_count"]), 0)


func test_all_shipped_units_are_wordless_in_each_tile_zone() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var checked: int = 0
	var found: Array[Dictionary] = []
	for definition: Dictionary in library.all_units():
		if str(definition.get("set", "")) != GameConfig.full_game().card_set():
			continue
		var card := CardView.new()
		add_child_autofree(card)
		for golden: bool in [false, true]:
			for zone: String in ["shop", "hand", "board", "scout"]:
				card.zone = zone
				var mode: CardView.Mode = CardView.Mode.BOARD
				if zone == "shop":
					mode = CardView.Mode.SHOP
				elif zone == "hand":
					mode = CardView.Mode.MINI
				card.show_unit(UnitViews.from_def(definition, golden), mode)
				var report: Dictionary = Capture.tile_words(card)
				var words: Array = report["words"]
				for word: Dictionary in words:
					found.append(word)
				assert_eq(
					CoreUtil.to_int(report["word_count"]), 0, str(definition["id"]) + ": " + zone
				)
		checked += 1
	assert_gt(checked, 100, "the whole shipped roster is visited")
	_roster = {
		"unit_count": checked,
		"zone_count": 4,
		"variant_count": 2,
		"word_count": found.size(),
		"words": found
	}


func test_hand_overlap_exception_keeps_other_zones_fonts_taps_and_bounds_checked() -> void:
	var holder := Control.new()
	add_child_autofree(holder)
	var fan := HandFan.new()
	fan.size = Vector2(400, 400)
	holder.add_child(fan)
	var cards: Array[CardView] = []
	for index: int in 2:
		var card := CardView.new()
		card.zone = "hand"
		card.index = index
		card.show_unit({"def_id": "one_swallow", "attack": 3, "health": 4}, CardView.Mode.BOARD)
		card.set_card_width(130)
		fan.add_card(card)
		cards.append(card)
	cards[1].position = cards[0].position
	var siblings: PackedStringArray = LayoutCheck.problems(holder, "intentional hand overlap")
	assert_false("\n".join(siblings).contains("cards overlap"))
	var outsider := CardView.new()
	outsider.zone = "shop"
	outsider.show_unit({"def_id": "one_swallow", "attack": 3, "health": 4}, CardView.Mode.BOARD)
	outsider.set_card_width(130)
	holder.add_child(outsider)
	outsider.position = cards[0].global_position
	assert_string_contains("\n".join(LayoutCheck.problems(holder, "cross zone")), "cards overlap")
	var health: Label = cards[0].get("_health_label")
	health.add_theme_font_size_override("font_size", 4)
	assert_string_contains("\n".join(LayoutCheck.problems(holder, "font retained")), "text 4 under")
	cards[0].set_card_size(Vector2(40, 40))
	assert_string_contains("\n".join(LayoutCheck.problems(holder, "tap retained")), "tap target")
	cards[0].position = Vector2(-200, -200)
	assert_string_contains(
		"\n".join(LayoutCheck.problems(holder, "bounds retained")), "leaves the window"
	)
