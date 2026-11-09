extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/combat_kit.gd")
const Log := preload("res://src/ui/screens/combat_log.gd")
const Model := preload("res://src/ui/screens/combat_model.gd")
const PlayLog := preload("res://tools/play/play_fight_log.gd")
const Screen := preload("res://src/ui/screens/combat_screen.gd")
var _combat: Combat


func _start(ours: Dictionary, theirs: Dictionary, rules: Array = [{}, {}]) -> void:
	_combat = Combat.create(
		LegacyWave1.library(), GameConfig.full_game(), RandomNumberGenerator.new()
	)
	_combat.side_rules = rules
	_combat._setup([KIT.board(ours), KIT.board(theirs)])
	_combat._recalc_auras(false)
	_combat.emit_event(
		"combat_start",
		{
			"boards": [_combat._board_views(0), _combat._board_views(1)],
			"first_side": 0,
			"player_ids": [0, 1]
		}
	)


func _events(kind: String) -> Array[Dictionary]:
	return KIT.of_type({"events": _combat.events}, kind)


func _lines() -> Array[String]:
	var model := Model.new()
	var log_text := Log.new()
	var names: Dictionary = {}
	var ui: PackedStringArray = []
	var cli: PackedStringArray = []
	for event: Dictionary in _combat.events:
		ui.append(log_text.describe(event, model, false))
		cli.append(PlayLog.event_line(event, names, 0))
		model.apply(event)
	return ["\n".join(ui), "\n".join(cli)]


func test_aura_losses_name_cluricaun_on_every_affected_unit_and_gains_name_the_source() -> void:
	_start(
		{
			0: KIT.u("cluricaun"),
			1: KIT.plain(3, 10),
			2: KIT.plain(3, 10),
			4: KIT.plain(3, 10),
			5: KIT.plain(3, 10)
		},
		{0: KIT.plain(1, 100)},
		[{"bands": [1, 1, 1, 0, 1, 1, 0]}, {}]
	)
	_combat.deal_effect_damage(null, _combat.unit_at(0, 0), 100)
	_combat._resolve_deaths(0)
	assert_eq(_events("stats").size(), 4)
	for text: String in _lines():
		assert_string_contains(text, "Cluricaun (F1)")
		assert_eq(text.count("-1 Attack"), 4)
		assert_eq(text.count("aura lost"), 4)
	_combat.summon_into("cluricaun", false, 0, 0, null)
	for text: String in _lines():
		assert_string_contains(text, "Cluricaun (F1)")
		assert_string_contains(text, "aura gained")


func test_rainbow_chaser_attack_recovery_names_jennys_lost_aura_and_hex_names_hex() -> void:
	_start({0: KIT.u("rainbow_chaser", 5, 20)}, {0: KIT.u("jenny_greenteeth", 1, 10)})
	CombatLanes.bell(_combat)
	_combat.deal_effect_damage(null, _combat.unit_at(1, 0), 100)
	_combat._resolve_deaths(1)
	var witch: CombatUnit = _combat.summon_into("hedge_witch", false, 1, 1, null)
	_combat.add_hex(witch, 0, 0, 2)
	for text: String in _lines():
		assert_string_contains(text, "+2 Attack")
		assert_string_contains(text, "Jenny Greenteeth (F1)")
		assert_string_contains(text, "aura lost")
		assert_string_contains(text, "Hex gained")


func test_bitter_shows_stacked_amount_and_regular_stat_changes_name_their_source() -> void:
	_start(
		{0: KIT.plain(10, 100)},
		{0: KIT.u("warty_nan", 1, 100), 1: KIT.u("warty_nan", 1, 100, true)}
	)
	var attacker: CombatUnit = _combat.unit_at(0, 0)
	var nan: CombatUnit = _combat.unit_at(1, 1)
	CombatLanes.bitter(_combat, _combat.unit_at(1, 0), attacker)
	_combat.buff(attacker, 1, 1, nan)
	for text: String in _lines():
		assert_string_contains(text, "-3 Attack (Bitter)")
		assert_string_contains(text, "Warty Nan (F2)")
		assert_string_contains(text, "ability")


