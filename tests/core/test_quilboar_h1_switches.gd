extends GutTest
## H1's frozen-size arm and the reference-only Created-spell economy guard.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _rules: RecruitRules
var _player: PlayerState


func before_each() -> void:
	_setup()


func _setup(reference_on: bool = true, frozen: bool = false, rate_limits: bool = false) -> void:
	var config := GameConfig.full_game()
	config.set_value("reference_quilboar", reference_on)
	config.set_value("reference_quilboar_freeze_size", frozen)
	config.set_value("quilboar_ref_preset", "uncut")
	config.set_value("card_rate_limits", rate_limits)
	config.set_value("card_size_caps", false)
	_kit = KIT.new()
	_kit.setup(config)
	_kit.library = _kit.rules.library
	_rules = _kit.rules
	_player = _kit.player
	_rules.start_phase(_player, 1)
	_kit.spell(
		"qb_h1_free_spell",
		{"effect": "buff", "attack": 1, "health": 1, "target": {"select": "chosen"}},
		"unit",
		{"cost": 0}
	)


func _cast(purchased: bool = false) -> void:
	var item := HandItem.make(_rules.library.get_card("qb_h1_free_spell"), _rules.new_iid())
	if purchased:
		item.paid_cost = 0
		item.pool_copies = 1
	_player.items.append(item)
	assert_eq(_rules.play_item(_player, _player.items.size() - 1, 1), "")


func test_frozen_size_keeps_printed_gems_but_hogrider_and_choices_still_fire() -> void:
	_setup(true, true)
	var hog: RecruitUnit = _kit.put("qb_turbo_hogrider", 0)
	var rat: RecruitUnit = _kit.put("qb_gem_rat", 1)
	var foodie: RecruitUnit = _kit.play("qb_fearless_foodie", 2)
	assert_true(_player.is_choosing())
	assert_eq(_rules.choose(_player, 0), "")
	assert_eq([_player.gem_attack_halves, _player.gem_health_halves], [2, 2])
	assert_eq([hog.gem_attack, rat.gem_attack, foodie.gem_attack], [2, 2, 2])
	_kit.play("qb_sanguine_champion", 3)
	assert_eq([_player.gem_attack_halves, _player.gem_health_halves], [2, 2])


