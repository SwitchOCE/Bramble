extends GutTest
## One test (or more) for each Locust unit and the Hopper token, each proving its card text in a
## real fight or recruit turn through the core, on the event log or the views.
## Design: docs/ideation-track-2/tribes/locust/units.json.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/locust/locust_kit.gd")
const DESIGN: String = "res://docs/ideation-track-2/tribes/locust/units.json"
## Every unit's golden copy reads as the design's `golden` line says (doubled numbers, or the
## card's golden_text where golden is not a plain doubling). The behaviour of each golden that is
## not a plain doubling has its own test below ("golden").
const GOLDEN_TEXT: Dictionary = {
	"hopper": "",
	"green-recruit": "When this dies, summon 4 Hoppers.",
	"husk-sentry": "Guard. Molt.",
	"prophet-of-the-dust": "At the end of your turn, Tide +2.",
	"horde-runner": "At the start of your turn, get 2 Hoppers.",
	"wheat-raider": "Molt. When this dies, deal 8 damage to a random enemy.",
	"brood-mother":
	"When this dies, summon 2 Hoppers and give your Hoppers +2/+2 for the rest of the game.",
	"skin-shedder": "Start of fight: Give Molt twice to the units next to this.",
	"gleaner": "After a friendly unit dies, deal 10 damage to the highest-Health enemy.",
	"gorger": "The first time you sell a unit each turn, this eats it and gains double its stats.",
	"famine-caller": "When this dies, Tide +4.",
	"sky-darkener": "Start of fight: Summon 6 Hoppers.",
	"orchard-stripper": "Molt. When this dies, deal 10 damage to all enemies.",
	"granary-glutton": "Whenever you sell a Locust, this eats it and gains double its stats.",
	"war-drummer": "Whenever this attacks, trigger the death effect of a unit behind it twice.",
	"twice-shed-veteran":
	"After another friendly unit returns, it and this gain +12/+12 this fight.",
	"the-eighth-plague":
	(
		"After a friendly unit dies, deal damage to a random enemy equal to twice the number of "
		+ "friendly units that died this fight."
	),
	"dirge-singer": "Your death effects trigger three times.",
	"swarm-lord": "After 2 friendly Locusts die, Tide +2.",
	"mother-of-thousands": "Whenever you summon Hoppers, summon three times as many.",
}

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = game.player(1)


func _put(card_id: String, slot: int, golden: bool = false) -> Unit:
	return Kit.put(game, p, card_id, slot, golden)


## An enemy that kills anything in one blow and takes a long time to die.
func _killer(slot: int = 0, attack: int = 50, health: int = 400) -> Unit:
	return Kit.wall(game, q, slot, attack, health)


# --- The content as designed --------------------------------------------------------------------


func test_the_locust_folder_loads_clean_with_every_designed_unit() -> void:
	var content: ContentSet = Kit.CoreKit.content(["locust"], false, true)
	assert_eq(content.errors, PackedStringArray())
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var cards: Array = design["units"] + design["tokens"]
	assert_eq(cards.size(), 20, "19 units and the Hopper")
	for raw: Variant in cards:
		var card: Dictionary = raw
		var id := StringName(card["id"])
		assert_true(content.library.has(id), "%s is a card" % id)
		if not content.library.has(id):
			continue
		var def: UnitDef = content.library.get_card(id)
		assert_eq(def.name, card["name"], "%s name" % id)
		assert_eq(def.tier, int(card["tier"]), "%s tier" % id)
		assert_eq(
			[def.attack, def.health], [int(card["attack"]), int(card["health"])], "%s stats" % id
		)
		assert_true(def.has_tribe("Locust"), "%s is a Locust" % id)
		var made: Unit = game.new_unit(def, false)
		assert_eq(made.view()["text"], card["text"], "%s text, numbers filled" % id)


