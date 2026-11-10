extends GutTest
## Review regressions through the real summon, phase and session paths.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
const Fight := preload("res://tests/core/combat_kit.gd")
const Legacy := preload("res://tests/core/legacy_wave1.gd")


func _combat(kit: Kit, ours: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([Fight.board(ours), Fight.board(theirs)])
	combat._recalc_auras(false)
	return combat


func test_clover_shares_two_buffs_between_recruiting_and_combat_normal_and_golden() -> void:
	for golden: bool in [false, true]:
		for recruit_uses: int in [0, 1, 2]:
			var kit := Kit.new()
			kit.setup(GameConfig.full_game())
			kit.rules.start_phase(kit.player, 1)
			var clover: RecruitUnit = kit.put("mrs_clover", 6, golden)
			for index: int in recruit_uses:
				kit.rules.place_summons(
					kit.player, "drip" if index == 0 else "mouse", false, [index]
				)
				assert_eq(kit.player.board[index].perm_attack, 2 if golden else 1)
			kit.rules.end_phase(kit.player)
			var combat := _combat(kit, {6: clover.combat_spec()}, {0: Fight.plain(0, 100)})
			var source: CombatUnit = combat.unit_at(0, 6)
			for slot: int in [0, 1, 2]:
				var summoned: CombatUnit = combat.summon_into("drip", false, 0, slot, source)
				var stats: int = (2 if golden else 1) if slot < 2 - recruit_uses else 0
				assert_eq(summoned.combat_attack, stats, "recruit uses: %d" % recruit_uses)
				assert_eq(summoned.combat_health, stats)
			assert_eq(source.limits["mrs_clover"], 2)


func test_clover_recruit_limit_resets_at_the_next_recruit_phase() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	var clover: RecruitUnit = kit.put("mrs_clover", 6)
	for slot: int in [0, 1, 2]:
		kit.rules.place_summons(kit.player, ["drip", "mouse", "shrewlet"][slot], false, [slot])
	assert_eq(kit.player.board[0].perm_attack, 1)
	assert_eq(kit.player.board[1].perm_attack, 1)
	assert_eq(kit.player.board[2].perm_attack, 0)
	kit.rules.end_phase(kit.player)
	kit.rules.after_fights(kit.player)
	kit.rules.start_phase(kit.player, 2)
	assert_false(clover.limits.has("mrs_clover"))
	kit.rules.place_summons(kit.player, "kit", false, [3])
	assert_eq(kit.player.board[3].perm_attack, 1)
	assert_eq(clover.limits["mrs_clover"], 1)


func test_clover_does_not_spend_a_buff_on_a_failed_summon() -> void:
	var kit := Kit.new()
	kit.setup()
	var clover: RecruitUnit = kit.put("mrs_clover", 6)
	var fillers: Array[String] = ["field_vole", "pill_bug", "mouse", "shrewlet", "drip", "kit"]
	for slot: int in range(6):
		kit.put(fillers[slot], slot)
	kit.rules.summon_units(kit.player, "drip", 1, false, 0)
	assert_false(clover.limits.has("mrs_clover"))
	kit.player.board[0] = null
	kit.rules.summon_units(kit.player, "drip", 1, false, 1)
	assert_eq(kit.player.board[0].perm_attack, 1)
	assert_eq(clover.limits["mrs_clover"], 1)


func test_elders_buff_their_own_wobbly_drips_only_without_belly_replays() -> void:
	for golden_drip: bool in [false, true]:
		for golden_elder: bool in [false, true]:
			var kit := Kit.new()
			kit.setup(null, false, Legacy.with_oozes(UnitLibrary.load_dir()))
			var combat := _combat(
				kit,
				{
					0: Fight.u("wee_wobbly", 1, 20, golden_drip),
					5: Fight.u("mr_syllabub"),
					6: Fight.u("elder_ooze", -1, -1, golden_elder),
				},
				{
					0: Fight.u("wee_wobbly", 1, 20, golden_drip),
					6: Fight.u("elder_ooze", -1, -1, not golden_elder),
				}
			)
			var source: CombatUnit = combat.unit_at(0, 0)
			combat._attack(source, combat.unit_at(1, 0))
			for side: int in [0, 1]:
				var drip: CombatUnit = combat.unit_at(side, 1)
				var stats: int = 2 if golden_elder == (side == 0) else 1
				assert_eq(drip.def_id(), "drip")
				assert_eq(drip.combat_attack, stats)
				assert_eq(drip.combat_health, stats)
				assert_eq(drip.attack, (2 if golden_drip else 1) + stats)
			var ordinary: CombatUnit = combat.summon_into("drip", false, 0, 2, source)
			assert_eq(ordinary.combat_attack, 0, "ordinary summons do not count as coming out")
			for event: Dictionary in combat.events:
				if event["type"] == "trigger":
					assert_ne(event["mechanic"], "syllabub", "a Drip was never in a Belly")


func test_elder_does_not_buff_returned_enemy_prisoners() -> void:
	var kit := Kit.new()
	kit.setup(null, false, Legacy.with_oozes(UnitLibrary.load_dir()))
	var combat := _combat(
		kit,
		{0: Fight.u("hasty_pudding"), 6: Fight.u("elder_ooze")},
		{0: Fight.plain(1, 10), 6: Fight.u("elder_ooze", -1, -1, true)}
	)
	var holder: CombatUnit = combat.unit_at(0, 0)
	var prisoner: CombatUnit = combat.unit_at(1, 0)
	CombatHeld.swallow(combat, holder, prisoner)
	CombatHeld.return_inside(combat, holder)
	assert_true(prisoner.on_board)
	assert_eq(prisoner.side, 1)
	assert_eq(prisoner.combat_attack, 0)
	assert_eq(prisoner.combat_health, 0)


func test_legacy_syllabub_replays_belly_contents_but_not_friendly_returns_with_native_birds(
) -> void:
	for golden: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(null, false, Legacy.with_oozes(UnitLibrary.load_dir()))
		kit.card(
			"legacy_return_start",
			[
				Kit.effect(
					"start_of_combat",
					{"effect": "buff", "attack": 3, "health": 0, "target": {"select": "self"}}
				)
			],
			["Oozes"],
			1,
			10
		)
		var combat := _combat(
			kit,
			{
				0: Fight.u("little_dollop"),
				1: Fight.u("legacy_return_start"),
				5: Fight.u("mr_syllabub", -1, -1, golden),
				6: Fight.u("chiffchaff")
			},
			{0: Fight.plain(1, 10)}
		)
		assert_true(
			Pass3Combat.has_content(combat), "native Birds must not opt old Syllabub into new rules"
		)
		var holder: CombatUnit = combat.unit_at(0, 0)
		var returned: CombatUnit = combat.unit_at(0, 1)
		CombatHeld.swallow(combat, holder, returned)
		CombatHeld.return_inside(combat, holder)
		assert_eq(returned.attack, 1, "legacy Syllabub never replayed friendly returns")
		assert_eq(Fight.of_type({"events": combat.events}, "trigger").size(), 0)
		holder.held_specs.append({"def_id": "legacy_return_start", "golden": false})
		var released: CombatUnit = CombatHeld.pop_one(combat, holder, false)
		assert_eq(released.attack, 7 if golden else 4, "legacy Belly pop replay remains unchanged")


func test_early_spoils_does_not_pay_either_player_for_a_live_tie() -> void:
	for round_number: int in [1, 4]:
		var config := GameConfig.full_game()
		config.set_value("hero_choice", false)
		var session := GameSession.create(99, UnitLibrary.load_dir(), config)
		session._round = round_number
		for id: int in [0, 1]:
			var player: PlayerState = session._players[id]
			player.board[0] = RecruitUnit.make(session._library.get_unit("field_vole"), 10000 + id)
			player.board[0].attack = 0
		session._fight(0, 1, 0)
		assert_eq(session.get_last_combat()["winner"], -1, "a live stalemate is a tie")
		for id: int in [0, 1]:
			var player: PlayerState = session._players[id]
			assert_eq(player.last_result, "tie")
			assert_eq(player.early_spoils_next_turn, 0)
			assert_eq(player.gold_next_turn, 0)
			assert_true(Kit.of_type(session.get_last_combat(), "early_spoils").is_empty())
			session._rules.start_phase(player, round_number + 1)
			assert_eq(player.early_spoils_income, 0)
