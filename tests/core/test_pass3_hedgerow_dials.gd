extends GutTest
## Literal answers check configured faces against actual End of Turn effects.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const ENDPOINTS: Array[float] = [0.0, 3.0]
var kit: KIT


func _setup(t: float, extra: Dictionary = {}) -> void:
	var config := GameConfig.full_game()
	var rates: Dictionary = Pass3Path.override(t)
	rates.merge(extra, true)
	for key: String in rates:
		config.set_value(key, rates[key])
	kit = KIT.new()
	kit.setup(config)
	kit.player.round_number = 1
	kit.player.gold = 100


func _body(unit: RecruitUnit, attack: int, health: int) -> void:
	unit.add_permanent(attack - unit.base_attack_now(), health - unit.base_health_now())


func _face(id: String, golden: bool) -> String:
	return str(kit.library.get_unit(id)["golden_text" if golden else "text"])


func _multiply_face(id: String, golden: bool, expected: float) -> void:
	var face: String = _face(id, golden)
	var found: RegExMatch = (
		RegEx
		. create_from_string("(double|triple|multiply) .*?stats(?: by ([\\d.]+))?\\.")
		. search(face)
	)
	assert_not_null(found, face)
	if found == null:
		return
	var amount: float = 2.0 if found.get_string(1) == "double" else 3.0
	if found.get_string(1) == "multiply":
		amount = found.get_string(2).to_float()
	assert_almost_eq(amount, expected, 1e-6, face)


func _mallow(golden: bool, multiple: float, selected: Array[Vector2i]) -> void:
	_multiply_face("mrs_mallow", golden, multiple)
	assert_string_contains(
		_face("mrs_mallow", golden), "your four smallest" if golden else "your two smallest"
	)
	kit.card("dial_hedge", [], ["Hedgerow folk"], 10, 20)
	var source: RecruitUnit = kit.put("mrs_mallow", 6, golden)
	_body(source, 1000, 1000)
	for slot: int in 5:
		_body(kit.put("dial_hedge", slot), (slot + 1) * 10, (slot + 1) * 20)
	var foreign: RecruitUnit = kit.put("pill_bug", 5)
	_body(foreign, 1, 1)
	kit.rules.end_phase(kit.player)
	for slot: int in 5:
		var expected := Vector2i((slot + 1) * 10, (slot + 1) * 20)
		if slot < selected.size():
			expected = selected[slot]
		var target: RecruitUnit = kit.player.board[slot]
		assert_eq(Vector2i(target.attack, target.health), expected, "target %d" % slot)
	assert_eq(Vector2i(source.attack, source.health), Vector2i(1000, 1000))
	assert_eq(Vector2i(foreign.attack, foreign.health), Vector2i(1, 1))


func _wake(golden: bool, multiple: float, expected: Vector2i) -> void:
	_multiply_face("alderman_dozey", golden, multiple)
	assert_string_contains(_face("alderman_dozey", golden), "Every 3 turns in this slot:")
	var dozey: RecruitUnit = kit.put("alderman_dozey", 6, golden)
	_body(dozey, 20, 40)
	kit.player.hedgerow_bonus = 4
	kit.player.ring_size = 1.0
	BoardUpkeep.add_ring(kit.player, 6, {"count": 40})
	dozey.add_combat(100, 200)
	kit.rules.board_changed(kit.player)
	assert_eq(Vector2i(dozey.tribe_attack, dozey.tribe_health), Vector2i(4, 4))
	assert_eq(Vector2i(dozey.aura_attack, dozey.aura_health), Vector2i(40, 40))
	for turn: int in 3:
		kit.rules.end_phase(kit.player)
		if turn < 2:
			assert_eq(Pass3Hedgerow.own_stats(dozey), Vector2i(24, 44), "still asleep")
		kit.player.round_number += 1
	assert_eq(Pass3Hedgerow.own_stats(dozey), expected, "wake includes tribe, excludes aura/fight")
	assert_eq(dozey.counters["hedgerow_last_wake_round"], 3)
	assert_eq(dozey.turns_in_slot, 3)


func _treasurer(golden: bool, per_gold: String, expected: Vector2i) -> void:
	assert_eq(
		_face("honorary_treasurer", golden),
		"End of Turn: gain +%s/+%s per gold in your Larder." % [per_gold, per_gold]
	)
	var treasurer: RecruitUnit = kit.put("honorary_treasurer", 6, golden)
	for id: String in ["acorn", "stash", "great_hoard"]:
		kit.rules.give_card(kit.player, id)
	assert_eq(kit.player.larder(), 22, "1 + 5 + 16 gold, not three held cards")
	kit.rules.end_phase(kit.player)
	assert_eq(Vector2i(treasurer.perm_attack, treasurer.perm_health), expected)
	assert_eq(kit.player.larder(), 22, "growth does not spend the Larder")


func test_mallow_endpoint_faces_multiply_two_or_four_preselected_targets() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			var selected: Array[Vector2i]
			if t == 0.0:
				selected = [Vector2i(20, 40), Vector2i(40, 80)]
				if golden:
					selected.append_array([Vector2i(60, 120), Vector2i(80, 160)])
			else:
				selected = [Vector2i(70, 140), Vector2i(140, 280)]
				if golden:
					selected.append_array([Vector2i(210, 420), Vector2i(280, 560)])
			_mallow(golden, 2.0 if t == 0.0 else 7.0, selected)


func test_normal_and_golden_dozey_endpoint_faces_wake_on_third_end_phase() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			_wake(
				golden,
				2.0 if t == 0.0 else 7.0,
				Vector2i(48, 88) if t == 0.0 else Vector2i(168, 308)
			)


func test_treasurer_endpoint_faces_use_larder_gold_and_golden_doubles_rate() -> void:
	for t: float in ENDPOINTS:
		for golden: bool in [false, true]:
			_setup(t)
			if t == 0.0:
				_treasurer(
					golden, "2" if golden else "1", Vector2i(44, 44) if golden else Vector2i(22, 22)
				)
			else:
				_treasurer(
					golden,
					"16" if golden else "8",
					Vector2i(352, 352) if golden else Vector2i(176, 176)
				)


func test_half_step_mallow_face_and_effect_keep_fractional_multiplier() -> void:
	for golden: bool in [false, true]:
		_setup(0.5)
		var selected: Array[Vector2i] = [Vector2i(25, 50), Vector2i(50, 100)]
		if golden:
			selected.append_array([Vector2i(75, 150), Vector2i(100, 200)])
		_mallow(golden, 2.5, selected)


func test_half_step_normal_and_golden_dozey_face_and_wake_keep_fractional_multiplier() -> void:
	for golden: bool in [false, true]:
		_setup(0.5)
		_wake(golden, 2.5, Vector2i(60, 110))


func test_half_step_treasurer_face_and_effect_keep_fractional_per_gold() -> void:
	for golden: bool in [false, true]:
		_setup(0.5)
		_treasurer(
			golden, "3" if golden else "1.5", Vector2i(66, 66) if golden else Vector2i(33, 33)
		)


func test_asymmetric_wake_overrides_read_normal_and_golden_dials_independently() -> void:
	for golden: bool in [false, true]:
		_setup(
			0.0,
			{
				"hedgerow_dozey_wake_multiplier": 2.5,
				"hedgerow_golden_dozey_wake_multiplier": 3.5,
			}
		)
		_wake(golden, 3.5 if golden else 2.5, Vector2i(84, 154) if golden else Vector2i(60, 110))