func test_every_locust_mechanic_has_a_display_entry_with_the_glossary_name() -> void:
	var display: Dictionary = game.display
	assert_eq(display["locust_molt"]["name"], "Molt")
	assert_eq(
		display["locust_molt"]["reminder"],
		(
			"The first time this dies each fight, it returns as a plain copy with 1 Health, "
			+ "then gains +2/+2 permanently."
		)
	)
	assert_eq(display["locust_gorge"]["name"], "Eat")
	assert_eq(
		display["locust_glut"]["reminder"],
		"This gains the sold unit's stats. The sold unit's death effect triggers."
	)
	assert_eq(display["locust_tide_end_turn"]["name"], "Tide +N")
	assert_eq(
		display["locust_tide_on_death"]["reminder"],
		"Your Locusts have +N Attack for the rest of the game."
	)
	assert_eq(
		display["locust_hoppers_on_death"]["reminder"],
		"A 2/2 Locust. In a fight, a Hopper with no room waits for a slot."
	)
	assert_eq(display["taunt"]["name"], "Guard", "Husk Sentry's Guard is the shared keyword")
	assert_false(display["locust_tide"]["hidden"], "the Tide is shown beside the board")


func test_golden_text_reads_as_the_design_golden_line() -> void:
	assert_eq(GOLDEN_TEXT.size(), 20)
	for card_id: String in GOLDEN_TEXT:
		var golden: Unit = game.new_unit(game.library.get_card(StringName(card_id)), true)
		assert_eq(golden.view()["text"], GOLDEN_TEXT[card_id], "%s golden text" % card_id)


## Reminders: a term a card's text uses is explained by a shown display entry the card reaches
## (a keyword it prints, one of its own mechanics, or a shown entry its text names), so no card
## repeats a glossary line in `reminders`; helper mechanics are hidden.
## Goldens that are plain doublings behave doubled (a sample across hooks: end of turn, death
## damage, start of fight, return).
func test_plain_doubling_goldens_act_doubled() -> void:
	_put("prophet-of-the-dust", 0, true)
	game.end_turn(0)
	assert_eq(p.counter(Kit.TIDE), 2, "Prophet: Tide +2")
	game = Kit.session()
	p = game.player(0)
	q = game.player(1)
	_put("wheat-raider", 0, true)
	_put("sky-darkener", 1, true)
	_put("twice-shed-veteran", 4, true)
	_killer()
	var combat: Combat = Kit.fight(game)
	var shots: Array[Dictionary] = Kit.effect_damage(combat, "locust_death_damage_random")
	assert_true(
		shots.size() > 0 and shots.all(func(e: Dictionary) -> bool: return e["amount"] == 8)
	)
	var made: int = (
		Kit.hopper_summons(combat, 0).size() + Kit.where(combat, "summon_waiting", "side", 0).size()
	)
	assert_gte(made, 6, "Sky-darkener: 6 Hoppers summoned or waiting")
	var vet: int = Kit.uid_of(combat, p.board[4])
	var grown: Array[Dictionary] = Kit.where(combat, "buff", "uid", vet)
	assert_eq([grown[0]["attack"], grown[0]["health"]], [24, 28], "Veteran: 12/16 + 12/12")


func test_terms_reach_their_display_entries_and_helpers_are_hidden() -> void:
	var display: Dictionary = game.display
	var hidden: Array[String] = [
		"locust_swarm",
		"locust_shed",
		"locust_death_damage_random",
		"locust_death_damage_all",
		"locust_glean",
		"locust_drum",
		"locust_veteran",
		"locust_plague",
		"locust_dirge"
	]
	for id: String in hidden:
		assert_true(display[id]["hidden"], "%s is a helper, hidden" % id)
	for id: String in ["locust_molt", "locust_tide", "locust_hopper_bonus"]:
		assert_false(display[id]["hidden"], "%s is shown" % id)
	var hoppers: Array[String] = [
		"locust_hoppers_on_death",
		"locust_brood",
		"locust_sky_darken",
		"locust_hopper_to_hand",
		"locust_mother"
	]
	for id: String in hoppers:
		assert_eq(display[id]["name"], "Hopper", "%s explains the Hopper its text names" % id)
	for id: String in ["locust_tide_end_turn", "locust_tide_on_death", "locust_swarm_lord"]:
		assert_eq(display[id]["name"], "Tide +N", "%s explains Tide +N, N from the text" % id)
	for id: String in ["locust_gorge", "locust_glut"]:
		assert_eq(display[id]["name"], "Eat")
	var shedder: UnitDef = game.library.get_card(&"skin-shedder")
	assert_eq(shedder.reminders.size(), 1, "only the line no display entry gives")
	for card_id: StringName in game.library.ids():
		var def: UnitDef = game.library.get_card(card_id)
		if def.has_tribe("Locust") and def.id != &"skin-shedder":
			assert_eq(def.reminders.size(), 0, "%s: its terms come from display entries" % def.id)


