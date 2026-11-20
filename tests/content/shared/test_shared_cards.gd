extends GutTest

@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/content/cross/cross_kit.gd")
const DESIGN: String = "res://docs/ideation-track-2/tribes/shared/units.json"

var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = Kit.opponent(game, p)


## Stop after Start of fight so tests can play a particular exchange or arrival in isolation.
func _before_attacks() -> Combat:
	game.config.attack_limit = 0
	var combat: Combat = Kit.fight(game, p, q)
	game.config.attack_limit = 100
	combat._halt_reason = ""
	return combat


func test_all_eight_cards_and_goldens_match_the_design() -> void:
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var units: Array = design["units"]
	assert_eq(units.size(), 8)
	for row: Dictionary in units:
		var def: UnitDef = game.library.get_card(StringName(row["id"]))
		assert_not_null(def)
		if def == null:
			continue
		assert_true(def.tribes.is_empty(), def.name)
		assert_eq(def.tier, int(row["tier"]), def.name)
		for golden: bool in [false, true]:
			var view: Dictionary = game.new_unit(def, golden).view()
			var multiple: int = 2 if golden else 1
			assert_eq(view["attack"], int(row["attack"]) * multiple, def.name)
			assert_eq(view["health"], int(row["health"]) * multiple, def.name)
			assert_eq(view["text"], row["golden"] if golden else row["text"], def.name)


func test_every_single_tribe_shop_includes_neutrals_at_the_usual_weight() -> void:
	var content: GameContent = GameContent.load_default()
	assert_eq(content.tribe_ids().size(), 5)
	assert_false(content.tribe_ids().has("shared"))
	for tribe: Dictionary in content.tribes:
		var lobby: GameSession = content.new_session(4, [str(tribe["name"])])
		var shared: int = 0
		for def: UnitDef in content.library.drawable_cards(false):
			var included: bool = def.tribes.is_empty() or def.has_tribe(str(tribe["name"]))
			var weight: int = lobby.config.unit_weights_by_tier[def.tier - 1] if included else 0
			assert_eq(lobby.unit_odds.weight_of(def.id), weight, def.name)
			if def.tribes.is_empty():
				shared += 1
		assert_eq(shared, 8)
		lobby.start_round()
		assert_true(
			lobby.players.any(
				func(player: PlayerState) -> bool: return player.shop_units.has(&"bumblebee")
			),
			"Bumblebee offered in the opening shops of the %s lobby" % tribe["name"]
		)


func test_back_row_ballista_killing_bee_or_toad_receives_the_death_effect(
	args: Array = use_parameters(
		[["bumblebee", false], ["bumblebee", true], ["bitter-toad", false], ["bitter-toad", true]]
	)
) -> void:
	var victim: Unit = Kit.put(game, p, args[0], 0, args[1])
	var shooter: Unit = Kit.put(game, q, "toothpick-ballista", 4)
	shooter.stats.set_health = 20
	Kit.wall(game, q, 0, 0, 100)
	var combat: Combat = _before_attacks()
	var uid: int = Kit.uid_of(combat, shooter)
	var dead: int = Kit.uid_of(combat, victim)
	assert_eq(Kit.where(combat, "death", "uid", dead)[0]["killer_uid"], uid)
	if args[0] == "bumblebee":
		var damage: Dictionary = Kit.where(combat, "damage", "source_uid", dead)[0]
		assert_eq(damage["uid"], uid)
		assert_eq(damage["amount"], 8 if args[1] else 4)
	else:
		assert_eq(Kit.where(combat, "death", "uid", uid)[0]["killer_uid"], dead)
		assert_true(victim.def.keywords.has(&"taunt"))


func test_queued_pilers_credit_the_first_lethal_hit() -> void:
	Kit.wall(game, p, 0, 5, 100)
	var first: Unit = Kit.put(game, p, "needle-page", 1)
	Kit.put(game, p, "needle-page", 4)
	var toad: Unit = Kit.put(game, q, "bitter-toad", 0)
	var combat: Combat = Kit.fight(game, p, q)
	var uid: int = Kit.uid_of(combat, first)
	assert_eq(Kit.where(combat, "death", "uid", Kit.uid_of(combat, toad))[0]["killer_uid"], uid)
	assert_eq(Kit.events(combat, "destroy")[0]["uid"], uid)


func test_no_retaliation_without_a_living_killer() -> void:
	Kit.put(game, p, "bumblebee", 0)
	Kit.put(game, p, "bitter-toad", 1)
	Kit.wall(game, q, 0, 3, 1)
	var combat: Combat = _before_attacks()
	var bee: CombatUnit = combat.unit_at(0, 0)
	var toad: CombatUnit = combat.unit_at(0, 1)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	combat.deal_damage(enemy, toad, 1)
	combat.run_death_effects(toad)
	assert_false(enemy.destroyed, "a live unit has no killer")
	combat.destroy(null, toad)
	assert_true(combat.attack_now(bee, enemy), "both sides deal lethal in one exchange")
	assert_eq(Kit.where(combat, "death", "uid", toad.uid)[0]["killer_uid"], -1)
	assert_eq(Kit.triggers(combat, "sting_killer").size(), 0, "its killer died in the exchange")
	assert_eq(Kit.triggers(combat, "destroy_killer").size(), 0, "sourceless destroy")


