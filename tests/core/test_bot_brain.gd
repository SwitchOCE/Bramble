extends GutTest
## The levelled bots, the scouting rule and the placer.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _library: UnitLibrary = UnitLibrary.load_dir()


func _full_game(seats: Array, game_seed: int, all_tribes: bool = false) -> GameSession:
	var config: GameConfig = GameConfig.full_game()
	if all_tribes:
		config.set_value("tribes_per_lobby", 6)
	config.set_value("human_bot", str(seats[0]))
	config.set_value("bots", seats.slice(1))
	return GameSession.create(game_seed, _library, config)


func _play_out(session: GameSession) -> void:
	var turns: int = 0
	while not session.is_over() and turns < 60:
		assert_eq(session.end_turn(), "", "turn %d" % turns)
		turns += 1
	assert_true(session.is_over(), "the game finishes")


func _rules() -> RecruitRules:
	var config: GameConfig = GameConfig.defaults()
	return RecruitRules.create(_library, config, UnitPool.create(_library, config))


func _placed(rules: RecruitRules, player: PlayerState, ids: Array) -> void:
	for slot: int in ids.size():
		if ids[slot] != null:
			player.board[slot] = RecruitUnit.make(
				_library.get_unit(str(ids[slot])), rules.new_iid()
			)


func test_scouting_is_empty_in_round_1() -> void:
	var session: GameSession = _full_game(["hard", "hard"], 1)
	var state: Dictionary = session.get_state()
	assert_eq(state["next_opponent_last_board"], [], "nothing to see before a fight")


func test_scouting_shows_the_opponents_board_as_it_fought() -> void:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var session: GameSession = GameSession.create(4, _library, config)
	session.end_turn()
	var state: Dictionary = session.get_state()
	var seen: Array = state["next_opponent_last_board"]
	assert_eq(seen.size(), BoardGeometry.SLOTS, "one entry per slot")
	var opponent: int = state["next_opponent_id"]
	var rows: Array = session.get_game_log()["players"]
	var fought: Array = rows[opponent]["rounds"][0]["board"]
	for slot: int in BoardGeometry.SLOTS:
		if fought[slot] == null:
			assert_null(seen[slot], "slot %d stays empty" % slot)
		else:
			assert_eq(seen[slot]["def_id"], fought[slot]["def_id"], "slot %d" % slot)
			assert_true(seen[slot].has("stat_layers"), "the same dict as a board unit")


func test_scouting_does_not_show_this_rounds_changes() -> void:
	var session: GameSession = _full_game(["hard", "hard"], 2)
	session.end_turn()
	var before: String = JSON.stringify(session.get_state()["next_opponent_last_board"])
	session.refresh()
	assert_eq(JSON.stringify(session.get_state()["next_opponent_last_board"]), before, "fixed")


func test_best_and_naive_profiles_play_full_games() -> void:
	for level: String in BotLevel.ALL:
		var seats: Array = [level, level, level, level, level, level, level, level]
		var session: GameSession = _full_game(seats, 11)
		_play_out(session)
		assert_eq(session.get_game_log()["players"].size(), 8, level)


func test_a_seed_replays_exactly() -> void:
	var seats: Array = ["hard", "hard", "hard", "naive", "hard", "hard", "hard", "naive"]
	var one: GameSession = _full_game(seats, 21)
	_play_out(one)
	var two: GameSession = _full_game(seats, 21)
	_play_out(two)
	assert_eq(JSON.stringify(one.get_game_log()), JSON.stringify(two.get_game_log()), "same game")


func test_names_build_the_right_bot() -> void:
	var pinned: BotBrain = BotBrain.from_name("hard:hedgerow_parish@shuffled")
	assert_eq(pinned.level.name, BotLevel.HARD, "level")
	assert_eq(pinned.pinned_strategy, "hedgerow_parish", "strategy")
	assert_eq(pinned.level.place, BotLevel.PLACE_SHUFFLED, "placing")
	assert_null(BotBrain.from_name("balanced"), "an old personality isn't a brain")
	assert_false(Bot.create("balanced") is BotBrain, "and stays the old bot")


