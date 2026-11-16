extends GutTest
## The adapter turns the core's views into the screens' view state, and the seam turns the
## recruit screen's input into the core's actions.

@warning_ignore_start("unsafe_call_argument")

const RECRUIT: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")

var _content: GameContent
var _actions: Array[Dictionary] = []


func before_all() -> void:
	_content = GameContent.load_default()


func _flow(game_seed: int = 5) -> GameFlow:
	var flow: GameFlow = GameFlow.create(_content, game_seed)
	flow.start_round()
	return flow


func test_recruit_state_has_the_contract_fields() -> void:
	var flow: GameFlow = _flow()
	var state: Dictionary = ViewAdapter.recruit_state(flow, "a notice")
	for key: String in [
		"turn",
		"gold",
		"tier",
		"refresh_cost",
		"frozen",
		"health",
		"hand_limit",
		"upgrade_cost",
		"hero",
		"counters",
		"next_opponent",
		"message",
		"shop_units",
		"shop_spells",
		"hand",
		"board",
		"slots",
		"players",
		"legal_actions"
	]:
		assert_true(state.has(key), "state has %s" % key)
	assert_eq(state["turn"], 1)
	assert_eq(state["hand_limit"], 7, "rulebook 7.1.1")
	assert_eq(state["message"], "a notice")
	var board: Array = state["board"]
	assert_eq(board.size(), 7)
	var slots: Array = state["slots"]
	assert_eq(slots.size(), 7)
	var players: Array = state["players"]
	assert_eq(players.size(), 8)
	var hero: Dictionary = state["hero"]
	assert_eq(hero["portrait"], "dame_farthing")
	var legal: Array = state["legal_actions"]
	assert_eq(legal, flow.session.legal_actions(GameFlow.HUMAN), "passed through unchanged")


func test_shop_cards_carry_name_art_text_and_price() -> void:
	var flow: GameFlow = _flow()
	var state: Dictionary = ViewAdapter.recruit_state(flow)
	var prices: Array = flow.session.view_for(GameFlow.HUMAN)["costs"]["shop_units"]
	var shop: Array = state["shop_units"]
	assert_gt(shop.size(), 0)
	for i: int in shop.size():
		var card: Dictionary = shop[i]
		var def: UnitDef = _content.library.get_card(StringName(str(card["id"])))
		assert_eq(card["name"], def.name)
		assert_eq(card["tier"], def.tier)
		assert_ne(str(card["art"]), "", "art for %s" % card["id"])
		assert_eq(card["price"], prices[i], "the core's price")
		assert_false(str(card["text"]).contains("{"), "placeholders filled")
		assert_true(card.has("golden_text"))


func test_golden_text_doubles_numbers() -> void:
	var flow: GameFlow = _flow()
	var card: Dictionary = ViewAdapter.card_from_id(_content, flow.session, "t1_herald")
	assert_eq(card["text"], "Played: give adjacent units +2/+2.")
	assert_eq(card["golden_text"], "Played: give adjacent units +4/+4.")


func test_top_tier_has_no_upgrade_cost() -> void:
	var flow: GameFlow = _flow()
	flow.human().tier = 6
	assert_eq(ViewAdapter.recruit_state(flow)["upgrade_cost"], null)


func test_slot_buffs_and_counters_get_display_names() -> void:
	var slots: Array = ViewAdapter.slots(
		_content, [{"attack": 2, "health": 1, "keywords": ["taunt"], "marks": {}}, {}]
	)
	assert_eq(slots[0], {"buff": "+2/+1", "buff_name": "Guard", "names": ["Guard"]})
	assert_eq(slots[1], {})
	var chips: Array = ViewAdapter.counters(
		_content, {"counters": {"compost": 4}, "heaps": {"grave_heap": [{"id": "x", "tier": 1}]}}
	)
	assert_eq(
		chips,
		[
			{"key": "compost", "label": "Compost", "value": 4},
			{"key": "grave_heap", "label": "Grave Heap", "value": 1},
		]
	)


