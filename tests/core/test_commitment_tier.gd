extends GutTest
## Tier-six reasons to stay in a tribe, through real spell and combat entry paths.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")
var _kit: KIT
var _combat: Combat


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	_combat = Combat.create(_kit.library, _kit.config, rng)


func test_monarch_is_a_flat_fairy_ring_bonus_in_both_phases_and_ends_when_removed() -> void:
	_kit.put("fairy_monarch", 0)
	_kit.put("fairy_monarch", 4, true)
	var fairy: RecruitUnit = _kit.put("wisp", 1)
	var neutral: RecruitUnit = _kit.put("pill_bug", 2)
	BoardUpkeep.add_ring(_kit.player, 1, {"attack": 10, "health": 10})
	BoardUpkeep.add_ring(_kit.player, 2, {"attack": 10, "health": 10})
	_kit.rules.board_changed(_kit.player)
	assert_eq(fairy.aura_attack, 7, "four on the capped Ring, one from normal and two from golden")
	assert_eq(neutral.aura_attack, 4, "only Fairies get the extra")
	_combat.slot_effects = [_kit.player.combat_slots(), []]
	_combat._slots_active = true
	_combat._setup([_kit.player.combat_board(), FIGHT.board({0: FIGHT.plain(1, 999)})])
	_combat._recalc_auras(false)
	assert_eq(_combat.unit_at(0, 1).attack, fairy.attack)
	assert_eq(_combat.unit_at(0, 2).attack, neutral.attack)
	_combat.sides[0][0] = null
	_combat.sides[0][4] = null
	_combat._recalc_auras(false)
	assert_eq(_combat.unit_at(0, 1).aura_attack, 4, "the capped Ring survives its Monarchs")


func test_moss_copies_a_spells_actual_gift_into_the_belly_and_golden_doubles_it() -> void:
	for golden: bool in [false, true]:
		_kit.player.board.fill(null)
		_kit.put("moss_ooze", 4, golden)
		var ooze: RecruitUnit = _kit.put("little_dollop", 0)
		var inner: RecruitUnit = RecruitUnit.make(_kit.library.get_unit("field_vole"), 900)
		ooze.held.append(inner)
		assert_eq(_kit.cast("elderflower_cordial", 0), "")
		assert_eq(Vector2i(ooze.perm_attack, ooze.perm_health), Vector2i(1, 2))
		var factor: int = 2 if golden else 1
		assert_eq(Vector2i(inner.perm_attack, inner.perm_health), Vector2i(factor, 2 * factor))


func test_moss_does_not_copy_the_standing_bonus_or_unit_text_or_an_item() -> void:
	_kit.put("moss_ooze", 4)
	var ooze: RecruitUnit = _kit.put("little_dollop", 0)
	var inner: RecruitUnit = RecruitUnit.make(_kit.library.get_unit("field_vole"), 900)
	ooze.held.append(inner)
	assert_eq(_kit.cast("harvest_supper", 0), "")
	assert_eq(ooze.tribe_attack, 1)
	assert_eq(inner.perm_attack, 0)
	var ctx: RecruitContext = RecruitContext.make(_kit.rules, _kit.player, "end_of_turn", {})
	ctx.buff(ooze, 2, 2, "permanent")
	assert_eq(inner.perm_attack, 0, "unit text is not the spell giving stats")
	_kit.spell(
		"test_item",
		{"effect": "buff", "attack": 1, "target": {"select": "chosen"}},
		"unit",
		{"kind": "item"}
	)
	assert_eq(_kit.cast("test_item", 0), "")
	assert_eq(inner.perm_attack, 0)


