# gdlint:disable=max-public-methods
extends GutTest
## Ask 3: real slice exchanges retain their causes and rewards without phantom attacks or heals.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")
var _kit: KIT
var _combat: Combat


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	var rng := RandomNumberGenerator.new()
	rng.seed = 56
	_combat = Combat.create(_kit.library, _kit.config, rng)


func _start(ours: Array, theirs: Array) -> void:
	_combat._setup([ours, theirs])
	_combat._recalc_auras(false)
	_combat.emit_event(
		"combat_start",
		{
			"boards": [_combat._board_views(0), _combat._board_views(1)],
			"player_ids": [0, 1],
			"first_side": 0
		}
	)
	CombatLanes.bell(_combat)


func _setup(ours: Dictionary, theirs: Dictionary) -> void:
	_start(FIGHT.board(ours), FIGHT.board(theirs))


func _events(kind: String) -> Array[Dictionary]:
	return FIGHT.of_type({"events": _combat.events}, kind)


func _stats_for(uid: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in _events("stats"):
		if event["target"] == uid:
			out.append(event)
	return out


func _apply_carry() -> void:
	for change: Dictionary in _combat.carry:
		_kit.rules.apply_carry(_kit.player, change)


func test_snap_target_queries_are_silent_and_the_real_turn_announces_its_attack() -> void:
	_setup({0: FIGHT.u("bridge_toad"), 4: FIGHT.u("young_pretender")}, {0: FIGHT.u("sable", 1, 20)})
	var frog: CombatUnit = _combat.unit_at(0, 4)
	var before: int = _combat.events.size()
	for _query: int in 4:
		assert_eq(_combat._choose_target(frog), _combat.unit_at(1, 0))
	assert_eq(_combat.events.size(), before, "reading a target does not announce an attack")
	_combat.unit_at(0, 0).flagged = true
	_combat._take_turn(0)
	var snaps: int = 0
	for event: Dictionary in _events("trigger"):
		if event["mechanic"] == "snap":
			snaps += 1
			var next: Dictionary = _combat.events[int(event["seq"]) + 1]
			assert_eq(next["type"], "attack")
			assert_eq(next["attacker"], frog.uid)
	assert_eq(snaps, 1)


func test_a_dead_snap_frog_has_no_target_or_new_attack_but_keeps_its_trade_reward() -> void:
	_setup({0: FIGHT.u("bridge_toad"), 4: FIGHT.u("young_pretender")}, {0: FIGHT.u("sable", 2, 3)})
	var frog: CombatUnit = _combat.unit_at(0, 4)
	_combat.unit_at(0, 0).flagged = true
	_combat._take_turn(0)
	assert_false(frog.on_board, "the frog and its Mired quarry trade")
	var before: int = _combat.events.size()
	assert_null(_combat._choose_target(frog, true))
	_combat._attack(frog, _combat.unit_at(0, 0))
	assert_eq(_combat.events.size(), before, "a stale reference cannot announce a new attack")
	var gold: int = 0
	for change: Dictionary in _combat.carry:
		gold += int(change.get("amount", 0))
	assert_eq(gold, 1, "the simultaneous kill still earns the Pretender's gold")
	var rewards: int = 0
	for event: Dictionary in _events("trigger"):
		if event["mechanic"] == "snap_kill":
			rewards += 1
	assert_eq(rewards, 1, "a kill reward is a separate event from Snap targeting")
	assert_eq(_events("damage").size(), 2)
	assert_eq(_events("death").size(), 2)


func test_a_dying_glutton_is_not_buffed_or_resurrected_by_a_simultaneous_take() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 20), 4: FIGHT.u("mountain_glutton", 4, 1)},
		{0: FIGHT.u("sable", 1, 2)}
	)
	var glutton: CombatUnit = _combat.unit_at(0, 4)
	var hunter: CombatUnit = _combat.unit_at(0, 0)
	var quarry: CombatUnit = _combat.unit_at(1, 0)
	_combat.deal_effect_damage(quarry, glutton, 1)
	_combat.deal_effect_damage(hunter, quarry, 2)
	_combat._resolve_deaths(0)
	assert_false(glutton.on_board)
	assert_lte(glutton.health, 0)
	assert_eq(glutton.attack, 4, "a combat buff cannot be gained after its recipient died")
	assert_true(_stats_for(glutton.uid).is_empty())
	assert_eq(_events("take").size(), 1)
	assert_eq(_events("damage").size(), 2)
	assert_eq(_events("death").size(), 2)


func test_a_dead_wick_does_not_get_after_join_growth() -> void:
	_setup({0: FIGHT.u("little_nip"), 1: FIGHT.u("wick")}, {0: FIGHT.u("sable")})
	var wick: CombatUnit = _combat.unit_at(0, 1)
	_combat.deal_effect_damage(null, wick, 99)
	_combat._resolve_deaths(0)
	_combat.reactions.pack_joiners = [wick]
	CombatHunt.after_attack(_combat, _combat.unit_at(0, 0), "")
	assert_true(_stats_for(wick.uid).is_empty())
	assert_eq(wick.attack, 2)


func test_gideons_lethal_counter_keeps_damage_and_death_without_a_cleanup_buff_on_his_corpse(
) -> void:
	_setup({0: FIGHT.u("gideon", 2, 5)}, {0: FIGHT.u("sable", 3, 100)})
	var gideon: CombatUnit = _combat.unit_at(0, 0)
	_combat._attack(_combat.unit_at(1, 0), gideon)
	assert_false(gideon.on_board)
	assert_eq(_events("immediate_attack").size(), 1)
	assert_eq(_events("damage").size(), 4, "both exchanges keep both damage hits")
	var died: bool = false
	for event: Dictionary in _combat.events:
		if event["type"] == "death" and event["uid"] == gideon.uid:
			died = true
		if died and event["type"] == "stats":
			assert_ne(event["target"], gideon.uid, "the temporary bonus is not removed on a corpse")


