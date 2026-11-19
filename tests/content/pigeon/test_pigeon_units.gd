extends GutTest
## Each Pigeon card's text, proved through the core in a real fight or recruit turn (the event
## log or the player view), plus the tribe's data checks. Design:
## docs/ideation-track-2/tribes/pigeon/units.json.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/pigeon/pigeon_kit.gd")
const DESIGN: String = "res://docs/ideation-track-2/tribes/pigeon/units.json"
const GOLDEN_TEXT: Dictionary = {
	"sentry": "At the end of your turn, give this slot +2/+2.",
	"territorial": "Reserve.",
	"old-campaigner":
	"After each fight, earn 2 Medals. Earn 4 if this survived.\nDecorated: Stiff Upper Lip.",
	"recruiting-sergeant":
	"When a slot in front of this is empty in a fight, summon a golden 4/4 Private there (2 a fight).",
	"lance-corporal": "Order (1): Give the slots in front of this +4/+4.",
	"colour-sergeant":
	"At the end of your turn, if this row is full of Pigeons, give its slots +6/+6.",
	"padre": "After a friendly unit dies, give its slot +2/+2 permanently (8 a fight).",
	"flying-ace": "After this kills, earn 2 Medals.\nDecorated: Cleave.",
	"grenadier-guard":
	"Order (1): Make a slot your Guard post.\nAt the end of your turn, give your Guard post +4/+8.",
	"lieutenant":
	(
		"Start of fight: If this row is full, each unit in it deals twice its slot's Attack buff"
		+ " to the enemy across from it."
	),
	"squadron-leader": "The units in front of this have Sortie and +6 Attack.",
	"adjutant": "After each fight, the units in front of this earn 4 Medals.",
	"bugler": "After a Pigeon joins the fight, give your Pigeons +4/+4.",
	"colour-ensign":
	"Start of fight: This slot and the slots next to it copy your strongest slot's buff.",
	"brigadier": "Your Decorated Pigeons attack twice.",
	"wing-commander":
	"Sortie.\nStart of fight: Your Pigeons with Sortie attack immediately, twice.",
	"regimental-sergeant-major":
	"At the end of your turn, give every slot +4/+4.\nBuffs you give to slots are tripled.",
	"the-colonel": "Units in your hand have Reserve.",
	"field-marshal":
	"Medals on your Pigeons are worth +6/+6.\nYour Decorated Pigeons have Stiff Upper Lip.",
}

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	game.start_round()
	p = game.player(0)
	q = game.player(1)


# --- Data -------------------------------------------------------------------------------------


func test_pigeon_content_loads_without_errors() -> void:
	var content: ContentSet = Kit.CoreKit.content(["pigeon"], false)
	assert_eq(content.errors, PackedStringArray(), "no loader errors")
	assert_true(content.standing.has(&"pigeon_guard_post"))


func test_every_card_matches_the_design_name_tier_stats_and_text() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var entries: Array = design["units"] + design["tokens"]
	assert_eq(entries.size(), 20, "19 units and the Private")
	for value: Variant in entries:
		var entry: Dictionary = value
		var card: UnitDef = game.library.get_card(StringName(entry["id"]))
		assert_not_null(card, "%s is a card" % entry["id"])
		if card == null:
			continue
		assert_eq(card.name, entry["name"])
		assert_eq(card.tier, int(entry["tier"]))
		assert_eq(card.attack, int(entry["attack"]))
		assert_eq(card.health, int(entry["health"]))
		assert_true(card.has_tribe("Pigeon"))
		var shown: Unit = Kit.CoreKit.unit(game, entry["id"])
		assert_eq(
			str(shown.view()["text"]).replace("\n", " "), entry["text"], "%s text" % entry["id"]
		)


func test_every_shown_display_entry_has_the_glossary_name_and_reminder() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var glossary: Dictionary = design["keywords"]
	var wanted: Dictionary = {
		"slot_buff": "Slot buff",
		"pigeon_lance_corporal": "Order (N)",
		"pigeon_grenadier": "Order (N)",
		"pigeon_guard_post": "Guard post",
		"pigeon_reserve": "Reserve",
		"pigeon_joins_the_fight": "Joins the fight",
		"pigeon_medal": "Medal",
		"pigeon_decorated": "Decorated",
		"pigeon_stiff_upper_lip": "Stiff Upper Lip",
		"pigeon_sortie": "Sortie",
		"pigeon_private": "Private",
	}
	for key: String in wanted:
		var entry: Dictionary = game.display[key]
		assert_eq(entry["name"], wanted[key])
		assert_eq(entry["reminder"], glossary[wanted[key]], key)
	assert_eq(game.display["cleave"]["reminder"], glossary["Cleave"])
	assert_eq(game.display["taunt"]["reminder"], glossary["Guard"])
	assert_false(game.display.has("pigeon_slot_buff"), "the shared slot_buff, not our own")