func test_quiet_fight_has_the_same_result() -> void:
	var board: Array = [{"def_id": "field_vole"}, null, null, null, null, null, null]
	var other: Array = [{"def_id": "marsh_frog"}, null, null, null, null, null, null]
	var results: Array = []
	for quiet: bool in [false, true]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var combat: Combat = Combat.create(_library, GameConfig.defaults(), rng)
		combat.log_events = not quiet
		var ids: Array[int] = [0, 1]
		var tiers: Array[int] = [1, 1]
		var result: Dictionary = combat.run([board, other], tiers, ids, 0)
		results.append([result["winner"], result["damage"]])
		assert_eq(result["events"].is_empty(), quiet, "events only when logging")
	assert_eq(results[0], results[1], "same fight")


func test_search_leaves_pinned_slots_alone() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	player.bot_rng.seed = 5
	_placed(rules, player, ["field_vole", "marsh_frog", null, null, "pixie_scout"])
	var problem := BoardSearch.Problem.new()
	problem.board = player.combat_board()
	problem.slots = player.combat_slots()
	problem.enemy = player.combat_board()
	problem.enemy_slots = player.combat_slots()
	problem.pinned = [0]
	problem.library = rules.library
	problem.config = rules.config
	var layout: Array[int] = BoardSearch.best_layout(problem, player.bot_rng, 40)
	assert_eq(layout[0], 0, "the pinned unit stays")


func test_search_with_nothing_scouted_keeps_the_board() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	player.bot_rng.seed = 6
	_placed(rules, player, ["field_vole", "marsh_frog", null, null, "pixie_scout"])
	var problem := BoardSearch.Problem.new()
	problem.board = player.combat_board()
	problem.library = rules.library
	problem.config = rules.config
	var same: Array[int] = BoardSearch.best_layout(problem, player.bot_rng, 40)
	assert_eq(same, BoardSearch.identity_layout(), "no enemy board, no change")


func test_moves_go_through_the_rules() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	_placed(rules, player, ["field_vole", "marsh_frog"])
	var layout: Array[int] = [1, 0, -1, -1, -1, -1, -1]
	var first: RecruitUnit = player.board[0]
	BotPlacer.apply_layout(player, rules, layout)
	assert_eq(player.board[1], first, "swapped")
	var moves: int = 0
	for entry: Dictionary in player.recruit_log:
		moves += 1 if str(entry["type"]) == "move" else 0
	assert_eq(moves, 1, "logged as one move")


func test_naive_buys_what_it_can_afford() -> void:
	var rules: RecruitRules = _rules()
	var player := PlayerState.new()
	player.bot_rng.seed = 3
	player.shop_rng.seed = 3
	rules.setup_player(player)
	rules.start_phase(player, 1)
	Bot.create("naive").play_turn(player, rules, 1)
	assert_eq(player.board_count(), 1, "3 gold, one unit, played")


func test_the_strategy_data_is_valid() -> void:
	var known: BotKnowledge = BotKnowledge.shared()
	assert_gt(known.strategies.size(), 0, "strategies load")
	for strategy_id: Variant in known.strategies:
		var entry: Dictionary = known.strategies[strategy_id]
		assert_eq(str(entry["id"]), str(strategy_id), "id")
		assert_true(entry.has("name") and entry.has("shape"), str(strategy_id))


# --- The slice's cards ---------------------------------------------------------------------------


func _slice_rules() -> RecruitRules:
	var config: GameConfig = GameConfig.full_game()
	var rules := RecruitRules.create(_library, config, UnitPool.create(_library, config))
	return rules


func _slice_player(rules: RecruitRules) -> PlayerState:
	var player := PlayerState.new()
	player.bot_rng.seed = 8
	player.shop_rng.seed = 8
	player.spell_rng.seed = 8
	rules.setup_player(player)
	return player


func _brain(bot_name: String, player: PlayerState, rules: RecruitRules) -> BotBrain:
	var brain: BotBrain = BotBrain.from_name(bot_name)
	brain._player = player
	brain._rules = rules
	return brain


