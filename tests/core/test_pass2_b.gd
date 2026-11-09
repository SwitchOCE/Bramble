# gdlint:disable=max-public-methods
extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const K := preload("res://tests/core/recruit_kit.gd")
const C := preload("res://tests/core/combat_kit.gd")
var _kit: K


func before_each() -> void:
	_kit = K.new()
	_kit.setup(GameConfig.full_game())
	_kit.rules.start_phase(_kit.player, 1)
	_kit.player.gold = 99


func _combat(ours: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	var fight := Combat.create(_kit.library, _kit.config, rng)
	fight._setup([C.board(ours), C.board(theirs)])
	fight._recalc_auras(false)
	CombatLanes.bell(fight)
	return fight


func test_both_tribes_have_sixteen_pool_cards_at_the_target_tiers() -> void:
	for tribe: String in ["Oozes", "Bog folk"]:
		var counts: Array[int] = [0, 0, 0, 0, 0, 0]
		for card: Dictionary in _kit.library.pool_units("slice"):
			if card["tribes"].has(tribe):
				counts[int(card["tier"]) - 1] += 1
		assert_eq(counts, [3, 3, 3, 3, 2, 2], tribe)


func test_soup_counts_each_recruit_source_and_resets_once_per_turn() -> void:
	for source: String in [HeldUnits.SHOP, HeldUnits.HAND, HeldUnits.BOARD]:
		before_each()
		var soup: RecruitUnit = _kit.put("stone_soup", 0)
		_kit.put("mrs_posset", 1)
		if source == HeldUnits.SHOP:
			_kit.shop("pill_bug")
		else:
			_kit.put("pill_bug", 2 if source == HeldUnits.BOARD else -1)
		var index: int = 2 if source == HeldUnits.BOARD else 0
		if source == HeldUnits.SHOP:
			_kit.player.shop = [_kit.player.shop.back()]
		assert_eq(_kit.rules.swallow(_kit.player, source, index, 1), "")
		assert_eq([soup.attack, soup.health], [2, 4], source)
		_kit.put("field_vole")
		assert_eq(_kit.rules.swallow(_kit.player, HeldUnits.HAND, 0, 0), "")
		assert_eq([soup.attack, soup.health], [2, 4], "once this turn")
		_kit.pass_turn()
		_kit.put("little_dollop", 2)
		_kit.put("pill_bug")
		assert_eq(_kit.rules.swallow(_kit.player, HeldUnits.HAND, 0, 2), "")
		assert_eq([soup.attack, soup.health], [3, 5], "fresh turn")


func test_soup_does_not_gain_from_combat_swallows() -> void:
	var soup: RecruitUnit = _kit.put("stone_soup", 0)
	_kit.put("hasty_pudding", 1)
	_kit.fight_board({1: C.plain(1, 99)})
	assert_eq([soup.perm_attack, soup.perm_health], [0, 0])


func test_ranocchio_rewards_once_even_when_its_attack_is_a_lethal_trade() -> void:
	for golden: bool in [false, true]:
		before_each()
		_kit.put("bridge_toad", 0)
		var tenor: RecruitUnit = _kit.put("signor_ranocchio", 4, golden)
		var fight := _combat(
			{0: _kit.player.board[0].combat_spec(), 4: tenor.combat_spec()}, {0: C.plain(99, 99)}
		)
		var attacker: CombatUnit = fight.unit_at(0, 4)
		var defender: CombatUnit = fight.unit_at(1, 0)
		fight._attack(attacker, defender)
		assert_false(attacker.on_board)
		for change: Dictionary in fight.carry:
			if int(change["side"]) == 0:
				_kit.rules.apply_carry(_kit.player, change)
		var gain: int = 2 if golden else 1
		assert_eq([tenor.perm_attack, tenor.perm_health], [gain, gain])
		assert_eq(int(attacker.limits.get("ranocchio", 0)), 1)


func test_ranocchio_does_not_grow_from_a_non_mired_target() -> void:
	var fight := _combat({0: C.u("signor_ranocchio", 1, 99)}, {0: C.plain(1, 99)})
	var tenor: CombatUnit = fight.unit_at(0, 0)
	fight._attack(tenor, fight.unit_at(1, 0))
	assert_false(tenor.limits.has("ranocchio"))


func test_tiddy_pays_the_attacked_unit_after_a_lethal_hit() -> void:
	var wall: RecruitUnit = _kit.put("madame_bufo", 0)
	_kit.put("tiddy_mun", 4)
	var fight := _combat(
		{0: wall.combat_spec(), 4: _kit.player.board[4].combat_spec()}, {0: C.plain(99, 99)}
	)
	var defender: CombatUnit = fight.unit_at(0, 0)
	fight._attack(fight.unit_at(1, 0), defender)
	assert_false(defender.on_board, "the reward does not revive a lethal hit")
	for change: Dictionary in fight.carry:
		if int(change["side"]) == 0:
			_kit.rules.apply_carry(_kit.player, change)
	assert_eq([wall.perm_attack, wall.perm_health], [1, 1])


func test_tiddy_caps_two_attacks_and_ignores_non_mired_attackers() -> void:
	var fight := _combat(
		{0: C.u("madame_bufo", 0, 99), 4: C.u("tiddy_mun")}, {0: C.plain(1, 99), 1: C.plain(1, 99)}
	)
	var wall: CombatUnit = fight.unit_at(0, 0)
	fight._attack(fight.unit_at(1, 1), wall)
	assert_eq(wall.combat_attack, 0)
	for _index: int in 3:
		fight._attack(fight.unit_at(1, 0), wall)
	assert_eq(wall.combat_attack, 2)
	assert_eq(int(fight.unit_at(0, 4).limits["tiddy_mun"]), 2)


func test_lantern_attack_tracks_new_and_removed_mired_enemies() -> void:
	for golden: bool in [false, true]:
		var fight := _combat(
			{0: C.u("prima_donna"), 4: C.u("lantern_man", -1, -1, golden)},
			{0: C.plain(1, 10), 1: C.plain(1, 10)}
		)
		var lantern: CombatUnit = fight.unit_at(0, 4)
		var each: int = 6 if golden else 3
		assert_eq(lantern.aura_attack, 2 * each)
		fight.deal_effect_damage(null, fight.unit_at(1, 0), 99)
		fight._resolve_deaths(1)
		assert_eq(lantern.aura_attack, each)
		fight.enter_from_spec(C.plain(1, 10), 1, 0, null)
		assert_eq(lantern.aura_attack, 2 * each)
		for slot: int in [0, 1]:
			fight.deal_effect_damage(null, fight.unit_at(1, slot), 99)
		fight._resolve_deaths(1)
		assert_eq(lantern.aura_attack, 0, "no Mired enemy remains")


func test_dying_elders_own_belly_keeps_its_last_known_release_buff() -> void:
	for golden: bool in [false, true]:
		before_each()
		_kit.put("elder_ooze", 0, golden)
		_kit.put("pill_bug")
		assert_eq(_kit.rules.swallow(_kit.player, HeldUnits.HAND, 0, 0), "")
		var fight := _combat({0: _kit.player.board[0].combat_spec()}, {0: C.plain(99, 99)})
		var holder: CombatUnit = fight.unit_at(0, 0)
		fight.deal_effect_damage(null, holder, 999)
		fight._resolve_deaths(0)
		var released: CombatUnit = fight.unit_at(0, 0)
		assert_eq(released.def_id(), "pill_bug")
		assert_eq(released.combat_attack, 2 if golden else 1)