func _full_board(id: String = "wee_wobbly") -> Dictionary:
	var board: Dictionary = {0: KIT.u(id, 3, 100)}
	for slot: int in range(1, 7):
		board[slot] = KIT.plain(1, 10)
	return board


func test_wobbly_fails_plainly_for_both_drip_and_held_unit_without_spending_a_release() -> void:
	for has_held: bool in [false, true]:
		var board: Dictionary = _full_board()
		if has_held:
			board[0]["held"] = [KIT.u("field_vole")]
		_start(board, {0: KIT.plain(1, 100)})
		var wobbly: CombatUnit = _combat.unit_at(0, 0)
		var index: int = wobbly.mechanic_ids.find("wobbly")
		wobbly.scripts[index].after_hit(_combat, wobbly, wobbly.params[index])
		assert_eq(_events("no_room").size(), 1)
		assert_eq(int(wobbly.counters.get("wobbly", 0)), 0)
		assert_eq(wobbly.held_specs.size(), 1 if has_held else 0)
		for text: String in _lines():
			assert_string_contains(text, "no room for " + ("Field Vole" if has_held else "Drip"))
			assert_eq("stays inside" in text, has_held)


func test_posset_death_reports_no_enemy_across_without_dealing_damage() -> void:
	_start({0: KIT.u("mrs_posset")}, {1: KIT.plain(1, 100)})
	_combat.deal_effect_damage(null, _combat.unit_at(0, 0), 100)
	_combat._resolve_deaths(0)
	assert_eq(_events("no_target").size(), 1)
	assert_eq(_combat.unit_at(1, 1).health, 100)
	for text: String in _lines():
		assert_string_contains(text, "Mrs Posset (F1)")
		assert_string_contains(text, "no enemy across")


func test_generic_and_placed_summons_report_no_room_including_empty_rings() -> void:
	_start(_full_board(), {0: KIT.plain(1, 100)})
	var source: CombatUnit = _combat.unit_at(0, 0)
	assert_null(_combat.summon("drip", false, 0, 0, source))
	var world := CombatWorld.make(_combat, source, 0, {}, "on_death")
	world.summon_placed({"unit": "drip", "at": "behind"}, 1, false)
	world.summon_placed({"unit": "drip", "at": "empty_rings"}, 1, false)
	assert_eq(_events("no_room").size(), 3)
	for text: String in _lines():
		assert_eq(text.count("no room for Drip"), 3)
		assert_string_contains(text, "no empty Ring slot")


func test_failed_belly_release_is_lost_for_the_fight_instead_of_staying_inside() -> void:
	var board: Dictionary = _full_board("mrs_posset")
	board[0]["held"] = [KIT.u("field_vole")]
	_start(board, {0: KIT.plain(1, 100)})
	assert_null(CombatHeld.pop_one(_combat, _combat.unit_at(0, 0), false))
	assert_true(_combat.unit_at(0, 0).held_specs.is_empty())
	for text: String in _lines():
		assert_string_contains(text, "lost for this fight")
		assert_false("stays inside" in text)


func test_mousewife_replaces_front_unit_even_with_a_blocked_back_slot() -> void:
	_start({0: KIT.plain(1, 2), 4: KIT.plain(1, 2)}, {0: KIT.plain(1, 100)})
	_combat.hero_effects[0] = HeroRules.effects_of(KIT.library.get_hero("old_mother_mousewife"))
	_combat.deal_effect_damage(null, _combat.unit_at(0, 0), 100)
	_combat._resolve_deaths(0)
	assert_eq(_combat.unit_at(0, 0).def_id(), "mouse")
	assert_not_null(_combat.unit_at(0, 4), "the back-row unit stays")
	assert_true(KIT.of_type({"events": _combat.events}, "no_room").is_empty())


