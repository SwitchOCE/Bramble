extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")

var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	combat._start_of_combat()
	return combat


func _receive(combat: Combat) -> void:
	for change: Dictionary in combat.carry:
		if CoreUtil.to_int(change["side"]) == 0:
			kit.rules.apply_carry(kit.player, change)


func _events(combat: Combat, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in combat.events:
		if str(event["type"]) == kind:
			out.append(event)
	return out


func test_real_take_waits_until_next_start_of_turn() -> void:
	var recruit: RecruitUnit = kit.put("little_nip", 0)
	var combat: Combat = _fight({0: recruit.combat_spec()}, {0: CK.plain(1, 1)})
	var hunter: CombatUnit = combat.unit_at(0, 0)
	combat._attack(hunter, combat.unit_at(1, 0))
	assert_eq(hunter.attack, 2, "a Take cannot help win another exchange in this fight")
	assert_eq(hunter.pending_attack, 1)
	assert_eq(hunter.pending_health, 1)
	assert_eq(_events(combat, "gain_pending").size(), 1)
	_receive(combat)
	assert_eq(recruit.attack, 2, "receiving fight carry does not land the gain")
	assert_eq(kit.player.pending_gains.size(), 1)
	kit.rules.after_fights(kit.player)
	assert_eq(recruit.attack, 2, "after-combat listeners still see the old body")
	kit.rules.start_phase(kit.player, 2)
	assert_eq([recruit.attack, recruit.health], [3, 4])
	assert_true(kit.player.pending_gains.is_empty())
	PendingGains.land(kit.rules, kit.player)
	assert_eq(recruit.attack, 3, "draining twice never pays twice")


func test_bridge_toad_uses_the_same_deferred_queue_before_its_tribe_rewrite() -> void:
	var recruit: RecruitUnit = kit.put("bridge_toad", 0)
	var combat: Combat = _fight({0: recruit.combat_spec()}, {0: CK.plain(1, 1)})
	var toad: CombatUnit = combat.unit_at(0, 0)
	combat._attack(combat.unit_at(1, 0), toad)
	assert_eq(toad.attack, 1)
	assert_eq(toad.pending_attack, 1)
	_receive(combat)
	assert_eq(recruit.attack, 1)
	kit.rules.start_phase(kit.player, 2)
	assert_eq([recruit.attack, recruit.health], [2, 4])


func test_pass3_off_keeps_immediate_legacy_take_and_bite_rewards() -> void:
	kit.setup(GameConfig.defaults(), true)
	assert_false(kit.config.get_bool("pass3_content"))
	var nip: RecruitUnit = kit.put("little_nip", 0)
	var combat: Combat = _fight({0: nip.combat_spec()}, {0: CK.plain(1, 1)})
	var fighter: CombatUnit = combat.unit_at(0, 0)
	combat._attack(fighter, combat.unit_at(1, 0))
	assert_eq(fighter.attack, 3, "legacy Take changes its fighting body immediately")
	assert_eq(fighter.pending_attack, 0)
	_receive(combat)
	assert_eq(nip.attack, 3, "legacy permanent carry lands after combat")
	assert_true(kit.player.pending_gains.is_empty())
	var toad: RecruitUnit = kit.put("bridge_toad", 0)
	combat = _fight({0: toad.combat_spec()}, {0: CK.plain(1, 100)})
	fighter = combat.unit_at(0, 0)
	combat._attack(combat.unit_at(1, 0), fighter)
	assert_eq(fighter.attack, 2, "legacy bite reward also grows the fighting body")
	assert_eq(fighter.pending_attack, 0)


func test_take_and_soak_share_one_queue_without_growing_or_healing_a_dead_fighter() -> void:
	var recruit: RecruitUnit = kit.put("little_nip", 0)
	var combat: Combat = _fight({0: recruit.combat_spec()}, {0: CK.plain(1, 100)})
	var fighter: CombatUnit = combat.unit_at(0, 0)
	fighter.damage_taken = fighter.max_health
	fighter.on_board = false
	var before: Array[int] = [
		fighter.attack, fighter.health, fighter.perm_attack, fighter.perm_health
	]
	PendingGains.queue(combat, fighter, 2, 3, fighter, "take")
	PendingGains.queue(combat, fighter, 5, 7, fighter, "soak")
	assert_eq([fighter.attack, fighter.health, fighter.perm_attack, fighter.perm_health], before)
	assert_eq([fighter.pending_attack, fighter.pending_health], [7, 10])
	assert_eq(fighter.view()["pending_attack"], 7)
	_receive(combat)
	assert_eq(kit.player.pending_gains.size(), 2)
	kit.rules.start_phase(kit.player, 2)
	assert_eq([recruit.attack, recruit.health], [9, 13], "fainting did not lose either reward")
	assert_eq(fighter.health, 0, "the departed fighting copy never revives")


func test_queued_gains_are_available_to_start_of_turn_text() -> void:
	kit.card(
		"clock_body",
		[
			{
				"id": "effect",
				"trigger": "start_of_turn",
				"do": {"effect": "multiply", "factor": 2, "target": {"select": "self"}}
			}
		],
		["Hunters"],
		2,
		3
	)
	var unit: RecruitUnit = kit.put("clock_body", 0)
	kit.rules.apply_carry(
		kit.player, {"op": "pending_gain", "iid": unit.iid, "attack": 1, "health": 1}
	)
	kit.rules.start_phase(kit.player, 2)
	assert_eq([unit.attack, unit.health], [6, 8], "3/4 lands before the turn's doubling")


func test_queue_tracks_identity_in_hand_belly_away_and_doorstep() -> void:
	var hand: RecruitUnit = kit.put("little_nip")
	var holder: RecruitUnit = kit.put("wee_wobbly", 0)
	var held: RecruitUnit = kit.put("little_nip")
	kit.player.hand.erase(held)
	holder.held.append(held)
	var away: RecruitUnit = kit.put("one_swallow")
	kit.player.hand.erase(away)
	kit.player.away.append({"unit": away, "left": 1, "due": 20, "nest": -1})
	var doorstep: RecruitUnit = kit.put("little_nip")
	kit.player.hand.erase(doorstep)
	kit.player.doorstep.append(doorstep)
	for unit: RecruitUnit in [hand, held, away, doorstep]:
		kit.rules.apply_carry(
			kit.player, {"op": "pending_gain", "iid": unit.iid, "attack": 3, "health": 4}
		)
	PendingGains.land(kit.rules, kit.player)
	for unit: RecruitUnit in [hand, held, away, doorstep]:
		assert_eq([unit.perm_attack, unit.perm_health], [3, 4])


func test_triples_merge_pending_rewards_without_doubling_them() -> void:
	var copies: Array[RecruitUnit] = [
		kit.put("little_nip", 0), kit.put("little_nip", 1), kit.put("little_nip")
	]
	for index: int in copies.size():
		kit.rules.apply_carry(
			kit.player,
			{
				"op": "pending_gain",
				"iid": copies[index].iid,
				"attack": index + 1,
				"health": index + 1
			}
		)
	kit.rules.combine(kit.player, copies, false)
	var golden: RecruitUnit = kit.player.hand[0]
	assert_true(golden.golden)
	assert_eq(golden.attack, 4)
	PendingGains.land(kit.rules, kit.player)
	assert_eq([golden.attack, golden.health], [10, 12], "all six queued stats land once")


func test_no_recipient_never_moves_the_reward_to_a_replacement_or_a_token() -> void:
	var old: RecruitUnit = kit.put("little_nip", 0)
	kit.rules.apply_carry(
		kit.player, {"op": "pending_gain", "iid": old.iid, "attack": 50, "health": 50}
	)
	kit.player.board[0] = null
	var replacement: RecruitUnit = kit.put("little_nip", 0)
	PendingGains.land(kit.rules, kit.player)
	assert_eq(replacement.attack, 2)
	var combat: Combat = _fight({0: CK.plain(1, 1)}, {0: CK.plain(1, 1)})
	PendingGains.queue(combat, combat.unit_at(0, 0), 5, 5, null, "soak")
	assert_true(combat.carry.is_empty(), "a combat-only token has no recruit copy")


func test_legacy_ceiling_reserves_pending_space_without_becoming_an_extra_cap() -> void:
	var unit: RecruitUnit = kit.put("bridge_toad", 0)
	var combat: Combat = _fight({0: unit.combat_spec()}, {0: CK.plain(1, 100)})
	var fighter: CombatUnit = combat.unit_at(0, 0)
	for index: int in 5:
		PendingGains.queue(combat, fighter, 1, 1, fighter, "soak")
	assert_eq(fighter.pending_attack, 3, "the badge promises only the authored cap's space")
	_receive(combat)
	PendingGains.land(kit.rules, kit.player)
	assert_eq(unit.perm_attack, 3)


func test_pack_joiners_never_cleave_but_their_leader_still_can() -> void:
	var combat: Combat = _fight(
		{0: "grey_agnes", 1: "great_lump"},
		{0: CK.plain(1, 20), 1: CK.plain(1, 20), 2: CK.plain(1, 20)}
	)
	combat._attack(combat.unit_at(0, 0), combat.unit_at(1, 1))
	assert_eq([combat.unit_at(1, 0).health, combat.unit_at(1, 2).health], [20, 20])
	assert_lt(combat.unit_at(1, 1).health, 20, "the Bird's granted Pack still joins")
	combat = _fight({0: "great_lump"}, {0: CK.plain(1, 20), 1: CK.plain(1, 20), 2: CK.plain(1, 20)})
	combat._attack(combat.unit_at(0, 0), combat.unit_at(1, 1))
	assert_lt(combat.unit_at(1, 0).health, 20, "the leading Bird still cleaves")


func test_pack_guard_disabled_reproduces_the_joiner_cleave_failure() -> void:
	kit.config.set_value("pass3_loop_guards", false)
	var combat: Combat = _fight(
		{0: "grey_agnes", 1: "great_lump"},
		{0: CK.plain(1, 20), 1: CK.plain(1, 20), 2: CK.plain(1, 20)}
	)
	combat._attack(combat.unit_at(0, 0), combat.unit_at(1, 1))
	assert_lt(combat.unit_at(1, 0).health, 20, "without the fix a joiner splashes its neighbours")


func test_extra_on_play_firings_cannot_repeat_doubling_or_advance_a_countdown() -> void:
	var unit: RecruitUnit = kit.put("field_vole", 0)
	var ctx := RecruitContext.make(kit.rules, kit.player, "on_play", {})
	ctx.source = unit
	ctx.source_slot = 0
	ctx.repeat_index = 1
	var multiply: Dictionary = {
		"do": {"effect": "multiply", "factor": 2, "target": {"select": "self"}}
	}
	var clock: Dictionary = {
		"every": 2, "counter": "played_clock", "do": {"effect": "gold", "amount": 1}
	}
	EffectRunner.run(multiply, ctx)
	EffectRunner.run(clock, ctx)
	assert_eq(unit.perm_attack, 0)
	assert_false(unit.counters.has("played_clock"))
	kit.config.set_value("pass3_loop_guards", false)
	EffectRunner.run(multiply, ctx)
	EffectRunner.run(clock, ctx)
	assert_gt(unit.perm_attack, 0, "counterexample works for a non-End-of-Turn firing")
	assert_eq(unit.counters["played_clock"], 1)