# --- Tokens and player numbers ------------------------------------------------------------------


func test_hopper_is_a_created_token_that_carries_the_tide_and_the_hopper_bonus() -> void:
	var def: UnitDef = game.library.get_card(&"hopper")
	assert_true(def.token, "never in the pool")
	assert_false(def.combines, "never combines into a golden")
	var ctx: RecruitContext = Kit.ctx(game, p)
	ctx.add_counter(Kit.TIDE, 3, null)
	ctx.add_counter(Kit.HOPPER_BONUS, 2, null)
	var hopper: Unit = _put("hopper", 0)
	var plain: Unit = _put("t1_plain", 1)
	assert_eq([hopper.attack(), hopper.health()], [7, 4], "2/2 + Tide 3 + Hopper bonus 2")
	assert_eq([hopper.stats.own_attack(), hopper.stats.own_health()], [2, 2], "both are borrowed")
	assert_eq(plain.attack(), 2, "the Tide is for Locusts only")


func test_three_hoppers_never_triple() -> void:
	for slot: int in 3:
		_put("hopper", slot)
	var ctx: RecruitContext = Kit.ctx(game, p)
	ctx.give_card(&"hopper", null)
	assert_eq(Kit.count_on_board(p, "hopper"), 3)
	assert_false(p.all_cards().any(func(u: Unit) -> bool: return u.golden))


# --- Tier 1 ---------------------------------------------------------------------------------------


func test_green_recruit_dies_into_two_hoppers_the_first_in_its_slot() -> void:
	_put("green-recruit", 0)
	_killer()
	var combat: Combat = Kit.fight(game)
	var hoppers: Array[Dictionary] = Kit.hopper_summons(combat, 0)
	assert_eq(hoppers.size(), 2)
	assert_eq(hoppers[0]["slot"], 0, "8.4.1 the first takes the dead unit's slot")
	assert_false(hoppers[0]["bought"], "Created")


func test_golden_green_recruit_summons_four() -> void:
	_put("green-recruit", 0, true)
	_killer()
	assert_eq(Kit.hopper_summons(Kit.fight(game), 0).size(), 4)


func test_husk_sentry_has_guard_and_molts_once_bigger_for_good() -> void:
	var sentry: Unit = _put("husk-sentry", 0)
	_put("t1_plain", 1)
	Kit.wall(game, q, 0, 3, 400)
	var combat: Combat = Kit.fight(game)
	var theirs: Array[Dictionary] = Kit.where(combat, "attack", "side", 1)
	var first: Dictionary = theirs[0]
	assert_eq(first["target_slot"], 0, "Guard: the enemy attacks the Sentry first")
	var returns: Array[Dictionary] = Kit.where(combat, "return", "id", "husk-sentry")
	assert_eq(returns.size(), 1, "printed Molt is once a fight")
	assert_eq([returns[0]["attack"], returns[0]["health"]], [5, 3], "a plain copy, 1 Health, +2/+2")
	assert_true(returns[0]["keywords"].has("taunt"), "the copy still has Guard")
	assert_eq(
		[sentry.stats.perm_attack, sentry.stats.perm_health], [2, 2], "on the recruit unit too"
	)
	var spent: Array[Dictionary] = Kit.where(combat, "status", "status", "locust_molt")
	assert_eq(spent.size(), 1, "the Molt pill drops once the charge is used")
	assert_eq(returns[0]["mechanic"], "locust_molt", "the return protocol's Molt")
	var uses: Array[Dictionary] = Kit.where(combat, "uses", "key", "locust_molt")
	assert_eq(uses.size(), 1)
	assert_eq([uses[0]["uid"], uses[0]["left"]], [returns[0]["uid"], 0], "no Molt left this fight")


# --- Tier 2 ---------------------------------------------------------------------------------------