## What a screen reads: every reminder id on a card is a shown display entry; every glossary term
## the design lists for the card is reachable from it (its reminders, or a shown keyword or
## mechanic of its own); printed keywords are shown entries; helper mechanics are hidden.
func test_every_card_reaches_a_reminder_for_every_term_it_uses() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var shown_keywords: Array = [
		"pigeon_reserve", "pigeon_sortie", "pigeon_lance_corporal", "pigeon_grenadier"
	]
	for value: Variant in design["units"]:
		var entry: Dictionary = value
		var card: UnitDef = game.library.get_card(StringName(entry["id"]))
		var names: Array = []
		for id: String in card.reminders:
			var shown: Dictionary = game.display.get(id, {})
			assert_false(shown.is_empty(), "%s: reminder %s has an entry" % [card.id, id])
			assert_false(shown.get("hidden", true), "%s: reminder %s is shown" % [card.id, id])
			names.append(shown.get("name", ""))
		var own: Array = []
		for spec: MechanicSpec in card.mechanics:
			own.append(spec.id)
		for id: Variant in own:
			var shown: Dictionary = game.display[String(id)]
			assert_eq(
				shown["hidden"], not shown_keywords.has(String(id)), "%s: %s shown?" % [card.id, id]
			)
			if not shown["hidden"]:
				names.append(shown["name"])
		for term: String in entry["keywords"]:
			var wanted: String = "Order (N)" if term == "Order" else term
			assert_true(names.has(wanted), "%s reaches %s" % [card.id, wanted])


func test_the_private_token_has_its_stats_for_the_screen() -> void:
	var private: UnitDef = game.library.get_card(&"private")
	assert_true(private.token)
	assert_eq([private.attack, private.health], [2, 2])
	assert_eq(game.display["pigeon_private"]["reminder"], "A 2/2 Pigeon.")
	var sergeant: UnitDef = game.library.get_card(&"recruiting-sergeant")
	assert_true(Array(sergeant.reminders).has("pigeon_private"))


func test_private_is_a_token_out_of_the_pool() -> void:
	assert_false(game.units.has_card(&"private"))
	assert_true(game.units.has_card(&"sentry"))


# --- Golden copies (the design's `golden` line for each unit) ---------------------------------


func test_every_golden_reads_as_the_design_golden_line_with_doubled_stats() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	assert_eq(GOLDEN_TEXT.size(), design["units"].size(), "one line per unit")
	for value: Variant in design["units"]:
		var entry: Dictionary = value
		var golden: Unit = Kit.CoreKit.unit(game, entry["id"], true)
		assert_eq(golden.view()["text"], GOLDEN_TEXT[entry["id"]], entry["id"])
		assert_eq(golden.attack(), 2 * int(entry["attack"]), "%s Attack" % entry["id"])
		assert_eq(golden.health(), 2 * int(entry["health"]), "%s Health" % entry["id"])


func test_golden_old_campaigner_earns_4_medals_when_it_survives_2_when_not() -> void:
	var lived: Unit = Kit.put(game, p, "old-campaigner", 0, -1, -1, true)
	game.finish_round()
	assert_eq(lived.counter(&"pigeon_medal"), 4)
	game = Kit.session()
	game.start_round()
	p = game.player(0)
	var fell: Unit = Kit.put(game, p, "old-campaigner", 0, -1, -1, true)
	Kit.put(game, game.player(game.opponent_of(0)), "t1_plain", 0, 500, 2000)
	game.finish_round()
	assert_eq(fell.counter(&"pigeon_medal"), 2)


func test_golden_flying_ace_earns_2_medals_a_kill() -> void:
	var ace: Unit = Kit.put(game, p, "flying-ace", 0, -1, 500, true)
	Kit.put(game, q, "t1_plain", 4, 0, 1)
	Kit.fight(game)
	assert_eq(ace.counter(&"pigeon_medal"), 2)


func test_golden_colour_sergeant_gives_6_6() -> void:
	Kit.put(game, p, "colour-sergeant", 4, -1, -1, true)
	Kit.put(game, p, "territorial", 5)
	Kit.put(game, p, "padre", 6)
	game.end_turn(0)
	for slot: int in game.geometry.back:
		assert_eq(p.slots[slot].attack, 6)


func test_golden_padre_gives_2_2_still_8_a_fight() -> void:
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.put(game, p, "padre", 4, 0, 500, true)
	Kit.put(game, q, "t1_plain", 0, 50, 500)
	var combat: Combat = Kit.fight(game)
	assert_eq(p.slots[0].attack, 2)
	assert_eq(p.slots[0].health, 2)
	assert_eq(Kit.events(combat, "uses", 0)[0]["left"], 7, "8 a fight, one used")


func test_golden_grenadier_guard_drills_its_post_4_8() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 0, -1, -1, true)
	p.gold = 3
	game.act(
		0, {"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 1}
	)
	assert_eq(p.gold, 2, "still 1 gold")
	game.end_turn(0)
	assert_eq(p.slots[1].attack, 4)
	assert_eq(p.slots[1].health, 8)


func test_golden_lieutenant_deals_double() -> void:
	Kit.ctx(game, p).slot_buff(1, 5, 0, null)
	Kit.put(game, p, "lieutenant", 0, -1, -1, true)
	Kit.put(game, p, "t1_plain", 1)
	Kit.put(game, p, "t1_plain", 2)
	Kit.put(game, p, "t1_plain", 3)
	Kit.put(game, q, "t1_plain", 1, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "damage", 1)[0]["amount"], 10)