func _item(rules: RecruitRules, card: String) -> HandItem:
	return HandItem.make(_library.get_card(card), rules.new_iid())


func test_every_id_in_the_bot_data_exists() -> void:
	var known: BotKnowledge = BotKnowledge.shared()
	for card: Variant in known.cards:
		var is_card: bool = not _library.get_unit(str(card)).is_empty()
		is_card = is_card or not _library.get_card(str(card)).is_empty()
		assert_true(is_card, "cards.json: %s" % card)
	for hero: Variant in known.heroes:
		assert_false(_library.get_hero(str(hero)).is_empty(), "heroes: %s" % hero)
	for strategy_id: Variant in known.strategies:
		var entry: Dictionary = known.strategies[strategy_id]
		var units: Dictionary = entry.get("units", {})
		for unit: Variant in units:
			assert_false(_library.get_unit(str(unit)).is_empty(), "%s: %s" % [strategy_id, unit])
		var spells: Dictionary = entry.get("spells", {})
		for spell: Variant in spells:
			assert_false(_library.get_card(str(spell)).is_empty(), "%s: %s" % [strategy_id, spell])


func test_a_unit_that_pays_every_few_turns_stays_pinned() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["sleeping_partner"])
	assert_eq(BotPlacer.pinned_slots(player), [0] as Array[int], "from the start")
	player.board[0].turns_in_slot = 3
	assert_eq(BotPlacer.pinned_slots(player), [0] as Array[int], "and after it has paid")


func test_a_band_pins_its_unit() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["pill_bug"])
	player.bands[0] = player.board[0].iid
	assert_eq(BotPlacer.pinned_slots(player), [0] as Array[int], "moving it would fade the band")


func test_acorns_are_cashed_only_when_gold_is_needed() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	player.items.append(_item(rules, "acorn"))
	player.items.append(_item(rules, "acorn"))
	var brain: BotBrain = _brain("hard", player, rules)
	player.gold = 3
	assert_true(brain._pay(3, 5.0), "has the gold")
	assert_eq(player.items.size(), 2, "keeps both Acorns")
	player.gold = 2
	assert_true(brain._pay(3, 5.0), "cashes to reach it")
	assert_eq([player.gold, player.items.size()], [3, 1], "one Acorn, no more")


func test_a_treasurer_makes_holding_worth_something() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["honorary_treasurer"])
	player.items.append(_item(rules, "acorn"))
	var brain: BotBrain = _brain("hard", player, rules)
	player.gold = 2
	assert_false(brain._pay(3, 0.5), "not for a small gain")
	assert_true(brain._pay(3, 50.0), "yes for a big one")


func test_stats_are_never_aimed_at_a_shy_unit() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["hob_in_the_hearth", "pill_bug"])
	var brain: BotBrain = _brain("hard", player, rules)
	var aim: int = brain._aim_for(HandItem.AIM_UNIT, _library.get_card("pinch_of_dust"))
	assert_eq(aim, 1, "the Pill Bug, though the Hob is worth more")


func test_a_shy_unit_can_take_the_only_empty_slot_even_on_a_ring() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(
		rules,
		player,
		["old_moth_annis", "pill_bug", "pill_bug", "pill_bug", null, "pill_bug", "pill_bug"]
	)
	BoardUpkeep.add_ring(player, 4, {"attack": 2, "health": 2})
	var shy: RecruitUnit = RecruitUnit.make(_library.get_unit("hob_in_the_hearth"), 900)
	var value := BotEval.make(BotLevel.of(BotLevel.HARD), BotKnowledge.shared())
	assert_eq(BotPlacer.play_slot(player, shy, value), 4)


func test_hard_puts_its_carry_where_a_pass_lands() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	_placed(rules, player, ["mr_crumb", "pill_bug", "alderman_dozey"])
	player.pending_passes.append({"iid": player.board[0].iid, "slot": 0, "attack": 1, "health": 1})
	var value := BotEval.make(BotLevel.of(BotLevel.HARD), BotKnowledge.shared())
	var layout: Array[int] = BotPlacer.rule_layout(player, value, [])
	var landings: Array[int] = BotPlacer._pass_landings(player, layout)
	var landed: float = BotPlacer._ring_score(player, value, layout[landings[0]])
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0:
			assert_true(landed >= BotPlacer._ring_score(player, value, layout[slot]), "the carry")


