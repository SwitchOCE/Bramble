extends GutTest
## Scope-review contracts: independent overlays, individually selected cards, and honest text.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")


func _config(sizes: bool = true, rates: bool = true) -> GameConfig:
	var config := GameConfig.defaults()
	config.set_value("card_size_caps", sizes)
	config.set_value("card_rate_limits", rates)
	return config


func test_size_and_rate_switches_are_independent_in_all_four_combinations() -> void:
	var raw: Dictionary = {
		"id": "effect",
		"once": true,
		"lifetime": 3,
		"limit": 1,
		"do": {"effect": "multiply", "most": 8, "per_max": 2},
		"permanent_buff_cap": 12
	}
	for sizes: bool in [false, true]:
		for rates: bool in [false, true]:
			var card: Dictionary = ScaleOverlay.card_for(raw, _config(sizes, rates))
			assert_eq(card.has("permanent_buff_cap"), sizes)
			var step: Dictionary = card["do"]
			assert_eq(step.has("most"), sizes)
			assert_eq(step.has("per_max"), sizes)
			assert_eq(card["once"], rates)
			assert_eq(card.has("lifetime"), rates)
			assert_eq(card["limit"], 1 if rates else BoardUnit.STAT_CLAMP)


func test_each_lever_is_alone_opt_in_and_game_reuses_one_private_library() -> void:
	var source: UnitLibrary = UnitLibrary.load_dir()
	var known: Array = EffectSchema.data()["lever_cards"]
	assert_eq(known.size(), 7)
	for id: String in known:
		var config: GameConfig = _config(false, false)
		config.set_value("scale_levers", [id])
		var session := GameSession.create(127, source, config)
		var library: UnitLibrary = session._library
		assert_ne(library, source)
		assert_eq(session._rules.library, library)
		assert_eq(ScaleOverlay.library_for(library, config), library)
		for other: String in known:
			assert_eq(session._pool.has_unit(other), other == id)
			assert_eq(not library.get_unit(other).is_empty(), other == id)
		for fight: int in 3:
			var rng := RandomNumberGenerator.new()
			rng.seed = fight
			assert_eq(
				Combat.create(library, config, rng).library,
				library,
				"combat construction never overlays"
			)
		assert_eq(source.all_units().size(), 157)


func test_numeric_lever_text_tracks_the_game_dials_and_doubler_copies_add() -> void:
	var config: GameConfig = _config()
	config.set_value(
		"scale_levers", ["scale_engine", "scale_answer", "scale_doubler", "scale_economy"]
	)
	config.set_value("scale_engine_self", true)
	config.set_value("scale_engine_percent", 40)
	config.set_value("scale_answer_percent", 25)
	config.set_value("scale_economy_cap", 7)
	var library: UnitLibrary = ScaleOverlay.library_for(UnitLibrary.load_dir(), config)
	assert_string_contains(library.get_unit("scale_engine")["text"], "+40%")
	assert_string_contains(library.get_unit("scale_engine")["golden_text"], "+80%")
	assert_string_contains(library.get_unit("scale_answer")["text"], "25%")
	assert_eq(
		library.get_unit("scale_doubler")["text"], "Your End of Turn effects trigger an extra time."
	)
	assert_string_contains(library.get_unit("scale_economy")["details"], "7")
	config.set_value("scale_engine_flat", 9)
	library = ScaleOverlay.library_for(library, config)
	assert_string_contains(library.get_unit("scale_engine")["text"], "+9/+9")
	assert_string_contains(library.get_unit("scale_engine")["golden_text"], "+18/+18")
	var kit := KIT.new()
	kit.setup(config)
	kit.library = kit.rules.library
	kit.put("scale_engine", 0)
	kit.put("scale_doubler", 1)
	kit.put("scale_doubler", 4)
	kit.rules.end_phase(kit.player)
	assert_eq(kit.player.board[0].attack, 30, "three additive firings of +9")