func test_golden_squadron_leader_gives_6_attack() -> void:
	Kit.put(game, p, "squadron-leader", 5, -1, -1, true)
	var plain: Unit = Kit.put(game, p, "t1_plain", 1)
	assert_eq(plain.attack(), 2 + 6)
	assert_true(plain.has_mechanic(&"pigeon_sortie"))


func test_golden_adjutant_gives_4_medals() -> void:
	Kit.put(game, p, "adjutant", 4, -1, -1, true)
	var left: Unit = Kit.put(game, p, "t1_plain", 0)
	game.finish_round()
	assert_eq(left.counter(&"pigeon_medal"), 4)


func test_golden_bugler_gives_4_4() -> void:
	Kit.put(game, p, "recruiting-sergeant", 4)
	var bugler: Unit = Kit.put(game, p, "bugler", 6, -1, -1, true)
	Kit.put(game, p, "t1_plain", 0)
	Kit.put(game, p, "t1_plain", 2)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.fight_copy(combat, 0, bugler).attack(), 8 + 4)


# --- Tier 1 -----------------------------------------------------------------------------------


func test_sentry_gives_its_slot_1_1_at_the_end_of_turn() -> void:
	var sentry: Unit = Kit.put(game, p, "sentry", 2)
	game.end_turn(0)
	assert_eq(p.view()["slots"][2]["attack"], 1)
	assert_eq(p.view()["slots"][2]["health"], 1)
	assert_eq(sentry.attack(), 2 + 1, "the unit standing there has it")


func test_golden_sentry_gives_2_2() -> void:
	var sentry: Unit = Kit.put(game, p, "sentry", 0, -1, -1, true)
	assert_eq(sentry.view()["text"], "At the end of your turn, give this slot +2/+2.")
	game.end_turn(0)
	assert_eq(p.slots[0].attack, 2)
	assert_eq(p.slots[0].health, 2)


func test_territorial_steps_in_from_reserve_where_a_friend_died() -> void:
	Kit.put(game, p, "t1_plain", 1, 1, 1)
	Kit.to_hand(game, p, "territorial")
	Kit.put(game, q, "t1_plain", 0, 10, 100)
	var combat: Combat = Kit.fight(game)
	var start: Dictionary = combat.events[0]
	assert_eq(start["reserve"][0].size(), 1, "in Reserve, off the board")
	assert_eq(start["boards"][0].size(), 1)
	var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
	assert_eq(stepped.size(), 1)
	assert_eq(stepped[0]["id"], "territorial")
	assert_eq(stepped[0]["slot"], 1, "the slot the friend died in")
	assert_eq(p.hand.size(), 1, "the hand is unchanged")


# --- Tier 2 -----------------------------------------------------------------------------------


func test_old_campaigner_earns_2_medals_when_it_survives() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	game.finish_round()
	assert_eq(campaigner.counter(&"pigeon_medal"), 2)
	assert_eq(campaigner.stats.perm_attack, 4, "each Medal is +2/+2 of its own")
	assert_eq(p.view()["board"][0]["counters"]["pigeon_medal"], 2)


func test_old_campaigner_earns_1_medal_when_it_dies() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	var rival: PlayerState = game.player(game.opponent_of(0))
	Kit.put(game, rival, "t1_plain", 0, 50, 200)
	game.finish_round()
	assert_eq(campaigner.counter(&"pigeon_medal"), 1)


func test_old_campaigner_decorated_has_stiff_upper_lip_once_a_fight() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	assert_false(campaigner.has_mechanic(&"pigeon_stiff_upper_lip"))
	Kit.medals(game, p, campaigner, 3)
	assert_true(campaigner.has_mechanic(&"pigeon_stiff_upper_lip"), "Decorated")
	Kit.put(game, q, "t1_plain", 0, 50, 500)
	var combat: Combat = Kit.fight(game)
	var mine: Array[Dictionary] = Kit.events(combat, "damage", 0)
	assert_eq(mine[0]["health"], 1, "the first lethal damage leaves it on 1")
	var saved: Array[Dictionary] = Kit.events(combat, "status", 0)
	assert_eq(saved.size(), 1)
	assert_eq(saved[0]["status"], "pigeon_stiff_upper_lip")
	assert_false(saved[0]["on"], "used up")
	assert_eq(Kit.events(combat, "death", 0).size(), 1, "the second lethal hit kills it")


func test_recruiting_sergeant_fills_the_empty_slots_in_front_at_start_of_fight() -> void:
	Kit.put(game, p, "recruiting-sergeant", 4)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	var privates: Array[Dictionary] = Kit.events(combat, "summon", 0)
	assert_eq(privates.size(), 2)
	var slots: Array[int] = []
	for event: Dictionary in privates:
		assert_eq(event["id"], "private")
		assert_eq(event["attack"], 2)
		assert_eq(event["health"], 2)
		slots.append(int(event["slot"]))
	assert_eq(slots, game.geometry.in_front_of(4), "into the slots in front of him")