func test_mousewife_no_room_after_a_death_summon_reaches_logs_and_hero_toast() -> void:
	_start(_full_board("earwig_mother"), {0: KIT.plain(1, 100)})
	_combat.hero_effects[0] = HeroRules.effects_of(KIT.library.get_hero("old_mother_mousewife"))
	_combat.deal_effect_damage(null, _combat.unit_at(0, 0), 999)
	_combat._resolve_deaths(0)
	assert_eq(_combat.unit_at(0, 0).def_id(), "nymph")
	var failures: Array[Dictionary] = []
	for event: Dictionary in _events("no_room"):
		if event.get("mechanic", "") == "mice":
			failures.append(event)
	assert_eq(failures.size(), 1)
	assert_eq(failures[0].get("mechanic", ""), "mice")
	for text: String in _lines():
		assert_string_contains(text, "no room for a Mouse")
	var screen := Screen.new()
	add_child_autofree(screen)
	screen.setup({"events": _combat.events}, PackedStringArray(["You", "Opponent"]), 0, "Round 5")
	screen.playing = false
	for event: Dictionary in _combat.events:
		screen._play_event(event, true)
	var caption: Label = screen.get("_caption")
	assert_eq(caption.text, "Mousewife: no room for a Mouse")
	var log_note: Control = screen.get("_log")
	assert_string_contains(str(log_note.call("all_text")), "no room for a Mouse")


func test_logs_use_mire_mired_and_the_actual_wasp_and_wren_card_words() -> void:
	_start({0: KIT.u("bridge_toad", 1, 100)}, {0: KIT.plain(4, 100)})
	CombatLanes.bell(_combat)
	var enemy: CombatUnit = _combat.unit_at(1, 0)
	_combat.set_status(enemy, "mired", false, null)
	_combat.set_status(enemy, "parasite", true, _combat.unit_at(0, 0))
	_combat.set_status(enemy, "borrowed_attack", true, null)
	_combat.set_status(enemy, "borrowed_attack", false, null)
	for text: String in _lines():
		assert_string_contains(text, "applies Mire")
		assert_string_contains(text, "is Mired")
		assert_string_contains(text, "no longer Mired")
		assert_string_contains(text, "will die after its next attack")
		assert_string_contains(text, "highest enemy Attack")
		for forbidden: String in [
			" bogs ", "gains mired", "loses mired", "parasite", "borrowed attack", "-- Bell"
		]:
			assert_false(forbidden in text, forbidden)


func test_pack_names_the_joiner_and_keeps_same_named_units_distinct() -> void:
	_start(
		{0: KIT.u("field_vole", 1, 100), 1: KIT.u("wick", 1, 100), 2: KIT.u("field_vole", 1, 100)},
		{0: KIT.plain(1, 100)}
	)
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	_combat._attack(_combat.unit_at(0, 2), _combat.unit_at(1, 0))
	for text: String in _lines():
		assert_string_contains(text, "Field Vole (F1)")
		assert_string_contains(text, "Field Vole (F3)")
		assert_string_contains(text, "Wick (F2)")
		assert_string_contains(text, "joins the attack")
		assert_false("in a Pack with" in text)


func test_recruit_summons_and_placed_summons_report_every_missing_slot() -> void:
	var kit := preload("res://tests/core/recruit_kit.gd").new()
	kit.setup(GameConfig.full_game())
	var ids: Array[String] = [
		"field_vole", "mr_crumb", "mrs_sorrel", "wick", "little_nip", "wee_wobbly", "rainbow_chaser"
	]
	for slot: int in 7:
		kit.put(ids[slot], slot)
	kit.rules.summon_units(kit.player, "drip", 2, false, 0)
	var ctx := RecruitContext.new()
	ctx.rules = kit.rules
	ctx.player = kit.player
	ctx.source_slot = 0
	ctx.summon_placed({"unit": "drip", "at": "behind"}, 1, false)
	var failures: int = 0
	for event: Dictionary in kit.player.recruit_log:
		if event["type"] == "no_room":
			failures += 1
			assert_eq(event["name"], "Drip")
	assert_eq(failures, 3)
	assert_eq(kit.player.board.size(), 7)


