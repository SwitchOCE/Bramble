extends GutTest
## Phase changes preserve the formation and object size; scouting returns to the market to buy.

const Card := preload("res://src/ui/widgets/card_view.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Fixture := preload("res://src/ui/adapter/fixture_port.gd")
const Recruit := preload("res://src/ui/screens/recruit_screen.gd")
const Views := preload("res://src/ui/unit_views.gd")
const Arena := preload("res://src/ui/arena_geometry.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const UNIT := Arena.UNIT


func after_each() -> void:
	Card.window_override = Vector2.ZERO


func _viewport(phone: bool) -> SubViewport:
	Card.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080) if phone else Vector2i(1920, 1080)
	add_child_autofree(viewport)
	return viewport


func _unit(uid: int = 1) -> Dictionary:
	var view: Dictionary = Views.from_def(TestLibraries.current().get_unit("old_moth_annis"))
	view["uid"] = uid
	view["iid"] = uid
	return view


func _spell() -> Dictionary:
	return {"name": "Acorn", "kind": "spell", "def_id": "acorn", "text": "Gain 1 gold.", "cost": 1}


func _recruit(viewport: SubViewport) -> Recruit:
	var port := Fixture.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var raw: Dictionary = port.get_state()
	raw["hand_limit"] = 4
	raw["hand"] = [_unit(801), _unit(802)]
	raw["hand_items"] = [_spell(), _spell()]
	var offers: Array = []
	var unit_counts: Array = GameConfig.full_game().get_value("shop_units_by_tier")
	var spell_counts: Array = GameConfig.full_game().get_value("shop_spells_by_tier")
	for index: int in CoreUtil.to_int(unit_counts.max()):
		offers.append(_unit(101 + index))
	raw["shop"] = offers
	raw["shop_size"] = offers.size()
	var spells: Array = []
	for index: int in CoreUtil.to_int(spell_counts.max()):
		spells.append(_spell())
	raw["shop_spells"] = spells
	var screen := Recruit.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


func _fight(viewport: SubViewport, standings: Array) -> CombatScreen:
	var screen := CombatScreen.new()
	screen.manual_playback = true
	screen.auto_return = false
	viewport.add_child(screen)
	screen.setup({"events": []}, PackedStringArray(["You", "Opponent"]), 0, "Turn 6", 30)
	var boards: Array[Array] = [[], []]
	for side: int in 2:
		for slot: int in 7:
			boards[side].append(_unit(side * 7 + slot + 1))
	screen._play_event(
		{"type": "combat_start", "boards": boards, "first_side": 0, "player_ids": [0, 1]}, false
	)
	screen.set_standings(standings, 1)
	return screen


func _assert_unit_sizes(board: Control) -> void:
	var found: int = 0
	var cards: Array[Card] = board.get("cards")
	for card: Card in board.get("cards"):
		if card != null:
			assert_eq(card.card_size, UNIT, "the same unit object size in every formation")
			assert_eq(
				card.get_global_rect().size, UNIT, "parent transforms never shrink a formation unit"
			)
			found += 1
	assert_gt(found, 0, "size checks exercise occupied units")
	for index: int in cards.size():
		if cards[index] == null:
			continue
		for other: int in range(index + 1, cards.size()):
			if cards[other] != null:
				assert_almost_eq(
					LayoutCheck._shared_face_area(cards[index], cards[other]),
					0.0,
					0.01,
					"formation hex faces never overlap"
				)


func test_own_formation_is_identical_in_recruit_scout_and_fight_at_both_sizes() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var recruit: Recruit = _recruit(viewport)
		await wait_process_frames(2)
		var own: Control = recruit.get("_board")
		var initial: Rect2 = own.get_global_rect()
		var frame: Rect2 = Arena.board_rect(Vector2(viewport.size))
		assert_true(frame.encloses(initial), "the lab formation fits its fixed lower surface")
		assert_almost_eq(initial.get_center().x, viewport.size.x / 2.0, 0.01)
		assert_almost_eq(initial.get_center().y, frame.get_center().y, 0.01)
		_assert_unit_sizes(own)
		recruit.toggle_scout()
		await wait_process_frames(2)
		assert_eq(own.get_global_rect(), initial, "scouting swaps only the upper zone")
		var scout: Control = recruit.get("_scout")
		var theirs: Control = scout.get("_board")
		assert_eq(theirs.size, own.size)
		assert_almost_eq(theirs.get_global_rect().get_center().x, initial.get_center().x, 0.01)
		assert_almost_eq(
			theirs.get_global_rect().get_center().y,
			Arena.board_rect(Vector2(viewport.size), true).get_center().y,
			0.01
		)
		_assert_unit_sizes(theirs)
		recruit.hide()
		var standings: Array = recruit.state["standings"]
		var fight: CombatScreen = _fight(viewport, standings)
		await wait_process_frames(2)
		assert_eq(
			fight.board_for_side(0).get_global_rect(), initial, "fight uses the recruit anchor"
		)
		assert_almost_eq(
			fight.board_for_side(1).global_position, theirs.global_position, Vector2.ONE * 0.01
		)
		assert_almost_eq(fight.board_for_side(1).size, theirs.size, Vector2.ONE * 0.01)
		_assert_unit_sizes(fight.board_for_side(0))
		_assert_unit_sizes(fight.board_for_side(1))


func test_maximum_market_and_four_mixed_hand_tiles_keep_the_same_full_size() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var screen: Recruit = _recruit(viewport)
		await wait_process_frames(2)
		var market: Control = screen.get("_shop_zone")
		var shop: Control = screen.get("_shop_cards")
		assert_eq(shop.get_child_count(), 7, "configured maximum is six units and one spell")
		for card: Card in shop.get_children():
			assert_eq(card.card_size, UNIT)
			assert_eq(card.get_global_rect().size, UNIT, "shop and hand retain full displayed size")
			assert_true(market.get_global_rect().encloses(card.get_global_rect()))
		var hand: Control = screen.get("_hand_zone")
		assert_eq(hand.get_global_rect(), Arena.hand_rect(Vector2(viewport.size)))
		assert_true(viewport.get_visible_rect().encloses(hand.get_global_rect()))
		var tray: Control = screen.get("_hand_cards")
		var cards: Array[Card] = tray.get("cards")
		assert_eq(cards.size(), 4, "hand_items share the four-card tray with units")
		for index: int in cards.size():
			var card: Card = cards[index]
			assert_eq(card.card_size, UNIT)
			assert_eq(card.get_global_rect().size, UNIT, "shop and hand retain full displayed size")
			assert_true(hand.get_global_rect().encloses(card.get_global_rect()))
			assert_true(
				viewport.get_visible_rect().encloses(card.get_global_rect()), "whole hand tile fits"
			)
			for other: int in range(index + 1, cards.size()):
				assert_almost_eq(
					LayoutCheck._shared_face_area(card, cards[other]),
					0.0,
					0.01,
					"hand faces never overlap"
				)
		assert_eq(cards[0].position.y, cards[1].position.y, "two tiles across")
		assert_eq(cards[2].position.y, cards[3].position.y)
		assert_gt(cards[2].position.y, cards[0].position.y, "two rows")
		var own: Control = screen.get("_board")
		assert_lte(hand.get_global_rect().end.x, own.get_global_rect().position.x)
		if phone:
			var first: Card = cards[0]
			var physical: Vector2 = first.get_global_rect().size * 780.0 / viewport.size.y
			assert_eq(physical, UNIT * 780.0 / viewport.size.y)
			assert_gt(
				physical.x, 176.0 * 780.0 / 1080.0, "phone tiles are larger than the old units"
			)


func test_market_controls_are_inside_market_and_reader_clears_source_and_purchasing() -> void:
	for phone: bool in [false, true]:
		var screen: Recruit = _recruit(_viewport(phone))
		await wait_process_frames(2)
		var market: Control = screen.get("_shop_zone")
		for key: String in ["_gold", "_tier_button", "_refresh_button", "_freeze_button"]:
			var control: Control = screen.get(key)
			assert_true(control.is_visible_in_tree())
			assert_true(market.get_global_rect().encloses(control.get_global_rect()), key)
		for zone: String in ["shop", "hand", "board"]:
			screen._on_tapped("table", -1)
			screen._on_tapped(zone, 0)
			await wait_process_frames(2)
			var reader: Control = screen.get("_detail")
			assert_true(reader.visible)
			assert_true(screen.get_viewport_rect().encloses(reader.get_global_rect()))
			var source: Control = screen._card_at(zone, 0)
			assert_false(reader.get_global_rect().intersects(source.get_global_rect()), zone)
			var own: Control = screen.get("_board")
			assert_false(reader.get_global_rect().intersects(own.get_global_rect()))
			for key: String in [
				"_gold", "_tier_button", "_refresh_button", "_freeze_button", "_end_button"
			]:
				var control: Control = screen.get(key)
				assert_false(reader.get_global_rect().intersects(control.get_global_rect()), key)


func _assert_strip(screen: Control) -> void:
	var strip: Control = screen.get("_lobby")
	assert_true(strip.is_visible_in_tree())
	var seats: Array[Control] = strip.get("plaques")
	assert_gt(seats.size(), 1)
	var bounds: Rect2 = seats[0].get_global_rect()
	for index: int in seats.size():
		var seat: Control = seats[index]
		var rect: Rect2 = seat.get_global_rect()
		bounds = bounds.merge(rect)
		assert_true(screen.get_viewport_rect().encloses(rect))
		assert_eq(rect.size.x, 122.0, "standings stay a slim portrait strip with full tap seats")
		assert_gte(rect.size.y, 122.0, "each seat retains the game phone tap minimum")
		assert_gte(rect.size.x * Card.window_override.y / 1080.0, 44.0, "phone tap width")
		assert_gte(rect.size.y * Card.window_override.y / 1080.0, 44.0, "phone tap height")
		for other: int in range(index + 1, seats.size()):
			assert_false(rect.intersects(seats[other].get_global_rect()))
	assert_almost_eq(bounds.get_center().y, 540.0, 0.01, "seats centre top to bottom")
	assert_lte(screen.get_viewport_rect().end.x - bounds.end.x, 24.0, "right edge")


func test_standings_remain_a_centred_right_portrait_strip_in_recruit_and_fight() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var recruit: Recruit = _recruit(viewport)
		await wait_process_frames(2)
		_assert_strip(recruit)
		recruit.hide()
		var standings: Array = recruit.state["standings"]
		var fight: CombatScreen = _fight(viewport, standings)
		await wait_process_frames(2)
		_assert_strip(fight)


func test_fight_standings_are_display_only_and_keep_the_supplied_health() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var standings: Array = [
			{"player_id": 0, "is_human": true, "health": 38, "alive": true},
			{"player_id": 1, "health": 21, "alive": true},
		]
		var fight: CombatScreen = _fight(viewport, standings)
		await wait_process_frames(2)
		var own: Control = fight.board_for_side(0)
		var enemy: Control = fight.board_for_side(1)
		var own_rect: Rect2 = own.get_global_rect()
		var enemy_card: Card = enemy.get("cards")[0]
		var strip: Control = fight.get("_lobby")
		var requests: Array = []
		strip.connect("scout_requested", func(id: int) -> void: requests.append(id))
		strip.connect("hero_requested", func(view: Dictionary) -> void: requests.append(view))
		for plaque: Control in strip.get("plaques"):
			var tap: Control = plaque.get("tap")
			assert_eq(tap.mouse_filter, Control.MOUSE_FILTER_IGNORE)
			assert_eq(tap.tooltip_text, "")
			plaque.call("_on_tapped", "lobby", 1)
			plaque.call("_on_hovered", "lobby", 1, true)
			var standing: Dictionary = plaque.get("_standing")
			if CoreUtil.to_int(standing["player_id"]) == 1:
				var hip: Control = plaque.get("_hip")
				assert_eq((hip.get_child(0) as Label).text, "21")
		assert_true(requests.is_empty(), "fight seats never open scouting or live hero details")
		assert_true(fight.playing)
		assert_true(enemy.is_visible_in_tree())
		var enemy_cards: Array[Card] = enemy.get("cards")
		assert_eq(enemy_cards[0], enemy_card)
		assert_eq(own.get_global_rect(), own_rect)
		var reader: Control = fight.get("_reader")
		assert_false(reader.visible)


func test_scout_hides_offer_actions_and_return_restores_market_header_and_controls() -> void:
	for phone: bool in [false, true]:
		var screen: Recruit = _recruit(_viewport(phone))
		var before: Dictionary = screen.port.get_state().duplicate(true)
		var tier: Label = screen.get("_tier_label")
		var market: Control = screen.get("_shop_zone")
		assert_eq(tier.text, "TIER %d" % CoreUtil.to_int(before["tier"]))
		assert_true(market.get_global_rect().encloses(tier.get_global_rect()))
		screen.scout_player(CoreUtil.to_int(before["next_opponent_id"]))
		await wait_process_frames(2)
		for key: String in ["_shop_cards", "_refresh_button", "_freeze_button", "_kin_button"]:
			var control: Control = screen.get(key)
			assert_false(control.is_visible_in_tree(), key)
		var gold: Control = screen.get("_gold")
		assert_true(gold.is_visible_in_tree())
		var scout: Control = screen.get("_scout")
		var nameplate: Label = scout.get("_title")
		assert_true(nameplate.is_visible_in_tree())
		assert_true(nameplate.has_theme_stylebox_override("normal"))
		assert_false(nameplate.text.is_empty())
		var back: Button = screen.get("_market_return")
		back.pressed.emit()
		await wait_process_frames(2)
		assert_eq(screen.port.get_state(), before)
		for key: String in ["_shop_cards", "_refresh_button", "_freeze_button"]:
			var control: Control = screen.get(key)
			assert_true(control.is_visible_in_tree(), key)
		assert_true(market.get_global_rect().encloses(tier.get_global_rect()))


func _assert_empty_slot_targets(board: Control, active: bool) -> void:
	var slots: Array = board.get("slots")
	assert_eq(slots.size(), 7, "exercise every empty formation cell")
	for slot: Control in slots:
		var highlight: Color = slot.get("highlight")
		assert_eq(highlight.a > 0.0, active, "legal targets track hand selection and dragging")


func test_hand_selection_and_drag_show_targets_and_cancel_keeps_empty_slots_quiet() -> void:
	for phone: bool in [false, true]:
		var screen: Recruit = _recruit(_viewport(phone))
		var formation: Array = screen.port.get_state()["board"]
		formation.fill(null)
		screen.render()
		await wait_process_frames(2)
		var board: Control = screen.get("_board")
		_assert_empty_slot_targets(board, false)
		screen._on_tapped("hand", 0)
		await wait_process_frames(2)
		var reader: Control = screen.get("_detail")
		assert_true(reader.visible, "the selected hand card remains readable")
		_assert_empty_slot_targets(board, true)
		screen._on_tapped("table", -1)
		_assert_empty_slot_targets(board, false)
		screen._on_tapped("hand", 0)
		screen._on_drag_started("hand", 0)
		var pocket: Control = screen.get("_drop_pocket")
		assert_true(pocket.is_visible_in_tree(), "the drag presents its real drop indicator")
		_assert_empty_slot_targets(board, true)
		screen.notification(Control.NOTIFICATION_DRAG_END)
		await wait_process_frames(2)
		_assert_empty_slot_targets(board, true)
		assert_true(reader.visible, "cancelling a drag preserves the selected card reader")
		screen._on_tapped("table", -1)
		_assert_empty_slot_targets(board, false)
		screen._on_drag_started("hand", 0)
		_assert_empty_slot_targets(board, true)
		screen.notification(Control.NOTIFICATION_DRAG_END)
		await wait_process_frames(2)
		_assert_empty_slot_targets(board, false)


func test_scout_bare_slot_reader_uses_selected_players_ring_snapshot() -> void:
	var screen: Recruit = _recruit(_viewport(false))
	screen.state["next_opponent_last_slot_effects"] = [
		[{"name": "Ring", "attack": 2, "health": 3, "count": 1}]
	]
	screen.set(
		"_scout_snapshot",
		{"slot_effects": [[{"name": "Ring", "attack": 7, "health": 9, "count": 1}]]}
	)
	screen.call("_show_their_bare_slot", 0)
	var reader: Control = screen.get("_detail")
	var shown: Dictionary = reader.get("shown")
	assert_string_contains(str(shown["text"]), "+7/+9")
	assert_false(str(shown["text"]).contains("+2/+3"), "another player's Ring is never substituted")


func test_knocked_out_hero_health_stays_zero_and_fits_its_badge() -> void:
	var viewport: SubViewport = _viewport(false)
	var fight: CombatScreen = _fight(viewport, [])
	fight.hero_health = [40, 3]
	fight.hero_health_after = [40, -17]
	fight._play_event(
		{"type": "combat_end", "winner": 0, "damage": 20, "survivors": [[], []]}, true
	)
	for frame: int in 60:
		fight.advance_playback(1.0 / 60.0)
	var labels: Array[Label] = fight.get("_health_labels")
	assert_eq(labels[1].text, "0", "post-fight overkill never overflows the hero's Health badge")


func test_ghost_scout_keeps_its_identity_in_the_reader() -> void:
	var screen: Recruit = _recruit(_viewport(false))
	var raw: Dictionary = screen.port.get_state()
	raw["next_opponent_id"] = -1
	raw["next_opponent_hero"] = null
	raw["standings"] = [
		{"player_id": 0, "is_human": true, "alive": true, "health": 30},
		{"player_id": 7, "alive": false, "health": 0, "placement": 8, "hero": "Brother Bracken"},
	]
	screen.render()
	var lobby: Control = screen.get("_lobby")
	var plaques: Array = lobby.get("plaques")
	for plaque: Control in plaques:
		if CoreUtil.to_bool(plaque.get("is_ghost")):
			plaque.call("_on_tapped", "lobby", 7)
	assert_eq(
		CoreUtil.to_int(screen.get("_scout_player_id")), -1, "the ghost seat requests its snapshot"
	)
	var reader: Control = screen.get("_detail")
	var shown: Dictionary = reader.get("shown")
	assert_true(reader.visible)
	assert_true(
		(str(shown.get("name", "")) + str(shown.get("text", ""))).to_lower().contains("ghost")
	)


func _assert_cream_glyph(button: Control) -> void:
	var glyph: TextureRect = button.get("_glyph")
	var picture: Image = glyph.texture.get_image()
	var color_sum := Vector3.ZERO
	var painted: int = 0
	for y: int in picture.get_height():
		for x: int in picture.get_width():
			var pixel: Color = picture.get_pixel(x, y)
			if pixel.a > 0.8:
				color_sum += Vector3(pixel.r, pixel.g, pixel.b)
				painted += 1
	assert_gt(painted, 0, "every tool has a visible glyph")
	var average: Vector3 = color_sum / maxi(painted, 1)
	assert_gt(average.x, 0.8, "tool ink stays cream against the dark strip")
	assert_gt(average.y, 0.8)
	assert_gt(average.z, 0.7)


func test_gears_and_fight_tools_are_quiet_icons_clear_of_turn() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var recruit: Recruit = _recruit(viewport)
		await wait_process_frames(2)
		var gear: Control = recruit.get("_menu_token")
		var turn: Control = recruit.get("_round_label")
		assert_true(turn.is_visible_in_tree())
		assert_false(gear.get_global_rect().intersects(turn.get_global_rect()))
		_assert_cream_glyph(gear)
		var glyph: Control = gear.get("_glyph")
		assert_lte(glyph.get_global_rect().size.x, 32.0, "the gear draws as a small icon")
		assert_gte(gear.size.x, 122.0 if phone else 88.0, "the quiet icon keeps its input target")
		recruit.hide()
		var fight_standings: Array = recruit.state["standings"]
		var fight: CombatScreen = _fight(viewport, fight_standings)
		await wait_process_frames(2)
		turn = fight.get("_round_label")
		assert_true(turn.is_visible_in_tree())
		var strip: Panel = fight.get("_tools_strip")
		assert_true(strip.is_visible_in_tree())
		var row_y: float = -1.0
		for key: String in [
			"_gear", "_step_button", "_play_button", "_skip_button", "_speed_button"
		]:
			var button: Control = fight.get(key)
			_assert_cream_glyph(button)
			glyph = button.get("_glyph")
			assert_true(strip.get_global_rect().encloses(glyph.get_global_rect()))
			assert_true(CoreUtil.to_bool(button.get("quiet")))
			assert_lte(glyph.get_global_rect().size.x, 32.0, key + " stays visually quiet")
			assert_false(button.get_global_rect().intersects(turn.get_global_rect()), key)
			assert_gte(button.size.x, 122.0 if phone else 88.0)
			if row_y >= 0.0:
				assert_eq(button.position.y, row_y, "the fight tools form a slim row")
			row_y = button.position.y

		for speed: float in [1.0, 2.0, 4.0]:
			fight.set_speed(speed)
			var speed_button: Control = fight.get("_speed_button")
			_assert_cream_glyph(speed_button)


func test_market_surface_fits_its_offers_and_control_row() -> void:
	for phone: bool in [false, true]:
		var screen: Recruit = _recruit(_viewport(phone))
		await wait_process_frames(2)
		var market: Control = screen.get("_shop_zone")
		var offers: Control = screen.get("_shop_cards")
		var controls: Control = screen.get("_market_controls")
		var market_box: Rect2 = market.get_global_rect()
		var canvas: Vector2 = screen.get_viewport_rect().size
		assert_eq(market_box, Arena.market_rect(canvas))
		var seam: float = Arena.board_rect(canvas).position.y - market_box.end.y
		assert_gte(seam, 0.0, "market never covers the stationary formation")
		assert_lte(seam, 16.0, "market meets the own board without an empty band")
		assert_true(market_box.encloses(offers.get_global_rect()))
		assert_true(market_box.encloses(controls.get_global_rect()))
		var gap: float = controls.get_global_rect().position.y - offers.get_global_rect().end.y
		assert_gte(gap, 0.0, "buttons never cover the offers")
		assert_lte(gap, 12.0, "the control row follows the offers without empty wood")
		assert_lte(market_box.end.y - controls.get_global_rect().end.y, 16.0)
