extends GutTest
## Phone regressions: birds away keep the shop controls, long sell help fits the detail panel,
## opposing scout columns line up, and slot marks leave the board's captions readable.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const PHONE_CANVAS: Vector2i = Vector2i(2337, 1080)


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _phone() -> SubViewport:
	CardView.window_override = Vector2(1688, 780)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = PHONE_CANVAS
	add_child_autofree(viewport)
	return viewport


func _screen(viewport: SubViewport) -> RecruitScreen:
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var screen: RecruitScreen = RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


## Actions can be below or beside the reader. Compare their real global boxes in either case.
func _assert_reader_actions_clear(detail: CardDetail, context: String) -> void:
	var notes: RichTextLabel = detail.get("_notes")
	var notes_rect: Rect2 = notes.get_global_rect()
	assert_true(detail.get_global_rect().encloses(notes_rect), context + ": rules stay in reader")
	assert_false(
		notes_rect.intersects(detail.actions.get_global_rect()), context + ": rules clear actions"
	)
	for child: Node in detail.actions.get_children():
		var button: Control = child as Control
		assert_true(
			detail.get_viewport_rect().encloses(button.get_global_rect()),
			context + ": each action fits on screen"
		)
		assert_false(notes_rect.intersects(button.get_global_rect()), context + ": clear button")


func test_birds_away_leave_gold_tier_and_refresh_available_until_a_nest_is_tapped() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var state: Dictionary = screen.port.get_state()
	state["away"] = [{"name": "Old Tern", "turns_left": 3, "nest": 2}]
	screen.render()
	await get_tree().process_frame
	for key: String in ["_gold", "_tier_button", "_refresh_button", "_freeze_button"]:
		var control: Control = screen.get(key)
		assert_true(control.is_visible_in_tree(), key)
	var detail: CardDetail = screen.get("_detail")
	assert_false(detail.visible)
	screen.call("_on_tapped", "board", 2)
	assert_true(detail.visible, "the Nest still opens its full explanation")
	assert_string_contains(str(detail.shown["text"]), "Old Tern comes home in 3 turns")


func test_long_bird_and_belly_help_fit_above_the_actions() -> void:
	var viewport: SubViewport = _phone()
	var detail: CardDetail = CardDetail.new()
	detail.theme = UiTheme.get_theme()
	detail.position = Vector2(1800, 112)
	detail.size = Vector2(442, 747)
	viewport.add_child(detail)
	for hint: String in [
		"Flies for no sale gold. It comes home in 3 turns.",
		"Tap a slot to play it, or an Ooze to swallow it",
	]:
		detail.clear_actions()
		detail.show_unit(
			{"name": "Mrs Jay", "def_id": "mrs_jay", "kind": "unit", "text": "Fly South."}, hint
		)
		detail.add_action("Sell for good", func() -> void: pass, 1)
		detail.add_action("Into a Belly", func() -> void: pass)
		await get_tree().process_frame
		var help: Label = detail.get("_hint")
		assert_false(help.visible, "action instructions belong in the tutorial")
		_assert_reader_actions_clear(detail, "stacked reader actions")
		assert_eq(LayoutCheck.problems(detail, "phone detail"), PackedStringArray())


func test_phone_scout_columns_match_and_shop_returns_unchanged_after_focus() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var before: Dictionary = screen.port.get_state().duplicate(true)
	screen.toggle_scout()
	await get_tree().process_frame
	var own: BoardView = screen.get("_board")
	var scout: Control = screen.get("_scout")
	var theirs: BoardView = scout.get("_board")
	for slot: int in BoardView.SLOTS:
		assert_almost_eq(
			own.slot_global_center(slot).x,
			theirs.slot_global_center(slot).x,
			0.1,
			"opposing slot %d" % slot
		)
	var shop: Control = screen.get("_shop_cards")
	assert_false(shop.is_visible_in_tree(), "scout focus collapses the shop")
	assert_false(theirs.get_global_rect().intersects(own.get_global_rect()))
	assert_eq(LayoutCheck.problems(screen, "phone scouting"), PackedStringArray())
	screen.toggle_scout()
	await get_tree().process_frame
	assert_true(shop.is_visible_in_tree(), "closing scout restores the shop")
	assert_eq(screen.port.get_state(), before, "focus changes no game state")