func test_screenshot_exchange_contains_mire_bitter_amount_and_full_board_failure() -> void:
	var fight: Dictionary = preload("res://tests/ui/feedback5_states.gd").fight()
	var model := Model.new()
	var log_text := Log.new()
	var lines: PackedStringArray = []
	for event: Dictionary in fight["events"]:
		lines.append(log_text.describe(event, model, false))
		model.apply(event)
	var text: String = "\n".join(lines)
	for expected: String in ["applies Mire", "is Mired", "-3 Attack (Bitter)", "no room for Drip"]:
		assert_string_contains(text, expected)


func test_logging_keeps_aura_bitter_and_failed_summon_results_and_random_streams_identical(
) -> void:
	for seed_now: int in range(58103, 58107):
		var outcomes: Array = []
		for logging: bool in [false, true]:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_now
			var combat := Combat.create(LegacyWave1.library(), GameConfig.full_game(), rng)
			combat.log_events = logging
			combat.side_rules = [{"bands": [1, 1, 0, 0, 0, 0, 0]}, {}]
			var result: Dictionary = combat.run(
				[
					KIT.board(
						{
							0: KIT.u("cluricaun"),
							1: KIT.u("wee_wobbly", 10, 20),
							2: KIT.u("rainbow_chaser")
						}
					),
					KIT.board(
						{
							0: KIT.u("madame_bufo"),
							1: KIT.u("warty_nan"),
							4: KIT.u("jenny_greenteeth")
						}
					)
				],
				[3, 3],
				[0, 1],
				0
			)
			result.erase("events")
			outcomes.append(
				{
					"result": result,
					"rng": rng.state,
					"effect_rng": combat.effect_rng.state,
					"carry": combat.carry,
					"triggers": combat._triggers
				}
			)
		assert_eq_deep(outcomes[0], outcomes[1])


func test_mousewife_logs_every_failure_but_toasts_once_per_fight_and_resets_on_restart() -> void:
	_start({0: KIT.plain(1, 2), 4: KIT.plain(1, 2)}, {0: KIT.plain(1, 100)})
	var start: Dictionary = _combat.events[0]
	var failure: Dictionary = {"type": "no_room", "side": 0, "mechanic": "mice", "def_id": "mouse"}
	var screen := Screen.new()
	add_child_autofree(screen)
	screen.setup({"events": [start]}, PackedStringArray(["You", "Opponent"]), 0, "Round 5")
	screen.playing = false
	screen._play_event(start, false)
	# Fast-forwarded events must not consume the one visible toast.
	screen._play_event(failure, false)
	assert_false(screen.get("_mouse_no_room_shown"))
	screen._play_event(failure, true)
	var caption: Label = screen.get("_caption")
	assert_eq(caption.text, "Mousewife: no room for a Mouse")
	caption.text = "Another notice"
	screen._play_event(failure, true)
	assert_eq(caption.text, "Another notice", "repeat failures cannot replace other toasts")
	failure["side"] = 1
	screen._play_event(failure, true)
	assert_eq(caption.text, "Another notice", "the toast budget covers both sides")
	var log_note: Control = screen.get("_log")
	assert_eq(str(log_note.call("all_text")).count("no room for a Mouse"), 4)
	screen.restart()
	screen.playing = false
	screen._play_event(start, false)
	screen._play_event(failure, true)
	assert_eq(caption.text, "Mousewife: no room for a Mouse", "new playback resets the budget")
	screen._play_event(start, false)
	assert_false(screen.get("_mouse_no_room_shown"), "a new fight also resets the budget")