func test_recruiting_sergeant_summons_only_2_a_fight() -> void:
	Kit.put(game, p, "recruiting-sergeant", 4, 0, 100000)
	Kit.put(game, q, "t1_plain", 0, 50, 500)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "summon", 0).size(), 2)
	assert_eq(Kit.events(combat, "death", 0).size(), 2, "both Privates fell; no third came")


func test_recruiting_sergeant_refills_a_slot_after_a_death() -> void:
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.put(game, p, "t1_plain", 1, 1, 1)
	Kit.put(game, p, "recruiting-sergeant", 4, 0, 500)
	Kit.put(game, q, "t1_plain", 0, 50, 500)
	var combat: Combat = Kit.fight(game)
	var privates: Array[Dictionary] = Kit.events(combat, "summon", 0)
	assert_eq(privates.size(), 2, "one into each emptied slot in front of him")


func test_golden_recruiting_sergeant_summons_4_4_privates() -> void:
	Kit.put(game, p, "recruiting-sergeant", 4, -1, -1, true)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	var private: CombatUnit = combat.unit_at(0, 0)
	assert_eq(private.def.id, &"private")
	assert_true(private.golden, "a golden Private")
	assert_eq(private.attack(), 4)
	assert_eq(private.health(), 4)
	assert_eq(Kit.events(combat, "buff", 0).size(), 0, "golden, not a 2/2 with a fight buff")
	var summons: Array[Dictionary] = Kit.events(combat, "summon", 0)
	assert_eq(summons.size(), 2, "still 2 a fight")
	assert_true(summons[0]["golden"])


func test_recruiting_sergeant_shows_privates_left() -> void:
	Kit.put(game, p, "recruiting-sergeant", 4)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	var left: Array = Kit.events(combat, "uses", 0).map(
		func(e: Dictionary) -> int: return e["left"]
	)
	assert_eq(left, [1, 0])


func test_lance_corporal_order_gives_the_slots_in_front_2_2_for_1_gold() -> void:
	var corporal: Unit = Kit.put(game, p, "lance-corporal", 5)
	p.gold = 3
	var order: Dictionary = {
		"type": "ability", "uid": corporal.uid, "mechanic": "pigeon_lance_corporal", "target": -1
	}
	assert_true(game.legal_actions(0).has(order), "the bot can take it")
	assert_eq(game.act(0, order), "")
	assert_eq(p.gold, 2)
	for slot: int in game.geometry.in_front_of(5):
		assert_eq(p.view()["slots"][slot]["attack"], 2)
		assert_eq(p.view()["slots"][slot]["health"], 2)
	assert_eq(p.slots[5].attack, 0)
	assert_eq(game.act(0, order), "already used this turn")


func test_lance_corporal_order_is_not_usable_from_the_front_row() -> void:
	var corporal: Unit = Kit.put(game, p, "lance-corporal", 0)
	p.gold = 3
	var order: Dictionary = {
		"type": "ability", "uid": corporal.uid, "mechanic": "pigeon_lance_corporal", "target": -1
	}
	assert_false(game.legal_actions(0).has(order), "not legal with no slot in front")
	assert_ne(
		game.recruit.ability_error(p, corporal, corporal.mechanics[0]), "", "shown as not usable"
	)
	assert_ne(game.act(0, order), "", "refused")
	assert_eq(p.gold, 3)
	for slot: int in game.geometry.slot_count:
		assert_eq(p.slots[slot].attack, 0)


func test_golden_lance_corporal_gives_4_4_still_for_1_gold() -> void:
	var corporal: Unit = Kit.put(game, p, "lance-corporal", 4, -1, -1, true)
	assert_eq(corporal.view()["text"], "Order (1): Give the slots in front of this +4/+4.")
	p.gold = 3
	var order: Dictionary = {
		"type": "ability", "uid": corporal.uid, "mechanic": "pigeon_lance_corporal", "target": -1
	}
	assert_eq(game.act(0, order), "")
	assert_eq(p.gold, 2)
	for slot: int in game.geometry.in_front_of(4):
		assert_eq(p.slots[slot].attack, 4)
		assert_eq(p.slots[slot].health, 4)


# --- Tier 3 -----------------------------------------------------------------------------------


func test_colour_sergeant_drills_a_row_full_of_pigeons() -> void:
	Kit.put(game, p, "colour-sergeant", 0)
	Kit.put(game, p, "territorial", 1)
	Kit.put(game, p, "padre", 2)
	Kit.put(game, p, "territorial", 3)
	game.end_turn(0)
	for slot: int in game.geometry.front:
		assert_eq(p.slots[slot].attack, 3)
		assert_eq(p.slots[slot].health, 3)
	for slot: int in game.geometry.back:
		assert_eq(p.slots[slot].attack, 0)


func test_colour_sergeant_does_nothing_unless_the_row_is_all_pigeons() -> void:
	Kit.put(game, p, "colour-sergeant", 0)
	Kit.put(game, p, "territorial", 1)
	Kit.put(game, p, "territorial", 2)
	Kit.put(game, p, "t1_plain", 3)
	game.end_turn(0)
	assert_eq(p.slots[0].attack, 0)


