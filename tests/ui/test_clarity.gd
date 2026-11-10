extends GutTest
## Newcomer explanations stay tied to the rules and remain readable at both window sizes.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_cast")

const Kit := preload("res://tests/core/recruit_kit.gd")
const Keywords := preload("res://src/ui/keyword_rules.gd")
const Guide := preload("res://src/ui/screens/how_to_play.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardPicker := preload("res://src/ui/widgets/card_picker.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const FightLog := preload("res://tools/play/play_fight_log.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_terms_are_found_in_card_text_and_keyword_reminders() -> void:
	var words: PackedStringArray = Keywords.named_on(
		{"text": "Behind this, beside it, next to it, touching. Once each cycle. Take: *"}
	)
	for term: String in ["Behind", "Beside", "Next to", "Touching", "Cycle", "Take", "*"]:
		assert_has(words, term)
		assert_string_contains(PlayView.how_to_play(), Keywords.text(term))
	assert_has(Keywords.named_on({"keywords": ["Pounce"]}), "Cycle")
	assert_false(Keywords.named_on({"keywords": ["Pass"]}).has("Touching"))
	assert_has(Keywords.named_on({"keywords": ["Pounce"]}), "Next to")
	# "Take" is a word only as written: "takes 2 damage" and Hunker's "Takes half" aren't it.
	assert_false(Keywords.named_on({"text": "Each enemy moved takes 2 damage."}).has("Take"))
	assert_false(Keywords.named_on({"keywords": ["Hunker"]}).has("Take"))


func test_crumb_queues_on_play_and_sale_but_lands_after_final_positioning() -> void:
	var kit := Kit.new()
	kit.setup(null, false, LegacyWave1.with_hedgerow(UnitLibrary.load_dir()))
	var left: RecruitUnit = kit.put("field_vole", 4)
	var right: RecruitUnit = kit.put("field_vole", 5)
	kit.put("mr_crumb")
	assert_eq(kit.rules.play(kit.player, 0, 0), "")
	assert_eq(kit.player.pending_passes.size(), 1)
	assert_eq(left.perm_attack, 0, "no bonus lands when played")
	assert_eq(kit.rules.move(kit.player, 0, 1), "")
	assert_eq(right.perm_attack, 0, "no bonus lands when moved")
	kit.rules.end_phase(kit.player)
	assert_eq(right.perm_attack, 1, "the queued Pass follows its source to F2")
	assert_eq(left.perm_attack, 0)
	assert_eq(kit.rules.sell(kit.player, 1), "")
	assert_eq(kit.player.pending_passes.size(), 1)
	assert_eq(right.perm_attack, 1, "no bonus lands when sold")
	kit.rules.end_phase(kit.player)
	assert_eq(right.perm_attack, 2, "the sale's Pass starts from F2 after its source has gone")
	assert_false(Keywords.text("Pass").contains("Mr Crumb"))
	assert_eq(Keywords.text("Pass"), "Pass X: your rightmost unit, other than this, gains X.")


func test_triple_rewards_offer_three_across_all_shop_tiers() -> void:
	for tier: int in range(1, 7):
		var kit := Kit.new()
		kit.setup(GameConfig.full_game())
		kit.player.tier = tier
		for copy: int in 3:
			kit.put("mr_crumb")
		kit.rules.check_triples(kit.player)
		assert_eq(kit.rules.play(kit.player, 0, 0), "")
		assert_eq(kit.rules.play_item(kit.player, 0), "")
		var choice: Dictionary = kit.player.pending[0]
		assert_eq(choice["options"].size(), 3, "tier %d" % tier)
		assert_eq(choice["note"], "")


func test_exhausted_discover_explains_two_options_and_an_empty_pool() -> void:
	var library := TestLibraries.current()
	var session := GameSession.create(12, library)
	var player: PlayerState = session._players[0]
	var cards: Array[Dictionary] = [library.get_unit("mr_crumb"), library.get_unit("field_vole")]
	session._rules.pool = UnitPool.from_cards(
		cards, GameConfig.defaults(), "pool_copies_by_tier", PackedStringArray()
	)
	session._rules.discover(player, {"count": 3, "tier": 2})
	var state: Dictionary = session.get_state()
	var choice: Dictionary = state["pending_choice"]
	assert_eq(choice["options"].size(), 2)
	assert_string_contains(choice["note"], "Only 2 of 3")
	assert_string_contains(choice["note"], "no more eligible cards")
	var lines: PackedStringArray = []
	PlayView._choice(state, lines)
	assert_string_contains("\n".join(lines), choice["note"])
	player.pending.clear()
	session._rules.pool = UnitPool.from_cards(
		[], GameConfig.defaults(), "pool_copies_by_tier", PackedStringArray()
	)
	session._rules.discover(player, {"count": 3, "tier": 2})
	assert_false(player.is_choosing())
	assert_string_contains(RecruitView.event_note(player.recruit_log[-1]), "no eligible cards")


func test_income_and_sell_values_follow_config_origin_savings_and_queries() -> void:
	var library := TestLibraries.current()
	var config := GameConfig.defaults()
	config.set_value("income_by_turn", [3, 8])
	var session := GameSession.create(4, library, config)
	var player: PlayerState = session._players[0]
	player.board[0] = RecruitUnit.make(library.get_unit("field_vole"), 900)
	player.board[0].origin = RecruitUnit.ORIGIN_CREATED
	player.hand.append(RecruitUnit.make(library.get_unit("pennywort_snail"), 901))
	player.hand[-1].counters["savings"] = 3
	var state: Dictionary = session.get_state()
	assert_eq(state["next_turn_income"], 8)
	assert_eq(state["board"][0]["sell_value"], 0)
	assert_eq(state["hand"][0]["sell_value"], session._rules.sell_value(player.hand[0], player))
	player.rule_handlers.append({"query": "sell_value", "op": "max", "value": 4})
	state = session.get_state()
	assert_eq(state["shop"][0]["sell_value"], 4)
	assert_eq(state["board"][0]["sell_value"], 4)
	assert_false(
		RecruitView.full_view("shop", state["shop"][0], state)["text"].contains("Sell value")
	)
	assert_false(PlayView._card(state["shop"][0]).contains("sell value"))
	assert_false(
		RecruitView.full_view("board", state["board"][0], state)["text"].contains("Sell value")
	)
	assert_false(
		RecruitView.full_view("board", state["board"][0], state)["text"].contains("Next income"),
		"income is beside the gold, not in rules text"
	)
	assert_string_contains(RecruitView.income_note(state), "Next income: +8 gold")
	var lines: PackedStringArray = []
	PlayView._board(state, lines)
	assert_string_contains("\n".join(lines), "sell: 4 gold")


func test_last_blow_explains_winner_kind_and_both_viewpoints() -> void:
	for mine: int in [0, 1]:
		for kind: String in ["attack", "effect"]:
			var event: Dictionary = {
				"type": "combat_end",
				"reason": "board_empty",
				"last_blow": true,
				"last_blow_kind": kind,
				"winner": 1,
				"survivors": [[], []]
			}
			var line: String = FightLog.event_line(event, {}, mine)
			assert_string_contains(line, "Both boards fell.")
			assert_string_contains(line, "Last Blow")
			assert_string_contains(line, "you win" if mine == 1 else "they win")
			assert_string_contains(line, "attack" if kind == "attack" else "finishing effect")
			assert_false(line.contains("Survivors:"))
			var names := PackedStringArray(["You", "Hob"] if mine == 0 else ["Hob", "You"])
			assert_string_contains(CombatLog.rules_note(event, names), line)


func test_changed_guide_pages_fit_desktop_and_phone() -> void:
	for width: int in [1920, 2337]:
		for page: int in [2, 4, 5, 12, 13]:
			var guide := Guide.new()
			add_child_autofree(guide)
			guide.set_anchors_preset(Control.PRESET_TOP_LEFT)
			guide.size = Vector2(width, 1080)
			guide.page = page
			guide._layout()
			guide._show_page()
			await wait_process_frames(2)
			var body: Label = guide.get("_text")
			assert_lte(body.get_minimum_size().y, body.size.y, "page %d at %d" % [page + 1, width])
			assert_lte(body.position.y + body.size.y, guide.get("_count").position.y)


func test_recruit_income_and_sell_detail_fit_at_both_sizes() -> void:
	for phone: bool in [false, true]:
		CardView.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(2337 if phone else 1920, 1080)
		add_child_autofree(viewport)
		var port := CorePort.new()
		port.setup()
		port.new_game(12)
		port.choose(0)
		var player: PlayerState = port.session._players[0]
		player.board[0] = RecruitUnit.make(port.library.get_unit("mr_crumb"), 901)
		var screen := RecruitScreen.new()
		viewport.add_child(screen)
		screen.setup(port)
		await wait_process_frames(2)
		assert_eq(LayoutCheck.problems(screen, "income"), PackedStringArray())
		for zone: String in ["shop", "board"]:
			screen.call("_on_tapped", zone, 0)
			await wait_process_frames(2)
			assert_false(screen.get("_detail").shown["text"].contains("Next income"))
			assert_eq(LayoutCheck.problems(screen, "buy/sell"), PackedStringArray())


func test_short_discover_note_and_scrollable_keyword_help_fit() -> void:
	for width: int in [1920, 2337]:
		CardView.window_override = Vector2(1688, 780) if width == 2337 else Vector2(1920, 1080)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(width, 1080)
		add_child_autofree(viewport)
		var picker := CardPicker.new()
		viewport.add_child(picker)
		var library := TestLibraries.current()
		var view: Dictionary = preload("res://src/ui/unit_views.gd").from_def(
			library.get_unit("brother_wolf")
		)
		# Short reminders fit, so long rules text makes the slip overflow and scroll.
		view["text"] = "%s %s" % [view["text"], "Pack. ".repeat(40)]
		picker.show_cards(
			"Discover: pick one",
			[view, view],
			false,
			"Only 2 of 3 offers: the pool has no more eligible cards."
		)
		await wait_process_frames(2)
		assert_eq(LayoutCheck.problems(picker, "short Discover"), PackedStringArray())
		var texts: Array = picker.get("_texts")
		var slip: RichTextLabel = texts[0]
		assert_true(slip.has_meta("must_fit"), "Discover slips stay covered by the layout guard")
		assert_true(slip.scroll_active)
		assert_false(slip.get_parsed_text().contains("joins in"), "reminders are off the slip")
		var reminders: Array = picker.get("_reminders")
		var reminder: Object = reminders[0]
		slip.meta_clicked.emit("kw:Pack")
		assert_string_contains(str(reminder.call("_reminder", "Pack")), "joins in")
		assert_eq(reminder.get("keyword"), "Pack", "a tap opens Pack's reminder")
		assert_eq(LayoutCheck.problems(picker, "Discover reminder"), PackedStringArray())
		# Shorter slips rarely overflow now; force one to keep the scroll guard honest.
		slip.size.y = slip.get_content_height() / 2.0
		assert_gt(float(slip.get_content_height()), slip.size.y, "exercise an overflowing slip")
		slip.scroll_active = false
		assert_false(LayoutCheck.problems(picker, "broken scrolling").is_empty())
		slip.scroll_active = true
		slip.size.y = 1
		assert_false(LayoutCheck.problems(picker, "unreadable scroll area").is_empty())


func test_pass_hint_names_end_of_turn_and_leaves_other_cards_alone() -> void:
	var library := TestLibraries.current()
	for slot: int in BoardGeometry.SLOTS:
		assert_eq(RecruitView.geometry_note(library.get_unit("mr_crumb"), slot), "")
	assert_eq(RecruitView.geometry_note(library.get_unit("field_vole"), 0), "")
	assert_eq(RecruitView.geometry_note({"text": "Units behind this gain +1 Attack."}, 1), "")


func test_only_queued_income_difference_is_visible_with_full_income_in_reader() -> void:
	var plaque := preload("res://src/ui/widgets/gold_plaque.gd").new()
	add_child_autofree(plaque)
	plaque.size = Vector2(422, 152)
	plaque.show_gold(10)
	plaque.show_income("Next income: +4 gold. Saved gold carries over.")
	await wait_process_frames(2)
	var income: Label = plaque.get("_income")
	assert_false(income.visible, "scheduled income needs no reminder")
	plaque.show_income("Next income: +6 gold. Includes 2 queued.", 2)
	assert_true(income.visible)
	assert_eq(income.text, "+2")
	assert_string_contains(income.tooltip_text, "Includes 2 queued")
	assert_true(Rect2(Vector2.ZERO, plaque.size).encloses(income.get_rect()))
	assert_lte(income.get_minimum_size().y, income.size.y)
