extends GutTest
## Data effects on combat triggers (rulebook 9.3, 9.6, 9.7, 9.8, 12.1.1, 12.2.1), and their random
## choices staying on their own stream.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup()


func _card(
	id: String, mechanics: Array, tribes: Array = [], attack: int = 1, health: int = 1
) -> String:
	return _kit.card(id, mechanics, tribes, attack, health)


func _fight(mine: Dictionary, theirs: Dictionary, fight_seed: int = 1) -> Dictionary:
	return _kit.fight(mine, theirs, fight_seed)


func _of(result: Dictionary, type: String) -> Array[Dictionary]:
	return KIT.of_type(result, type)


func _stats_of(result: Dictionary, permanent: bool = false) -> Array:
	var out: Array = []
	for event: Dictionary in _of(result, "stats"):
		if event["permanent"] == permanent:
			out.append([event["attack_delta"], event["health_delta"]])
	return out


func test_start_of_combat_buff_9_3() -> void:
	var step: Dictionary = {"effect": "buff", "attack": 2, "target": {"select": "in_front"}}
	_card("drill", [KIT.effect("start_of_combat", step)], [], 0, 5)
	var result: Dictionary = _fight({4: "drill", 0: "field_vole"}, {0: "field_vole"})
	assert_eq(_stats_of(result), [[2, 0]], "F1 is in front of B1")


func test_on_death_summon_uses_the_dying_slot_8_4_1() -> void:
	var step: Dictionary = {"effect": "summon", "unit": "hoglet"}
	_card("dier", [KIT.effect("on_death", step)], [], 0, 1)
	var result: Dictionary = _fight(
		{1: "dier"}, {0: {"def_id": "field_vole", "attack": 5, "health": 50}}
	)
	var summons: Array[Dictionary] = _of(result, "summon")
	assert_eq(summons.size(), 1, "summoned")
	assert_eq(summons[0]["slot"], 1, "into its own slot")


func test_on_attack_fires_each_strike_9_6_1() -> void:
	_card("angry", [KIT.effect("on_attack", {"effect": "buff", "attack": 1})], [], 2, 30)
	var result: Dictionary = _fight(
		{0: "angry", 4: "field_vole"}, {0: {"def_id": "field_vole", "attack": 0, "health": 50}}
	)
	assert_gt(_of(result, "stats").size(), 0, "it grew")


func test_on_attacked_with_subject_targets_the_attacker_9_6_1() -> void:
	var step: Dictionary = {"effect": "damage", "amount": 1, "target": {"select": "subject"}}
	_card("barbed", [KIT.effect("on_attacked", step)], [], 0, 30)
	var result: Dictionary = _fight(
		{0: "barbed"}, {0: {"def_id": "field_vole", "attack": 1, "health": 3}}
	)
	var effect_damage: Array = []
	for event: Dictionary in _of(result, "damage"):
		if event["kind"] == "effect":
			effect_damage.append(event["amount"])
	assert_eq(effect_damage.size(), 3, "three attacks, three pricks: the 3-Health attacker dies")


func test_on_damage_taken_cant_recurse_forever_9_10_2() -> void:
	# Two units that hit each other whenever hit: the trigger limit ends it, the stack survives.
	_kit.config.set_value("trigger_limit_combat", 100)
	var step: Dictionary = {"effect": "damage", "amount": 1, "target": {"select": "enemies"}}
	_card("echo", [KIT.effect("on_damage_taken", step)], [], 1, 1000)
	var result: Dictionary = _fight({0: "echo"}, {0: "echo"})
	assert_eq(result["reason"], Combat.REASON_TRIGGER_LIMIT, "stopped by the limit")


func test_on_friendly_death_9_7_2() -> void:
	var step: Dictionary = {"effect": "buff", "attack": 3}
	_card("mourner", [KIT.effect("on_friendly_death", step)], [], 1, 50)
	var result: Dictionary = _fight(
		{0: {"def_id": "field_vole", "attack": 0, "health": 1}, 1: "mourner"},
		{0: {"def_id": "field_vole", "attack": 5, "health": 500}},
		3
	)
	assert_true(_stats_of(result).has([3, 0]), "it heard the death")


func test_on_summon_in_combat_9_8_1() -> void:
	var step: Dictionary = {"effect": "summon", "unit": "hoglet"}
	_card("dier2", [KIT.effect("on_death", step)], [], 0, 1)
	_card("cheer", [KIT.effect("on_summon", {"effect": "buff", "attack": 1})], [], 0, 50)
	var result: Dictionary = _fight(
		{0: "dier2", 1: "cheer"}, {0: {"def_id": "field_vole", "attack": 3, "health": 500}}, 3
	)
	assert_true(_stats_of(result).has([1, 0]), "the summon was heard")


func test_aura_with_position_and_recalc_12_2_1() -> void:
	var aura_step: Dictionary = {
		"effect": "buff", "attack": 2, "health": 3, "target": {"select": "adjacent"}
	}
	_card("banner", [KIT.effect("aura", aura_step)], [], 0, 1)
	var result: Dictionary = _fight(
		{1: "banner", 2: {"def_id": "field_vole", "attack": 1, "health": 1}},
		{0: {"def_id": "field_vole", "attack": 2, "health": 50}},
		1
	)
	var start: Dictionary = _of(result, "combat_start")[0]
	var boards: Array = start["boards"]
	var vole: Dictionary = boards[0][2]
	assert_eq([vole["attack"], vole["health"]], [3, 4], "the aura is in the opening numbers")
	assert_gt(_stats_of(result).size(), 0, "and it comes off when the banner dies")