func test_prophet_of_the_dust_raises_the_tide_at_the_end_of_the_turn() -> void:
	_put("prophet-of-the-dust", 0)
	var recruit: Unit = _put("green-recruit", 1)
	game.end_turn(0)
	assert_eq(p.counter(Kit.TIDE), 1)
	assert_eq(recruit.attack(), 3, "every Locust has +1 Attack")
	assert_eq(p.view()["counters"]["locust_tide"], 1, "the screen shows the Tide")


func test_horde_runner_gets_a_hopper_at_the_start_of_the_turn() -> void:
	_put("horde-runner", 0)
	p.hand.clear()
	game.recruit.start_turn(p)
	assert_eq(p.hand.size(), 1)
	assert_eq(p.hand[0].def.id, &"hopper")
	assert_false(p.hand[0].is_bought(), "Created: sells for 0")
	p.board[0] = null
	_put("horde-runner", 0, true)
	p.hand.clear()
	game.recruit.start_turn(p)
	assert_eq(p.hand.size(), 2, "golden: gives 2")


func test_wheat_raider_deals_4_each_time_it_dies_and_molts() -> void:
	var raider: Unit = _put("wheat-raider", 0)
	_killer()
	var combat: Combat = Kit.fight(game)
	var uids: Array[int] = Kit.lineage(combat, Kit.uid_of(combat, raider))
	assert_eq(uids.size(), 2, "it returned once")
	var shots: Array[Dictionary] = Kit.effect_damage(combat, "locust_death_damage_random", uids)
	shots = shots.filter(func(e: Dictionary) -> bool: return e["amount"] == 4 and e["side"] == 1)
	assert_eq(Kit.triggers(combat, "locust_death_damage_random").size(), 2, "it died twice")
	assert_eq(shots.size(), 2, "4 damage each death")
	assert_eq(raider.stats.perm_attack, 2)


# --- Tier 3 ---------------------------------------------------------------------------------------


func test_brood_mother_summons_a_hopper_and_raises_the_hopper_bonus_for_good() -> void:
	_put("brood-mother", 0)
	_killer()
	var combat: Combat = Kit.fight(game)
	var hoppers: Array[Dictionary] = Kit.hopper_summons(combat, 0)
	assert_eq(hoppers.size(), 1)
	var shown: Array[Dictionary] = Kit.where(combat, "stats", "uid", hoppers[0]["uid"])
	assert_gt(shown.size(), 0, "the bonus reaches the Hopper at once")
	assert_eq([shown[-1]["attack"], shown[-1]["health"]], [3, 3])
	assert_eq(p.counter(Kit.HOPPER_BONUS), 1, "kept after the fight")
	var later: Unit = _put("hopper", 3)
	assert_eq([later.attack(), later.health()], [3, 3], "and every later Hopper has it")


func test_golden_brood_mother_summons_two_and_gives_plus_two() -> void:
	_put("brood-mother", 0, true)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.hopper_summons(combat, 0).size(), 2)
	assert_eq(p.counter(Kit.HOPPER_BONUS), 2)


func test_skin_shedder_gives_molt_next_to_it_and_a_second_molt_to_a_unit_that_has_it() -> void:
	var sentry: Unit = _put("husk-sentry", 0)
	_put("skin-shedder", 1)
	var plain: Unit = _put("t1_plain", 2)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "return", "id", "husk-sentry").size(), 2, "Molt twice this fight")
	assert_eq(Kit.where(combat, "return", "id", "t1_plain").size(), 1, "given Molt: once")
	assert_eq(Kit.where(combat, "return", "id", "skin-shedder").size(), 0, "not itself")
	assert_eq(sentry.stats.perm_attack, 4, "+2/+2 for each return, on the recruit unit")
	assert_eq(plain.stats.perm_health, 2, "any tribe's unit keeps its +2/+2")
	assert_false(plain.has_mechanic(&"locust_molt"), "the given Molt was for this fight only")
	var sentry_uid: int = Kit.uid_of(combat, sentry)
	var shown: Array[Dictionary] = Kit.where(combat, "uses", "uid", sentry_uid)
	assert_eq(shown[0]["left"], 2, "the screen sees two Molts on the Sentry at the start")


