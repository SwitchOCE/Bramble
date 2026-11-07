extends GutTest
## Commitment changes through real recruit actions, ownership and combat snapshots.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())


func test_kin_spells_reward_shared_tribes_and_leave_splashes_at_one() -> void:
	_kit.put("field_vole", 1)
	var kin: RecruitUnit = _kit.put("field_vole", 4)
	var other: RecruitUnit = _kit.put("wisp", 5)
	assert_eq(_kit.cast("stand_behind_me", 1), "")
	assert_eq(Vector2i(kin.perm_attack, kin.perm_health), Vector2i(2, 2))
	assert_eq(Vector2i(other.perm_attack, other.perm_health), Vector2i(1, 1))


func test_bonus_applies_everywhere_owned_and_to_later_units_but_not_shop() -> void:
	var board: RecruitUnit = _kit.put("field_vole", 0)
	var hand: RecruitUnit = _kit.put("field_vole")
	var shop: RecruitUnit = _kit.shop("field_vole")
	var ooze: RecruitUnit = _kit.put("little_dollop", 1)
	var inside: RecruitUnit = RecruitUnit.make(_kit.library.get_unit("field_vole"), 900)
	ooze.held.append(inside)
	assert_eq(_kit.cast("harvest_supper", 0), "")
	for unit: RecruitUnit in [board, hand, inside]:
		assert_eq(unit.tribe_attack, 1)
		assert_eq(unit.perm_attack, 0, "separate from permanent unit buffs")
	assert_eq(shop.tribe_attack, 0, "shop is not owned")
	_kit.rules.give_card(_kit.player, "field_vole")
	assert_eq(_kit.player.hand.back().tribe_attack, 1, "a later unit inherits it")
	var spec: Dictionary = board.combat_spec()
	assert_eq(spec["attack"], board.base_attack_now() + 1)


func test_harvest_is_once_a_turn_and_capped_without_consuming_failed_cast() -> void:
	_kit.put("field_vole", 0)
	assert_eq(_kit.cast("harvest_supper", 0), "")
	assert_ne(_kit.cast("harvest_supper", 0), "")
	assert_eq(_kit.player.items.size(), 1, "failed cast stays in hand")
	_kit.player.items.clear()
	for turn: int in [2, 3]:
		_kit.rules.start_phase(_kit.player, turn)
		assert_eq(_kit.cast("harvest_supper", 0), "")
	_kit.rules.start_phase(_kit.player, 4)
	assert_ne(_kit.cast("harvest_supper", 0), "")
	assert_eq(_kit.player.tribe_bonuses["Hedgerow folk"], 3)


func test_dual_tribe_unit_gets_both_bonuses_and_triple_does_not_multiply_them() -> void:
	_kit.card("dual", [], ["Fairies", "Birds"])
	var dual: RecruitUnit = _kit.put("dual", 0)
	_kit.player.tribe_bonuses = {"Fairies": 2, "Birds": 1}
	_kit.rules.board_changed(_kit.player)
	assert_eq(dual.tribe_attack, 3)
	_kit.put("dual")
	_kit.put("dual")
	_kit.rules.check_triples(_kit.player)
	var golden: RecruitUnit = _kit.player.hand[0]
	assert_true(golden.golden)
	assert_eq(golden.tribe_attack, 3)
	assert_eq(golden.perm_attack, 0)


func test_fight_summons_do_not_gain_the_tribe_bonus() -> void:
	_kit.player.tribe_bonuses = {"Fairies": 3}
	_kit.put("will_o_the_wisp", 0)
	BoardUpkeep.add_ring(_kit.player, 1, {"attack": 1, "health": 1})
	_kit.rules.board_changed(_kit.player)
	var result: Dictionary = _kit.fight_board({0: {"def_id": "pill_bug", "health": 999}})
	var summons: Array[Dictionary] = KIT.of_type(result, "summon")
	assert_gt(summons.size(), 0)
	for event: Dictionary in summons:
		var unit: Dictionary = event["unit"]
		if str(unit["def_id"]) == "wisp":
			assert_eq(unit["attack"], 1, "printed summon before Ring recalculation; no tribe bonus")


func test_hiring_fair_reserves_one_distinct_tier_six_of_committed_tribe() -> void:
	for slot: int in 5:
		_kit.put("field_vole", slot)
	var before: int = _kit.pool.total_copies()
	assert_eq(_kit.cast("hiring_fair"), "")
	var options: PackedStringArray = _kit.player.pending[0]["options"]
	assert_eq(options.size(), 3)
	assert_eq(_kit.pool.total_copies(), before - 3)
	var kin: int = 0
	var distinct: Dictionary = {}
	for id: String in options:
		distinct[id] = true
		assert_eq(_kit.library.get_unit(id)["tier"], 6)
		if _kit.library.get_unit(id)["tribes"].has("Hedgerow folk"):
			kin += 1
	assert_eq(distinct.size(), 3)
	assert_gt(kin, 0)
	assert_eq(_kit.rules.choose(_kit.player, 0), "")
	assert_eq(_kit.pool.total_copies(), before - 1)