func test_new_lever_cards_play_the_shared_mechanics() -> void:
	var config: GameConfig = _config()
	config.set_value("scale_levers", ["scale_biggest_answer", "scale_defender", "scale_cleaver"])
	var kit := KIT.new()
	kit.setup(config)
	kit.library = kit.rules.library
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(kit.library, config, rng)
	combat._setup(
		[
			KIT._board({0: "scale_biggest_answer"}),
			KIT._board(
				{0: "field_vole", 4: {"def_id": "field_vole", "attack": 10000, "health": 20000}}
			)
		]
	)
	combat._start_of_combat()
	assert_eq(combat.unit_at(1, 4).attack, 5000)
	assert_eq(combat.unit_at(1, 4).health, 10000)
	combat = Combat.create(kit.library, config, rng)
	combat._setup([KIT._board({0: "scale_defender"}), KIT._board({0: "field_vole"})])
	var defender: CombatUnit = combat.unit_at(0, 0)
	combat.deal_effect_damage(combat.unit_at(1, 0), defender, 10)
	assert_eq(defender.health, 12)
	assert_false(defender.has_status("shield"))
	combat.deal_effect_damage(combat.unit_at(1, 0), defender, 10)
	assert_eq(defender.health, 4)
	combat = Combat.create(kit.library, config, rng)
	combat._setup(
		[
			KIT._board({0: "scale_cleaver"}),
			KIT._board({0: "field_vole", 1: "field_vole", 2: "field_vole"})
		]
	)
	combat._perform_attack(combat.unit_at(0, 0), combat.unit_at(1, 1))
	assert_eq(combat.units_of(1).size(), 0, "cleave hits both units beside the defender")


func test_overlay_text_keeps_active_limits_and_drops_only_disabled_rules() -> void:
	var source: UnitLibrary = UnitLibrary.load_dir()
	for sizes: bool in [false, true]:
		for rates: bool in [false, true]:
			var config: GameConfig = _config(sizes, rates)
			var library: UnitLibrary = ScaleOverlay.library_for(source, config)
			var toad: Dictionary = library.get_unit("bridge_toad")
			assert_eq(str(toad["text"]).contains("up to"), sizes)
			assert_eq(str(toad["details"]).contains("cap"), sizes)
			var clover: Dictionary = library.get_unit("mrs_clover")
			assert_eq(str(clover["text"]).contains("Twice a turn"), rates)
			assert_eq(str(library.get_unit("prima_donna")["details"]).contains("spent"), rates)
			var mast: Dictionary = library.get_unit("old_mother_mast")
			assert_eq(str(mast["text"]).contains("first unit buy"), rates)
			var snail: Dictionary = library.get_unit("pennywort_snail")
			assert_eq(str(snail["text"]).contains("up to 3 turns"), rates)
			var supper: Dictionary = library.get_card("harvest_supper")
			assert_eq(str(supper["text"]).contains("up to"), sizes)
			assert_eq(str(supper["text"]).contains("Once a turn"), rates)
			var painted: Dictionary = library.get_unit("wee_wobbly")["mechanic_text"]
			assert_eq(str(painted["1"]["text"]).contains("Twice a fight"), rates)
			assert_string_contains(
				library.get_unit("granny_stir_up")["golden_text"], "twice their Attack"
			)
			assert_string_contains(library.get_unit("gabble_ratchet")["details"], "once per Nest")
	assert_string_contains(source.get_unit("bridge_toad")["text"], "up to")


func test_rate_overlay_does_not_disable_size_ceilings_or_trigger_guards() -> void:
	var config: GameConfig = _config(true, false)
	var library: UnitLibrary = ScaleOverlay.library_for(UnitLibrary.load_dir(), config)
	var toad := RecruitUnit.make(library.get_unit("bridge_toad"), 1)
	toad.add_permanent(1000, 1000)
	assert_eq(toad.perm_attack, 3)
	var hero: Dictionary = library.get_hero("hob_mumblecrust")
	assert_eq(HeroRules.uses_per_turn(hero), BoardUnit.STAT_CLAMP)
	var player := PlayerState.new()
	player.card_rate_limits = false
	player.market_stalls = 3
	assert_false(MarketStalls.limit_reached(player))
	assert_true(player.card_size_caps)
	assert_eq(config.get_int("trigger_limit_action"), 1000)
	assert_eq(config.get_int("trigger_limit_combat"), 10000)


