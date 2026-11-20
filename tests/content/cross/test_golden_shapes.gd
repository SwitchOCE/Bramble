extends GutTest
## Each balance override is made in a copy of the actual card JSON and loaded as a card.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/cross/cross_kit.gd")
const SHAPES: Dictionary = {
	"hedge-lancer": ["badger", "badger_lance", "attacks"],
	"tourney-champion": ["badger", "badger_tourney", "targets"],
	"the-oakfeller": ["badger", "badger_oakfeller", "extra_attacks"],
	"herald-of-the-charge": ["badger", "badger_herald", "target_set"],
	"greatsword-bearer": ["badger", "badger_greatsword", "target_set"],
	"quartermaster": ["pigeon", "pigeon_quartermaster", "reserve_targets"],
}

var content: GameContent
var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	content = GameContent.load_default()


func _start() -> void:
	game = content.new_session(1)
	game.start_round()
	p = game.player(0)
	q = Kit.opponent(game, p)


func _load_override(id: String, golden_value: Variant) -> UnitLibrary:
	var shape: Array = SHAPES[id]
	var file: String = "res://src/content/%s/units.json" % shape[0]
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
	for card: Dictionary in data["cards"]:
		if card["id"] != id:
			continue
		for entry: Variant in card.get("keywords", []) + card.get("effects", []):
			if entry is Dictionary and entry["mechanic"] == shape[1]:
				entry["golden"][shape[2]] = golden_value
				var library := UnitLibrary.new()
				library.add_cards([card], content.registry)
				return library
	return null


func _card(id: String, golden: bool, golden_value: Variant = null) -> Unit:
	var library: UnitLibrary = content.library
	if golden_value != null:
		library = _load_override(id, golden_value)
		assert_eq(library.errors, PackedStringArray(), id)
	return game.new_unit(library.get_card(StringName(id)), golden)


func _place(unit: Unit, slot: int) -> void:
	p.place(unit, slot)
	game.recruit.refresh_auras(p)


func _opening() -> Array[Dictionary]:
	var combat: Combat = Kit.fight(game, p, q)
	return Kit.where(combat, "attack", "out_of_turn", true)


func test_lancer_repeats_its_damage_free_opening_attack() -> void:
	for golden_value: Variant in [null, 2, 3]:
		for golden: bool in [false, true]:
			_start()
			var lancer: Unit = _card("hedge-lancer", golden, golden_value)
			_place(lancer, 0)
			Kit.wall(game, q, 0, 1, 5000)
			var count: int = int(golden_value) if golden and golden_value != null else 1
			var opening: Array[Dictionary] = _opening()
			assert_eq(opening.size(), count)
			for attack: Dictionary in opening:
				assert_true(attack["takes_no_damage"])
			var suffix: String = ["", " twice", " three times"][count - 1]
			assert_eq(
				lancer.view()["text"],
				(
					"Fury %d.\nStart of fight: This attacks immediately%s and takes no damage."
					% [2 if golden else 1, suffix]
				)
			)


func test_tourney_attacks_distinct_top_enemies_including_the_back_row() -> void:
	for golden_value: Variant in [null, 2]:
		for golden: bool in [false, true]:
			_start()
			var champion: Unit = _card("tourney-champion", golden, golden_value)
			_place(champion, 0)
			Kit.wall(game, q, 0, 2, 5000).grant(game.registry, &"taunt")
			Kit.wall(game, q, 1, 11, 5000)
			Kit.wall(game, q, 4, 15, 5000)
			Kit.wall(game, q, 5, 11, 5000)
			var wider: bool = golden and golden_value != null
			var opening: Array[Dictionary] = _opening()
			assert_eq(
				opening.map(func(e: Dictionary) -> int: return e["target_slot"]),
				[4, 1] if wider else [4],
				"highest Attack first, then the first of the tied enemies"
			)
			for attack: Dictionary in opening:
				assert_true(attack["takes_no_damage"])
			assert_eq(
				champion.view()["text"],
				(
					"Fury %d.\nStart of fight: This attacks %s with the most Attack and takes no damage."
					% [2 if golden else 1, "the 2 enemies" if wider else "the enemy"]
				)
			)


func test_oakfeller_can_attack_twice_more_without_starting_a_new_chain() -> void:
	for golden_value: Variant in [null, 2]:
		for golden: bool in [false, true]:
			_start()
			var oakfeller: Unit = _card("the-oakfeller", golden, golden_value)
			_place(oakfeller, 0)
			for slot: int in 4:
				Kit.wall(game, q, slot, 0, 48 if golden else 24)
			var combat: Combat = Kit.fight(game, p, q)
			var count: int = 2 if golden and golden_value != null else 1
			var attacks: Array[Dictionary] = Kit.events(combat, "attack")
			assert_false(attacks[0]["out_of_turn"])
			var followups: int = 0
			for attack: Dictionary in attacks.slice(1):
				if not attack["out_of_turn"]:
					break
				followups += 1
			assert_eq(followups, count)
			var start: int = combat.events.find(attacks[0])
			var end: int = (
				combat.events.find(attacks[count + 1]) if attacks.size() > count + 1 else -1
			)
			var chain: Array = combat.events.slice(start, end if end >= 0 else combat.events.size())
			var triggers: Array = chain.filter(
				func(e: Dictionary) -> bool: return e.get("mechanic") == "badger_oakfeller"
			)
			assert_eq(triggers.size(), 1, "kills in follow-ups never start another chain")
			assert_eq(
				oakfeller.view()["text"],
				(
					"Fury %d.\nOverrun.\nAfter this attacks and kills a unit, it attacks %s more."
					% [6 if golden else 3, "twice" if count == 2 else "once"]
				)
			)


