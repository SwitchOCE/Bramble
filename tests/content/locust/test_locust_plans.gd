extends GutTest
## The Locust plans' key interactions (README "The five plans"), through real fights and recruit
## turns: Rising Tide, Brood, Molt, Devastation and Feast, and the swarm against the limits.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/content/locust/locust_kit.gd")

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = game.player(1)


func _put(card_id: String, slot: int, golden: bool = false) -> Unit:
	return Kit.put(game, p, card_id, slot, golden)


func test_rising_tide_drummed_famine_caller_raises_the_tide_each_attack_and_hoppers_carry_it(
) -> void:
	_put("war-drummer", 0)
	_put("famine-caller", game.geometry.behind(0)[0])
	_put("green-recruit", 1)
	Kit.ctx(game, p).add_counter(Kit.HOPPER_BONUS, 1, null)
	Kit.wall(game, q, 0, 9, 400)
	var combat: Combat = Kit.fight(game)
	var drums: int = Kit.triggers(combat, "locust_drum").size()
	assert_gt(drums, 0)
	var hoppers: Array[Dictionary] = Kit.hopper_summons(combat, 0)
	assert_gt(hoppers.size(), 0, "the Recruit died into Hoppers")
	var tide_then: int = 0
	for event: Dictionary in combat.events:
		if (
			event["type"] == "player_counter"
			and event["side"] == 0
			and event["key"] == "locust_tide"
		):
			tide_then = event["value"]
		if event["type"] == "summon" and event["id"] == "hopper" and event["side"] == 0:
			break
	assert_eq(
		hoppers[0]["attack"], 2 + tide_then + 1, "a summoned Hopper has the Tide and the bonus"
	)
	assert_eq(hoppers[0]["health"], 3)
	assert_eq(p.counter(Kit.TIDE), 2 * drums + 2, "each drumbeat +2, and the Famine-caller's death")


func test_brood_drummed_mother_raises_the_hopper_bonus_and_hoppers_wait_on_a_full_board() -> void:
	_put("war-drummer", 0)
	_put("brood-mother", game.geometry.behind(0)[0])
	for slot: int in [1, 2, 3, 5, 6]:
		Kit.wall(game, p, slot, 0, 60)
	Kit.wall(game, q, 0, 1, 200)
	var combat: Combat = Kit.fight(game)
	var drums: int = Kit.triggers(combat, "locust_drum").size()
	assert_gt(drums, 0)
	var broods: int = Kit.triggers(combat, "locust_brood").size()
	var mother_deaths: int = broods - drums
	assert_true(mother_deaths == 0 or mother_deaths == 1, "+1/+1 a drumbeat; it died at most once")
	assert_eq(p.counter(Kit.HOPPER_BONUS), broods, "each time it resolves, kept")
	assert_gte(Kit.where(combat, "summon_waiting", "side", 0).size(), drums, "no room: they wait")


func test_brood_with_mother_of_thousands_and_dirge_singer_a_recruit_leaves_four() -> void:
	_put("green-recruit", 0)
	_put("mother-of-thousands", 4)
	_put("dirge-singer", 5)
	Kit.wall(game, q, 0, 50, 2000)
	var combat: Combat = Kit.fight(game)
	var made: int = (
		Kit.hopper_summons(combat, 0).size() + Kit.where(combat, "summon_waiting", "side", 0).size()
	)
	var waited: int = (
		Kit
		. hopper_summons(combat, 0)
		. filter(func(e: Dictionary) -> bool: return e.get("waited", false))
		. size()
	)
	assert_eq(made - waited, 4, "1 Hopper, doubled by the Mother, twice by the Dirge-singer")


