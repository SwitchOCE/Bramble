extends GutTest
## The Pigeon plans' key interactions (docs/ideation-track-2/tribes/pigeon/README.md, "The four
## plans"), each through the core: Parade ground, Hold the post, Old soldiers, Air wing.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/pigeon/pigeon_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	game.start_round()
	p = game.player(0)
	q = game.player(1)


func _order(unit: Unit, mechanic: String, target: int) -> String:
	return game.act(0, {"type": "ability", "uid": unit.uid, "mechanic": mechanic, "target": target})


# --- Parade ground ------------------------------------------------------------------------------


func test_parade_drilled_front_row_opens_with_the_lieutenant() -> void:
	Kit.put(game, p, "colour-sergeant", 0)
	Kit.put(game, p, "lieutenant", 1)
	Kit.put(game, p, "territorial", 2)
	Kit.put(game, p, "sentry", 3)
	game.end_turn(0)
	assert_eq(p.slots[0].attack, 3, "the Colour Sergeant drilled the row")
	assert_eq(p.slots[3].attack, 3 + 1, "and the Sentry its own slot")
	for slot: int in game.geometry.front:
		Kit.put(game, q, "t1_plain", slot, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	var amounts: Array[int] = []
	for event: Dictionary in Kit.events(combat, "damage", 1):
		amounts.append(int(event["amount"]))
	assert_eq(amounts, [3, 3, 3, 4], "each slot's Attack buff, across")


func test_parade_reserve_steps_in_before_the_sergeants_private_and_the_bugler_hears_both() -> void:
	Kit.put(game, p, "t1_plain", 0, 0, 1)
	Kit.put(game, p, "t1_herald", 1, 0, 100000)
	Kit.put(game, p, "recruiting-sergeant", 4, 0, 100000)
	Kit.put(game, p, "bugler", 5, 0, 100000)
	var reservist: Unit = Kit.to_hand(game, p, "territorial")
	reservist.stats.set_attack = 0
	Kit.put(game, q, "t1_plain", 0, 50, 100000)
	var combat: Combat = Kit.fight(game)
	var arrivals: Array[String] = []
	for event: Dictionary in combat.events:
		if event["type"] in ["reserve", "summon"] and int(event["side"]) == 0:
			arrivals.append("%s@%d" % [event["id"], int(event["slot"])])
	assert_eq(arrivals.slice(0, 2), ["territorial@0", "private@0"])
	assert_eq(Kit.triggers(combat, "pigeon_bugler").size(), 3, "both Privates and the Reserve")


# --- Hold the post ------------------------------------------------------------------------------


func test_post_built_by_orders_and_fed_from_reserve_first() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 4, 0, 100000)
	var corporal: Unit = Kit.put(game, p, "lance-corporal", 5, 0, 100000)
	Kit.put(game, p, "t1_plain", 0, 0, 1)
	Kit.put(game, p, "t1_herald", 1, 0, 1)
	Kit.to_hand(game, p, "territorial")
	p.gold = 5
	assert_eq(_order(grenadier, "pigeon_grenadier", 1), "")
	assert_eq(_order(corporal, "pigeon_lance_corporal", -1), "")
	game.end_turn(0)
	assert_eq(p.slots[1].attack, 2 + 2, "the Corporal's drill and the Grenadier's")
	assert_eq(p.slots[1].health, 2 + 4)
	Kit.put(game, q, "t4_cleaver", 0, 10, 100000)
	for slot: int in [1, 2, 3, 4]:
		Kit.put(game, q, "t1_plain", slot, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var first: Dictionary = Kit.events(combat, "attack", 1)[0]
	assert_eq(first["target_slot"], 1, "the post has Guard")
	var first_deaths: Array[int] = []
	for event: Dictionary in Kit.events(combat, "death", 0).slice(0, 2):
		first_deaths.append(int(event["slot"]))
	assert_eq(first_deaths, [0, 1], "the Cleave took F1 and the post at once")
	var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
	assert_eq(stepped.size(), 1)
	assert_eq(stepped[0]["slot"], 1, "into the Guard post first")
	assert_eq(stepped[0]["attack"], 4 + 4, "with the post's buff")
	var next: Array[Dictionary] = Kit.events(combat, "attack", 1)
	assert_eq(next[1]["target_slot"], 1, "and Guard: still the post")


func test_post_padre_grows_the_slot_with_each_death_there() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 4, 0, 100000)
	Kit.put(game, p, "padre", 5, 0, 100000)
	Kit.put(game, p, "t1_plain", 1, 0, 1)
	p.gold = 5
	assert_eq(_order(grenadier, "pigeon_grenadier", 1), "")
	Kit.to_hand(game, p, "territorial")
	Kit.to_hand(game, p, "territorial")
	Kit.put(game, q, "t1_plain", 0, 100, 100000)
	Kit.fight(game)
	assert_eq(p.slots[1].attack, 3, "three deaths in the post, +1/+1 each, for good")