func test_nests_and_rings_keep_floor_state_without_slot_codes_or_captions() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	raw["away"] = [{"name": "Old Tern", "turns_left": 3, "nest": 2}]
	screen.render()
	await get_tree().process_frame
	var board: BoardView = screen.get("_board")
	var marks: Control = board.get("_marks")
	var nests: Array = marks.get("_nest_labels")
	var rings: Array = marks.get("_ring_labels")
	var nest: Label = nests[2]
	var ring: Label = rings[0]
	assert_false(nest.visible, "countdown lives on the away token")
	assert_false(ring.visible, "one Ring needs dots only")
	for chip: Label in board.get("_chips"):
		assert_false(chip.visible)
	assert_true(board.slots[2].filled, "the Nest still changes the empty pocket")
	raw["next_opponent_last_nests"] = [0, 5]
	screen.toggle_scout()
	await get_tree().process_frame
	assert_eq(LayoutCheck.problems(screen, "wordless Nest and Ring"), PackedStringArray())


func test_selected_bird_keeps_economy_visible_and_shows_every_rule_and_hint_line() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	var units: Array = raw["board"]
	var library: UnitLibrary = TestLibraries.current()
	var bird: Dictionary = UnitViews.from_def(library.get_unit("mrs_jay"))
	bird["played_round"] = 1
	units[0] = bird
	var ooze: Dictionary = units[1]
	ooze["belly"] = 1
	ooze["held"] = []
	var slot_effects: Array = raw["slot_effects"]
	slot_effects[1] = [{"attack": 2, "health": 2}]
	screen.render()
	screen.call("_on_tapped", "board", 0)
	await get_tree().process_frame
	await get_tree().process_frame
	var detail: CardDetail = screen.get("_detail")
	assert_true(detail.visible, "the bird is selected")
	assert_eq(str(detail.shown["def_id"]), "mrs_jay")
	assert_eq(detail.actions.get_child_count(), 2, "Fly south and Into a Belly both stay available")
	for key: String in [
		"_gold", "_tier_button", "_refresh_button", "_freeze_button", "_end_button"
	]:
		var control: Control = screen.get(key)
		assert_true(control.is_visible_in_tree(), key + " stays visible while reading the bird")
		assert_false(detail.get_global_rect().intersects(control.get_global_rect()), key)
	var notes: RichTextLabel = detail.get("_notes")
	var hint: Label = detail.get("_hint")
	assert_lte(float(notes.get_content_height()), notes.size.y, "the complete Fly South rules fit")
	assert_false(hint.visible, "the reader gives rules and numbered actions without instructions")
	_assert_reader_actions_clear(detail, "external phone action column")
	var board: BoardView = screen.get("_board")
	for slot: int in BoardView.SLOTS:
		assert_gte(board.slots[slot].size.x, 122.0, "slot %d remains finger sized" % slot)
		assert_gte(board.slots[slot].size.y, 122.0)
	assert_false(detail.get_global_rect().intersects(board.get_global_rect()))
	var marks: Control = board.get("_marks")
	var rings: Array = marks.get("_ring_labels")
	for slot: int in BoardView.SLOTS:
		var ring: Label = rings[slot]
		if not ring.visible or board.cards[slot] == null:
			continue
		var slip: Control = board.cards[slot].get("_turns")
		if slip != null and slip.visible:
			assert_false(ring.get_global_rect().intersects(slip.get_global_rect()))
	assert_eq(LayoutCheck.problems(screen, "selected phone bird"), PackedStringArray())


func test_scout_slot_labels_clear_every_stat_badge() -> void:
	var screen: RecruitScreen = _screen(_phone())
	screen.toggle_scout()
	await get_tree().process_frame
	var scout: Control = screen.get("_scout")
	var board: BoardView = scout.get("_board")
	var chips: Array = board.get("_chips")
	var own: Control = screen.get("_board")
	for slot: int in BoardView.SLOTS:
		var card: CardView = board.cards[slot]
		if card == null:
			continue
		var chip: Label = chips[slot]
		assert_false(chip.is_visible_in_tree(), "geometry needs no slot caption")
		for key: String in ["_attack_badge", "_health_badge"]:
			var badge: Control = card.get(key)
			assert_false(
				chip.get_global_rect().intersects(badge.get_global_rect()), "%d %s" % [slot, key]
			)
		assert_false(chip.get_global_rect().intersects(own.get_global_rect()))