func test_molt_board_shedder_sentry_and_veteran() -> void:
	var sentry: Unit = _put("husk-sentry", 0)
	_put("skin-shedder", 1)
	_put("wheat-raider", 2)
	var veteran: Unit = _put("twice-shed-veteran", 4)
	Kit.wall(game, q, 0, 50, 400)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "return", "id", "husk-sentry").size(), 2)
	assert_eq(
		Kit.where(combat, "return", "id", "wheat-raider").size(), 2, "next to the shedder: twice"
	)
	assert_eq(Kit.triggers(combat, "locust_veteran").size(), 4, "+6/+6 on every return")
	var own: Array[Dictionary] = Kit.where(combat, "buff", "uid", Kit.uid_of(combat, veteran))
	assert_eq(own[-1]["attack"], 6 + 24)
	assert_eq(sentry.stats.perm_attack, 4, "two Molts kept")


func test_devastation_gleaner_and_plague_hurt_them_for_every_death() -> void:
	_put("green-recruit", 0)
	_put("wheat-raider", 1)
	_put("green-recruit", 2)
	_put("gleaner", 4)
	_put("the-eighth-plague", 5)
	var big: Unit = Kit.wall(game, q, 0, 50, 80)
	Kit.wall(game, q, 1, 1, 10)
	var combat: Combat = Kit.fight(game)
	var gleaner_uid: int = Kit.uid_of(combat, p.board[4])
	var big_uid: int = Kit.uid_of(combat, big)
	var gleans: Array[Dictionary] = Kit.effect_damage(combat, "locust_glean", [gleaner_uid])
	assert_gt(gleans.size(), 0)
	assert_eq(gleans[0]["uid"], big_uid, "the Gleaner goes for their biggest unit")
	var plague: Array = Kit.effect_damage(combat, "locust_plague").map(
		func(e: Dictionary) -> int: return e["amount"]
	)
	assert_gt(plague.size(), 3)
	for i: int in plague.size():
		assert_eq(plague[i], i + 1, "the n-th friendly death deals n")


func test_feast_eaten_death_effects_pay_in_the_shop() -> void:
	var gorger: Unit = _put("gorger", 0)
	var glutton: Unit = _put("granary-glutton", 1)
	_put("brood-mother", 2)
	_put("famine-caller", 3)
	assert_eq(game.act(0, {"type": "sell", "slot": 2}), "")
	assert_eq([gorger.stats.perm_attack, gorger.stats.perm_health], [3, 6], "the Gorger eats first")
	assert_eq(p.counter(Kit.HOPPER_BONUS), 1)
	assert_eq(game.act(0, {"type": "sell", "slot": 3}), "")
	assert_eq([glutton.stats.perm_attack, glutton.stats.perm_health], [6, 4], "then the Glutton")
	assert_eq(p.counter(Kit.TIDE), 2, "an eaten Famine-caller raises the Tide")
	assert_eq(gorger.attack(), 5 + 3 + 2, "own 8, Tide 2")


## Hoppers asked for by one source uid (summoned at once or waiting; a waited one landing later
## is not a new request).
func _asked(combat: Combat, source: int) -> int:
	var count: int = 0
	for event: Dictionary in combat.events:
		if CoreUtil.to_int(event.get("source_uid", -2)) != source or event.get("id") != "hopper":
			continue
		if (
			event["type"] == "summon_waiting"
			or (event["type"] == "summon" and not event.get("waited", false))
		):
			count += 1
	return count


