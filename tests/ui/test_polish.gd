extends GutTest
## What the first playtest round tripped over (docs/ideation/evidence/playtest-1.md) stays fixed:
## names, ghosts, triples, ids in logs, scouting, tile tags, game over, guide wording, round tokens.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const HowToPlay := preload("res://src/ui/screens/how_to_play.gd")
const LobbyStrip := preload("res://src/ui/widgets/lobby_strip.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardPicker := preload("res://src/ui/widgets/card_picker.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const PlayerDriver := preload("res://tests/ui/player_driver.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const ReminderSlip := preload("res://src/ui/widgets/reminder_slip.gd")
const Records := preload("res://src/ui/records.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")

const RAW_ID: String = "\\b[a-z]+_[a-z_]+\\b"


func before_all() -> void:
	Records.path = "user://test_records.cfg"


func _slice_screen() -> RecruitScreen:
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	return screen


func _ghost_state() -> Dictionary:
	return {
		"next_opponent_id": -1,
		"standings":
		[
			{"player_id": 0, "name": "You", "is_human": true, "alive": true},
			{"player_id": 1, "name": "Bot 1 (x)", "hero": "Pipkin", "alive": false, "placement": 7},
			{"player_id": 2, "name": "Bot 2 (x)", "hero": "Hob", "alive": false, "placement": 6},
			{"player_id": 3, "name": "Bot 3 (x)", "hero": "Wren", "alive": true},
		],
	}


func test_a_bot_is_called_by_its_hero_and_you_stay_you() -> void:
	assert_eq(UiTheme.player_name({"name": "Bot 3 (wide)", "hero": "Pipkin"}), "Pipkin")
	assert_eq(UiTheme.player_name({"name": "Bot 3 (wide)", "hero": ""}), "Choosing a hero")
	assert_eq(UiTheme.player_name({"name": "You", "is_human": true, "hero": "Pipkin"}), "You")
	assert_eq(UiTheme.player_name({"name": "Old Tansy", "hero": ""}), "Old Tansy")


func test_a_real_lobby_shows_no_bot_numbers_and_long_names_fit() -> void:
	var port: CorePort = CorePort.new()
	port.setup()
	var app: App = App.new()
	add_child_autofree(app)
	app.setup(port)
	app.start_game(7)
	var choosing: RecruitScreen = app.current as RecruitScreen
	choosing.render()
	var pending_lobby: LobbyStrip = choosing.get("_lobby")
	for plaque: Control in pending_lobby.plaques:
		var pending_name: Label = plaque.get("_name")
		assert_false(pending_name.text.begins_with("Bot"), pending_name.text)
	port.choose(0)
	var screen: RecruitScreen = app.current as RecruitScreen
	screen.render()
	var lobby: LobbyStrip = screen.get("_lobby")
	assert_eq(lobby.plaques.size(), 8)
	for plaque: Control in lobby.plaques:
		var words: Label = plaque.get("_name")
		assert_false(words.text.begins_with("Bot"), words.text)


func test_a_ghost_is_named_as_next_opponent_everywhere() -> void:
	var state: Dictionary = _ghost_state()
	assert_true(RecruitView.is_ghost_next(state))
	assert_eq(RecruitView.next_name(state), "Ghost of Hob", "the last one out")
	assert_eq(RecruitView.fight_note(state), "then fight a ghost")
	var card: Dictionary = RecruitView.ghost_card(state)
	assert_string_contains(str(card["text"]), "Hob")
	assert_string_contains(str(card["text"]), "no Health")
	var strip: LobbyStrip = LobbyStrip.new()
	strip.size = Vector2(1800, LobbyStrip.HEIGHT)
	add_child_autofree(strip)
	var standings: Array = state["standings"]
	strip.show_standings(standings, -1, 2)
	var next_plaques: Array = []
	for plaque: LobbyPlaque in strip.plaques:
		if plaque.is_next:
			next_plaques.append(plaque)
	assert_eq(next_plaques.size(), 1, "one plaque says NEXT")
	var ghost: LobbyPlaque = next_plaques[0]
	assert_true(ghost.is_ghost)
	assert_true(ghost.tap != null, "a tap on it scouts")
	var words: Label = ghost.get("_name")
	assert_eq(words.text, "Ghost of Hob")


func test_opening_scout_on_a_ghost_says_what_a_ghost_is() -> void:
	var screen: RecruitScreen = _slice_screen()
	var raw: Dictionary = screen.port.get_state()
	raw["next_opponent_id"] = -1
	raw["next_opponent_hero"] = null
	screen.render()
	screen.toggle_scout()
	var detail: Control = screen.get("_detail")
	assert_true(detail.visible)
	var shown: Dictionary = detail.get("shown")
	assert_string_contains(str(shown["text"]), "The last board of")


func test_a_triple_keeps_a_cold_frame_paid_for() -> void:
	var library: UnitLibrary = TestLibraries.current()
	var config: GameConfig = GameConfig.full_game()
	var session: GameSession = GameSession.create(5, library, config)
	session.choose(0)
	var rules: RecruitRules = session.get_rules()
	var player: PlayerState = session.get("_players")[0]
	var def: Dictionary = library.get_unit("kit")
	for i: int in 3:
		var copy: RecruitUnit = RecruitUnit.make(def, 900 + i)
		if i == 0:
			copy.timers.append({"turns": 2, "left": 1, "attack": 5, "health": 5})
		player.hand.append(copy)
	rules.check_triples(player)
	var golden: RecruitUnit = null
	for unit: RecruitUnit in player.hand:
		if unit.golden:
			golden = unit
	assert_true(golden != null, "the triple formed")
	assert_eq(golden.timers.size(), 1, "the wait came along")
	var view: Dictionary = golden.view()
	var reward_due: bool = view["reward_pending"]
	assert_true(reward_due, "and the reward is on its way")


func test_buying_a_third_copy_says_what_it_does_before_it_happens() -> void:
	var waiting: Dictionary = {
		"def_id": "kit", "name": "Kit", "timers": [{"left": 1}], "turns_in_slot": 1
	}
	var state: Dictionary = {"board": [waiting], "hand": [{"def_id": "kit", "name": "Kit"}]}
	var warning: String = RecruitView.triple_warning(state, {"def_id": "kit", "name": "Kit"})
	assert_string_contains(warning, "golden Kit")
	assert_string_contains(warning, "start over")
	assert_string_contains(warning, "Triple Reward")
	assert_eq(RecruitView.triple_warning(state, {"def_id": "wisp", "name": "Wisp"}), "")
	var fresh: Dictionary = RecruitView.with_reward_note({"text": "", "reward_pending": true})
	assert_string_contains(str(fresh["text"]), "Play this")


func test_tile_tags_say_something_for_every_unit_in_the_game() -> void:
	var source: UnitLibrary = TestLibraries.current()
	var expected: Dictionary = {
		"sleeping_partner": "Acorns every 3",
		"mrs_clover": "Summons grow",
		"alderman_dozey": "Food + wake",
		"goodman_hayward": "Tribe grows",
	}
	for preset: String in ["B", "C"]:
		var config: GameConfig = GameConfig.full_game()
		config.set_value("pass3_preset", preset)
		var configured: UnitLibrary = ScaleOverlay.library_for(source, config)
		for id: String in expected:
			for golden: bool in [false, true]:
				var view: Dictionary = UnitViews.from_def(configured.get_unit(id), golden)
				var tag: String = CardView.chip_text(view)
				assert_eq(tag, str(expected[id]), "%s/%s/golden=%s" % [id, preset, golden])
				assert_lte(tag.length(), 16)

	var library: UnitLibrary = TestLibraries.current()
	for def: Dictionary in library.pool_units("slice"):
		var view: Dictionary = UnitViews.from_def(def)
		var tag: String = CardView.chip_text(view)
		assert_ne(tag, "Ability", str(def["id"]))
		if not str(view["text"]).is_empty():
			assert_false(tag.is_empty(), str(def["id"]))
			assert_lte(tag.length(), 16, "%s: %s" % [def["id"], tag])


func test_tile_tags_read_from_the_rules_as_they_stand() -> void:
	assert_eq(_tag("When played: Ring this slot +1/+1.", ["Ring"]), "Ring +1/+1")
	assert_eq(_tag("When played and when sold: Pass right +2/+2.", ["Pass"]), "Pass +2/+2")
	assert_eq(_tag("Whenever this is attacked, they gain.", []), "When hit")
	assert_eq(_tag("After 3 turns in this slot: get 2 Acorns.", ["Acorn"]), "2 Acorns")
	assert_eq(_tag("Peck 2.", ["Peck"]), "Peck 2")
	assert_eq(_tag("Start of Combat: the enemy across has -1 Attack.", ["Hex"]), "Hex")
	assert_eq(_tag("Quite new wording nobody wrote a tag for.", []), "Ability")


func _tag(rules: String, keywords: Array) -> String:
	return CardView.chip_text({"text": rules, "keywords": keywords})


func test_every_keyword_in_a_discover_is_one_hover_or_tap_from_its_reminder() -> void:
	var picker: CardPicker = CardPicker.new()
	add_child_autofree(picker)
	var library: UnitLibrary = TestLibraries.current()
	var views: Array = [
		UnitViews.from_def(library.get_unit("belladonna")),
		UnitViews.from_def(library.get_unit("nan_toadstool")),
		UnitViews.from_def(library.get_unit("mr_crumb")),
	]
	picker.show_cards("Discover: pick one", views, false)
	var slips: Array = picker.get("_texts")
	var reminders: Array = picker.get("_reminders")
	assert_eq(slips.size(), 3)
	for i: int in 3:
		var slip: RichTextLabel = slips[i]
		var view: Dictionary = views[i]
		for keyword: String in KeywordRules.named_on(view):
			assert_false(slip.get_parsed_text().contains(keyword + ":"), "no reminder on the slip")
			# A term a reminder introduces (Pass's touching) is explained on that reminder's slip.
			var link: String = "[url=kw:%s]" % keyword
			if KeywordRules.HELP_WORDS.has(keyword) and not slip.text.contains(link):
				continue
			assert_string_contains(slip.text, link)
			var reminder: ReminderSlip = reminders[i]
			slip.meta_hover_started.emit("kw:" + keyword)
			assert_eq(reminder.keyword, keyword, "hovering %s opens its reminder" % keyword)
			assert_true(reminder.visible)


func test_keywords_named_only_in_a_rules_line_are_found() -> void:
	var card: Dictionary = {"text": "Give a unit Nightshade. Spill."}
	var words: PackedStringArray = KeywordRules.named_on(card)
	assert_true(words.has("Nightshade"))
	assert_true(words.has("Spill"))
	assert_false(words.has("Hex"))


func test_scout_shows_a_units_hex_and_leaves_shop_board_and_hand_in_view() -> void:
	var screen: RecruitScreen = _slice_screen()
	var raw: Dictionary = screen.port.get_state()
	var theirs: Array = raw["next_opponent_last_board"]
	var hexer: Dictionary = theirs[0]
	hexer["counters"] = {"hex": 7}
	screen.toggle_scout()
	await get_tree().process_frame
	var scout: Control = screen.get("_scout")
	var card: CardView = scout.call("card_at", 0)
	assert_eq(card.turns_shown, "Hex 7")
	var shop: Control = screen.get("_shop_cards")
	var board: Control = screen.get("_board")
	var hand: Control = screen.get("_hand_zone")
	var theirs_tray: Control = scout.get("_board")
	var tray: Rect2 = theirs_tray.get_global_rect()
	assert_gt(shop.get_child_count(), 0)
	assert_false(tray.intersects(shop.get_global_rect()), "the shop stays beside it")
	assert_false(tray.intersects(board.get_global_rect()), "your board stays under it")
	assert_false(tray.intersects(hand.get_global_rect()), "your hand stays clear")
	assert_true((shop.get_child(0) as CardView).mode == CardView.Mode.MINI)
	screen.call("_on_tapped", "shop", 0)
	var selected: Dictionary = screen.get("_selected")
	assert_eq(str(selected["zone"]), "shop", "the small tiles still buy")
	screen.toggle_scout()
	assert_true((shop.get_child(0) as CardView).mode == CardView.Mode.SHOP, "closing restores it")


func test_a_word_clipped_by_a_round_token_fails_the_layout_check() -> void:
	var token: TokenButton = TokenButton.new("Scoutmaster", "", UiTheme.FONT_SMALL)
	token.size = Vector2(100, 109)
	var holder: Control = Control.new()
	holder.size = Vector2(400, 400)
	holder.add_child(token)
	add_child_autofree(holder)
	await get_tree().process_frame
	var problems: PackedStringArray = LayoutCheck.problems(holder, "token", false)
	assert_gt(problems.size(), 0)


func test_game_over_says_who_ended_it_and_your_best_moments() -> void:
	var rounds: Array = [
		{"round": 1, "result": "won", "damage": 3, "opponent": "Pipkin", "opponent_id": 2},
		{"round": 2, "result": "won", "damage": 9, "opponent": "Hob", "opponent_id": 3},
		{"round": 3, "result": "lost", "damage": 12, "opponent": "Wren", "opponent_id": 4},
	]
	var game_log: Dictionary = {
		"players":
		[
			{
				"player_id": 0,
				"rounds":
				[
					{"round": 2, "board": [{"name": "Kit", "attack": 1, "health": 1}, null]},
					{
						"round": 3,
						"board": [{"name": "Dozey", "attack": 6, "health": 9, "golden": true}]
					},
				],
			},
		],
	}
	var lines: PackedStringArray = GameOverScreen.moment_lines(rounds, 8, game_log)
	assert_eq(lines[0], "Knocked out by Wren on turn 3.")
	assert_eq(lines[1], "Best win: 9 damage to Hob on turn 2.")
	assert_eq(lines[2], "Biggest unit: Golden Dozey, 6/9 on turn 3.")
	var won: PackedStringArray = GameOverScreen.moment_lines(rounds, 1, {})
	assert_eq(won[0], "Last one standing.")


func test_the_guide_says_gold_and_shows_only_whats_in_the_game() -> void:
	var guide: HowToPlay = HowToPlay.new()
	add_child_autofree(guide)
	for entry: Dictionary in HowToPlay.PAGES:
		var words: String = str(entry["text"]) + str(entry["title"])
		assert_false(words.contains("acorns on"), words)
	var library: UnitLibrary = TestLibraries.current()
	var allowed: Array[String] = ["Hedgerow folk", "Fairies", "Oozes", "Birds"]
	var in_game: Dictionary = {}
	for unit: Dictionary in library.pool_units("slice"):
		for tribe: Variant in unit["tribes"]:
			in_game[str(tribe)] = true
	for tribe: String in allowed:
		assert_true(in_game.has(tribe), "%s is in the game" % tribe)
	var samples: Array[Dictionary] = guide.call("_samples")
	assert_eq(samples.size(), HowToPlay.SAMPLE_IDS.size())
	for view: Dictionary in samples:
		assert_false(library.get_unit(str(view["def_id"])).is_empty())
		for tribe: Variant in view["tribes"]:
			assert_true(allowed.has(str(tribe)), str(tribe))


func test_a_real_games_words_have_no_raw_ids_in_the_log_or_the_tool() -> void:
	var game: PlayGame = PlayGame.start(11)
	game.session.choose(0)
	var raw: RegEx = RegEx.create_from_string(RAW_ID)
	for turn: int in 14:
		if game.session.is_over():
			break
		var bot_plays: PackedStringArray = _buy_what_you_can(game)
		assert_eq(bot_plays, PackedStringArray())
		game.session.end_turn()
		var words: String = PlayView.text(game, "")
		var found: RegExMatch = raw.search(words)
		assert_null(found, "turn %d: %s" % [turn, found.get_string() if found != null else ""])
		assert_false(words.contains("You goes"), "You goes")
		assert_false(words.contains("You has"), "You has")
		assert_false(RegEx.create_from_string("\\bBot \\d").search(words) != null, "Bot number")
		var key_at: int = words.find("KEYWORDS:")
		if key_at >= 0:
			assert_true(words.substr(key_at + 11, 40).contains(":"), "keywords keep their names")
	var review: String = PlayView.log_text(game)
	assert_false(RegEx.create_from_string("\\bBot \\d").search(review) != null, "Bot number in log")


## Buys and plays whatever the first few offers are, for a board that triggers things.
func _buy_what_you_can(game: PlayGame) -> PackedStringArray:
	var session: GameSession = game.session
	for attempt: int in 3:
		var state: Dictionary = session.get_state()
		var shop: Array = state["shop"]
		if shop.is_empty() or CoreUtil.to_int(state["gold"]) < 3:
			break
		session.buy(0)
		state = session.get_state()
		var hand: Array = state["hand"]
		var board: Array = state["board"]
		var empty: int = board.find(null)
		if not hand.is_empty() and empty >= 0:
			session.play(0, empty)
		while session.get_state()["pending_choice"] != null:
			session.choose(0)
	return PackedStringArray()


func test_nothing_says_ghost_before_the_first_pairing() -> void:
	var offer: Dictionary = {
		"next_opponent_id": -1, "standings": [{"player_id": 1, "alive": true, "placement": null}]
	}
	assert_false(RecruitView.is_ghost_next(offer))
	assert_eq(RecruitView.fight_note(offer), "")


func _live_screen() -> RecruitScreen:
	var port: CorePort = CorePort.new()
	port.setup(GameConfig.full_game())
	port.new_game(4242)
	port.choose(0)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	return screen


func _hand_after_buying_the_first_mini_tile(screen: RecruitScreen) -> int:
	screen.toggle_scout()
	var tile: CardView = screen.call("_card_at", "shop", 0)
	assert_eq(tile.mode, CardView.Mode.MINI, "the shop is small while scouting")
	screen.call("_on_tapped", "shop", 0)
	var driver: PlayerDriver = PlayerDriver.new(1)
	driver.call("_press_detail_action", screen, "Buy")
	return Data.a(screen.state, "hand").size()


func test_a_mini_tile_buys_while_scouting() -> void:
	var screen: RecruitScreen = _live_screen()
	var before: int = Data.a(screen.state, "hand").size()
	assert_eq(_hand_after_buying_the_first_mini_tile(screen), before + 1)
	var scout: Control = screen.get("_scout")
	assert_true(scout.visible, "scouting stays open")


func test_a_mini_tile_drags_to_the_board_while_scouting() -> void:
	var screen: RecruitScreen = _live_screen()
	screen.toggle_scout()
	var tile: CardView = screen.call("_card_at", "shop", 0)
	var data: Variant = tile.drag_data_fn.call("shop", 0)
	assert_true(data is Dictionary, "a tile can be picked up")
	var drag: Dictionary = data
	var droppable: bool = screen.call("_can_drop", drag, "board", 0)
	assert_true(droppable, "and dropped on an empty slot")
	screen.call("_drop", drag, "board", 0)
	var slot_now: Variant = Data.a(screen.state, "board")[0]
	assert_true(slot_now is Dictionary, "the unit is on the board")


func test_the_triple_warning_only_speaks_of_waits_that_exist() -> void:
	var shop_card: Dictionary = {"def_id": "a", "name": "A"}
	var plain: Dictionary = {"def_id": "a", "turns_in_slot": 3, "turns_goal": 0, "timers": []}
	var view: Dictionary = {"board": [plain, plain.duplicate()], "hand": []}
	assert_false(RecruitView.triple_warning(view, shop_card).contains("start over"), "plain unit")
	var counting: Dictionary = plain.duplicate()
	counting["turns_goal"] = 3
	view["board"] = [counting, plain]
	assert_true(RecruitView.triple_warning(view, shop_card).contains("start over"), "a count")
	var waiting: Dictionary = plain.duplicate()
	waiting["timers"] = [{"left": 1}]
	view["board"] = [waiting, plain]
	assert_true(RecruitView.triple_warning(view, shop_card).contains("start over"), "a wait")


func test_a_spell_with_nowhere_to_go_says_why() -> void:
	var bread: Dictionary = {"name": "Bread", "kind": "spell", "aim": "back_unit"}
	var unit: Dictionary = {"name": "A"}
	var view: Dictionary = {"board": [unit, null, null, null, null, null, null], "shop": []}
	assert_string_contains(RecruitView.no_target_note(view, bread), "back row")
	view["board"] = [null, null, null, null, unit, null, null]
	assert_eq(RecruitView.no_target_note(view, bread), "")
	assert_eq(RecruitView.no_target_note(view, {"aim": "none"}), "")
	assert_string_contains(RecruitView.no_target_note(view, {"aim": "shop_unit"}), "shop")