func test_queen_does_not_feed_an_unrelated_tribe() -> void:
	_kit.put("queen_of_elfland", 0)
	_kit.put("field_vole", 4)
	var fairy: RecruitUnit = _kit.put("wisp", 1)
	var unrelated: RecruitUnit = _kit.put("pill_bug", 2)
	for _turn: int in 3:
		_kit.rules.end_phase(_kit.player)
	assert_gt(fairy.perm_attack, 0)
	assert_eq(unrelated.perm_attack, 0)


func test_golden_burner_burns_eight_at_same_rate() -> void:
	_kit.put("charcoal_burner", 0, true)
	var behind: RecruitUnit = _kit.put("pill_bug", 4)
	_kit.player.gold = 100
	_kit.rules.end_phase(_kit.player)
	assert_eq(_kit.player.gold, 92)
	assert_eq(behind.perm_attack, 4)


func test_capped_unit_keeps_tribe_bonus_as_separate_combat_layer() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", 0)
	dozey.add_permanent(12, 12)
	_kit.player.tribe_bonuses = {"Hedgerow folk": 3}
	_kit.rules.board_changed(_kit.player)
	var fighter: CombatUnit = CombatUnit.make(dozey.def, dozey.combat_spec(), 1, 0)
	assert_eq(fighter.perm_attack, 12)
	assert_eq(fighter.tribe_attack, 3)
	assert_eq(fighter.attack, dozey.attack)
	assert_eq(fighter.health, dozey.health)
	_kit.rules.apply_carry(_kit.player, {"op": "buff", "iid": dozey.iid, "attack": 1, "health": 1})
	assert_eq(dozey.perm_attack, 12, "fight carry still respects the printed cap")
	assert_eq(dozey.tribe_attack, 3, "the owner layer stays separate")


func test_hiring_fair_four_units_uses_the_normal_discover_draw() -> void:
	var control: KIT = KIT.new()
	control.setup(GameConfig.full_game())
	for slot: int in 4:
		_kit.put("field_vole", slot)
	assert_eq(_kit.cast("hiring_fair"), "")
	control.rules.discover(control.player, {"count": 3, "tier": 6})
	assert_eq(_kit.player.pending[0]["options"], control.player.pending[0]["options"])


func test_hiring_fair_exhausted_kin_still_offers_three_and_preserves_pool_counts() -> void:
	for slot: int in 5:
		_kit.put("field_vole", slot)
	while _kit.pool.take("old_mother_mast"):
		pass
	var before: int = _kit.pool.total_copies()
	assert_eq(_kit.cast("hiring_fair"), "")
	var options: PackedStringArray = _kit.player.pending[0]["options"]
	assert_eq(options.size(), 3)
	assert_eq(_kit.pool.total_copies(), before - 3)
	assert_false(options.has("old_mother_mast"), "an exhausted copy cannot be created")


func test_legal_actions_hide_neutral_capped_and_already_used_harvest_targets() -> void:
	var session: GameSession = GameSession.create(71, _kit.library, GameConfig.full_game())
	while session.get_state()["pending_choice"] != null:
		session.choose(0)
	var player: PlayerState = session._players[GameSession.HUMAN_ID]
	player.board.fill(null)
	player.board[0] = RecruitUnit.make(_kit.library.get_unit("field_vole"), 900)
	player.board[1] = RecruitUnit.make(_kit.library.get_unit("pill_bug"), 901)
	player.items = [HandItem.make(_kit.library.get_card("harvest_supper"), 902)]
	var plays: Array = []
	for action: Dictionary in LegalActions.of(session.get_state()):
		if str(action["action"]) == "play_item":
			plays.append(action["args"])
	assert_eq(plays, [[0, 0]], "only the unit with a tribe can be aimed at")
	player.harvest_supper_round = player.round_number
	plays.clear()
	for action: Dictionary in LegalActions.of(session.get_state()):
		if str(action["action"]) == "play_item":
			plays.append(action["args"])
	assert_true(plays.is_empty(), "once a turn is visible to action users")
	player.harvest_supper_round = -1
	player.tribe_bonuses = {"Hedgerow folk": 3}
	plays.clear()
	for action: Dictionary in LegalActions.of(session.get_state()):
		if str(action["action"]) == "play_item":
			plays.append(action["args"])
	assert_true(plays.is_empty(), "a capped tribe does not waste the spell")


func test_golden_units_keep_one_tribe_bonus_in_total_attack_and_health() -> void:
	var golden: RecruitUnit = _kit.put("field_vole", 0, true)
	golden.add_permanent(1, 2)
	_kit.player.tribe_bonuses = {"Hedgerow folk": 3}
	_kit.rules.board_changed(_kit.player)
	assert_eq(
		golden.attack, 8, "4 printed + 1 permanent + 3 tribe; golden does not double the bonus"
	)
	assert_eq(
		golden.health, 11, "6 printed + 2 permanent + 3 tribe; golden does not double the bonus"
	)
	var fighter: CombatUnit = CombatUnit.make(golden.def, golden.combat_spec(), 1, 0)
	assert_eq(fighter.attack, 8, "combat keeps the same total Attack")
	assert_eq(fighter.health, 11, "combat keeps the same total Health")