func test_padre_gives_a_dead_friends_slot_1_1_for_good() -> void:
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.put(game, p, "padre", 4, 0, 500)
	Kit.put(game, q, "t1_plain", 0, 50, 500)
	var combat: Combat = Kit.fight(game)
	var given: Array[Dictionary] = Kit.events(combat, "slot", 0)
	assert_gt(given.size(), 0)
	assert_eq(given[0]["slot"], 0, "the slot it died in")
	assert_true(given[0]["permanent"])
	assert_eq(p.slots[0].attack, 1, "the real slot too")
	assert_eq(p.slots[0].health, 1)


func test_padre_stops_after_8_a_fight() -> void:
	Kit.put(game, p, "padre", 4, 0, 100000)
	Kit.put(game, p, "the-colonel", 5, 0, 100000)
	for slot: int in game.geometry.front:
		Kit.put(game, p, "t1_plain", slot, 1, 1)
	for _i: int in 6:
		Kit.to_hand(game, p, "t1_plain")
	Kit.put(game, q, "t1_plain", 0, 50, 100000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "death", 0).size(), 10, "ten friends died")
	assert_eq(Kit.triggers(combat, "pigeon_padre").size(), 8)


func test_flying_ace_has_no_sortie_and_earns_a_medal_for_the_kill() -> void:
	var ace: Unit = Kit.put(game, p, "flying-ace", 0)
	assert_false(ace.has_mechanic(&"pigeon_sortie"), "no Sortie of its own since 19 Nov")
	Kit.put(game, q, "t1_guard", 0, 0, 3)
	Kit.put(game, q, "t1_plain", 4, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var swing: Dictionary = Kit.events(combat, "attack", 0)[0]
	assert_eq(swing["target_slot"], 0, "the front-row Guard, like any unit")
	assert_eq(ace.counter(&"pigeon_medal"), 1, "a Medal on the real unit")
	assert_eq(ace.stats.perm_attack, 2)


func test_a_squadron_leader_behind_the_flying_ace_gives_it_sortie() -> void:
	Kit.put(game, p, "flying-ace", 1)
	Kit.put(game, p, "squadron-leader", 5)
	Kit.put(game, q, "t1_guard", 0, 0, 100000)
	Kit.put(game, q, "t1_plain", 4, 0, 3)
	var combat: Combat = Kit.fight(game)
	var swing: Dictionary = Kit.events(combat, "attack", 0)[0]
	assert_eq(swing["slot"], 1)
	assert_eq(swing["target_slot"], 4, "the back row, past a front-row Guard")


func test_flying_ace_keeps_the_medal_when_it_dies_in_the_same_exchange() -> void:
	var ace: Unit = Kit.put(game, p, "flying-ace", 0)
	Kit.put(game, q, "t1_plain", 0, 20, 3)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "death", 0).size(), 1, "the Ace died")
	assert_eq(ace.counter(&"pigeon_medal"), 1)
	assert_eq(ace.stats.perm_health, 2)


func test_cleave_hits_only_one_of_the_two_units_beside_the_target() -> void:
	var ace: Unit = Kit.put(game, p, "flying-ace", 0, -1, 500)
	Kit.medals(game, p, ace, 3)
	Kit.put(game, q, "t1_plain", 0, 0, 1)
	Kit.put(game, q, "t1_guard", 1, 0, 1)
	Kit.put(game, q, "t1_plain", 2, 0, 1)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "attack", 0)[0]["target_slot"], 1, "the Guard in the middle")
	assert_eq(Kit.events(combat, "death", 1).size(), 2, "the target and one unit beside it")


func test_decorated_flying_ace_cleaves() -> void:
	var ace: Unit = Kit.put(game, p, "flying-ace", 0, -1, 500)
	Kit.medals(game, p, ace, 3)
	assert_true(ace.has_mechanic(&"cleave"))
	Kit.put(game, q, "t1_plain", 4, 0, 1)
	Kit.put(game, q, "t1_plain", 5, 0, 1)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "attack", 0).size(), 1, "one attack")
	assert_eq(Kit.events(combat, "death", 1).size(), 2, "it also hit the unit next to it")
	assert_eq(ace.counter(&"pigeon_medal"), 3 + 2, "a Medal for each kill")


func test_grenadier_guard_order_makes_a_slot_the_guard_post_and_drills_it() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 0)
	p.gold = 3
	var order: Dictionary = {
		"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 1
	}
	assert_true(game.legal_actions(0).has(order))
	assert_eq(game.act(0, order), "")
	assert_eq(p.gold, 2)
	var keywords: Array = p.view()["slots"][1]["keywords"]
	assert_true(keywords.has("pigeon_guard_post"))
	assert_true(keywords.has("taunt"))
	game.end_turn(0)
	assert_eq(p.slots[1].attack, 2)
	assert_eq(p.slots[1].health, 4)


func test_grenadier_guard_moving_the_post_clears_the_old_one_and_the_stats_stay() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 0)
	p.gold = 3
	var first: Dictionary = {
		"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 1
	}
	assert_eq(game.act(0, first), "")
	game.end_turn(0)
	game.finish_round()
	game.start_round()
	p.gold = 3
	var order: Dictionary = {
		"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 3
	}
	assert_eq(game.act(0, order), "")
	assert_false(p.slots[1].keywords.has(&"pigeon_guard_post"))
	assert_false(p.slots[1].keywords.has(&"taunt"))
	assert_true(p.slots[3].keywords.has(&"pigeon_guard_post"))
	assert_eq(p.slots[1].health, 4, "stats given to the old post stay there")


