extends GutTest
## The two Mouse mechanics of the rework (Reworks S6), before any card prints them: Pile on N
## (rulebook 11.7.11, 7.3.5a) and Hand-me-down (11.7.12-11.7.13). Two test cards carry them;
## today's Pile on cards keep their uncounted Pile on and behave as before (test_mouse_units.gd).
## Slots: F1-F4 are 0-3, B1-B3 are 4-6.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const Kit := preload("res://tests/content/mouse/mouse_kit.gd")
const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")

const CARDS: Array = [
	{
		"id": "test-pile-two",
		"name": "Pile Two",
		"tier": 1,
		"attack": 3,
		"health": 1000,
		"tribes": ["Mouse"],
		"types": ["Mouse"],
		"text": "Pile on {pile_on}.",
		"effects": [{"mechanic": "mouse_pile_on", "pile_on": 2}],
	},
	{
		"id": "test-kin",
		"name": "Kin",
		"tier": 1,
		"attack": 5,
		"health": 1,
		"tribes": ["Mouse"],
		"types": ["Mouse"],
		"text": "Hand-me-down.",
		"keywords": ["mouse_hand_me_down"],
	},
]
## Today's cards with Pile on: each keeps the uncounted one ("Pile on.", N 0).
const TODAYS_PILERS: Array[String] = [
	"cousin",
	"needle-page",
	"harvest-piper",
	"shrew-cutpurse",
	"needle-pikeman",
	"fencing-master",
	"dame-bodkin",
]

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	_start(Kit.session())


func _start(session: GameSession) -> void:
	game = session
	game.library.add_cards(CARDS, game.registry)
	assert_eq(game.library.errors, PackedStringArray(), "the test cards load")
	p = game.player(0)
	q = game.player(1)


## A wall at F1 that attacks every other turn, a piler beside it at F2, and an enemy that
## never dies. Returns [the fight, F1's attacks, the piler's hits].
func _pile_fight(attacks: int = 16) -> Array:
	Kit.wall(game, q, 0, 0, 100000)
	game.config.attack_limit = attacks
	var combat: Combat = Kit.fight(game)
	var wall: int = Kit.uid_at(combat, 0, 0)
	var piler: int = Kit.uid_at(combat, 0, 1)
	return [
		combat,
		Kit.where(combat, "attack", "uid", wall).size(),
		Kit.where(combat, "hit", "uid", piler),
	]


func _pile_uses(combat: Combat) -> Array:
	return Kit.where(combat, "uses", "key", "mouse_pile_on").map(
		func(e: Dictionary) -> int: return CoreUtil.to_int(e["left"])
	)


# --- Pile on N ------------------------------------------------------------------------------------


func test_pile_on_two_hits_for_the_first_two_neighbour_attacks_only() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	CoreKit.put(game, p, "test-pile-two", 1)
	var run: Array = _pile_fight()
	assert_gt(run[1], 3, "the neighbour attacked more than twice")
	assert_eq(run[2].size(), 2, "N counts neighbour attacks: the first 2")
	assert_eq(_pile_uses(run[0]), [1, 0], "its uses left show, down to 0")
	assert_eq(CoreKit.unit(game, "test-pile-two").view()["text"], "Pile on 2.")


func test_a_golden_piler_keeps_n_and_hits_with_its_doubled_attack() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	var golden: Unit = Kit.golden(game, p, "test-pile-two", 1)
	assert_eq(golden.view()["text"], "Pile on 2.", "golden never doubles N (7.3.5a)")
	var run: Array = _pile_fight()
	assert_eq(run[2].size(), 2, "still 2 pile-ons")
	var combat: Combat = run[0]
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 1)).slice(0, 2), [6, 6] as Array[int])


func test_todays_uncounted_pile_on_hits_every_neighbour_attack() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	CoreKit.put(game, p, "needle-page", 1)
	var run: Array = _pile_fight()
	assert_gt(run[1], 3)
	assert_eq(run[2].size(), run[1], "one pile-on for every attack beside it, as before")
	assert_eq(_pile_uses(run[0]), [], "an uncounted Pile on shows no uses")


func test_todays_pile_on_cards_carry_the_uncounted_pile_on_and_print_no_number() -> void:
	for id: String in TODAYS_PILERS:
		var card: UnitDef = game.library.get_card(StringName(id))
		var counts: Array = []
		for spec: MechanicSpec in card.mechanics:
			if spec.id == MouseRules.PILE_ON:
				counts.append(spec.params.num(&"pile_on"))
		assert_eq(counts, [MouseRules.PILE_ON_UNCOUNTED], id)
		assert_true(card.text.begins_with("Pile on."), id)


func test_pile_on_from_two_sources_adds_up_and_hits_once_an_attack() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	var piler: Unit = CoreKit.put(game, p, "test-pile-two", 1)
	assert_true(piler.grant_effect(game.registry, MouseRules.PILE_ON, {"pile_on": 1}))
	var run: Array = _pile_fight(24)
	assert_gt(run[1], 4)
	assert_eq(run[2].size(), 3, "Pile on 2 and Pile on 1 make 3")
	var combat: Combat = run[0]
	var wall: int = Kit.uid_at(combat, 0, 0)
	var at: int = Kit.index_of(combat, "attack", {"uid": wall})
	assert_eq(Kit.between(combat, at, Kit.next_attack(combat, at), "hit").size(), 1)


