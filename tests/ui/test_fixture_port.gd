extends GutTest
## The fixture port reads SPEC-format fixtures and units, hands out ints (not JSON floats), and
## steps through its fixed state sequence. It has no rules: recruit actions are refused.

const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")


func test_fixture_numbers_are_ints() -> void:
	var state: Dictionary = FixturePort.load_fixture("recruit_round7")
	var gold: Variant = state["gold"]
	assert_true(gold is int, "gold is an int")
	var shop: Array = state["shop"]
	var first: Dictionary = shop[0]
	var attack: Variant = first["attack"]
	assert_true(attack is int, "unit attack is an int")


func test_every_fixture_unit_view_has_keyword_text() -> void:
	var state: Dictionary = FixturePort.load_fixture("recruit_round7")
	var hand: Array = state["hand"]
	for entry: Variant in hand:
		var view: Dictionary = entry
		assert_true(view.has("keyword_text"), "%s has keyword_text" % view["name"])


func test_new_game_then_end_turn_steps_states_and_sets_combat() -> void:
	var port: FixturePort = FixturePort.new()
	assert_eq(port.new_game(1), "")
	var round_one: int = port.get_state()["round"]
	assert_eq(round_one, 1)
	assert_true(port.get_last_combat().is_empty(), "no combat before the first end turn")
	assert_eq(port.end_turn(), "")
	var round_seven: int = port.get_state()["round"]
	assert_eq(round_seven, 7)
	var events: Array = port.get_last_combat()["events"]
	assert_gt(events.size(), 0, "combat has events")
	assert_eq(port.end_turn(), "")
	assert_true(port.is_over(), "third state is game over")
	assert_ne(port.end_turn(), "", "end turn refused once the game is over")


func test_recruit_actions_are_refused_with_a_reason() -> void:
	var port: FixturePort = FixturePort.new()
	port.new_game(1)
	for reason: String in [port.buy(0), port.sell(0), port.play(0, 0), port.move(0, 1)]:
		assert_string_contains(reason, "Fixture mode")
	for reason: String in [port.refresh(), port.toggle_freeze(), port.tier_up()]:
		assert_string_contains(reason, "Fixture mode")


func test_library_has_every_unit_sorted_by_tier() -> void:
	var units: Array[Dictionary] = FixturePort.new().library_units()
	assert_eq(
		units.size(), 129, "40 library units, the Hoglet, 79 shop units and 9 created slice cards"
	)
	var last_tier: int = 0
	for unit: Dictionary in units:
		var tier: int = unit["tier"]
		assert_true(tier >= last_tier, "%s is in tier order" % unit["name"])
		last_tier = tier


func test_sandbox_fight_returns_the_nightshade_events() -> void:
	var result: Dictionary = FixturePort.new().sandbox_fight([[], []], 1)
	var winner: int = result["winner"]
	var damage: int = result["damage"]
	assert_eq(winner, 0)
	assert_eq(damage, 10)
	var events: Array = result["events"]
	var first: Dictionary = events[0]
	var kind: String = first["type"]
	assert_eq(kind, "combat_start")