func test_the_unit_on_the_guard_post_has_guard_in_a_fight() -> void:
	var grenadier: Unit = Kit.put(game, p, "grenadier-guard", 0)
	Kit.put(game, p, "t1_plain", 2, 0, 500)
	p.gold = 3
	game.act(
		0, {"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 2}
	)
	grenadier.stats.set_attack = 0
	Kit.put(game, q, "t1_plain", 0, 1, 500)
	var combat: Combat = Kit.fight(game)
	var swings: Array[Dictionary] = Kit.events(combat, "attack", 1)
	assert_gt(swings.size(), 0)
	for swing: Dictionary in swings:
		assert_eq(swing["target_slot"], 2, "enemies must attack the post")


# --- Tier 4 -----------------------------------------------------------------------------------


func test_lieutenant_full_row_deals_each_slots_attack_buff_across() -> void:
	var ctx: RecruitContext = Kit.ctx(game, p)
	ctx.slot_buff(1, 5, 0, null)
	ctx.slot_buff(3, 7, 0, null)
	Kit.put(game, p, "lieutenant", 0)
	Kit.put(game, p, "t1_plain", 1)
	Kit.put(game, p, "t1_plain", 2)
	Kit.put(game, p, "t1_plain", 3)
	Kit.put(game, q, "t1_plain", 1, 0, 100)
	Kit.put(game, q, "t1_plain", 2, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	var hurt: Array[Dictionary] = Kit.events(combat, "damage", 1)
	assert_eq(hurt.size(), 2)
	assert_eq(hurt[0]["slot"], 1, "across from F2")
	assert_eq(hurt[0]["amount"], 5)
	assert_eq(hurt[1]["slot"], 2, "F4's across is empty: the nearest enemy in that row")
	assert_eq(hurt[1]["amount"], 7)
	assert_eq(Kit.events(combat, "attack").size(), 0, "damage, not an attack")


func test_lieutenant_does_nothing_unless_its_row_is_full() -> void:
	Kit.ctx(game, p).slot_buff(1, 5, 0, null)
	Kit.put(game, p, "lieutenant", 0)
	Kit.put(game, p, "t1_plain", 1)
	Kit.put(game, q, "t1_plain", 1, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "damage", 1).size(), 0)


func test_squadron_leader_gives_the_units_in_front_sortie_and_3_attack() -> void:
	Kit.put(game, p, "squadron-leader", 5)
	var plain: Unit = Kit.put(game, p, "t1_plain", 1)
	var aside: Unit = Kit.put(game, p, "t1_plain", 3)
	assert_eq(plain.attack(), 2 + 3)
	assert_true(plain.has_mechanic(&"pigeon_sortie"))
	assert_eq(aside.attack(), 2, "not in front of it")
	assert_eq(plain.stats.own_attack(), 2, "borrowed")
	aside.stats.set_attack = 0
	Kit.put(game, q, "t1_guard", 0, 0, 500)
	Kit.put(game, q, "t1_plain", 4, 0, 500)
	var combat: Combat = Kit.fight(game)
	var swing: Dictionary = Kit.events(combat, "attack", 0)[0]
	assert_eq(swing["slot"], 1)
	assert_eq(swing["target_slot"], 4)


func test_adjutant_gives_the_units_in_front_2_medals_after_each_fight() -> void:
	Kit.put(game, p, "adjutant", 4)
	var left: Unit = Kit.put(game, p, "t1_plain", 0)
	var right: Unit = Kit.put(game, p, "t1_guard", 1)
	var aside: Unit = Kit.put(game, p, "t1_herald", 2)
	game.finish_round()
	assert_eq(left.counter(&"pigeon_medal"), 2)
	assert_eq(right.counter(&"pigeon_medal"), 2)
	assert_eq(left.stats.perm_attack, 4)
	assert_eq(aside.counter(&"pigeon_medal"), 0)


func test_bugler_gives_every_pigeon_2_2_when_a_pigeon_joins_the_fight() -> void:
	var sergeant: Unit = Kit.put(game, p, "recruiting-sergeant", 4)
	var bugler: Unit = Kit.put(game, p, "bugler", 6)
	Kit.put(game, p, "t1_plain", 0)
	Kit.put(game, p, "t1_plain", 2)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "pigeon_bugler").size(), 1, "one Private joined")
	var private: CombatUnit = combat.unit_at(0, 1)
	assert_eq(private.def.id, &"private")
	assert_eq(private.attack(), 4)
	var bugler_copy: CombatUnit = Kit.fight_copy(combat, 0, bugler)
	assert_eq(bugler_copy.attack(), 4 + 2)
	assert_eq(Kit.fight_copy(combat, 0, sergeant).attack(), 3 + 2)
	assert_eq(combat.unit_at(0, 0).attack(), 2, "not a Pigeon")