func test_a_pinned_bot_plays_its_strategy() -> void:
	var seats: Array = []
	for strategy_id: String in ["fairies_hag", "hedgerow_parish"]:
		for _copy: int in 4:
			seats.append("hard:%s" % strategy_id)
	for game_seed: int in range(31, 35):
		var config: GameConfig = GameConfig.full_game()
		config.set_value("pass3_preset", "B")
		config.set_value("tribes_per_lobby", 6)
		config.set_value("human_bot", str(seats[0]))
		config.set_value("bots", seats.slice(1))
		var session: GameSession = GameSession.create(game_seed, _library, config)
		_play_out(session)
		var rows: Array = session.get_game_log()["players"]
		var fairy_share: Array[float] = [0.0, 0.0]
		var purchases: Array = []
		for group: int in 2:
			var fairies: int = 0
			var hedgerow: int = 0
			for seat: int in range(group * 4, group * 4 + 4):
				var bought: Dictionary = rows[seat]["bought_by_tribe"]
				fairies += CoreUtil.to_int(bought.get("Fairies", 0))
				hedgerow += CoreUtil.to_int(bought.get("Hedgerow folk", 0))
			fairy_share[group] = float(fairies) / maxi(1, fairies + hedgerow)
			purchases.append({"fairies": fairies, "hedgerow": hedgerow})
		var builds: Array[String] = []
		for seat: int in 8:
			builds.append(session.build_of(seat))
		print(
			"pinned_B_result ",
			JSON.stringify(
				{
					"seed": game_seed,
					"fairy_share": fairy_share,
					"purchases": purchases,
					"builds": builds
				}
			)
		)
		assert_gt(fairy_share[0], 0.6, "B seed %d: the fairy pin buys mostly Fairies" % game_seed)
		assert_lt(
			fairy_share[1], 0.4, "B seed %d: the hedgerow pin buys mostly Hedgerow folk" % game_seed
		)
		for seat: int in 8:
			var expected: String = "fairies_hag" if seat < 4 else "hedgerow_parish"
			assert_eq(
				session.build_of(seat),
				expected,
				"B seed %d seat %d retains its build" % [game_seed, seat]
			)


func test_off_route_cluricaun_requires_seven_ringed_slots_not_stacked_rings() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	var cluricaun: RecruitUnit = kit.put("cluricaun")
	BoardUpkeep.add_ring(kit.player, 4, {"attack": 250, "health": 250})
	var parish: BotBrain = _brain("hard:hedgerow_parish", kit.player, kit.rules)
	parish.value.recruit_rules = kit.rules
	assert_eq(BotPass3.text_value(cluricaun, kit.player, parish.value), 0.0)
	var fairies: BotBrain = _brain("hard:fairies_hag", kit.player, kit.rules)
	fairies.value.recruit_rules = kit.rules
	assert_gt(
		BotPass3.text_value(cluricaun, kit.player, fairies.value),
		0.0,
		"the Fairy route still plans rainbow completion"
	)
	for slot: int in BoardGeometry.SLOTS:
		if slot != 4:
			BoardUpkeep.add_ring(kit.player, slot, {"attack": 1, "health": 1})
	assert_gt(
		BotPass3.text_value(cluricaun, kit.player, parish.value),
		0.0,
		"a full rainbow remains a useful off-route engine"
	)