func test_golden_skin_shedder_gives_two_more_molts() -> void:
	var sentry: Unit = _put("husk-sentry", 0)
	_put("skin-shedder", 1, true)
	var plain: Unit = _put("t1_plain", 2)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "return", "id", "husk-sentry").size(), 3, "1 + 2 this fight")
	assert_eq(Kit.where(combat, "return", "id", "t1_plain").size(), 2, "given Molt twice")
	assert_eq([sentry.stats.perm_attack, plain.stats.perm_attack], [6, 4])
	var copies: Array[Dictionary] = Kit.where(combat, "return", "id", "t1_plain")
	assert_true(
		copies[0]["keywords"].has("locust_molt"), "a plain copy with a charge left keeps it"
	)


## Ruling 17 through the return protocol: Root (RETURN_FIRST) before Molt when the heap can pay,
## decided by priority, not hook order. The bridge's Root test card (test_root, cost 2) stands in
## for the briars' Root here; the next test uses the real briar unit.
func test_molt_given_by_a_skin_shedder_yields_to_root_when_the_heap_can_pay() -> void:
	game = Kit.CoreKit.content(["locust"], true, true).session(1)
	game.start_round()
	p = game.player(0)
	q = game.player(1)
	var rooter: Unit = Kit.put(game, p, "b3_rooter", 0)
	Kit.put(game, p, "skin-shedder", 1)
	Kit.wall(game, q, 0, 50, 400)
	p.heap(&"test_heap").add(&"t1_plain", 1)
	p.heap(&"test_heap").add(&"t1_plain", 1)
	var combat: Combat = Kit.fight(game)
	var back: Array = Kit.where(combat, "return", "id", "b3_rooter").map(
		func(e: Dictionary) -> String: return e["mechanic"]
	)
	assert_eq(back, ["test_root", "locust_molt"], "Root first, then the given Molt")
	assert_eq(p.heap(&"test_heap").size(), 0, "Root paid")
	assert_eq(rooter.stats.perm_attack, 2, "Molt paid only for its own return")


func test_molt_comes_first_when_the_heap_cannot_pay_for_root() -> void:
	game = Kit.CoreKit.content(["locust"], true, true).session(1)
	game.start_round()
	p = game.player(0)
	q = game.player(1)
	Kit.put(game, p, "b3_rooter", 0)
	Kit.put(game, p, "skin-shedder", 1)
	Kit.wall(game, q, 0, 50, 400)
	var combat: Combat = Kit.fight(game)
	var back: Array = Kit.where(combat, "return", "id", "b3_rooter").map(
		func(e: Dictionary) -> String: return e["mechanic"]
	)
	assert_eq(back, ["locust_molt"])


## The same with the briars' real Root unit (Blackthorn Sapling, Root 1) on every tribe's content:
## Compost 1, the Sapling beside a Skin-shedder, a 200/5000 killer opposite. Root first, then the
## Molt given this fight, which survives Root's return in fight counts.
## Until the briars' Root answers the return protocol (return_offer), the old route is asked only
## when no mechanic offers, so the given Molt comes first: that known gap is asserted instead, and
## the ruling takes over by itself once the briars' Root moves.
func test_real_briar_root_beside_a_skin_shedder() -> void:
	var on_protocol: bool = (
		FileAccess
		. get_file_as_string("res://src/content/thorn/mechanics/root.gd")
		. contains("func return_offer")
	)
	var content: ContentSet = Kit.CoreKit.all_tribes()
	assert_eq(content.errors, PackedStringArray())
	game = content.session(1)
	game.start_round()
	p = game.player(0)
	q = game.player(1)
	Kit.put(game, p, "blackthorn-sapling", 0)
	Kit.put(game, p, "skin-shedder", 1)
	var wall: Unit = Kit.put(game, q, "prophet-of-the-dust", 0)
	wall.stats.set_attack = 200
	wall.stats.set_health = 5000
	p.heap(&"thorn_compost").add(&"hopper", 1)
	var combat: Combat = Kit.fight(game)
	var back: Array = Kit.where(combat, "return", "id", "blackthorn-sapling").map(
		func(e: Dictionary) -> String: return e["mechanic"]
	)
	if on_protocol:
		assert_eq(back, ["thorn_root", "locust_molt"], "Root first when the Compost can pay")
	else:
		# the old Root refuses once the unit has returned (unit.returns > 0), so only Molt fires
		assert_eq(back, ["locust_molt"], "known gap: Molt takes the death Root should take")


