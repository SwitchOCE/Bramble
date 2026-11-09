# gdlint:disable=max-public-methods
extends GutTest
## Pack rewards distinguish killing attack damage, joining, leading and return hits.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func _owned(id: String, attack: int = 4, health: int = 100, golden: bool = false) -> Dictionary:
	var spec: Dictionary = CK.u(id, attack, health, golden)
	spec["iid"] = 71
	return spec


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	combat._start_of_combat()
	return combat


func test_wick_and_grizel_reward_only_the_pack_attackers_and_queue_their_shares() -> void:
	var combat: Combat = _fight(
		{0: _owned("little_nip"), 1: _owned("wick", 3), 4: _owned("grizel")}, {0: CK.plain(9, 6)}
	)
	var leader: CombatUnit = combat.unit_at(0, 0)
	var wick: CombatUnit = combat.unit_at(0, 1)
	combat._attack(leader, combat.unit_at(1, 0))
	assert_eq([leader.pending_attack, leader.pending_health], [9, 6], "Take plus Grizel")
	assert_eq([wick.pending_attack, wick.pending_health], [6, 4], "Wick plus Grizel")
	assert_eq(combat.unit_at(0, 4).pending_attack, 0, "Grizel did not join this attack")
	assert_eq(leader.attack, 4)


func test_wick_does_not_grow_from_a_join_without_a_kill_or_when_it_leads() -> void:
	var combat: Combat = _fight(
		{0: CK.u("little_nip", 1, 100), 1: _owned("wick", 1)}, {0: CK.plain(0, 100)}
	)
	var wick: CombatUnit = combat.unit_at(0, 1)
	combat._attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
	assert_eq(wick.pending_attack, 0)
	combat.unit_at(1, 0).damage_taken = 99
	combat.unit_at(0, 0).flagged = true
	combat._attack(wick, combat.unit_at(1, 0))
	assert_eq(wick.pending_attack, 0, "the Wick ability rewards joining, not leading")


func test_grizel_and_dying_leader_share_a_simultaneous_pack_kill_without_healing() -> void:
	var combat: Combat = _fight(
		{0: _owned("grizel", 4, 1), 1: _owned("wick", 3)}, {0: CK.plain(90, 6)}
	)
	var grizel: CombatUnit = combat.unit_at(0, 0)
	var wick: CombatUnit = combat.unit_at(0, 1)
	combat._attack(grizel, combat.unit_at(1, 0))
	assert_false(grizel.on_board)
	assert_lte(grizel.health, 0)
	assert_eq([grizel.pending_attack, grizel.pending_health], [30, 2])
	assert_eq([wick.pending_attack, wick.pending_health], [60, 4])


func test_bristle_kill_is_a_take_but_not_a_pack_kill() -> void:
	var leader_spec: Dictionary = _owned("little_nip", 1)
	leader_spec["grants"] = [{"entry": {"id": "bristle", "n": 20}, "golden": false}]
	var combat: Combat = _fight({0: leader_spec, 1: _owned("wick", 1)}, {0: CK.plain(5, 20)})
	var leader: CombatUnit = combat.unit_at(0, 0)
	var wick: CombatUnit = combat.unit_at(0, 1)
	combat._attack(leader, combat.unit_at(1, 0))
	assert_eq(combat.takes[0], 1)
	assert_eq(leader.pending_attack, 3)
	assert_eq(wick.pending_attack, 0)


func test_agnes_reduces_only_pack_leader_return_hits_and_strongest_source_applies() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight(
			{
				0: CK.u("little_nip", 1, 100),
				1: "wick",
				4: CK.u("grey_agnes", -1, -1, golden),
				6: "grey_agnes"
			},
			{0: CK.plain(9, 100)}
		)
		var leader: CombatUnit = combat.unit_at(0, 0)
		var enemy: CombatUnit = combat.unit_at(1, 0)
		combat._attack(leader, enemy)
		assert_eq(leader.health, 97 if golden else 95)
		combat.deal_effect_damage(enemy, leader, 9)
		assert_eq(leader.health, 88 if golden else 86)
		combat._attack(enemy, leader)
		assert_eq(leader.health, 79 if golden else 77, "an enemy's attack is not a return hit")


func test_brother_wolf_prioritizes_both_neighbours_and_joins_each_once_a_cycle() -> void:
	var combat: Combat = _fight(
		{
			0: CK.plain(1, 100),
			1: CK.u("little_nip", 1, 100),
			2: CK.u("brother_wolf", 2, 100),
			3: CK.u("little_nip", 1, 100)
		},
		{1: CK.plain(0, 100), 3: CK.plain(0, 100)}
	)
	var order: Array[CombatUnit] = combat._attack_order(0)
	assert_eq([order[0].slot, order[1].slot], [1, 3])
	var wolf: CombatUnit = combat.unit_at(0, 2)
	assert_false(CombatHunt.can_lead(combat, wolf))
	combat._attack(combat.unit_at(0, 1), combat.unit_at(1, 1))
	combat._attack(combat.unit_at(0, 3), combat.unit_at(1, 3))
	var events: Array[Dictionary] = CK.of_type({"events": combat.events}, "attack")
	assert_eq(events[0]["joiners"], [wolf.uid])
	assert_eq(events[1]["joiners"], [wolf.uid])
	combat._attack(combat.unit_at(0, 1), combat.unit_at(1, 1))
	events = CK.of_type({"events": combat.events}, "attack")
	assert_true(events[-1]["joiners"].is_empty())
	combat.cycles[0] += 1
	combat._attack(combat.unit_at(0, 1), combat.unit_at(1, 1))
	events = CK.of_type({"events": combat.events}, "attack")
	assert_eq(events[-1]["joiners"], [wolf.uid])