func test_herald_can_charge_all_front_units_in_reading_order() -> void:
	for golden_value: Variant in [null, "front_row"]:
		for golden: bool in [false, true]:
			_start()
			var herald: Unit = _card("herald-of-the-charge", golden, golden_value)
			_place(herald, 4)
			for slot: int in [0, 1, 2, 3, 5]:
				Kit.wall(game, p, slot, 1, 20)
			Kit.wall(game, q, 0, 1, 5000)
			var wider: bool = golden and golden_value != null
			assert_eq(
				_opening().map(func(e: Dictionary) -> int: return e["slot"]),
				[0, 1, 2, 3] if wider else [0, 1]
			)
			assert_eq(
				herald.view()["text"],
				(
					"Squire.\nStart of fight: %s attack immediately."
					% ("Your front-row units" if wider else "The units in front of this")
				)
			)


func test_greatsword_can_grant_overrun_to_the_entire_front_row() -> void:
	for golden_value: Variant in [null, "front_row"]:
		for golden: bool in [false, true]:
			_start()
			var bearer: Unit = _card("greatsword-bearer", golden, golden_value)
			_place(bearer, 4)
			for slot: int in [0, 1, 2, 3, 5]:
				Kit.wall(game, p, slot, 1, 20)
			var wider: bool = golden and golden_value != null
			var expected: Array = [0, 1, 2, 3] if wider else [0, 1]
			assert_eq(
				bearer.view()["text"],
				(
					"Squire.\n%s have Overrun."
					% ("Your front-row units" if wider else "The units in front of this")
				)
			)
			Kit.wall(game, q, 0, 1, 5000)
			var combat: Combat = Kit.fight(game, p, q)
			for slot: int in [0, 1, 2, 3, 5]:
				var unit: Unit = p.board[slot]
				assert_eq(unit.has_mechanic(&"badger_overrun"), expected.has(slot))
				assert_eq(
					Kit.start_view(combat, unit)["keywords"].has("badger_overrun"),
					expected.has(slot)
				)


func test_quartermaster_can_keep_the_grant_at_one_and_call_two_more() -> void:
	for golden_value: Variant in [null, 1]:
		for golden: bool in [false, true]:
			_start()
			var first: Unit = Kit.hold(game, p, "sentry")
			var next: Unit = Kit.hold(game, p, "padre")
			var officer: Unit = _card("quartermaster", golden, golden_value)
			assert_true(game.recruit._gain(p, officer, first.uid))
			assert_true(first.has_mechanic(&"pigeon_reserve"))
			var two_targets: bool = golden and golden_value == null
			assert_eq(next.has_mechanic(&"pigeon_reserve"), two_targets)
			p.hand.erase(officer)
			_place(officer, 0)
			var limit: int = game.config.reserve_limit + (2 if golden else 1)
			assert_eq(game.rules.reserve_limit(p), limit)
			Kit.wall(game, q, 0, 1, 5000)
			game.config.attack_limit = 1
			assert_eq(Kit.fight(game, p, q).arrivals.limit(0), limit)
			assert_eq(
				officer.view()["text"],
				(
					"Recruit: Give %s in your hand Reserve.\nYou can call %s each fight."
					% [
						"2 units" if two_targets else "a unit",
						"2 more reservists" if golden else "1 more reservist"
					]
				)
			)


func test_text_override_is_checked_on_load_and_used_by_the_golden_preview() -> void:
	var invalid: UnitLibrary = _load_override("herald-of-the-charge", 2)
	assert_false(invalid.has(&"herald-of-the-charge"))
	assert_string_contains(invalid.errors[0], "golden 'target_set' must be text")

	var preview := GameContent.new()
	preview.library = _load_override("herald-of-the-charge", "front_row")
	preview.registry = content.registry
	var plain: Dictionary = ViewAdapter.printed_unit(preview, "herald-of-the-charge")
	var golden: Dictionary = ViewAdapter.printed_unit(preview, "herald-of-the-charge", true)
	assert_eq(
		plain["text"], "Squire.\nStart of fight: The units in front of this attack immediately."
	)
	assert_eq(golden["text"], "Squire.\nStart of fight: Your front-row units attack immediately.")