func test_bitter_does_not_report_an_attack_loss_on_an_already_lethal_attacker() -> void:
	_setup({0: FIGHT.u("madame_bufo", 1, 4)}, {0: FIGHT.u("little_nip", 5, 1)})
	var attacker: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(attacker, _combat.unit_at(0, 0))
	assert_eq(_events("death").size(), 2)
	assert_true(_stats_for(attacker.uid).is_empty())


func test_grizel_rewards_the_leader_that_traded_without_a_fake_live_stat_line() -> void:
	var nip: RecruitUnit = _kit.put("little_nip", 0)
	_kit.put("grizel", 1)
	_start(_kit.player.combat_board(), FIGHT.board({0: FIGHT.u("sable", 2, 6)}))
	var leader: CombatUnit = _combat.unit_at(0, 0)
	_combat._attack(leader, _combat.unit_at(1, 0))
	assert_false(leader.on_board)
	assert_lte(leader.health, 0, "the permanent reward does not save its combat copy")
	assert_true(_stats_for(leader.uid).is_empty())
	var rewards: Array[Dictionary] = _events("permanent_reward")
	assert_eq(rewards.size(), 2, "Nip own Take and Grizel each reward the trade")
	for reward: Dictionary in rewards:
		assert_eq(reward["target"], leader.uid)
		assert_eq(reward["attack_delta"], 1)
	_apply_carry()
	assert_eq(nip.perm_attack, 2, "Nip and Grizel each add Attack")
	assert_eq(nip.perm_health, 1, "only Nip adds Health")
	var our_takes: int = 0
	for event: Dictionary in _events("take"):
		our_takes += 1 if event["side"] == 0 else 0
	assert_eq(our_takes, 1, "the trading Hunter still witnesses its Take")


func test_tiddys_lethal_attack_reward_reaches_recruit_without_reviving_it() -> void:
	_kit.put("natterjack_chorus", 5)
	var tiddy: RecruitUnit = _kit.put("tiddy_mun", 4)
	_start(_kit.player.combat_board(), FIGHT.board({4: FIGHT.u("sable", 99, 99)}))
	var spirit: CombatUnit = _combat.unit_at(0, 4)
	_combat._attack(_combat.unit_at(1, 4), spirit)
	assert_false(spirit.on_board)
	assert_lte(spirit.health, 0)
	assert_true(_stats_for(spirit.uid).is_empty())
	assert_eq(_events("permanent_reward").size(), 1)
	_apply_carry()
	assert_eq(tiddy.perm_attack, 1)
	assert_eq(tiddy.perm_health, 1)
	assert_eq(_events("death").size(), 1)


func test_multiple_trade_rewards_keep_the_real_slice_permanent_ceiling() -> void:
	_kit.put("grizel", 0)
	var dozey: RecruitUnit = _kit.put("alderman_dozey", 1)
	dozey.add_permanent(11, 11)
	_kit.put("grizel", 2)
	_start(_kit.player.combat_board(), FIGHT.board({1: FIGHT.u("sable", 100, 10)}))
	var leader: CombatUnit = _combat.unit_at(0, 1)
	_combat._attack(leader, _combat.unit_at(1, 1))
	assert_false(leader.on_board)
	var earned: int = 0
	for reward: Dictionary in _events("permanent_reward"):
		if reward["target"] == leader.uid:
			earned += int(reward["attack_delta"])
	assert_eq(earned, 1, "only the gain that fits the ceiling is reported")
	_apply_carry()
	assert_eq(dozey.perm_attack, 12)
	assert_eq(dozey.perm_health, 11)


func test_a_lethal_health_debuff_on_a_living_unit_still_explains_the_death() -> void:
	_setup({0: FIGHT.u("little_nip")}, {0: FIGHT.u("sable")})
	var target: CombatUnit = _combat.unit_at(1, 0)
	_combat.buff(target, 0, -3, _combat.unit_at(0, 0))
	_combat._resolve_deaths(0)
	assert_eq(_stats_for(target.uid).size(), 1)
	assert_eq(_stats_for(target.uid)[0]["health_delta"], -3)
	assert_eq(_events("death").size(), 1)


func test_peat_king_reports_full_board_without_using_a_summon_and_can_use_a_later_gap() -> void:
	var ours: Dictionary = {1: FIGHT.u("prima_donna"), 5: FIGHT.u("peat_king")}
	for slot: int in [0, 2, 3, 4, 6]:
		ours[slot] = FIGHT.u("warty_nan", 1, 20)
	_setup(ours, {0: FIGHT.u("sable", 1, 1), 1: FIGHT.u("little_nip", 1, 1)})
	var king: CombatUnit = _combat.unit_at(0, 5)
	_combat.deal_effect_damage(null, _combat.unit_at(1, 0), 1)
	_combat._resolve_deaths(0)
	assert_eq(_events("no_room").size(), 1)
	assert_eq(_events("no_room")[0]["uid"], king.uid)
	assert_eq(_events("no_room")[0]["mechanic"], "peat_king")
	assert_eq(_events("no_room")[0]["def_id"], "peatling")
	assert_eq(int(king.limits.get("peat_king", 0)), 0)
	_combat.deal_effect_damage(null, _combat.unit_at(0, 4), 99)
	_combat._resolve_deaths(0)
	_combat.deal_effect_damage(null, _combat.unit_at(1, 1), 1)
	_combat._resolve_deaths(0)
	assert_eq(_events("summon").size(), 1)
	assert_eq(int(king.limits.get("peat_king", 0)), 1)