func test_ballista_chooses_lowest_current_health_again_for_each_hit(
	golden: bool = use_parameters([false, true])
) -> void:
	Kit.put(game, p, "toothpick-ballista", 0, golden)
	Kit.wall(game, q, 0, 2, 14).grant(game.registry, &"taunt")
	Kit.wall(game, q, 4, 1, 7)
	var combat: Combat = _before_attacks()
	var hits: Array[Dictionary] = Kit.events(combat, "hit")
	assert_eq(
		hits.map(func(e: Dictionary) -> int: return e["target_slot"]), [4, 0] if golden else [4]
	)
	assert_eq(Kit.events(combat, "attack").size(), 0)
	assert_eq(Kit.events(combat, "damage", 0).size(), 0)
	for event: Dictionary in Kit.events(combat, "damage", 1):
		assert_eq(event["amount"], 16 if golden else 8)


func test_beetle_blocks_hits_thorns_and_splash_but_takes_both_sides_of_an_exchange(
	golden: bool = use_parameters([false, true])
) -> void:
	Kit.put(game, p, "stag-beetle", 0, golden)
	Kit.wall(game, p, 1, 0, 1)
	var striker: Unit = Kit.wall(game, q, 0, 3, 100)
	striker.grant(game.registry, &"cleave")
	striker.grant(game.registry, &"badger_overrun")
	Kit.put(game, q, "nettle-sprout", 1)
	var combat: Combat = _before_attacks()
	var beetle: CombatUnit = combat.unit_at(0, 0)
	var foe: CombatUnit = combat.unit_at(1, 0)
	var thorns: CombatUnit = combat.unit_at(1, 1)
	combat.hit(foe, beetle)
	combat.attack_now(foe, combat.unit_at(0, 1))
	assert_eq(beetle.damage, 0, "Hit, Overrun carry and Cleave splash")
	assert_eq(Kit.where(combat, "prevented", "uid", beetle.uid).size(), 3)
	combat.attack_now(beetle, thorns)
	assert_eq(beetle.damage, thorns.attack(), "strike back gets through, Thorns does not")
	combat.attack_now(foe, beetle)
	assert_eq(beetle.damage, thorns.attack() + 3, "direct attack")


func test_weasel_spends_charge_on_each_enemy_summon_only(
	golden: bool = use_parameters([false, true])
) -> void:
	Kit.put(game, p, "weasel", 4, golden)
	Kit.wall(game, q, 0, 1, 30)
	var combat: Combat = _before_attacks()
	var weasel: CombatUnit = combat.unit_at(0, 4)
	combat.summon(0, &"private", -1, false, null)
	combat.step_in(1, &"private", 2, null)
	var returning: CombatUnit = combat.unit_at(1, 0)
	combat.bridge(1).give_keyword(returning, &"reborn", false, returning)
	combat.destroy(null, returning)
	combat._resolve_deaths(1)
	assert_eq(Kit.events(combat, "return").size(), 1)
	assert_eq(Kit.events(combat, "hit").size(), 0, "friends, step-ins and returns spend no Charge")
	var limit: int = 12 if golden else 6
	for i: int in limit + 1:
		var entered: CombatUnit = combat.summon(1, &"private", -1, false, null)
		assert_eq(entered.damage, weasel.attack() if i < limit else 0)
		combat._resolve_deaths(1)
	var hits: Array[Dictionary] = Kit.where(combat, "hit", "uid", weasel.uid)
	assert_eq(hits.size(), limit)
	assert_eq(Kit.where(combat, "uses", "uid", weasel.uid)[-1]["left"], 0)


func test_weasel_hits_during_a_pile_on_window_before_the_joining_hits_land() -> void:
	Kit.wall(game, p, 0, 1, 50)
	Kit.put(game, p, "needle-page", 1)
	Kit.put(game, p, "thimble-captain", 4)
	Kit.put(game, q, "weasel", 0)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game, p, q)
	var summoned: Dictionary = Kit.events(combat, "summon")[0]
	var hits: Array[Dictionary] = Kit.events(combat, "hit")
	assert_eq(hits.size(), 2)
	assert_eq(hits[0]["target_uid"], summoned["uid"], "Weasel answers the summon immediately")
	assert_eq(hits[1]["slot"], 1, "the Page's queued Hit lands afterwards")


func test_venomous_and_double_attacks_use_the_printed_keywords(
	args: Array = use_parameters(
		[
			["heath-adder", false],
			["heath-adder", true],
			["shrew-harrier", false],
			["shrew-harrier", true],
			["hornet-queen", false],
			["hornet-queen", true]
		]
	)
) -> void:
	Kit.put(game, p, args[0], 0, args[1])
	for slot: int in 2:
		Kit.wall(game, q, slot, 0, 80)
	var combat: Combat = _before_attacks()
	var unit: CombatUnit = combat.unit_at(0, 0)
	combat._take_turn(0)
	var twice: bool = args[0] != "heath-adder"
	assert_eq(Kit.events(combat, "attack", 0).size(), 2 if twice else 1)
	combat._take_turn(0)
	assert_eq(
		Kit.where(combat, "destroy", "source_uid", unit.uid).size(),
		0 if args[0] == "shrew-harrier" else 1
	)