func test_a_unit_between_two_skin_shedders_molts_twice_without_molt_of_its_own() -> void:
	_put("skin-shedder", 0)
	var plain: Unit = _put("t1_plain", 1)
	_put("skin-shedder", 2)
	plain.grant(game.registry, &"taunt")
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "return", "id", "t1_plain").size(), 2, "two charges, kept across")
	assert_eq(plain.stats.perm_attack, 4)


func test_gleaner_hits_the_highest_health_enemy_after_each_friendly_death() -> void:
	_put("t1_plain", 0)
	_put("gleaner", 4)
	Kit.wall(game, q, 0, 50, 30)
	var biggest: Unit = Kit.wall(game, q, 1, 1, 40)
	var combat: Combat = Kit.fight(game)
	var gleans: Array[Dictionary] = Kit.effect_damage(combat, "locust_glean")
	assert_true(gleans.all(func(e: Dictionary) -> bool: return e["amount"] == 5))
	assert_gt(gleans.size(), 0)
	assert_eq(gleans[0]["uid"], Kit.uid_of(combat, biggest), "either row, most Health left")
	var deaths: int = Kit.where(combat, "death", "side", 0).size()
	assert_eq(
		Kit.triggers(combat, "locust_glean").size(), deaths - 1, "every friendly death but its own"
	)


func test_gorger_eats_the_first_unit_sold_each_turn() -> void:
	var gorger: Unit = _put("gorger", 0)
	_put("green-recruit", 1)
	_put("t1_plain", 2)
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq([gorger.stats.perm_attack, gorger.stats.perm_health], [2, 2], "the sold unit's stats")
	assert_eq(Kit.count_on_board(p, "hopper"), 2, "its death effect ran in the shop")
	assert_eq(p.board[1].def.id, &"hopper", "the first Hopper lands in the slot the sale left")
	var ate: Array[Dictionary] = Kit.CoreKit.log_of(game, "turn_counter").filter(
		func(e: Dictionary) -> bool: return e["key"] == "locust_ate"
	)
	assert_eq(ate.size(), 1, "eating once a turn is a logged turn counter")
	assert_eq(game.act(0, {"type": "sell", "slot": 2}), "")
	assert_eq(gorger.stats.perm_attack, 2, "the second sale this turn isn't eaten")
	game.recruit.start_turn(p)
	_put("t1_plain", 2)
	assert_eq(game.act(0, {"type": "sell", "slot": 2}), "")
	assert_eq([gorger.stats.perm_attack, gorger.stats.perm_health], [4, 6], "next turn, any tribe")


func test_gorger_takes_own_stats_only_and_golden_doubles() -> void:
	var gorger: Unit = _put("gorger", 0, true)
	var meal: Unit = _put("green-recruit", 1)
	meal.stats.perm_attack = 3
	Kit.ctx(game, p).add_counter(Kit.TIDE, 5, null)
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(
		[gorger.stats.perm_attack, gorger.stats.perm_health], [10, 4], "(2+3)x2 / 2x2; no Tide"
	)


# --- Tier 4 ---------------------------------------------------------------------------------------


func test_famine_caller_raises_the_tide_at_once_when_it_dies() -> void:
	_put("famine-caller", 0)
	var recruit: Unit = _put("green-recruit", 1)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(p.counter(Kit.TIDE), 2, "for the rest of the game")
	var uid: int = Kit.uid_of(combat, recruit)
	var shown: Array[Dictionary] = Kit.where(combat, "stats", "uid", uid)
	assert_true(
		shown.any(func(e: Dictionary) -> bool: return e["attack"] == 4),
		"Locusts still fighting have it"
	)


func test_sky_darkener_summons_three_hoppers_and_they_wait_on_a_full_board() -> void:
	_put("sky-darkener", 0)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "locust_sky_darken").size(), 1)
	assert_eq(Kit.hopper_summons(combat, 0).size(), 3)
	game = Kit.session()
	p = game.player(0)
	q = game.player(1)
	_put("sky-darkener", 0)
	for slot: int in range(1, 7):
		Kit.wall(game, p, slot, 1, 1)
	_killer()
	combat = Kit.fight(game)
	assert_eq(
		Kit.where(combat, "summon_waiting", "side", 0).size(), 3, "a full board: all three wait"
	)
	var landed: Array[Dictionary] = Kit.hopper_summons(combat, 0).filter(
		func(e: Dictionary) -> bool: return e.get("waited", false)
	)
	assert_gt(landed.size(), 0, "they land as slots empty")