func test_borrowed_monarch_and_moss_text_work_in_recruit() -> void:
	var borrower: RecruitUnit = _kit.put("frumenty", 4)
	borrower.held.append(RecruitUnit.make(_kit.library.get_unit("fairy_monarch"), 900))
	var fairy: RecruitUnit = _kit.put("wisp", 1)
	BoardUpkeep.add_ring(_kit.player, 1, {"attack": 2, "health": 2})
	_kit.rules.board_changed(_kit.player)
	assert_eq(fairy.aura_attack, 3)
	borrower.held.clear()
	borrower.held.append(RecruitUnit.make(_kit.library.get_unit("moss_ooze"), 901))
	var ooze: RecruitUnit = _kit.put("little_dollop", 0)
	var inner: RecruitUnit = RecruitUnit.make(_kit.library.get_unit("field_vole"), 902)
	ooze.held.append(inner)
	assert_eq(_kit.cast("pinch_of_dust", 0), "")
	assert_eq(inner.perm_attack, 1)


func test_elder_gives_each_friendly_belly_exit_the_same_flat_bonus() -> void:
	for golden: bool in [false, true]:
		var rng := RandomNumberGenerator.new()
		_combat = Combat.create(_kit.library, _kit.config, rng)
		_combat._setup(
			[
				FIGHT.board(
					{0: FIGHT.u("little_dollop"), 4: FIGHT.u("elder_ooze", -1, -1, golden)}
				),
				FIGHT.board({0: FIGHT.plain(1, 999)})
			]
		)
		var holder: CombatUnit = _combat.unit_at(0, 0)
		for _count: int in range(1, 5):
			holder.held_specs = [FIGHT.u("field_vole")]
			var emerged: CombatUnit = CombatHeld.pop_one(_combat, holder, false)
			assert_not_null(emerged)
			var bonus: int = 2 if golden else 1
			assert_eq(emerged.combat_attack, bonus)
			assert_eq(emerged.perm_attack, 0, "the reward ends with the fight")


func test_elder_ignores_a_returned_enemy_and_a_plain_summon() -> void:
	_combat._setup(
		[
			FIGHT.board({0: FIGHT.u("hasty_pudding"), 4: FIGHT.u("elder_ooze")}),
			FIGHT.board({0: FIGHT.plain(1, 999)})
		]
	)
	var holder: CombatUnit = _combat.unit_at(0, 0)
	var enemy: CombatUnit = _combat.enter_from_spec(
		FIGHT.u("field_vole"), 1, 1, holder, {"came_out": true}
	)
	assert_eq(enemy.combat_attack, 0)
	assert_false(_combat.notes.has("ooze_out_0"))
	var summoned: CombatUnit = _combat.enter_from_spec(FIGHT.u("field_vole"), 0, 1, holder)
	assert_eq(summoned.combat_attack, 0)
	assert_false(_combat.notes.has("ooze_out_0"))


func test_laird_pays_all_hunters_after_each_take_and_never_before_or_permanently() -> void:
	_combat._setup(
		[
			FIGHT.board(
				{
					0: FIGHT.u("little_nip", 2, 99),
					1: FIGHT.plain(2, 99),
					4: FIGHT.u("laird_of_sett")
				}
			),
			FIGHT.board({0: FIGHT.plain(1, 1), 1: FIGHT.plain(1, 1)})
		]
	)
	CombatLanes.bell(_combat)
	var hunter: CombatUnit = _combat.unit_at(0, 0)
	var neutral: CombatUnit = _combat.unit_at(0, 1)
	var laird: CombatUnit = _combat.unit_at(0, 4)
	assert_ne(neutral.quarry, 0, "every unit with an enemy across can get a quarry")
	assert_eq(hunter.combat_attack, 0)
	_combat._attack(hunter, _combat.unit_at(1, 0))
	assert_eq(hunter.combat_attack, 2, "Laird +1 and Nip own Take +1")
	assert_eq(laird.combat_attack, 1)
	assert_eq(neutral.combat_attack, 0)
	hunter.quarry = _combat.unit_at(1, 1).uid
	_combat._attack(hunter, _combat.unit_at(1, 1))
	assert_eq(hunter.combat_attack, 4, "two Laird rewards and two Nip rewards")
	assert_eq(laird.combat_attack, 2)
	assert_eq(laird.perm_attack, 0)
	for change: Dictionary in _combat.carry:
		assert_ne(str(change["op"]), "buff")
