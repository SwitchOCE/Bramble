extends GutTest
## The slice's neutrals (docs/ideation/content/SLICE.md, neutrals-spells-heroes.md).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const F1: int = 0
const F2: int = 1
const F3: int = 2
const B1: int = 4
const B2: int = 5

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game(), false, LegacyWave1.current_with_neutrals())
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)


func _events(result: Dictionary, type: String) -> Array:
	var out: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == type:
			out.append(event)
	return out


func test_lamp_moth_reduces_only_the_next_tier_up_cost() -> void:
	var before: int = _rules.tier_up_cost(_player)
	_kit.play("lamp_moth", B2)
	assert_eq(_rules.tier_up_cost(_player), before - 1)
	_player.gold = 20
	assert_eq(_rules.tier_up(_player), "")
	assert_eq(_player.gold, 20 - (before - 1))
	assert_eq(_rules.tier_up_cost(_player), _rules.base_upgrade_cost(2))


func test_lamp_moth_golden_saves_two_and_no_longer_buffs_the_front() -> void:
	var before: int = _rules.tier_up_cost(_player)
	_kit.play("lamp_moth", B1, true)
	assert_eq(_rules.tier_up_cost(_player), before - 2)
	_kit.put("field_vole", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	assert_true(_events(result, "stats").is_empty(), "the old Start of Combat effect is gone")


func test_pill_bug_attacked_gives_the_units_behind_attack() -> void:
	_kit.put("pill_bug", F1)
	_kit.put("field_vole", B1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "field_vole", "attack": 1, "health": 50}}
	)
	assert_gt(_events(result, "stats").size(), 0, "the unit behind rose")


func test_turnip_scarecrow_the_enemy_across_skips_its_first_attack() -> void:
	_kit.put("turnip_scarecrow", F1)
	var result: Dictionary = _kit.fight_board(
		{
			F1: {"def_id": "pill_bug", "attack": 1, "health": 9},
			F2: {"def_id": "pill_bug", "health": 9}
		}
	)
	assert_eq(_status_on(result, "stalled"), 1)
	assert_eq(_events(result, "skip").size(), 1)


func _status_on(result: Dictionary, status: String) -> int:
	var count: int = 0
	for event: Dictionary in _events(result, "status"):
		if event["status"] == status and event["on"]:
			count += 1
	return count


func test_turnip_scarecrow_golden_skips_two_attacks() -> void:
	_kit.put("turnip_scarecrow", F1, true)
	var spec: Dictionary = {"def_id": "pill_bug", "attack": 1, "health": 5}
	var one: Dictionary = _kit.fight_board({F1: spec})
	var hits_while_stalled: Array = _events(one, "attack")
	assert_gt(hits_while_stalled.size(), 0)
	assert_eq(_status_on(one, "stalled"), 1)
	var stalled_ends: int = 0
	var skips: int = 0
	for event: Dictionary in one["events"]:
		if event["type"] == "status" and event["status"] == "stalled" and not event["on"]:
			stalled_ends += 1
		if event["type"] == "skip":
			skips += 1
	assert_eq(stalled_ends, 1)
	assert_eq(skips, 2, "two turns skipped")


func test_earwig_mother_dies_into_two_nymphs_behind_it() -> void:
	_kit.put("earwig_mother", F2)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 5, "health": 50}}
	)
	var summons: Array = []
	for event: Dictionary in _events(result, "summon"):
		summons.append(event["slot"])
	assert_has(summons, B1)
	assert_has(summons, B2)


func test_earwig_mother_falls_back_to_the_nearest_when_full_behind() -> void:
	_kit.put("earwig_mother", F1)
	_kit.put("pill_bug", B1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 9, "health": 50}}
	)
	assert_gte(_events(result, "summon").size(), 2, "still two Nymphs")


func test_earwig_mother_golden_makes_2_2_nymphs() -> void:
	_kit.put("earwig_mother", F2, true)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 9, "health": 50}}
	)
	assert_eq(_events(result, "summon")[0]["unit"]["attack"], 2)