func test_orchard_stripper_damages_every_enemy_each_time_it_dies() -> void:
	_put("orchard-stripper", 0)
	for slot: int in 3:
		Kit.wall(game, q, slot, 50, 100)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "locust_death_damage_all").size(), 2, "twice through Molt")
	var fives: Array[Dictionary] = Kit.effect_damage(combat, "locust_death_damage_all")
	assert_eq(fives.size(), 6, "5 to each of three enemies, twice")
	assert_true(fives.all(func(e: Dictionary) -> bool: return e["amount"] == 5 and e["side"] == 1))


func test_granary_glutton_eats_every_locust_sold_and_nothing_else() -> void:
	var glutton: Unit = _put("granary-glutton", 0)
	_put("green-recruit", 1)
	_put("t1_plain", 2)
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(glutton.stats.perm_attack, 2)
	assert_eq(game.act(0, {"type": "sell", "slot": 2}), "")
	assert_eq(glutton.stats.perm_attack, 2, "not a Locust")
	var hopper: Unit = p.board_units().filter(func(u: Unit) -> bool: return u.def.id == &"hopper")[0]
	assert_eq(game.act(0, {"type": "sell", "slot": hopper.slot}), "")
	assert_eq(
		[glutton.stats.perm_attack, glutton.stats.perm_health], [4, 4], "a Hopper is a 2/2 meal"
	)


func test_golden_granary_glutton_gains_double_the_stats() -> void:
	var glutton: Unit = _put("granary-glutton", 0, true)
	_put("hopper", 1)
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq([glutton.stats.perm_attack, glutton.stats.perm_health], [4, 4])


func test_gorger_eats_first_and_the_glutton_takes_the_next_locust() -> void:
	var glutton: Unit = _put("granary-glutton", 0)
	var gorger: Unit = _put("gorger", 1)
	_put("hopper", 2)
	_put("hopper", 3)
	assert_eq(game.act(0, {"type": "sell", "slot": 2}), "")
	assert_eq([gorger.stats.perm_attack, glutton.stats.perm_attack], [2, 0], "each sale eaten once")
	assert_eq(game.act(0, {"type": "sell", "slot": 3}), "")
	assert_eq([gorger.stats.perm_attack, glutton.stats.perm_attack], [2, 2])


# --- Tier 5 ---------------------------------------------------------------------------------------


func test_war_drummer_sets_off_the_death_effect_behind_it_without_a_death() -> void:
	_put("war-drummer", 0)
	var behind: int = game.geometry.behind(0)[0]
	var caller: Unit = _put("famine-caller", behind)
	Kit.wall(game, q, 0, 1, 60)
	var combat: Combat = Kit.fight(game)
	var drums: int = Kit.triggers(combat, "locust_drum").size()
	assert_gt(drums, 0)
	assert_eq(Kit.triggers(combat, "locust_tide_on_death").size(), drums, "once each attack")
	assert_eq(p.counter(Kit.TIDE), 2 * drums)
	assert_eq(
		Kit.where(combat, "death", "uid", Kit.uid_of(combat, caller)).size(), 0, "nothing died"
	)


func test_golden_war_drummer_triggers_the_death_effect_twice() -> void:
	_put("war-drummer", 0, true)
	_put("famine-caller", game.geometry.behind(0)[0])
	Kit.wall(game, q, 0, 1, 60)
	var combat: Combat = Kit.fight(game)
	var drums: int = Kit.triggers(combat, "locust_drum").size()
	assert_gt(drums, 0)
	assert_eq(Kit.triggers(combat, "locust_tide_on_death").size(), 2 * drums, "twice each attack")


func test_war_drummer_does_nothing_from_the_back_row() -> void:
	_put("war-drummer", 4)
	_put("famine-caller", 0)
	_killer(0, 1, 60)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "locust_drum").size(), 0)