func test_bugler_hears_a_reserve_unit_step_in() -> void:
	Kit.put(game, p, "bugler", 4, 0, 500)
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.to_hand(game, p, "territorial")
	Kit.put(game, q, "t1_plain", 0, 50, 500)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "pigeon_bugler").size(), 1)


# --- Tier 5 -----------------------------------------------------------------------------------


func test_colour_ensign_copies_the_strongest_slot_for_the_fight() -> void:
	Kit.ctx(game, p).slot_buff(0, 5, 6, null)
	var ensign: Unit = Kit.put(game, p, "colour-ensign", 2)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	var copy: CombatUnit = Kit.fight_copy(combat, 0, ensign)
	assert_eq(copy.attack(), 6 + 5)
	assert_eq(copy.health(), 14 + 6)
	assert_false(Kit.events(combat, "slot", 0)[0]["permanent"])
	assert_eq(p.slots[2].attack, 0, "for this fight only")


func test_colour_ensign_copy_is_not_doubled_by_the_sergeant_major() -> void:
	Kit.put(game, p, "regimental-sergeant-major", 6)
	Kit.ctx(game, p).slot_buff(0, 5, 5, null)
	assert_eq(p.slots[0].attack, 10, "a buff given is doubled")
	var ensign: Unit = Kit.put(game, p, "colour-ensign", 2)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.fight_copy(combat, 0, ensign).attack(), 6 + 10, "the copy is not")


func test_golden_colour_ensign_gives_the_slots_next_to_it_the_copy_too() -> void:
	Kit.ctx(game, p).slot_buff(0, 5, 5, null)
	Kit.put(game, p, "colour-ensign", 2, -1, -1, true)
	Kit.put(game, q, "t1_plain", 0, 0, 100)
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game)
	for slot: int in [1, 2, 3]:
		assert_eq(combat.bridge(0).slot(slot).attack, 5)


func test_brigadier_makes_decorated_pigeons_attack_twice() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	var brigadier: Unit = Kit.put(game, p, "brigadier", 1)
	Kit.medals(game, p, campaigner, 3)
	assert_true(campaigner.has_mechanic(&"windfury"))
	assert_false(brigadier.has_mechanic(&"windfury"), "not Decorated itself")
	Kit.put(game, q, "t1_plain", 0, 0, 500)
	var combat: Combat = Kit.fight(game)
	var swings: Array[int] = Kit.CoreKit.attack_slots(combat, 0)
	assert_eq(swings.slice(0, 3), [0, 0, 1], "back to back, then the Brigadier once")


func test_brigadier_does_not_double_a_decorated_non_pigeon() -> void:
	Kit.put(game, p, "brigadier", 1)
	var plain: Unit = Kit.put(game, p, "t1_plain", 0)
	Kit.medals(game, p, plain, 3)
	assert_false(plain.has_mechanic(&"windfury"))


func test_wing_commander_sends_every_sortie_pigeon_at_the_back_row_at_start_of_fight() -> void:
	Kit.put(game, p, "wing-commander", 0)
	var flier: Unit = Kit.put(game, p, "sentry", 1)
	flier.grant(game.registry, &"pigeon_sortie")
	Kit.put(game, p, "t1_plain", 2)
	Kit.put(game, q, "t1_guard", 0, 0, 500)
	Kit.put(game, q, "t1_plain", 4, 0, 500)
	game.config.attack_limit = 2
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "pigeon_wing_commander").size(), 1)
	var swings: Array[Dictionary] = Kit.events(combat, "attack", 0)
	assert_eq(swings.size(), 2)
	assert_eq(swings[0]["slot"], 0)
	assert_eq(swings[1]["slot"], 1)
	for swing: Dictionary in swings:
		assert_eq(swing["target_slot"], 4)


func test_golden_wing_commander_makes_them_attack_twice() -> void:
	Kit.put(game, p, "wing-commander", 0, -1, -1, true)
	Kit.put(game, q, "t1_plain", 4, 0, 500)
	game.config.attack_limit = 2
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.CoreKit.attack_slots(combat, 0), [0, 0])


# --- Tier 6 -----------------------------------------------------------------------------------


func test_regimental_sergeant_major_gives_every_slot_4_4_and_doubles_slot_buffs() -> void:
	Kit.put(game, p, "regimental-sergeant-major", 0)
	Kit.put(game, p, "sentry", 1)
	game.end_turn(0)
	assert_eq(p.slots[0].attack, 4, "+2/+2, doubled")
	assert_eq(p.slots[1].attack, 4 + 2, "the Sentry's +1/+1 doubled too")
	assert_eq(p.slots[6].health, 4)


func test_two_sergeant_majors_do_not_stack_and_golden_triples() -> void:
	Kit.put(game, p, "regimental-sergeant-major", 0)
	Kit.put(game, p, "regimental-sergeant-major", 1, -1, -1, true)
	Kit.ctx(game, p).slot_buff(4, 1, 1, null)
	assert_eq(p.slots[4].attack, 3, "the bigger applies: tripled")