func test_permanent_buff_in_combat_is_carried_back_12_1_1() -> void:
	var step: Dictionary = {"effect": "buff", "attack": 1, "health": 1, "duration": "permanent"}
	_card("learner", [KIT.effect("start_of_combat", step)], [], 1, 1)
	var result: Dictionary = _fight(
		{0: {"def_id": "learner", "iid": 42}},
		{0: {"def_id": "field_vole", "attack": 0, "health": 9}}
	)
	var carried: Array[Dictionary] = result["carry"]
	assert_eq(carried.size(), 1, "one change")
	assert_eq([carried[0]["iid"], carried[0]["attack"], carried[0]["side"]], [42, 1, 0], "for it")
	assert_eq(_stats_of(result, true).size(), 1, "logged as permanent")


func test_carry_reaches_the_recruit_unit_and_gold_12_1_1() -> void:
	var player: PlayerState = _kit.player
	var rules: RecruitRules = _kit.rules
	var unit: RecruitUnit = _kit.put("field_vole", 0)
	rules.apply_carry(player, {"op": "buff", "iid": unit.iid, "attack": 2, "health": 1})
	assert_eq(unit.perm_attack, 2, "permanently")
	rules.apply_carry(player, {"op": "gold_next_turn", "amount": 4})
	assert_eq(player.gold_next_turn, 4, "gold for next turn")
	rules.apply_carry(player, {"op": "add_card", "card": "hoglet", "count": 1, "from_pool": false})
	assert_eq(player.hand[0].def_id(), "hoglet", "a card")


func test_gold_and_cards_from_combat_arrive_later_12_1_1() -> void:
	var gold_step: Dictionary = {"effect": "gold", "amount": 2}
	_card("looter", [KIT.effect("on_death", gold_step)], [], 0, 1)
	var result: Dictionary = _fight(
		{0: "looter"}, {0: {"def_id": "field_vole", "attack": 3, "health": 9}}
	)
	var carried: Array[Dictionary] = result["carry"]
	assert_eq(carried[0]["op"], "gold_next_turn", "banked for next turn")


func test_status_effect_first_bite_9_6_2() -> void:
	var step: Dictionary = {
		"effect": "status", "status": "first_bite", "target": {"select": "behind"}
	}
	_card("herald", [KIT.effect("start_of_combat", step)], [], 0, 9)
	var result: Dictionary = _fight({0: "herald", 4: "field_vole"}, {0: "field_vole"})
	var statuses: Array[Dictionary] = _of(result, "status")
	assert_eq(statuses[0]["status"], "first_bite", "granted")


func test_grant_in_combat_9_6() -> void:
	var step: Dictionary = {
		"effect": "grant",
		"keyword": "Bristle",
		"mechanic": {"id": "bristle", "n": 2},
		"target": {"select": "self"},
	}
	_card("armour", [KIT.effect("start_of_combat", step)], [], 0, 20)
	var result: Dictionary = _fight(
		{0: "armour"}, {0: {"def_id": "field_vole", "attack": 1, "health": 2}}
	)
	assert_eq(_of(result, "keyword")[0]["keyword"], "Bristle", "logged")
	var thorns: Array = []
	for event: Dictionary in _of(result, "damage"):
		if event["kind"] == "thorns":
			thorns.append(event["amount"])
	assert_eq(thorns, [2], "and it pricks")


func test_across_selector_8_2_6() -> void:
	var step: Dictionary = {"effect": "damage", "amount": 1, "target": {"select": "across"}}
	_card("snipe", [KIT.effect("start_of_combat", step)], [], 0, 9)
	var result: Dictionary = _fight(
		{2: "snipe"},
		{
			2: {"def_id": "field_vole", "attack": 0, "health": 9},
			0: {"def_id": "field_vole", "attack": 0, "health": 9}
		}
	)
	var damage: Dictionary = _of(result, "damage")[0]
	var start: Dictionary = _of(result, "combat_start")[0]
	var boards: Array = start["boards"]
	assert_eq(damage["target"], boards[1][2]["uid"], "the slot across")


func test_random_effects_cant_shift_targeting_prototype_lessons_7() -> void:
	# The same fight with and without a random pick must pick the same attack targets.
	var step: Dictionary = {
		"effect": "buff", "attack": 0, "target": {"select": "friendly", "pick": "random"}
	}
	_card("noisy", [KIT.effect("start_of_combat", step)], [], 0, 9)
	var enemy: Dictionary = {
		0: {"def_id": "field_vole", "attack": 0, "health": 99},
		1: {"def_id": "field_vole", "attack": 0, "health": 99}
	}
	var attacker: Dictionary = {"def_id": "field_vole", "attack": 1, "health": 9}
	var with_noise: Dictionary = _fight({0: attacker, 4: "noisy"}, enemy, 7)
	var without: Dictionary = _fight(
		{0: attacker, 4: {"def_id": "field_vole", "attack": 0, "health": 9}}, enemy, 7
	)
	var targets_a: Array = []
	for event: Dictionary in _of(with_noise, "attack"):
		targets_a.append(event["defender"])
	var targets_b: Array = []
	for event: Dictionary in _of(without, "attack"):
		targets_b.append(event["defender"])
	assert_eq(targets_a, targets_b, "the same targets")
