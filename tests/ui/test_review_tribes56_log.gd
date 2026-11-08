extends GutTest
## Ask 3: replay real slice events through the UI and the play tool, without hiding exchanges.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const FightLog := preload("res://tools/play/play_fight_log.gd")
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


func _ui_lines() -> Array[String]:
	var model: CombatModel = CombatModel.new()
	var log_text: CombatLog = CombatLog.new()
	var lines: Array[String] = []
	for event: Dictionary in _combat.events:
		lines.append(log_text.describe(event, model, false))
		model.apply(event)
	return lines


func _tool_lines() -> Array[String]:
	var names: Dictionary = {}
	var lines: Array[String] = []
	for event: Dictionary in _combat.events:
		lines.append(FightLog.event_line(event, names, 0))
	return lines


func _play_text() -> String:
	var lines: PackedStringArray = []
	PlayView.fight_lines(
		{"events": _combat.events, "round": 1, "opponent_id": 1, "winner": -1, "damage": 0},
		{"standings": [{"player_id": 1, "name": "Opponent"}]},
		lines
	)
	return "\n".join(lines)


func _assert_damage_and_deaths_are_visible() -> void:
	var ui: Array[String] = _ui_lines()
	var tool: Array[String] = _tool_lines()
	for index: int in _combat.events.size():
		var event: Dictionary = _combat.events[index]
		if event["type"] in ["damage", "death", "health_loss"]:
			assert_false(ui[index].is_empty(), "UI retains %s" % event["type"])
			assert_false(tool[index].is_empty(), "play tool retains %s" % event["type"])


func test_same_named_slice_units_are_distinguished_by_their_slots_in_both_logs() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("little_nip", 2, 20)},
		{0: FIGHT.u("sable", 1, 100)}
	)
	for slot: int in [0, 1]:
		_combat._attack(_combat.unit_at(0, slot), _combat.unit_at(1, 0))
	for lines: Array[String] in [_ui_lines(), _tool_lines()]:
		var text: String = "\n".join(lines)
		assert_string_contains(text, "Little Nip (F1)")
		assert_string_contains(text, "Little Nip (F2)")
		assert_string_contains(text, "Sable (F1)")
	assert_string_contains(_play_text(), "Little Nip (F2) attacks")
	_assert_damage_and_deaths_are_visible()


func test_chorus_borrowed_mire_and_bitter_are_named_on_the_hunter_receiving_them() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 1, 20), 1: FIGHT.u("natterjack_chorus")},
		{0: FIGHT.u("sable", 3, 20)}
	)
	_combat._attack(_combat.unit_at(1, 0), _combat.unit_at(0, 0))
	var ui: Array[String] = _ui_lines()
	var tool: Array[String] = _tool_lines()
	var seen: Array[String] = []
	for index: int in _combat.events.size():
		var event: Dictionary = _combat.events[index]
		if event["type"] == "trigger" and event["uid"] == _combat.unit_at(0, 0).uid:
			if event["mechanic"] in ["mire", "bitter"]:
				var word: String = str(event["mechanic"]).capitalize()
				seen.append(word)
				assert_string_contains(ui[index], ": %s." % word)
				assert_string_contains(tool[index], ": %s" % word)
				assert_false(ui[index].contains("ability goes off"))
				assert_false(tool[index].contains("ability goes off"))
	assert_has(seen, "Mire")
	assert_has(seen, "Bitter")


func test_snap_is_an_attack_and_the_trade_payment_is_clearly_a_different_reward() -> void:
	_setup({0: FIGHT.u("bridge_toad"), 4: FIGHT.u("young_pretender")}, {0: FIGHT.u("sable", 2, 3)})
	var frog: CombatUnit = _combat.unit_at(0, 4)
	_combat.unit_at(0, 0).flagged = true
	_combat._take_turn(0)
	var ui: Array[String] = _ui_lines()
	var tool: Array[String] = _tool_lines()
	var dead: bool = false
	var reward_seen: bool = false
	for index: int in _combat.events.size():
		var event: Dictionary = _combat.events[index]
		if event["type"] == "death" and event["uid"] == frog.uid:
			dead = true
		if dead:
			assert_false(ui[index].contains("Snap"), "the dead frog is not attacking again")
			assert_false(tool[index].contains("Snap"), "the play tool distinguishes the reward")
		if event["type"] == "trigger" and event["mechanic"] == "snap_kill":
			reward_seen = true
			assert_string_contains(ui[index], "Mired kill reward")
			assert_string_contains(tool[index], "Mired kill reward")
	assert_true(dead)
	assert_true(reward_seen, "the gold reward is still reported")
	_assert_damage_and_deaths_are_visible()