func test_frozen_combat_size_ignores_refiner_and_champion_rewards() -> void:
	_setup(true, true)
	_kit.put("qb_sanguine_refiner", 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 82
	var combat := Combat.create(_kit.library, _kit.config, rng)
	combat.side_rules = [_rules.fight_rules(_player), {}]
	combat._tiers = [6, 6]
	combat._setup([_player.combat_board(), KIT._board({0: "field_vole"})])
	var unit: CombatUnit = combat.unit_at(0, 0)
	var world := CombatWorld.make(combat, unit, 0, {}, "on_attack")
	world.gem_size_add(2, 2)
	world.gem(unit, 3)
	assert_eq(
		[combat.side_rules[0]["gem_attack_halves"], combat.side_rules[0]["gem_health_halves"]],
		[2, 2]
	)
	assert_eq([unit.combat_gem_attack, unit.combat_gem_health], [3, 3])
	assert_eq(combat.carry.size(), 0)


func test_frozen_bot_chooses_real_gems_when_size_modes_have_no_payoff() -> void:
	_setup(true, true)
	_kit.put("qb_turbo_hogrider", 0)
	var brain: BotBrain = BotBrain.from_name("quilboar_choose_one")
	brain._player = _player
	brain._rules = _rules
	brain._round_now = 12
	assert_eq(BotQuilboar.mode(brain, {"item_id": "qb_fearless_foodie"}), 1)
	assert_eq(BotQuilboar.mode(brain, {"item_id": "qb_crater_miner"}), 0)


func test_created_free_spell_refunds_once_per_turn_with_caps_off() -> void:
	_kit.put("cricket_busker", 0)
	_kit.put("field_vole", 1)
	var before: int = _player.gold
	_cast()
	_cast()
	assert_eq(_player.gold, before + 1)
	_rules.start_phase(_player, 2)
	before = _player.gold
	_cast()
	_cast()
	assert_eq(_player.gold, before + 1, "the loop guard resets at the next recruit phase")


func test_native_busker_gets_both_pelt_refunds_in_caps_off_reference_lobby() -> void:
	_kit.put("cricket_busker", 0)
	_kit.put("fox_cub", 1)
	assert_true(_player.reference_quilboar)
	assert_false(_rules.config.get_bool("card_size_caps"))
	assert_false(_rules.config.get_bool("card_rate_limits"))
	var before: int = _player.gold
	assert_eq(_kit.cast("pelt", 1), "")
	assert_eq(_kit.cast("pelt", 1), "")
	assert_eq(_player.gold, before + 2, "native Created spells keep both Busker refunds")


func test_golden_busker_doubles_the_refund_without_repeating_the_created_spell_guard() -> void:
	_kit.put("cricket_busker", 0, true)
	_kit.put("field_vole", 1)
	var before: int = _player.gold
	_cast()
	_cast()
	assert_eq(_player.gold, before + 2)


func test_nonreference_caps_off_busker_behavior_is_unchanged() -> void:
	_setup(false)
	_kit.put("cricket_busker", 0)
	_kit.put("field_vole", 1)
	var before: int = _player.gold
	_cast()
	_cast()
	assert_eq(_player.gold, before + 2)


func test_bought_free_spells_do_not_use_the_reference_created_spell_budget() -> void:
	_kit.put("cricket_busker", 0)
	_kit.put("field_vole", 1)
	var before: int = _player.gold
	_cast(true)
	_cast(true)
	_cast()
	_cast()
	assert_eq(_player.gold, before + 3, "two bought spells plus one Created refund")


func test_gem_day_retains_created_provenance_through_delayed_mode_resolution() -> void:
	_kit.put("cricket_busker", 0)
	_kit.put("qb_gem_rat", 1)
	var before: int = _player.gold
	for _index: int in 2:
		assert_eq(_kit.cast("qb_gem_day"), "")
		assert_true(_player.is_choosing())
		assert_eq(_rules.choose(_player, 0), "")
	assert_eq(_player.gold, before + 1)


func test_authored_rate_limit_still_applies_to_all_spells_when_caps_are_on() -> void:
	_setup(true, false, true)
	_kit.put("cricket_busker", 0)
	_kit.put("field_vole", 1)
	var before: int = _player.gold
	_cast(true)
	_cast(true)
	_cast()
	assert_eq(_player.gold, before + 1)


func _brain(round_number: int = 12) -> BotBrain:
	var brain: BotBrain = BotBrain.from_name("quilboar_choose_one")
	brain._player = _player
	brain._rules = _rules
	brain._round_now = round_number
	brain.value.library = _rules.library
	brain.value.recruit_rules = _rules
	brain.value.board_owner = _player
	_player.round_number = round_number
	_player.tier = 6
	_player.gold = 40
	return brain


func test_four_shop_cycles_leave_created_tunneler_cards_additional() -> void:
	_kit.put("qb_turbo_hogrider", 0)
	_kit.put("qb_gem_rat", 1)
	var brain: BotBrain = _brain()
	var ids: Array[String] = [
		"qb_fearless_foodie",
		"qb_sly_infiltrator",
		"qb_crater_miner",
		"qb_snare_trapper",
		"qb_veteran_brigand"
	]
	for id: String in ids:
		_kit.put(id)
	BotQuilboar._play_hand(brain)
	assert_eq(BotQuilboar._cycle_count(_player), 0, "Created cards do not consume shop cycles")
	assert_true(_player.hand.is_empty(), "more than four Created cards can be played")
	for id: String in ids:
		var unit: RecruitUnit = _kit.put(id)
		unit.origin = RecruitUnit.ORIGIN_BOUGHT
	BotQuilboar._play_hand(brain)
	assert_eq(BotQuilboar._cycle_count(_player), 4)
	assert_eq(_player.hand.size(), 1, "the fifth shop-bought cycle waits")
	var created: RecruitUnit = _kit.put("qb_fearless_foodie")
	BotQuilboar._play_hand(brain)
	assert_eq(
		BotQuilboar._cycle_count(_player), 4, "Created also plays after the shop budget is full"
	)
	assert_false(_player.hand.has(created))
	assert_eq(_player.hand.size(), 1)
	_player.shop.clear()
	_kit.shop("qb_fearless_foodie")
	assert_eq(BotQuilboar._offer(brain), -1, "a fifth shop cycle cannot bypass the budget")
	_rules.start_phase(_player, 13)
	BotQuilboar._play_hand(brain)
	assert_eq(BotQuilboar._cycle_count(_player), 1, "the shop budget resets on a new turn")
	assert_true(_player.hand.is_empty())


func test_trailblazer_uses_foodie_before_gem_day_when_both_are_available() -> void:
	_kit.put("qb_turbo_hogrider", 0)
	_kit.put("qb_gem_rat", 1)
	var trailblazer: RecruitUnit = _kit.put("qb_thorned_trailblazer", 4)
	_kit.put("qb_fearless_foodie")
	_rules.give_card(_player, "qb_gem_day")
	var brain: BotBrain = _brain()
	BotQuilboar._cast_items(brain, false)
	assert_eq(
		_kit.item_ids().count("qb_gem_day"), 1, "hold the Gem Day for Foodie's combined choice"
	)
	BotQuilboar._play_hand(brain)
	var cards: Array[String] = []
	for event: Dictionary in _player.recruit_log:
		if str(event.get("type", "")) == "choose_one":
			cards.append(str(event["card"]))
	assert_eq(cards, ["qb_fearless_foodie", "qb_gem_day"])
	assert_eq(CoreUtil.to_int(trailblazer.limits.get("qb_both", 0)), 1)
	assert_eq([_player.gem_attack_halves, _player.gem_health_halves], [6, 4])


func test_flex_policy_keeps_at_most_two_off_tribe_units_even_with_empty_slots() -> void:
	var a: String = _kit.card("h1_flex_a", [], [], 20, 20)
	var b: String = _kit.card("h1_flex_b", [], [], 10, 10)
	var c: String = _kit.card("h1_flex_c", [], [], 1, 1)
	_kit.put(a, 0)
	_kit.put(b, 1)
	_kit.put(c)
	var brain: BotBrain = _brain(4)
	BotQuilboar._play_hand(brain)
	assert_eq(BotQuilboar._flex_count(_player), 2)
	assert_eq(_player.board_count(), 2, "an empty slot does not permit a third flex keeper")
	assert_eq(_player.hand.size(), 1)


func test_quilboar_replacement_sells_flex_before_an_on_tribe_body() -> void:
	var a: String = _kit.card("h1_strong_flex", [], [], 20, 20)
	var b: String = _kit.card("h1_weak_flex", [], [], 10, 10)
	_kit.put(a, 0)
	_kit.put(b, 1)
	_kit.put("qb_razorfen_geomancer", 2)
	var brain: BotBrain = _brain(4)
	assert_eq(
		BotQuilboar._sell_slot(brain), 1, "flex goes first even when its printed stats are larger"
	)


func test_release_reference_request_has_an_explicit_error_instead_of_a_fallback() -> void:
	var config := GameConfig.defaults()
	config.set_value("reference_quilboar", true)
	var problem: String = ReferenceQuilboar.request_error(config, false)
	assert_string_contains(problem, "requires an editor executable")
	assert_false(ReferenceQuilboar.allowed(config, false))
	assert_eq(ReferenceQuilboar.request_error(config, true), "")
	config.set_value("reference_quilboar", false)
	assert_eq(ReferenceQuilboar.request_error(config, false), "")
	assert_true(ReferenceQuilboar.validate_request(config, false))