func _ring_replacement_fixture(engine: bool) -> Dictionary:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.player.gold = 3
	kit.player.tier = 6
	kit.player.round_number = 12
	var old_id: String = kit.card("ring_incumbent", [], ["Fairies"], 2, 3)
	var old: RecruitUnit = kit.put(old_id, 0)
	for slot: int in range(1, BoardGeometry.SLOTS):
		var filler: String = kit.card("ring_filler_%d" % slot, [], [], 5000, 5000)
		kit.put(filler, slot)
	var mechanics: Array = []
	if engine:
		mechanics.append(
			KIT.effect(
				"start_of_combat",
				{"effect": "buff", "attack": 1, "health": 1, "target": {"select": "touching"}}
			)
		)
	var new_id: String = kit.card("ring_recruit", mechanics, ["Hedgerow folk"], 3, 4)
	if engine:
		kit.library.get_unit(new_id)["tier"] = 4
	var recruit: RecruitUnit = kit.shop(new_id)
	BoardUpkeep.add_ring(kit.player, 0, {"attack": 100, "health": 100})
	kit.rules.board_changed(kit.player)
	var brain: BotBrain = _brain("hard:hedgerow_parish", kit.player, kit.rules)
	brain._round_now = 12
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	brain.value.board_owner = kit.player
	return {"kit": kit, "brain": brain, "old": old, "recruit": recruit}


func test_replacement_purchase_and_play_keep_the_destination_ring() -> void:
	var fixture: Dictionary = _ring_replacement_fixture(false)
	var kit: KIT = fixture["kit"]
	var brain: BotBrain = fixture["brain"]
	var recruit: RecruitUnit = fixture["recruit"]
	var ring: Vector2i = BoardUpkeep.ring_value(kit.player.slot_effects[0])
	assert_gt(
		brain._ordinary_unit_gain(recruit), 0.0, "the incumbent does not own the Ring's stats"
	)
	assert_gt(
		brain._replacement_gain(recruit, 0), 0.0, "execution uses the same destination comparison"
	)
	var offer: Dictionary = brain._best_offer()
	assert_false(offer.is_empty())
	assert_true(brain._buy_offer(offer))
	assert_same(kit.player.board[0], recruit)
	assert_false(kit.player.board.has(fixture["old"]))
	assert_eq(recruit.attack, recruit.base_attack_now() + ring.x)
	assert_eq(recruit.health, recruit.base_health_now() + ring.y)
	assert_eq(BoardUpkeep.ring_value(kit.player.slot_effects[0]), ring)


func test_carrier_upgrade_prices_its_engine_on_the_same_destination_ring() -> void:
	var fixture: Dictionary = _ring_replacement_fixture(true)
	var brain: BotBrain = fixture["brain"]
	var recruit: RecruitUnit = fixture["recruit"]
	var plan: Dictionary = BotCarrier.upgrade_plan(brain, recruit)
	assert_eq(plan.get("slot"), 0)
	assert_gt(CoreUtil.to_float(plan.get("gain", 0)), 0.0)


func test_ring_projection_removes_the_current_slot_and_never_buffs_shy() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	var id: String = kit.card("ring_mover", [], [], 3, 4)
	var mover: RecruitUnit = kit.put(id, 0)
	var shy: RecruitUnit = kit.put("lob_lie_by_the_fire", 6)
	BoardUpkeep.add_ring(kit.player, 0, {"attack": 10, "health": 10})
	BoardUpkeep.add_ring(kit.player, 1, {"attack": 30, "health": 30})
	kit.rules.board_changed(kit.player)
	var predicted: int = mover.attack + mover.health + BotEval.ring_change(mover, kit.player, 1)
	assert_eq(kit.rules.move(kit.player, 0, 1), "")
	assert_eq(mover.attack + mover.health, predicted, "moving replaces its old Ring contribution")
	assert_eq(BotEval.ring_change(shy, kit.player, 0), 0)
	var shy_body := Vector2i(shy.attack, shy.health)
	assert_eq(kit.rules.move(kit.player, 6, 0), "")
	assert_eq(
		Vector2i(shy.attack, shy.health), shy_body, "the legal move confirms Shy gets no Ring"
	)