func test_cricket_busker_only_first_spell_refunds_immediately() -> void:
	_kit.put("cricket_busker", F1)
	_player.gold = 0
	_player.gold_next_turn = 0
	for _cast: int in 3:
		_kit.cast("pinch_of_dust", F1)
	assert_eq(_player.gold, 1, "once a turn, paid immediately")
	assert_eq(_player.gold_next_turn, 0)
	_kit.pass_turn()
	_player.gold = 0
	_kit.cast("pinch_of_dust", F1)
	assert_eq(_player.gold, 1, "the limit comes back")


func test_cricket_busker_golden_pays_two_immediately() -> void:
	_kit.put("cricket_busker", F1, true)
	_player.gold = 0
	_player.gold_next_turn = 0
	_kit.cast("pinch_of_dust", F1)
	assert_eq(_player.gold, 2)
	assert_eq(_player.gold_next_turn, 0)


func test_ballooning_spider_in_the_back_row_attacks_the_enemy_back_row() -> void:
	_kit.put("ballooning_spider", B1)
	_kit.put("pill_bug", F1)
	var result: Dictionary = _kit.fight_board(
		{
			F1: {"def_id": "pill_bug", "attack": 0, "health": 50},
			B1: {"def_id": "pill_bug", "attack": 0, "health": 50}
		}
	)
	var spider: int = _uid_of(result, 0, B1)
	var enemy_back: int = _uid_of(result, 1, B1)
	var hit_back: bool = false
	for event: Dictionary in _events(result, "attack"):
		if event["attacker"] == spider:
			assert_eq(event["defender"], enemy_back)
			hit_back = true
	assert_true(hit_back, "it attacked")


func test_ballooning_spider_in_the_front_row_follows_the_usual_rule() -> void:
	_kit.put("ballooning_spider", F1)
	var result: Dictionary = _kit.fight_board(
		{
			F1: {"def_id": "pill_bug", "attack": 0, "health": 50},
			B1: {"def_id": "pill_bug", "attack": 0, "health": 50}
		}
	)
	var spider: int = _uid_of(result, 0, F1)
	var enemy_front: int = _uid_of(result, 1, F1)
	for event: Dictionary in _events(result, "attack"):
		if event["attacker"] == spider:
			assert_eq(event["defender"], enemy_front)


func _uid_of(result: Dictionary, side: int, slot: int) -> int:
	return result["events"][0]["boards"][side][slot]["uid"]


func test_sexton_beetle_a_friendly_death_pays_next_turn_twice_a_fight() -> void:
	_kit.put("sexton_beetle", B1)
	_kit.put("field_vole", F1)
	_kit.put("field_vole", F2)
	_player.gold_next_turn = 0
	_kit.fight_board({F1: {"def_id": "pill_bug", "attack": 99, "health": 999}})
	assert_eq(_player.gold_next_turn, 2, "two die before it; it pays for both")


func test_sexton_beetle_golden_pays_two() -> void:
	_kit.put("sexton_beetle", B1, true)
	_kit.put("field_vole", F1)
	_player.gold_next_turn = 0
	_kit.fight_board({F1: {"def_id": "pill_bug", "attack": 99, "health": 999}})
	assert_eq(_player.gold_next_turn, 2)


func test_charcoal_burner_burns_above_5_for_units_behind() -> void:
	_kit.put("charcoal_burner", F2)
	var left: RecruitUnit = _kit.put("pill_bug", B1)
	var right: RecruitUnit = _kit.put("pill_bug", B2)
	_player.gold = 12
	_rules.end_phase(_player)
	assert_eq(_player.gold, 6)
	assert_eq(left.attack, 1 + 3, "burn capped at six")
	assert_eq(right.health, 4 + 3)


func test_charcoal_burner_below_5_burns_nothing() -> void:
	_kit.put("charcoal_burner", F2)
	var left: RecruitUnit = _kit.put("pill_bug", B1)
	_player.gold = 5
	_rules.end_phase(_player)
	assert_eq(_player.gold, 5)
	assert_eq(left.attack, 1)


func test_charcoal_burner_golden_doubles() -> void:
	_kit.put("charcoal_burner", F2, true)
	var left: RecruitUnit = _kit.put("pill_bug", B1)
	_player.gold = 9
	_rules.end_phase(_player)
	assert_eq(left.attack, 1 + 2, "golden keeps +1 per two; doubles the burn cap")