func test_twice_shed_veteran_grows_with_each_friendly_return() -> void:
	_put("husk-sentry", 0)
	var veteran: Unit = _put("twice-shed-veteran", 4)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "locust_veteran").size(), 1)
	var back: Dictionary = Kit.where(combat, "return", "id", "husk-sentry")[0]
	var grown: Array[Dictionary] = Kit.where(combat, "buff", "uid", back["uid"])
	assert_eq([grown[-1]["attack"], grown[-1]["health"]], [11, 9], "a plain 3/1, +2/+2, +6/+6")
	var own: Array[Dictionary] = Kit.where(combat, "buff", "uid", Kit.uid_of(combat, veteran))
	assert_eq([own[0]["attack"], own[0]["health"]], [12, 14])
	assert_eq(veteran.stats.perm_attack, 0, "this fight only")


func test_the_eighth_plague_deals_the_number_of_friendly_deaths_so_far() -> void:
	for slot: int in 3:
		Kit.wall(game, p, slot, 1, 1)
	_put("the-eighth-plague", 4)
	var cleaver: Unit = _killer(0, 5, 400)
	cleaver.grant(game.registry, &"cleave")
	var combat: Combat = Kit.fight(game)
	var amounts: Array = Kit.effect_damage(combat, "locust_plague").map(
		func(e: Dictionary) -> int: return e["amount"]
	)
	assert_eq(amounts, [1, 2, 3], "1, 2, 3 even when they die together")
	var batch: int = 0
	for event: Dictionary in combat.events:
		if event["type"] == "attack":
			batch = 0
		elif event["type"] == "death" and event["side"] == 0:
			batch += 1
			if batch >= 2:
				break
	assert_gte(batch, 2, "the cleave killed two or more at once")


func test_golden_eighth_plague_deals_two_for_each_death() -> void:
	for slot: int in 3:
		Kit.wall(game, p, slot, 1, 1)
	_put("the-eighth-plague", 4, true)
	_killer(0, 5, 400).grant(game.registry, &"cleave")
	var combat: Combat = Kit.fight(game)
	var amounts: Array = Kit.effect_damage(combat, "locust_plague").map(
		func(e: Dictionary) -> int: return e["amount"]
	)
	assert_eq(amounts, [2, 4, 6])


# --- Tier 6 ---------------------------------------------------------------------------------------


func test_dirge_singer_makes_death_effects_trigger_twice() -> void:
	_put("green-recruit", 0)
	_put("dirge-singer", 4)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "locust_hoppers_on_death").size(), 2)
	assert_eq(Kit.hopper_summons(combat, 0).size(), 4)


func test_golden_dirge_singer_makes_death_effects_trigger_three_times() -> void:
	_put("famine-caller", 0)
	_put("dirge-singer", 4, true)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "locust_tide_on_death").size(), 3)
	assert_eq(p.counter(Kit.TIDE), 6)


func test_dirge_singer_doubles_an_eaten_death_effect_in_the_shop() -> void:
	_put("gorger", 0)
	_put("brood-mother", 1)
	_put("dirge-singer", 2)
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(p.counter(Kit.HOPPER_BONUS), 2)
	assert_eq(Kit.count_on_board(p, "hopper"), 2)


func test_swarm_lord_raises_the_tide_after_every_two_friendly_locust_deaths() -> void:
	_put("hopper", 0)
	_put("t1_plain", 1)
	_put("hopper", 2)
	_put("swarm-lord", 4)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(
		Kit.triggers(combat, "locust_swarm_lord").size(),
		1,
		"two Hoppers; the plain one isn't a Locust"
	)
	assert_eq(p.counter(Kit.TIDE), 1)


func test_mother_of_thousands_doubles_hoppers_in_a_fight_and_in_the_shop() -> void:
	_put("green-recruit", 0)
	_put("mother-of-thousands", 4)
	_killer()
	assert_eq(Kit.hopper_summons(Kit.fight(game), 0).size(), 4)
	game = Kit.session()
	p = game.player(0)
	_put("gorger", 0)
	_put("green-recruit", 1)
	_put("mother-of-thousands", 2, true)
	assert_eq(game.act(0, {"type": "sell", "slot": 1}), "")
	assert_eq(
		Kit.count_on_board(p, "hopper"), 5, "golden: three times as many, 6, and 5 slots free"
	)
