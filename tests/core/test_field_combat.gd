extends GutTest
@warning_ignore_start("unsafe_call_argument")


func _side(input: Dictionary, side: int) -> Dictionary:
	return {
		"round": input["round"],
		"layout": "blind",
		"config": input["config"],
		"board": input["boards"][side],
		"slots": input["slots"][side],
		"hero_effects": input["hero_effects"][side],
		"fight_rules": input["fight_rules"][side],
		"tier": input["tiers"][side],
	}


func test_composed_real_capture_preserves_hidden_state_and_raw_outcome() -> void:
	var library := UnitLibrary.load_dir()
	var session := GameSession.create(71, library)
	var a: PlayerState = session._players[0]
	var b: PlayerState = session._players[1]
	a.board[0] = RecruitUnit.make(library.get_unit("elder_ooze"), 91)
	a.board[0].held.append(RecruitUnit.make(library.get_unit("wood_mouse_guard"), 92))
	a.slot_effects[0] = [{"name": "Ring", "attack": 3, "health": 2}]
	HeroRules.assign(a, library.get_hero("brother_bracken"))
	b.board[0] = RecruitUnit.make(library.get_unit("bridge_toad"), 93)
	var captured: Array[Dictionary] = []
	session.fight_capture_observer = func(
		raw_input: Dictionary, raw_result: Dictionary, _combat: Combat
	) -> void:
		captured.append({"input": raw_input.duplicate(true), "result": raw_result.duplicate(true)})
	session._fight(0, 1, 0)
	var input: Dictionary = captured[0]["input"]
	var expected: Dictionary = captured[0]["result"]
	var left: Dictionary = _side(input, 0)
	var right: Dictionary = _side(input, 1)
	var before: String = FightCapture.canonical([left, right])
	var result: Dictionary = FieldCombat.fight(
		left, right, str(input["rng_seed"]).to_int(), library
	)
	expected.erase("events")
	result.erase("events")
	assert_eq(FightCapture.canonical(result), FightCapture.canonical(expected))
	assert_eq(FightCapture.canonical([left, right]), before, "field inputs are never mutated")
	var swapped: Dictionary = FieldCombat.pair_input(right, left, 19)
	assert_eq(swapped["hero_effects"], [right["hero_effects"], left["hero_effects"]])
	assert_eq(swapped["fight_rules"], [right["fight_rules"], left["fight_rules"]])
