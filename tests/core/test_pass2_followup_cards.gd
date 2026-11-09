# gdlint:disable=max-public-methods
extends GutTest
## Follow-up card amendments: bounded growth, lifetime income and touching buffs.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")
var _kit: KIT
var _combat: Combat


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	_combat = Combat.create(_kit.library, _kit.config, rng)


func _setup_owned(enemies: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	_combat = Combat.create(_kit.library, _kit.config, rng)
	_combat._setup([_kit.player.combat_board(), FIGHT.board(enemies)])
	_combat._recalc_auras(false)
	CombatLanes.bell(_combat)


func _carry_home() -> void:
	for change: Dictionary in _combat.carry:
		if change["side"] == 0:
			_kit.rules.apply_carry(_kit.player, change)


func test_bridge_lethal_hit_keeps_growth_without_reviving_the_fighter() -> void:
	var owned: RecruitUnit = _kit.put("bridge_toad", 0)
	_setup_owned({0: FIGHT.plain(10, 50)})
	var wall: CombatUnit = _combat.unit_at(0, 0)
	_combat._attack(_combat.unit_at(1, 0), wall)
	assert_false(wall.on_board)
	assert_lte(wall.health, 0)
	_carry_home()
	assert_eq([owned.attack, owned.health], [2, 4])
	assert_eq(_kit.player.gold_next_turn, 0)


func test_bridge_banked_growth_stays_at_cap_across_fights_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		var owned: RecruitUnit = _kit.put("bridge_toad", 0, golden)
		var factor: int = 2 if golden else 1
		for fight: int in 5:
			_setup_owned({0: FIGHT.plain(0, 50)})
			_combat._attack(_combat.unit_at(1, 0), _combat.unit_at(0, 0))
			_carry_home()
			var growth: int = mini(fight + 1, 3) * factor
			assert_eq([owned.perm_attack, owned.perm_health], [growth, growth])
		assert_eq([owned.attack, owned.health], [4 * factor, 6 * factor])


func test_bridge_existing_permanent_buffs_share_the_printed_ceiling() -> void:
	var owned: RecruitUnit = _kit.put("bridge_toad", 0)
	owned.add_permanent(2, 3)
	_setup_owned({0: FIGHT.plain(0, 50)})
	_combat._attack(_combat.unit_at(1, 0), _combat.unit_at(0, 0))
	_carry_home()
	assert_eq([owned.perm_attack, owned.perm_health], [3, 3])


func test_cutter_pays_once_per_fight_three_times_in_all_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		before_each()
		_kit.put("prima_donna", 1)
		var cutter: RecruitUnit = _kit.put("peat_cutter", 4, golden)
		var factor: int = 2 if golden else 1
		for fight: int in 4:
			_setup_owned({0: FIGHT.plain(0, 20), 1: FIGHT.plain(0, 20), 2: FIGHT.plain(0, 20)})
			for slot: int in 3:
				_combat.deal_effect_damage(null, _combat.unit_at(1, slot), 999)
				_combat._resolve_deaths(1)
			_carry_home()
			assert_eq(_kit.player.gold_next_turn, mini(fight + 1, 3) * factor)
			assert_eq(cutter.counters.get("paid_peat_cutting", 0), mini(fight + 1, 3))


func test_cutter_unmired_death_does_not_spend_a_lifetime_payment() -> void:
	var cutter: RecruitUnit = _kit.put("peat_cutter", 0)
	_setup_owned({1: FIGHT.plain(0, 20)})
	_combat.deal_effect_damage(null, _combat.unit_at(1, 1), 999)
	_combat._resolve_deaths(1)
	_carry_home()
	assert_eq(cutter.counters.get("paid_peat_cutting", 0), 0)
	assert_eq(_kit.player.gold_next_turn, 0)


func test_prima_donna_bitter_is_two_and_golden_four() -> void:
	for golden: bool in [false, true]:
		_kit.put("prima_donna", 0, golden)
		_setup_owned({0: FIGHT.plain(10, 50)})
		var wall: CombatUnit = _combat.unit_at(0, 0)
		var attacker: CombatUnit = _combat.unit_at(1, 0)
		_combat._attack(attacker, wall)
		assert_eq(attacker.attack, 6 if golden else 8)


func test_committee_touching_and_full_bonuses_double_on_golden() -> void:
	for golden: bool in [false, true]:
		for full: bool in [false, true]:
			before_each()
			var committee: RecruitUnit = _kit.put("standing_committee", 0, golden)
			var factor: int = 2 if golden else 1
			assert_eq([committee.attack, committee.health], [5 * factor, 7 * factor])
			for slot: int in [1, 2, 3, 4, 5, 6] if full else [2, 4]:
				_kit.put("field_vole", slot)
			_setup_owned({0: FIGHT.plain(0, 50)})
			_combat._start_of_combat()
			var bonus: int = (2 if full else 1) * factor
			var wall: CombatUnit = _combat.unit_at(0, 0)
			assert_eq([wall.attack, wall.max_health], [5 * factor + bonus, 8 * factor])
			var touching: CombatUnit = _combat.unit_at(0, 4)
			assert_eq([touching.combat_attack, touching.combat_health], [bonus, factor])
			if not full:
				var isolated: CombatUnit = _combat.unit_at(0, 2)
				assert_eq([isolated.combat_attack, isolated.combat_health], [0, 0])
			_carry_home()
			assert_eq([committee.attack, committee.health], [5 * factor, 7 * factor])