func test_selected_phone_posset_counters_do_not_overlap() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	var units: Array = raw["board"]
	var library: UnitLibrary = TestLibraries.current()
	var posset: Dictionary = UnitViews.from_def(library.get_unit("mrs_posset"))
	posset["belly"] = 1
	posset["held"] = [UnitViews.from_def(library.get_unit("mrs_sorrel"))]
	units[0] = posset
	var bird: Dictionary = UnitViews.from_def(library.get_unit("mrs_jay"))
	bird["played_round"] = 1
	units[6] = bird
	var effects: Array = raw["slot_effects"]
	effects[0] = [{"attack": 2, "health": 2}]
	screen.render()
	screen.call("_on_tapped", "board", 6)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: BoardView = screen.get("_board")
	var card: CardView = board.cards[0]
	var face: Control = card.get("_combat_marks")
	var counter: Label = face.get("counter")
	assert_true(counter.visible)
	assert_eq(counter.text, "1", "held-unit count is the occupied glyph spot")
	var local_pip: Rect2 = face.get("_counter_rect")
	var pip: Rect2 = face.get_global_transform() * local_pip
	assert_true(card.get_global_rect().encloses(counter.get_global_rect()))
	assert_true(card.get_global_rect().encloses(pip), "the whole counter pip stays on its card")
	for key: String in ["_attack_badge", "_health_badge"]:
		var badge: Control = card.get(key)
		assert_false(counter.get_global_rect().intersects(badge.get_global_rect()), key)
		assert_false(pip.intersects(badge.get_global_rect()), key + " clears the whole pip")
	assert_eq(LayoutCheck.problems(screen, "selected phone cosmetics"), PackedStringArray())


func test_phone_scout_hero_name_lives_in_the_reader() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	var hero: Dictionary = raw["hero"]
	for words: String in ["Hob Mumblecrust", "Old Mother Mousewife"]:
		hero["name"] = words
		raw["next_opponent_hero"] = hero.duplicate(true)
		screen.render()
		var scout: Control = screen.get("_scout")
		if not scout.visible:
			screen.toggle_scout()
		screen.call("_show_opponent")
		await get_tree().process_frame
		var detail: CardDetail = screen.get("_detail")
		assert_eq(str(detail.shown["name"]), words, "the full identity remains readable")


func _set_shop_spell(raw: Dictionary) -> void:
	raw["shop_spells"] = [
		{"name": "Acorn", "kind": "spell", "def_id": "acorn", "text": "Gain 1 gold.", "cost": 1}
	]


func test_maximum_phone_shop_offers_remain_full_sized_while_the_reader_floats() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	var offers: Array = raw["shop"]
	while offers.size() < 6:
		var offer: Dictionary = offers[0]
		offers.append(offer.duplicate(true))
	raw["shop_size"] = 6
	_set_shop_spell(raw)
	screen.render()
	await get_tree().process_frame
	var shop: GridContainer = screen.get("_shop_cards")
	var before: Rect2 = shop.get_global_rect()
	screen.call("_on_tapped", "board", 0)
	await get_tree().process_frame
	await get_tree().process_frame
	var detail: Control = screen.get("_detail")
	assert_true(detail.visible)
	for child: Node in shop.get_children():
		var card: CardView = child as CardView
		assert_eq(card.card_size, Vector2(176, 226), "maximum market never shrinks offers")
	assert_eq(shop.get_child_count(), 7)
	assert_eq(shop.get_global_rect(), before, "reading a card never squeezes the merchant")


