extends GutTest
## One test (or more) for each Locust unit and the Hopper token, each proving its card text in a
## real fight or recruit turn through the core, on the event log or the views.
## Design: docs/ideation-track-2/tribes/locust/units.json.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/locust/locust_kit.gd")
const DESIGN: String = "res://docs/ideation-track-2/tribes/locust/units.json"

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


func test_golden_text_reads_doubled_numbers() -> void:
	var golden: Unit = _put("green-recruit", 0, true)
	assert_eq(golden.view()["text"], "When this dies, summon 4 Hoppers.")
	var lord: Unit = _put("swarm-lord", 1, true)
	assert_eq(lord.view()["text"], "After 2 friendly Locusts die, Tide +2.", "the count stays 2")


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


# --- Tier 6 ---------------------------------------------------------------------------------------


func test_dirge_singer_makes_death_effects_trigger_twice() -> void:
	_put("green-recruit", 0)
	_put("dirge-singer", 4)
	_killer()
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.triggers(combat, "locust_hoppers_on_death").size(), 2)
	assert_eq(Kit.hopper_summons(combat, 0).size(), 4)


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