func test_percent_hex_recruit_view_reports_percent_and_flat_components_separately() -> void:
	var kit := KIT.new()
	kit.setup()
	kit.card("percent_display", [{"id": "hex", "percent": 25}])
	var unit: RecruitUnit = kit.put("percent_display", 0)
	unit.counters["hex_percent"] = 125
	var view: Dictionary = unit.view()
	assert_eq(view["hex_amount"], 0)
	assert_eq(view["hex_stored"], 0)
	assert_eq(view["hex_percent_amount"], 100)
	assert_eq(view["hex_percent_stored"], 150)


func test_rank_ties_vary_with_fight_seed_and_repeat_for_the_same_seed() -> void:
	var kit := KIT.new()
	kit.setup()
	var seen: Dictionary = {}
	for seed_value: int in range(1, 33):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var combat := Combat.create(kit.library, kit.config, rng)
		combat._setup(
			[KIT._board({0: "field_vole"}), KIT._board({0: "field_vole", 4: "field_vole"})]
		)
		var world := CombatWorld.make(combat, combat.unit_at(0, 0), 0, {}, "start_of_combat")
		var before: int = rng.state
		var target: BoardUnit = (
			TargetSelect.pick({"select": "enemies", "pick": "biggest"}, world)[0]
		)
		seen[world.enemy.find(target)] = true
		rng.state = before
		assert_eq(TargetSelect.pick({"select": "enemies", "pick": "biggest"}, world)[0], target)
	assert_eq(seen.size(), 2)


func test_rate_switch_controls_first_spell_and_free_refresh_without_changing_size_caps() -> void:
	for rates: bool in [false, true]:
		var config: GameConfig = _config(true, rates)
		var kit := KIT.new()
		kit.setup(config)
		kit.library = kit.rules.library
		kit.put("prince_restored", 0)
		kit.player.spells_bought_turn = 1
		var spell := HandItem.make(kit.library.get_card("pinch_of_dust"), 99)
		assert_eq(
			BogFolk.spell_cost(kit.player, spell),
			spell.cost() if rates else maxi(0, spell.cost() - 1)
		)
		HeroRules.assign(kit.player, kit.library.get_hero("sample_thrifty"))
		kit.player.paid_refreshes = 3
		assert_eq(kit.rules.refresh_cost(kit.player), 1 if rates else 0)
		assert_true(kit.player.card_size_caps)


func test_figgy_cooldown_is_a_rate_limit_and_still_consumes_bought_copies() -> void:
	for rates: bool in [false, true]:
		var kit := KIT.new()
		kit.setup(_config(true, rates))
		kit.library = kit.rules.library
		kit.player.round_number = 5
		var figgy: RecruitUnit = kit.put("figgy_duff", 0)
		figgy.counters["figgy_round"] = 5
		var inner: RecruitUnit = kit.put("field_vole")
		inner.origin = RecruitUnit.ORIGIN_BOUGHT
		kit.player.hand.erase(inner)
		figgy.held.append(inner)
		var other: RecruitUnit = kit.put("field_vole", 1)
		other.origin = RecruitUnit.ORIGIN_BOUGHT
		assert_eq(HeldUnits.figgy_pair(kit.rules, kit.player), not rates)
		assert_eq(figgy.held.size(), 1 if rates else 0)
		if not rates:
			assert_eq(kit.player.hand.size(), 1)
			assert_true(kit.player.hand[0].golden)


func test_overlay_text_has_no_disabled_lifetime_or_spent_claims() -> void:
	var library: UnitLibrary = ScaleOverlay.library_for(
		UnitLibrary.load_dir(), _config(false, false)
	)
	for id: String in [
		"peat_cutter",
		"sleeping_partner",
		"pennywort_snail",
		"his_highness",
		"toll_bard",
		"prima_donna"
	]:
		var card: Dictionary = library.get_unit(id)
		for field: String in ["text", "golden_text", "details", "golden_details"]:
			var words: String = str(card.get(field, ""))
			assert_false(words.to_lower().contains("once a"), id)
			assert_false(words.to_lower().contains("twice a"), id)
			assert_false(words.to_lower().contains("times in all"), id)
			assert_false(words.contains(". ."), id)
	assert_eq(str(library.get_unit("prima_donna")["details"]), "")