func test_the_pile_on_pill_says_its_n_or_the_general_rule() -> void:
	var table: Dictionary = game.display
	var counted: Array[Dictionary] = CardTerms.pills(
		{"text": "Pile on 2.", "keywords": [], "mechanics": ["mouse_pile_on"]}, table
	)
	assert_eq(counted[0]["words"], "Pile on 2")
	assert_eq(
		counted[0]["reminder"],
		"The first 2 times a neighbour attacks each fight, this hits the target first."
	)
	var plain: Array[Dictionary] = CardTerms.pills(
		{"text": "Pile on.", "keywords": [], "mechanics": ["mouse_pile_on"]}, table
	)
	assert_eq(plain[0]["words"], "Pile on")
	assert_eq(plain[0]["reminder"], "Whenever a neighbour attacks, this hits the target first.")


# --- Hand-me-down: who inherits -------------------------------------------------------------------


## The board as it stands, from a fight with no attacks.
func _still_fight() -> Combat:
	Kit.wall(game, q, 0, 0, 100)
	game.config.attack_limit = 0
	return Kit.fight(game)


func test_nearest_is_fewest_neighbour_steps_not_reading_order() -> void:
	CoreKit.put(game, p, "needle-page", 0)
	CoreKit.put(game, p, "test-kin", 3)
	CoreKit.put(game, p, "needle-page", 6)
	var combat: Combat = _still_fight()
	var heir: CombatUnit = MouseRules.nearest_mouse(combat, combat.unit_at(0, 3))
	assert_eq(heir.slot, 6, "B3 is 1 step from F4; F1 is 3")


func test_nearest_ties_go_in_reading_order_and_skip_other_tribes() -> void:
	CoreKit.put(game, p, "test-kin", 0)
	Kit.wall(game, p, 1, 1, 10)
	CoreKit.put(game, p, "hedgerow-scout", 2)
	CoreKit.put(game, p, "hedgerow-scout", 5)
	var combat: Combat = _still_fight()
	var heir: CombatUnit = MouseRules.nearest_mouse(combat, combat.unit_at(0, 0))
	assert_eq(heir.slot, 2, "F3 and B2 are both 2 steps from F1; F3 reads first; F2 isn't a Mouse")


func test_with_no_other_mouse_nobody_inherits() -> void:
	CoreKit.put(game, p, "test-kin", 0)
	Kit.wall(game, p, 1, 1, 10)
	var combat: Combat = _still_fight()
	assert_null(MouseRules.nearest_mouse(combat, combat.unit_at(0, 0)))


# --- Hand-me-down: what passes --------------------------------------------------------------------


## The Kin at F1 (5/1, +3 Attack for good) attacks first into a 1/1000 wall and dies to the strike
## back; a Scout at F2 inherits. Its slot has +4 Attack and a Standard-bearer's aura adds more:
## neither passes.
func _kin_dies() -> Combat:
	var kin: Unit = CoreKit.put(game, p, "test-kin", 0)
	kin.stats.perm_attack = 3
	p.slots[0].attack = 4
	CoreKit.put(game, p, "hedgerow-scout", 1)
	CoreKit.put(game, p, "parish-standard-bearer", 6)
	Kit.wall(game, q, 0, 1, 1000)
	game.config.attack_limit = 1
	return Kit.fight(game)


func test_hand_me_down_passes_only_the_units_own_attack_this_fight() -> void:
	var combat: Combat = _kin_dies()
	var kin: int = Kit.uid_at(combat, 0, 0)
	assert_eq(Kit.where(combat, "death", "uid", kin).size(), 1, "the Kin died")
	assert_gt(Kit.start_view(combat, 0, 0)["attack"], 8, "it stood with its slot and the aura")
	assert_eq(Kit.where(combat, "trigger", "mechanic", "mouse_hand_me_down").size(), 1)
	var heir: CombatUnit = combat.unit_at(0, 1)
	assert_eq(heir.stats.combat_attack, 5 + 3, "printed and its own buffs; no slot, no aura")
	assert_eq(heir.stats.perm_attack, 0, "this fight only")
	assert_eq(p.board[1].stats.perm_attack, 0, "the recruit Scout keeps nothing")


func test_dirge_singer_resolves_hand_me_down_twice() -> void:
	_start(CoreKit.content(["mouse", "locust"], false).session(1))
	game.start_round()
	CoreKit.put(game, p, "dirge-singer", 5)
	var combat: Combat = _kin_dies()
	assert_eq(Kit.where(combat, "trigger", "mechanic", "mouse_hand_me_down").size(), 2)
	assert_eq(combat.unit_at(0, 1).stats.combat_attack, 2 * (5 + 3), "the Scout inherits twice")


func test_hand_me_down_shows_as_a_keyword_with_its_reminder() -> void:
	var entry: Dictionary = game.display["mouse_hand_me_down"]
	assert_eq(entry["name"], "Hand-me-down")
	assert_eq(
		entry["reminder"], "When this dies, the nearest friendly Mouse gains its Attack this fight."
	)
	assert_false(entry["hidden"])
	var view: Dictionary = CoreKit.unit(game, "test-kin").view()
	assert_true(view["keywords"].has("mouse_hand_me_down"))
	assert_true(game.registry.get_mechanic(MouseRules.HAND_ME_DOWN).has_death_effect())
