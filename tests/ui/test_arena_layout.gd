extends GutTest
## Phase changes preserve the formation, object size, and live purchasing context.

const Card := preload("res://src/ui/widgets/card_view.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const Fixture := preload("res://src/ui/adapter/fixture_port.gd")
const Recruit := preload("res://src/ui/screens/recruit_screen.gd")
const Views := preload("res://src/ui/unit_views.gd")
const UNIT := Vector2(176, 226)


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
	for card: Card in board.get("cards"):
		if card != null:
			assert_eq(card.card_size, UNIT, "the same unit object size in every formation")
			assert_eq(
				card.get_global_rect().size, UNIT, "parent transforms never shrink a formation unit"
			)
			found += 1
	assert_gt(found, 0, "size checks exercise occupied units")


func test_own_formation_is_identical_in_recruit_scout_and_fight_at_both_sizes() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var recruit: Recruit = _recruit(viewport)
		await wait_process_frames(2)
		var own: Control = recruit.get("_board")
		var initial: Rect2 = own.get_global_rect()
		var frame := Rect2((viewport.size.x - 820.0) / 2.0, 554, 820, 510)
		assert_true(frame.encloses(initial), "the lab formation fits its fixed lower surface")
		assert_almost_eq(initial.get_center().x, viewport.size.x / 2.0, 0.01)
		assert_almost_eq(initial.get_center().y, 809.0, 0.01)
		_assert_unit_sizes(own)
		recruit.toggle_scout()
		await wait_process_frames(2)
		assert_eq(own.get_global_rect(), initial, "scouting swaps only the upper zone")
		var scout: Control = recruit.get("_scout")
		var theirs: Control = scout.get("_board")
		assert_eq(theirs.size, own.size)
		assert_almost_eq(theirs.get_global_rect().get_center().x, initial.get_center().x, 0.01)
		assert_almost_eq(theirs.get_global_rect().get_center().y, 271.0, 0.01)
		_assert_unit_sizes(theirs)
		recruit.hide()
		var standings: Array = recruit.state["standings"]
		var fight: CombatScreen = _fight(viewport, standings)
		await wait_process_frames(2)
		assert_eq(
			fight.board_for_side(0).get_global_rect(), initial, "fight uses the recruit anchor"
		)
		assert_eq(fight.board_for_side(1).get_global_rect(), theirs.get_global_rect())
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
		var tray: Control = screen.get("_hand_cards")
		var cards: Array[Card] = tray.get("cards")
		assert_eq(cards.size(), 4, "hand_items share the four-card tray with units")
		for index: int in cards.size():
			var card: Card = cards[index]
			assert_eq(card.card_size, UNIT)
			assert_eq(card.get_global_rect().size, UNIT, "shop and hand retain full displayed size")
			assert_true(hand.get_global_rect().encloses(card.get_global_rect()))
			for other: int in range(index + 1, cards.size()):
				assert_false(card.get_global_rect().intersects(cards[other].get_global_rect()))
		assert_eq(cards[0].position.y, cards[1].position.y, "two tiles across")
		assert_eq(cards[2].position.y, cards[3].position.y)
		assert_gt(cards[2].position.y, cards[0].position.y, "two rows")
		var own: Control = screen.get("_board")
		assert_lte(hand.get_global_rect().end.x, own.get_global_rect().position.x)
		if phone:
			var first: Card = cards[0]
			var physical: Vector2 = first.get_global_rect().size * 780.0 / viewport.size.y
			assert_almost_eq(physical.x, 127.11, 0.01)
			assert_almost_eq(physical.y, 163.22, 0.01)


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


func test_fight_standings_scouting_preserves_own_board_and_restores_playback() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var recruit: Recruit = _recruit(viewport)
		recruit.hide()
		var standings: Array = recruit.state["standings"]
		var fight: CombatScreen = _fight(viewport, standings)
		await wait_process_frames(2)
		var own: Control = fight.board_for_side(0)
		var enemy: Control = fight.board_for_side(1)
		var own_rect: Rect2 = own.get_global_rect()
		var enemy_rect: Rect2 = enemy.get_global_rect()
		var enemy_card: Card = enemy.get("cards")[0]
		fight.scout_provider = func(player_id: int) -> Dictionary:
			return {
				"board": [_unit(901)],
				"name": "Scouted player",
				"standing": {"player_id": player_id, "health": 21}
			}
		var strip: Control = fight.get("_lobby")
		strip.emit_signal("scout_requested", 1)
		await wait_process_frames(2)
		var scouted: Control = fight.get("_scout_board")
		assert_true(scouted.is_visible_in_tree(), "the standings selection opens scouting")
		assert_false(enemy.is_visible_in_tree())
		assert_true(own.is_visible_in_tree())
		assert_eq(own.get_global_rect(), own_rect)
		assert_eq(scouted.get_global_rect(), enemy_rect)
		_assert_unit_sizes(scouted)
		assert_false(fight.playing, "scouting pauses the fight")
		var scout_controller: RefCounted = fight.get("_scout")
		scout_controller.call("_show_detail", 0)
		await wait_process_frames(2)
		var reader: Control = fight.get("_reader")
		assert_true(reader.visible)
		assert_false(reader.get_global_rect().intersects(own_rect))
		var source: Card = scouted.get("cards")[0]
		assert_false(reader.get_global_rect().intersects(source.get_global_rect()))
		fight.close_scout()
		await wait_process_frames(2)
		assert_false(scouted.is_visible_in_tree())
		assert_true(enemy.is_visible_in_tree())
		var restored_cards: Array[Card] = enemy.get("cards")
		assert_eq(restored_cards[0], enemy_card, "the live fight formation survives scouting")
		assert_eq(own.get_global_rect(), own_rect)
		assert_true(fight.playing, "closing scouting resumes the previously running fight")


func _assert_empty_slot_targets(board: Control, active: bool) -> void:
	var slots: Array = board.get("slots")
	assert_eq(slots.size(), 7, "exercise every empty formation cell")
	for slot: Control in slots:
		var highlight: Color = slot.get("highlight")
		assert_eq(highlight.a > 0.0, active, "drop targets appear only during a drag")


func test_hand_reader_keeps_empty_slots_quiet_until_drag_and_clears_targets_on_drag_end() -> void:
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
		assert_true(reader.visible, "the hand card remains readable without lighting empty cells")
		_assert_empty_slot_targets(board, false)
		screen._on_drag_started("hand", 0)
		var pocket: Control = screen.get("_drop_pocket")
		assert_true(pocket.is_visible_in_tree(), "the drag presents its real drop indicator")
		_assert_empty_slot_targets(board, true)
		screen.notification(Control.NOTIFICATION_DRAG_END)
		await wait_process_frames(2)
		_assert_empty_slot_targets(board, false)
		assert_true(reader.visible, "cancelling a drag preserves the selected card reader")


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


func test_gears_and_fight_tools_are_quiet_icons_clear_of_turn() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var recruit: Recruit = _recruit(viewport)
		await wait_process_frames(2)
		var gear: Control = recruit.get("_menu_token")
		var turn: Control = recruit.get("_round_label")
		assert_true(turn.is_visible_in_tree())
		assert_false(gear.get_global_rect().intersects(turn.get_global_rect()))
		var glyph: Control = gear.get("_glyph")
		assert_lte(glyph.get_global_rect().size.x, 32.0, "the gear draws as a small icon")
		assert_gte(gear.size.x, 122.0 if phone else 88.0, "the quiet icon keeps its input target")
		recruit.hide()
		var fight_standings: Array = recruit.state["standings"]
		var fight: CombatScreen = _fight(viewport, fight_standings)
		await wait_process_frames(2)
		turn = fight.get("_round_label")
		assert_true(turn.is_visible_in_tree())
		var row_y: float = -1.0
		for key: String in [
			"_gear", "_step_button", "_play_button", "_skip_button", "_speed_button"
		]:
			var button: Control = fight.get(key)
			glyph = button.get("_glyph")
			assert_true(CoreUtil.to_bool(button.get("quiet")))
			assert_lte(glyph.get_global_rect().size.x, 32.0, key + " stays visually quiet")
			assert_false(button.get_global_rect().intersects(turn.get_global_rect()), key)
			assert_gte(button.size.x, 122.0 if phone else 88.0)
			if row_y >= 0.0:
				assert_eq(button.position.y, row_y, "the fight tools form a slim row")
			row_y = button.position.y


func test_market_surface_fits_its_offers_and_control_row() -> void:
	for phone: bool in [false, true]:
		var screen: Recruit = _recruit(_viewport(phone))
		await wait_process_frames(2)
		var market: Control = screen.get("_shop_zone")
		var offers: Control = screen.get("_shop_cards")
		var controls: Control = screen.get("_market_controls")
		var market_box: Rect2 = market.get_global_rect()
		assert_lt(
			market_box.size.y,
			510.0,
			"the recruit market no longer fills a fight formation's height"
		)
		assert_true(market_box.encloses(offers.get_global_rect()))
		assert_true(market_box.encloses(controls.get_global_rect()))
		var gap: float = controls.get_global_rect().position.y - offers.get_global_rect().end.y
		assert_gte(gap, 0.0, "buttons never cover the offers")
		assert_lte(gap, 12.0, "the control row follows the offers without empty wood")
		assert_lte(market_box.end.y - controls.get_global_rect().end.y, 16.0)