## Sky-darkener's 2 Hoppers are 4 with the Mother, all waiting on a full board; each golden Green
## Recruit's death effect runs twice (Dirge-singer) and each run asks for 2 x 2 Hoppers. The fight
## still ends inside the limits.
func test_a_hopper_flood_ends_within_the_limits() -> void:
	_put("mother-of-thousands", 4)
	var darkener: Unit = _put("sky-darkener", 5)
	_put("dirge-singer", 6)
	for slot: int in 4:
		_put("green-recruit", slot, true)
	for slot: int in 7:
		Kit.wall(game, q, slot, 1, 300).grant(game.registry, &"taunt")
	var combat: Combat = Kit.fight(game)
	var sky: int = Kit.uid_of(combat, darkener)
	assert_eq(_asked(combat, sky), 2 * 2, "Sky-darkener's 2, doubled by the Mother")
	var waits: Array[Dictionary] = Kit.where(combat, "summon_waiting", "source_uid", sky)
	assert_eq(waits.size(), 4, "a full board: all four wait")
	var runs: Array[Dictionary] = Kit.triggers(combat, "locust_hoppers_on_death")
	var died: Array[int] = []
	for run: Dictionary in runs:
		var uid: int = CoreUtil.to_int(run["uid"])
		if not died.has(uid):
			died.append(uid)
	assert_gt(died.size(), 0, "Green Recruits died")
	for uid: int in died:
		var times: int = runs.filter(func(e: Dictionary) -> bool: return e["uid"] == uid).size()
		assert_eq(times, 2, "Dirge-singer: each death effect twice")
		assert_eq(_asked(combat, uid), 2 * 2 * 2, "twice, 2 Hoppers each, doubled by the Mother")
	var end: Dictionary = Kit.events(combat, "combat_end")[0]
	assert_true(Combat.REASONS.has(end["reason"]), "the fight ends: %s" % end["reason"])
	assert_lte(CoreUtil.to_int(end["attacks"]), game.config.attack_limit)
	assert_lte(CoreUtil.to_int(end["triggers"]), game.config.combat_trigger_limit)


## Golden on both sides: each Brood Mother's death effect runs three times (golden Dirge-singer),
## each run asks for 2 Hoppers three times over (golden Mother) and adds +2 to the Hopper bonus
## for good, so every Hopper lands as 2/2 plus the bonus at that moment.
func test_two_hopper_floods_with_big_hoppers_against_each_other() -> void:
	for player: PlayerState in [p, q]:
		Kit.put(game, player, "mother-of-thousands", 4, true)
		Kit.put(game, player, "sky-darkener", 5, true)
		Kit.put(game, player, "dirge-singer", 6, true)
		for slot: int in 4:
			Kit.put(game, player, "brood-mother", slot, true)
		Kit.ctx(game, player).add_counter(Kit.HOPPER_BONUS, 20, null)
	var combat: Combat = Kit.fight(game)
	for side: int in 2:
		var runs: Array[Dictionary] = Kit.triggers(combat, "locust_brood").filter(
			func(e: Dictionary) -> bool: return e["side"] == side
		)
		var player: PlayerState = game.player(side)
		assert_gt(runs.size(), 0, "side %d: Brood Mothers died" % side)
		assert_eq(player.counter(Kit.HOPPER_BONUS), 20 + 2 * runs.size(), "+2 a run, for good")
		var mothers: Array[int] = []
		for run: Dictionary in runs:
			var uid: int = CoreUtil.to_int(run["uid"])
			if not mothers.has(uid):
				mothers.append(uid)
		for uid: int in mothers:
			var times: int = runs.filter(func(e: Dictionary) -> bool: return e["uid"] == uid).size()
			assert_eq(times, 3, "side %d: each death effect three times" % side)
			assert_eq(_asked(combat, uid), 3 * 2 * 3, "three runs of 2 Hoppers, tripled")
		for hopper: Dictionary in Kit.hopper_summons(combat, side):
			assert_true(hopper["golden"] == false, "a Hopper is a plain token")
			assert_eq(hopper["attack"] - 2, hopper["health"] - 2, "the bonus is +N/+N")
			assert_gte(CoreUtil.to_int(hopper["attack"]), 2 + 20, "with the bonus it had then")
	var end: Dictionary = Kit.events(combat, "combat_end")[0]
	assert_true(Combat.REASONS.has(end["reason"]))
	var made: int = Kit.hopper_summons(combat, 0).size() + Kit.hopper_summons(combat, 1).size()
	assert_gt(made, 40, "a flood")