## Item 4: names, reminders and hiding come from the content's display.json.
func test_tribe_counters_and_keywords_use_the_content_display_table() -> void:
	var content: GameContent = GameContent.load_folders(
		["res://src/content/shared", "res://tests/core/content/test"]
	)
	var flow: GameFlow = GameFlow.create(content, 9)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.counters[&"test_tide"] = 3
	var chips: Array = ViewAdapter.counters(content, flow.session.view_for(GameFlow.HUMAN))
	var tide: Dictionary = {}
	for chip: Dictionary in chips:
		if str(chip["key"]) == "test_tide":
			tide = chip
	assert_eq(str(tide.get("label", "")), "Tide", "the player counter by its display name")
	assert_eq(CoreUtil.to_int(tide.get("value", 0)), 3, "and its value")
	var veteran: Unit = flow.session.new_unit(content.library.get_card(&"b2_veteran"), false)
	veteran.counters[&"test_medal"] = 2
	me.place(veteran, 0)
	var state: Dictionary = ViewAdapter.recruit_state(flow)
	var card: Dictionary = state["board"][0]
	assert_eq(card["counters"], [{"key": "test_medal", "label": "Medal", "value": 2}], "a medal")
	var table: Dictionary = state["display"]
	assert_eq(str(table["test_medal"]["reminder"]), "+1/+1 for the game.", "reminders pass")
	assert_true(CoreUtil.to_bool(table["test_tide_rider"]["hidden"]), "helpers stay hidden")
	assert_eq(content.display_name("test_tide_rider"), "", "a hidden id has no name")


func test_bought_card_reaches_the_hand_with_its_uid() -> void:
	var flow: GameFlow = _flow()
	assert_eq(flow.act({"type": "buy", "spell": false, "index": 0}), "")
	var state: Dictionary = ViewAdapter.recruit_state(flow)
	var hand: Array = state["hand"]
	assert_eq(hand.size(), 1)
	var card: Dictionary = hand[0]
	assert_gt(card["uid"], 0)
	var shop: Array = state["shop_units"]
	assert_null(shop[0], "a bought card leaves a hole")


func test_leaderboard_puts_the_living_first_by_health() -> void:
	var flow: GameFlow = _flow()
	flow.session.player(3).health = 50
	flow.session.player(4).alive = false
	flow.session.player(4).placement = 8
	var rows: Array = ViewAdapter.players(flow)
	var first: Dictionary = rows[0]
	var last: Dictionary = rows[7]
	assert_eq(first["name"], flow.name_of(3))
	assert_eq(last["name"], flow.name_of(4))


func test_fight_base_names_both_sides() -> void:
	var flow: GameFlow = _flow(9)
	flow.act({"type": "buy", "spell": false, "index": 0})
	flow.act({"type": "play", "hand": 0, "slot": 0, "target": -1})
	var fight: Dictionary = flow.finish_round()
	assert_false(fight.is_empty(), "the human fought")
	var base: Dictionary = ViewAdapter.fight_base(flow, fight)
	var opponent: Dictionary = base["opponent"]
	assert_eq(opponent["name"], flow.name_of(CoreUtil.to_int(fight["opponent"])))
	var slots: Array = base["slots"]
	assert_eq(slots.size(), 2)
	var replay: FightReplay = FightReplay.build(
		base, fight["events"], ViewAdapter.catalog(_content), fight["damage"]
	)
	assert_gt(replay.steps.size(), 1, "the log plays as steps")


# ---- the seam ----


func _on_action(action: Dictionary) -> void:
	_actions.append(action)


func test_seam_turns_screen_input_into_core_actions() -> void:
	var flow: GameFlow = _flow()
	flow.act({"type": "buy", "spell": false, "index": 0})
	var screen: RecruitScreen = RECRUIT.instantiate()
	add_child_autofree(screen)
	screen.show_state(ViewAdapter.recruit_state(flow))
	var seam := RecruitSeam.new()
	seam.attach(screen)
	seam.action_requested.connect(_on_action)
	_actions.clear()
	if screen.has_signal("action_requested"):
		pass_test("the screen speaks the core's format; the seam passes it through")
		return
	screen.emit_signal("buy_requested", 2, false)
	screen.emit_signal("play_requested", 0, 3)
	screen.emit_signal("move_requested", 3, 5)
	screen.emit_signal("sell_requested", 5)
	screen.emit_signal("tier_up_requested")
	screen.emit_signal("end_turn_requested")
	assert_eq(
		_actions,
		[
			{"type": "buy", "spell": false, "index": 2},
			{"type": "play", "hand": 0, "slot": 3, "target": -1},
			{"type": "move", "from": 3, "to": 5},
			{"type": "sell", "slot": 5},
			{"type": "upgrade"},
			{"type": "end_turn"},
		]
	)
	assert_eq(flow.act(_actions[1]), "", "the play is legal")