func test_late_scout_focus_restores_all_shop_offers_at_both_sizes() -> void:
	for dimensions: Vector2i in [Vector2i(1920, 1080), PHONE_CANVAS]:
		var viewport: SubViewport = _phone()
		viewport.size = dimensions
		if dimensions.x == 1920:
			CardView.window_override = Vector2(1920, 1080)
		var screen: RecruitScreen = _screen(viewport)
		var raw: Dictionary = screen.port.get_state()
		var offers: Array = raw["shop"]
		while offers.size() < 6:
			var offer: Dictionary = offers[0]
			offers.append(offer.duplicate(true))
		raw["shop_size"] = 6
		_set_shop_spell(raw)
		raw["frozen"] = true
		screen.render()
		var before: Dictionary = screen.port.get_state().duplicate(true)
		var board: Control = screen.get("_board")
		var own_rect: Rect2 = board.get_global_rect()
		screen.toggle_scout()
		screen.call("_on_tapped", "scout", 0)
		await get_tree().process_frame
		await get_tree().process_frame
		var shop: GridContainer = screen.get("_shop_cards")
		var scroll: ScrollContainer = screen.get("_shop_scroll")
		assert_false(shop.is_visible_in_tree(), "scout focus collapses all shop offers")
		assert_false(scroll.is_visible_in_tree(), "the old shop sidebar is collapsed")
		assert_eq(shop.get_child_count(), 7, "focus preserves six units and the spell")
		assert_eq(LayoutCheck.problems(screen, "late scout focus"), PackedStringArray())
		var back: Button = screen.get("_market_return")
		assert_true(back.is_visible_in_tree(), "scouting has an explicit route back to market")
		back.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		assert_eq(
			screen.port.get_state(),
			before,
			"scouting preserves gold, freeze and all buying context"
		)
		assert_eq(
			board.get_global_rect(), own_rect, "returning to market keeps the formation anchored"
		)
		assert_true(shop.is_visible_in_tree(), "closing focus restores shop decisions")
		assert_eq(shop.get_child_count(), 7)
		for child: Node in shop.get_children():
			var card: CardView = child as CardView
			assert_true(card.is_visible_in_tree())
			assert_eq(card.card_size, Vector2(176, 226), "restored offer keeps full unit size")
		assert_eq(LayoutCheck.problems(screen, "restored late shop"), PackedStringArray())


