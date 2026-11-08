extends GutTest
## Round 5: the simplified text describes the existing targeting, timing and payouts.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
const Fight := preload("res://tests/core/combat_kit.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
var _kit: Kit


func before_each() -> void:
	_kit = Kit.new()
	_kit.setup(GameConfig.full_game())
	_kit.rules.start_phase(_kit.player, 1)


func _combat(ours: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	var combat := Combat.create(_kit.library, _kit.config, rng)
	combat._setup([Fight.board(ours), Fight.board(theirs)])
	combat._recalc_auras(false)
	CombatLanes.bell(combat)
	return combat


func test_queen_names_destroyed_stats_and_explains_the_live_teind_count() -> void:
	var queen: RecruitUnit = _kit.put("queen_of_elfland", 0)
	var victim: RecruitUnit = _kit.put("field_vole", 4)
	victim.add_permanent(3, 5)
	var fairy: RecruitUnit = _kit.put("wisp", 1)
	var attack: int = victim.base_attack_now() + victim.perm_attack
	var health: int = victim.base_health_now() + victim.perm_health
	var card: Dictionary = _kit.library.get_unit("queen_of_elfland")
	assert_string_contains(card["text"], "the destroyed units' stats")
	assert_string_contains(card["details"], "Teind counts End of Turns")
	assert_string_contains(card["details"], "resets after 3")
	for count: int in [1, 2]:
		_kit.rules.end_phase(_kit.player)
		assert_eq(queen.counters["teind"], count)
		assert_same(_kit.player.board[4], victim)
	_kit.rules.end_phase(_kit.player)
	assert_eq(queen.counters["teind"], 0)
	assert_null(_kit.player.board[4])
	assert_eq(fairy.perm_attack, attack)
	assert_eq(fairy.perm_health, health)


func test_brother_wolf_text_names_who_joins_and_who_leads() -> void:
	var combat: Combat = _combat(
		{0: Fight.plain(1, 100), 1: Fight.u("brother_wolf", 3, 100)}, {0: Fight.plain(1, 200)}
	)
	var wolf: CombatUnit = combat.unit_at(0, 1)
	assert_false(CombatHunt.can_lead(combat, wolf))
	combat._attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
	var attacks: Array[Dictionary] = Fight.of_type({"events": combat.events}, "attack")
	assert_eq(attacks[0]["joiners"], [wolf.uid])
	var text: String = _kit.library.get_unit("brother_wolf")["text"]
	assert_true(text.begins_with("Pack."))
	assert_string_contains(text, "Units beside this attack first")
	assert_string_contains(text, "this joins each once a cycle")


func test_changeling_text_describes_both_sides_and_the_return_after_one_attack() -> void:
	var combat: Combat = _combat({0: Fight.u("changeling", 2, 100)}, {0: Fight.plain(1, 100)})
	var changeling: CombatUnit = combat.unit_at(0, 0)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	CombatMoves.borrow_across(combat, changeling, enemy, 0)
	assert_same(combat.unit_at(0, 0), enemy)
	assert_same(combat.unit_at(1, 0), changeling)
	combat._attack(enemy, changeling)
	assert_same(combat.unit_at(0, 0), changeling)
	assert_same(combat.unit_at(1, 0), enemy)
	var text: String = _kit.library.get_unit("changeling")["text"]
	assert_string_contains(text, "swap sides")
	assert_string_contains(text, "after that enemy attacks once")


func test_young_brock_text_distinguishes_recipients_from_the_enemy_across_brock() -> void:
	var combat: Combat = _combat(
		{0: Fight.u("young_brock"), 1: Fight.plain(2, 100)},
		{0: Fight.plain(1, 100), 1: Fight.plain(1, 100)}
	)
	assert_eq(combat.unit_at(0, 1).attack, 3)
	assert_eq(combat.unit_at(0, 1).quarry, combat.unit_at(1, 0).uid)
	assert_ne(combat.unit_at(0, 1).quarry, combat.unit_at(1, 1).uid)
	var text: String = _kit.library.get_unit("young_brock")["text"]
	assert_string_contains(text, "They mark the enemy across from this as quarry")


func test_pass_is_one_short_sentence_with_recruit_timing_and_a_touching_chain() -> void:
	var reminder: String = KeywordRules.text("Pass")
	assert_lte(reminder.split(" ", false).size(), 16)
	assert_eq(reminder.count("."), 1)
	assert_string_contains(reminder, "last touching unit rightward")
	assert_string_contains(reminder, "or this does")
	assert_string_contains(reminder, "recruiting: at End of Turn")
	assert_false("recruiting waits" in reminder)
	assert_string_contains(reminder, "End of Turn")
	var occupied: Array[bool] = [true, true, false, true, true, false, false]
	assert_eq(BoardGeometry.pass_landing(occupied, 0), 1, "F1-B1-F2 ends before empty B2")
	occupied[4] = false
	assert_eq(BoardGeometry.pass_landing(occupied, 0), 0, "the source keeps it at a gap")


func test_rewritten_cards_keep_both_faces_within_the_guide_limit() -> void:
	for id: String in ["queen_of_elfland", "brother_wolf", "changeling", "young_brock"]:
		var card: Dictionary = _kit.library.get_unit(id)
		for face: String in ["text", "golden_text"]:
			var text: String = card[face]
			assert_lte(text.split(" ", false).size(), 22, "%s %s" % [id, face])


func test_pass_rightmost_unit_keeps_its_bonus_at_end_of_turn() -> void:
	var crumb: RecruitUnit = _kit.put("mr_crumb")
	assert_eq(_kit.rules.play(_kit.player, 0, 3), "")
	assert_eq(crumb.perm_attack, 0, "the recruiting Pass waits until End of Turn")
	assert_eq(crumb.perm_health, 0)
	_kit.rules.end_phase(_kit.player)
	assert_eq(crumb.perm_attack, 1, "no unit to the right: this keeps the bonus")
	assert_eq(crumb.perm_health, 1)


func test_golden_changeling_explicitly_buffs_that_enemy() -> void:
	var combat: Combat = _combat({0: Fight.u("changeling", 2, 100, true)}, {0: Fight.plain(1, 100)})
	var changeling: CombatUnit = combat.unit_at(0, 0)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	var index: int = changeling.mechanic_ids.find("changeling")
	changeling.scripts[index].on_start_of_combat(combat, changeling, changeling.params[index])
	assert_same(combat.unit_at(0, 0), enemy)
	assert_eq(enemy.attack, 5)
	assert_eq(enemy.health, 104)
	assert_eq(changeling.attack, 2)
	assert_string_contains(
		_kit.library.get_unit("changeling")["golden_text"], "that enemy gains +4/+4"
	)