## What the bots may know of the next opponent is what a player can see.
func test_bots_read_only_what_the_scout_view_shows() -> void:
	var session: GameSession = _full_game(["hard", "hard", "hard", "hard"], 5)
	var seen: Array = []
	session.turn_observer = func(player: PlayerState, _r: int, _u: int) -> void:
		if player.id == 0 and not player.scout.is_empty():
			seen.append(player.scout.duplicate())
	for _turn: int in 4:
		session.end_turn()
	assert_gt(seen.size(), 0, "it scouted")
	for value: Variant in seen:
		var scout: Dictionary = value
		var rules: Dictionary = scout["rules"]
		assert_false(rules.has("larder"), "no one can see a Larder")
		assert_true(rules.has("back_row_first"), "hero text is public")
	var state: Dictionary = session.get_state()
	var slots: Array = state["next_opponent_last_slot_effects"]
	assert_eq(slots.size(), BoardGeometry.SLOTS, "the player sees the slots too, one entry each")


func test_a_blind_bot_has_no_scout() -> void:
	var session: GameSession = _full_game(["hard@blind", "hard", "hard", "hard"], 5)
	var blind: Array[bool] = []
	session.turn_observer = func(player: PlayerState, r: int, _u: int) -> void:
		if player.id == 0 and r > 1:
			blind.append(player.scout.is_empty())
	for _turn: int in 3:
		session.end_turn()
	assert_eq(blind, [true, true], "scouting removed")


func test_a_lobby_deals_different_builds() -> void:
	var names: PackedStringArray = PackedStringArray(BotLobby.seats(BotLevel.HARD))
	var tribes: PackedStringArray = ["Fairies", "Hedgerow folk"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var dealt: PackedStringArray = BotLobby.resolve(names, tribes, rng)
	var unique: Dictionary = {}
	for bot_name: String in dealt:
		assert_true(bot_name.begins_with("hard:"), bot_name)
		unique[bot_name] = true
	assert_eq(unique.size(), 7, "no repeats while builds remain")
	assert_false(unique.has("hard:plant_bad"), "test bots aren't dealt")
	rng.seed = 3
	assert_eq(BotLobby.resolve(names, tribes, rng), dealt, "seeded")
	rng.seed = 3
	var no_hedgerow: PackedStringArray = BotLobby.resolve(names, ["Fairies"], rng)
	for bot_name: String in no_hedgerow:
		assert_false(bot_name.contains("hedgerow_"), "only builds open here: %s" % bot_name)


func test_the_next_opponents_hero_is_public() -> void:
	var session: GameSession = _full_game(["hard", "hard", "hard", "hard"], 8)
	session.end_turn()
	var state: Dictionary = session.get_state()
	var opponent: int = state["next_opponent_id"]
	if opponent == Matchmaking.GHOST:
		assert_null(state["next_opponent_hero"], "the ghost has none")
		return
	var hero: Dictionary = state["next_opponent_hero"]
	assert_eq(hero["name"], session.get_standings()[opponent]["hero"], "their hero")
	assert_true(hero.has("text"), "and what it does")


## The bench can seat a dealt bot in seat 0.
func test_seat_zero_can_be_dealt_a_build() -> void:
	var session: GameSession = _full_game(BotLobby.seats(BotLevel.HARD) + ["hard"], 4)
	assert_ne(session.build_of(0), "", "dealt")
	assert_true(BotKnowledge.shared().strategies.has(session.build_of(0)), "a real build")


func test_best_policy_keeps_its_original_offer_rng_consumption() -> void:
	var rules: RecruitRules = _slice_rules()
	var player: PlayerState = _slice_player(rules)
	var brain: BotBrain = _brain("hard", player, rules)
	var reference := RandomNumberGenerator.new()
	reference.state = player.bot_rng.state
	reference.randf_range(-1.0, 1.0)
	brain._unit_gain(RecruitUnit.make(_library.get_unit("field_vole"), 900))
	assert_eq(player.bot_rng.state, reference.state)


func test_only_best_and_tools_yardstick_profiles_exist() -> void:
	assert_eq(BotLevel.ALL, PackedStringArray(["naive", "hard"]))
	var profile: BotLevel = BotLevel.of(BotLevel.HARD)
	assert_eq(profile.search_budget, 20)
	assert_eq(profile.max_refreshes, 30)
	assert_eq(profile.replace_margin, 3.0)