# --- Old soldiers -------------------------------------------------------------------------------


func test_old_soldiers_adjutant_decorates_and_the_brigadier_doubles_them() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	var brigadier: Unit = Kit.put(game, p, "brigadier", 1)
	Kit.put(game, p, "adjutant", 4)
	game.finish_round()
	assert_eq(campaigner.counter(&"pigeon_medal"), 2 + 2, "Adjutant 2, survived 2")
	assert_true(campaigner.has_mechanic(&"windfury"), "Decorated: attacks twice")
	assert_true(campaigner.has_mechanic(&"pigeon_stiff_upper_lip"))
	assert_eq(brigadier.counter(&"pigeon_medal"), 2)
	assert_false(brigadier.has_mechanic(&"windfury"))
	game.start_round()
	game.finish_round()
	assert_true(brigadier.has_mechanic(&"windfury"), "the Brigadier himself, once Decorated")


func test_old_soldiers_field_marshal_doubles_medal_value_and_saves_the_decorated() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	Kit.put(game, p, "field-marshal", 4, 0, 100000)
	Kit.medals(game, p, campaigner, 3)
	assert_eq(campaigner.attack(), 4 + 3 * 4)
	Kit.put(game, q, "t1_plain", 0, 1000, 100000)
	var combat: Combat = Kit.fight(game)
	var saved: Array[Dictionary] = Kit.events(combat, "status", 0)
	assert_eq(saved.size(), 1, "one Stiff Upper Lip from two sources")


func test_a_reserve_flying_ace_earns_its_medal_on_the_unit_in_hand() -> void:
	Kit.put(game, p, "the-colonel", 4, 0, 100000)
	Kit.put(game, p, "t1_plain", 0, 0, 1)
	var ace: Unit = Kit.to_hand(game, p, "flying-ace")
	ace.stats.set_health = 100000
	Kit.put(game, q, "t1_plain", 0, 1, 100000)
	Kit.put(game, q, "t1_plain", 4, 1, 3)
	Kit.fight(game)
	assert_gt(ace.counter(&"pigeon_medal"), 0, "written to the unit in hand")


# --- Air wing -----------------------------------------------------------------------------------


func test_air_wing_squadron_leader_and_wing_commander_open_on_the_back_row() -> void:
	Kit.put(game, p, "t1_plain", 0)
	Kit.put(game, p, "flying-ace", 1)
	Kit.put(game, p, "wing-commander", 2)
	Kit.put(game, p, "squadron-leader", 4)
	for slot: int in game.geometry.front:
		Kit.put(game, q, "t1_guard", slot, 0, 100000)
	Kit.put(game, q, "t1_plain", 5, 0, 100000)
	game.config.attack_limit = 2
	var combat: Combat = Kit.fight(game)
	var swings: Array[Dictionary] = Kit.events(combat, "attack", 0)
	assert_eq(swings.size(), 2)
	assert_eq(swings[0]["slot"], 1, "the Ace, given Sortie and +4 Attack")
	assert_eq(swings[1]["slot"], 2, "the Wing Commander; the plain unit is not a Pigeon")
	for swing: Dictionary in swings:
		assert_eq(swing["target_slot"], 5, "over a front row of Guards")
	var ace_copy: CombatUnit = combat.unit_at(0, 1)
	assert_eq(ace_copy.attack(), 8 + 3, "its own 8 and the Squadron Leader's +3")