func test_sergeant_major_doubles_a_slot_buff_given_in_a_fight() -> void:
	Kit.put(game, p, "regimental-sergeant-major", 4, 0, 500)
	Kit.put(game, p, "padre", 5, 0, 500)
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.put(game, q, "t1_plain", 0, 50, 5000)
	Kit.fight(game)
	assert_eq(p.slots[0].attack, 2, "the Padre's +1/+1, doubled")


func test_the_colonel_puts_every_hand_unit_in_reserve() -> void:
	Kit.put(game, p, "the-colonel", 4, 0, 500)
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.to_hand(game, p, "t1_plain")
	Kit.to_hand(game, p, "t1_herald")
	Kit.put(game, q, "t1_plain", 0, 50, 5000)
	var combat: Combat = Kit.fight(game)
	assert_eq(combat.events[0]["reserve"][0].size(), 2)
	var stepped: Array[Dictionary] = Kit.events(combat, "reserve", 0)
	assert_eq(stepped.size(), 2, "each steps in once, after each death")
	assert_eq(stepped[0]["id"], "t1_plain")
	assert_eq(stepped[1]["id"], "t1_herald")


func test_without_the_colonel_a_plain_hand_unit_stays_out() -> void:
	Kit.put(game, p, "t1_plain", 0, 1, 1)
	Kit.to_hand(game, p, "t1_plain")
	Kit.put(game, q, "t1_plain", 0, 50, 5000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "reserve", 0).size(), 0)


func test_field_marshal_makes_medals_worth_4_4_on_pigeons() -> void:
	Kit.put(game, p, "field-marshal", 4)
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	var plain: Unit = Kit.put(game, p, "t1_plain", 1)
	Kit.medals(game, p, campaigner, 2)
	Kit.medals(game, p, plain, 2)
	assert_eq(campaigner.attack(), 4 + 2 * 4)
	assert_eq(campaigner.stats.own_attack(), 4 + 2 * 2, "the extra is borrowed")
	assert_eq(plain.attack(), 2 + 2 * 2, "not a Pigeon")
	assert_false(campaigner.has_mechanic(&"pigeon_stiff_upper_lip"))


func test_field_marshal_gives_decorated_pigeons_stiff_upper_lip() -> void:
	Kit.put(game, p, "field-marshal", 4, 0, 500)
	var ace: Unit = Kit.put(game, p, "flying-ace", 0, 0, 1)
	Kit.medals(game, p, ace, 3)
	assert_true(ace.has_mechanic(&"pigeon_stiff_upper_lip"))
	Kit.put(game, q, "t1_plain", 0, 1000, 5000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.events(combat, "status", 0).size(), 1, "saved once")


func _lip_saves(combat: Combat) -> Array[Dictionary]:
	return Kit.events(combat, "status", 0).filter(
		func(e: Dictionary) -> bool: return e["status"] == "pigeon_stiff_upper_lip"
	)


## A plain-copy return (Reborn, Molt) has no Medals (SHARED-RULES "Plain copy"), so a Decorated
## Pigeon comes back undecorated, without Stiff Upper Lip; the recruit unit keeps its Medals.
func test_a_plain_copy_return_loses_the_medals_and_stiff_upper_lip() -> void:
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	Kit.medals(game, p, campaigner, 3)
	assert_true(campaigner.grant(game.registry, &"reborn"))
	Kit.put(game, q, "t1_plain", 0, 1000, 100000)
	var combat: Combat = Kit.fight(game)
	var back: Array[Dictionary] = Kit.events(combat, "return", 0)
	assert_eq(back.size(), 1, "it came back")
	assert_false(back[0]["counters"].has("pigeon_medal"), "no Medals on the copy")
	assert_false(back[0]["keywords"].has("pigeon_stiff_upper_lip"), "not Decorated")
	assert_eq(_lip_saves(combat).size(), 1, "saved once, before it died")
	assert_eq(campaigner.counter(&"pigeon_medal"), 3, "the recruit unit keeps them")


## A return as it stands (Root) keeps the Medals; its Stiff Upper Lip stays used (SHARED-RULES
## 21: a fight count carries across the return).
func test_stiff_upper_lip_stays_used_on_a_unit_returned_as_it_stands() -> void:
	game = Kit.CoreKit.content(["pigeon"], true).session(1)
	game.start_round()
	p = game.player(0)
	q = game.player(1)
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	Kit.medals(game, p, campaigner, 3)
	assert_true(campaigner.grant(game.registry, &"test_root_full"))
	Kit.put(game, q, "t1_plain", 0, 1000, 100000)
	var combat: Combat = Kit.fight(game)
	var back: Array[Dictionary] = Kit.events(combat, "return", 0)
	assert_eq(back.size(), 1, "it came back as it stands")
	assert_eq(back[0]["counters"].get("pigeon_medal", 0), 3, "with its Medals")
	assert_eq(_lip_saves(combat).size(), 1, "once a fight, returns included")


func test_golden_field_marshal_makes_medals_worth_6_6() -> void:
	Kit.put(game, p, "field-marshal", 4, -1, -1, true)
	var campaigner: Unit = Kit.put(game, p, "old-campaigner", 0)
	Kit.medals(game, p, campaigner, 1)
	assert_eq(campaigner.attack(), 4 + 6)