func test_phone_attack_order_guide_is_decorative_like_other_guide_boards() -> void:
	var guide: Control = preload("res://src/ui/screens/how_to_play.gd").new()
	_phone().add_child(guide)
	guide.set("page", 7)
	guide.call("_show_page")
	await get_tree().process_frame
	await get_tree().process_frame
	var demo: Control = guide.get("_demo")
	var boards: int = 0
	for child: Node in demo.get_children():
		if child is BoardView:
			boards += 1
			for pocket: Control in (child as BoardView).slots:
				assert_eq(pocket.mouse_filter, Control.MOUSE_FILTER_IGNORE)
			for card: CardView in (child as BoardView).cards:
				if card != null:
					assert_eq(card.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(boards, 1, "page 8 now teaches attack order on a single board")
	assert_eq(LayoutCheck.problems(guide, "phone attack order guide"), PackedStringArray())


func test_empty_world_slots_receive_real_viewport_taps() -> void:
	for pixels: Vector2 in [Vector2(1920, 1080), Vector2(1688, 780)]:
		CardView.window_override = pixels
		var viewport := SubViewport.new()
		viewport.size = Vector2i(roundi(1080 * pixels.x / pixels.y), 1080)
		viewport.gui_disable_input = false
		add_child_autofree(viewport)
		var screen: RecruitScreen = _screen(viewport)
		var board_state: Array = screen.port.get_state()["board"]
		board_state.fill(null)
		screen.render()
		await wait_process_frames(2)
		var board: BoardView = screen.get("_board")
		var received: Array[int] = []
		for slot: Control in board.slots:
			slot.connect("tapped", func(_zone: String, index: int) -> void: received.append(index))
		for index: int in BoardView.SLOTS:
			screen.call("_on_tapped", "shop", 0)
			var detail: CardDetail = screen.get("_detail")
			assert_true(detail.visible)
			assert_eq(
				detail._notes.mouse_filter, Control.MOUSE_FILTER_PASS, "selected rules retain links"
			)
			var target: Control = board.slots[index]
			var rect: Rect2 = target.get_global_rect()
			var at: Vector2 = rect.get_center()
			for fraction: Vector2 in [
				Vector2(0.5, 0.5),
				Vector2(0.2, 0.8),
				Vector2(0.8, 0.8),
				Vector2(0.5, 0.95),
				Vector2(0.1, 0.2),
				Vector2(0.9, 0.2)
			]:
				at = rect.position + rect.size * fraction
				var motion := InputEventMouseMotion.new()
				motion.position = at
				motion.global_position = at
				viewport.push_input(motion, true)
				if viewport.gui_get_hovered_control() == target:
					break
			for pressed: bool in [true, false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = pressed
				event.position = at
				event.global_position = at
				viewport.push_input(event, true)
		assert_eq(
			received,
			[0, 1, 2, 3, 4, 5, 6],
			"every quiet cell receives an exposed tap with a reader open"
		)


func test_pc_reader_leaves_occupied_rear_slots_fully_tappable() -> void:
	CardView.window_override = Vector2(1920, 1080)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.gui_disable_input = false
	add_child_autofree(viewport)
	var screen: RecruitScreen = _screen(viewport)
	var state: Dictionary = screen.port.get_state()
	var units: Array = state["board"]
	for index: int in BoardView.SLOTS:
		units[index] = UnitViews.from_def(TestLibraries.current().get_unit("old_moth_annis"))
	screen.render()
	await wait_process_frames(2)
	var board: BoardView = screen.get("_board")
	var detail: CardDetail = screen.get("_detail")
	var received: Array[int] = []
	for index: int in [5, 6]:
		board.cards[index].tapped.connect(func(_zone: String, at: int) -> void: received.append(at))
	# Retain the reported pointer origins and last attempted hit fraction as the table moves.
	for failure: Array in [
		[5, Vector2(627, 400)],
		[6, Vector2(1025, 400)],
	]:
		var index: int = failure[0]
		var card: CardView = board.cards[index]
		for at: Vector2 in [
			card.get_global_rect().get_center(),
			card.get_global_rect().position + card.size * Vector2(0.9, 0.2)
		]:
			var motion := InputEventMouseMotion.new()
			motion.position = failure[1]
			motion.global_position = failure[1]
			viewport.push_input(motion, true)
			screen.call("_read_external", board.cards[0].unit)
			await wait_process_frames(2)
			assert_true(detail.visible)
			assert_eq(detail._notes.mouse_filter, Control.MOUSE_FILTER_PASS)
			assert_true(card.get_global_rect().has_point(at), "the attempted point is on the unit")
			assert_false(
				detail.get_global_rect().intersects(card.get_global_rect()),
				"reading keeps the whole occupied rear slot visible"
			)
			motion.position = at
			motion.global_position = at
			viewport.push_input(motion, true)
			for pressed: bool in [true, false]:
				var event := InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.pressed = pressed
				event.position = at
				event.global_position = at
				viewport.push_input(event, true)
			assert_false(received.is_empty(), "the unit receives the tap, without an edge search")
			if not received.is_empty():
				assert_eq(received[received.size() - 1], index)
			received.clear()
			await wait_process_frames(2)


func test_tier_animation_anchor_stays_on_its_header_through_repeated_layouts() -> void:
	for pixels: Vector2 in [Vector2(1920, 1080), Vector2(1688, 780)]:
		var viewport: SubViewport = _phone()
		viewport.size = Vector2i(roundi(1080.0 * pixels.x / pixels.y), 1080)
		CardView.window_override = pixels
		var screen: RecruitScreen = _screen(viewport)
		await wait_process_frames(3)
		var icon: Control = screen.get("_tier_label")
		var market: Control = screen.get("_shop_zone")
		var original: Vector2 = icon.get_global_rect().get_center()
		for pass_index: int in 12:
			screen.call("_layout")
			assert_eq(
				icon.get_global_rect().get_center(),
				original,
				"layout never drifts the coin destination"
			)
			assert_true(
				market.get_global_rect().encloses(icon.get_global_rect()),
				"tier animation lands on the visible market header"
			)
