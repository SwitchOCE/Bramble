extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CombatLog := preload("res://src/ui/screens/combat_log.gd")

var _library: UnitLibrary = UnitLibrary.load_dir()


func _session() -> GameSession:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("players", 2)
	config.set_value("hero_choice", false)
	config.set_value("human_bot", "naive")
	config.set_value("bots", ["naive"])
	return GameSession.create(41, _library, config)


func test_draw_costs_both_heroes_and_toll_grows_after_round_eight() -> void:
	var session: GameSession = _session()
	session._fight(0, 1, 4)
	assert_eq(session._players[0].health, 39)
	assert_eq(session._players[1].health, 39)
	assert_eq(session.get_last_combat()["damage"], 1)
	session._round = 14
	session._players[0].armor = 4
	session._fight(0, 1, 0)
	assert_eq(session._players[0].health, 36, "Armor absorbs four of the seven")
	assert_eq(session._players[1].health, 32, "draw toll seven")
	var events: Array = session.get_last_combat()["events"]
	var last: Dictionary = events.back()
	assert_eq(last["round_toll"], 7)
	assert_eq(last["damage"], 7)
	var log_text: CombatLog = CombatLog.new()
	assert_true("Each hero takes 7" in log_text._end(last))


func test_toll_is_inside_damage_caps_and_winner_takes_none() -> void:
	var session: GameSession = _session()
	session._round = 15
	session._players[0].board[0] = RecruitUnit.make(_library.get_unit("pill_bug"), 100)
	session._fight(0, 1, 10)
	assert_eq(session._players[0].health, 40, "winning avoids toll")
	assert_eq(session._players[1].health, 30, "base damage plus toll is capped at ten")
	assert_eq(session.get_last_combat()["damage"], 10)


func test_bare_rules_remain_configurable_and_final_mutual_knockout_ranks_by_health() -> void:
	var session: GameSession = _session()
	session._config.set_value("round_toll", false)
	session._fight(0, 1, 0)
	assert_eq(session._players[0].health, 40)
	assert_eq(session.get_last_combat()["damage"], 0)
	session._config.set_value("round_toll", true)
	session._round = 14
	session._players[0].health = 6
	session._players[1].health = 4
	session._fight(0, 1, 0)
	session._eliminate()
	assert_true(session.is_over())
	assert_eq(session._players[0].placement, 1)
	assert_eq(session._players[1].placement, 2)


func test_toll_reports_only_its_addition_after_the_cap() -> void:
	var session: GameSession = _session()
	session._round = 14
	for base: int in [4, 10, 12, 18]:
		var event: Dictionary = {"type": "combat_end"}
		var result: Dictionary = {
			"damage_uncapped": base, "damage": mini(base, 12), "events": [event]
		}
		session._apply_round_toll(result, 12)
		assert_eq(event["round_toll_added"], mini(base + 7, 12) - mini(base, 12))
		assert_eq(event["round_toll"], 7, "the nominal toll is unchanged")
	for round_number: int in [10, 14, 30]:
		session._round = round_number
		assert_eq(session._damage_cap(), 0, "cap lifts for the final four and duel")