func test_grizels_trade_reward_does_not_read_like_healing_a_dead_unit() -> void:
	_kit.put("little_nip", 0)
	_kit.put("grizel", 1)
	_start(_kit.player.combat_board(), FIGHT.board({0: FIGHT.u("sable", 2, 6)}))
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	var rewards: int = 0
	var ui: Array[String] = _ui_lines()
	var tool: Array[String] = _tool_lines()
	for index: int in _combat.events.size():
		if _combat.events[index]["type"] == "permanent_reward":
			rewards += 1
			assert_string_contains(ui[index], "Little Nip (F1)")
			assert_string_contains(tool[index], "Little Nip (F1)")
			assert_string_contains(ui[index], "permanently")
			assert_string_contains(tool[index], "permanently")
			assert_false(ui[index].contains("now "))
			assert_false(tool[index].contains("now "))
	assert_eq(rewards, 1)
	_assert_damage_and_deaths_are_visible()


func test_tiddys_simultaneous_death_reward_is_visible_after_death_without_reviving_the_model(
) -> void:
	_kit.put("bridge_toad", 0)
	_kit.put("tiddy_mun", 4)
	_start(_kit.player.combat_board(), FIGHT.board({0: FIGHT.u("sable", 1, 1)}))
	var spirit: CombatUnit = _combat.unit_at(0, 4)
	for unit: CombatUnit in [_combat.unit_at(0, 0), spirit, _combat.unit_at(1, 0)]:
		_combat.deal_effect_damage(null, unit, 99)
	_combat._resolve_deaths(0)
	var ui: Array[String] = _ui_lines()
	var tool: Array[String] = _tool_lines()
	var reward: int = -1
	for index: int in _combat.events.size():
		if _combat.events[index]["type"] == "permanent_reward":
			reward = index
	assert_gt(reward, 0)
	assert_string_contains(ui[reward], "Tiddy Mun (B1)")
	assert_string_contains(tool[reward], "Tiddy Mun (B1)")
	assert_string_contains(_play_text(), "permanently")
	var model: CombatModel = CombatModel.new()
	for event: Dictionary in _combat.events:
		model.apply(event)
	assert_false(bool(model.unit(spirit.uid)["alive"]))
	assert_lte(int(model.unit(spirit.uid)["health"]), 0)
	_assert_damage_and_deaths_are_visible()


func test_peat_kings_full_board_fizzle_is_visible_in_the_actual_play_tool_path() -> void:
	var ours: Dictionary = {1: FIGHT.u("prima_donna"), 5: FIGHT.u("peat_king")}
	for slot: int in [0, 2, 3, 4, 6]:
		ours[slot] = FIGHT.u("warty_nan", 1, 20)
	_setup(ours, {0: FIGHT.u("sable", 1, 1)})
	_combat.deal_effect_damage(null, _combat.unit_at(1, 0), 1)
	_combat._resolve_deaths(0)
	assert_string_contains(_play_text(), "The Peat King (B2) has no room for a Peatling")
	assert_string_contains("\n".join(_ui_lines()), "no room for a Peatling.")
	assert_false("\n".join(_ui_lines()).contains("stays inside"))
	_assert_damage_and_deaths_are_visible()


func test_relocation_changes_subsequent_slot_tags_in_both_logs() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("little_nip", 2, 20)},
		{0: FIGHT.u("sable", 1, 100)}
	)
	CombatMoves.swap_rows(_combat, 0)
	_combat.buff(_combat.unit_at(0, 5), 1, 0, _combat.unit_at(0, 5))
	var nip: CombatUnit = _combat.unit_at(0, 4)
	_combat.deal_effect_damage(_combat.unit_at(1, 0), nip, 99)
	_combat._resolve_deaths(0)
	for lines: Array[String] in [_ui_lines(), _tool_lines()]:
		var text: String = "\n".join(lines)
		assert_string_contains(text, "Little Nip (F1)")
		assert_string_contains(text, "Little Nip (B1)")
		assert_string_contains(text, "Little Nip (B2)")
	_assert_damage_and_deaths_are_visible()


func test_summoned_copies_keep_distinct_slot_tags() -> void:
	_setup({0: FIGHT.u("peatling"), 5: FIGHT.u("peat_king")}, {0: FIGHT.u("sable", 1, 100)})
	var king: CombatUnit = _combat.unit_at(0, 5)
	var summoned: CombatUnit = _combat.summon_into("peatling", false, 0, 2, king)
	_combat.buff(summoned, 1, 0, king)
	_combat.buff(_combat.unit_at(0, 0), 1, 0, king)
	for lines: Array[String] in [_ui_lines(), _tool_lines()]:
		var text: String = "\n".join(lines)
		assert_string_contains(text, "Peatling (F1)")
		assert_string_contains(text, "Peatling (F3)")


func test_an_enemy_prince_keeps_its_side_and_slot_after_transforming() -> void:
	_setup({0: FIGHT.u("sable", 1, 1)}, {0: FIGHT.u("bridge_toad"), 4: FIGHT.u("his_highness")})
	var highness: CombatUnit = _combat.unit_at(1, 4)
	highness.counters["kisses"] = 2
	_combat.deal_effect_damage(_combat.unit_at(1, 0), _combat.unit_at(0, 0), 1)
	_combat._resolve_deaths(1)
	_combat.buff(highness, 1, 0, highness)
	assert_string_contains(_play_text(), "enemy The Prince Restored (B1) +1 Attack")
	assert_string_contains("\n".join(_ui_lines()), "The Prince Restored (B1)")
	_assert_damage_and_deaths_are_visible()
