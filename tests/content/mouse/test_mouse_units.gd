extends GutTest
## One test or more for each Mouse unit and the Cousin token, proving its text through the core:
## a real fight or a real Recruit Phase action, read from the fight log or the views.
## Slots: F1-F4 are 0-3, B1-B3 are 4-6. A back slot neighbours the two front slots it sits
## between (4: 0 and 1; 5: 1 and 2; 6: 2 and 3).

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const Kit := preload("res://tests/content/mouse/mouse_kit.gd")
var game: GameSession
var p: PlayerState
var q: PlayerState


func before_each() -> void:
	game = Kit.session()
	p = game.player(0)
	q = game.player(1)


## The hits logged during the attack that starts at log index `at`.
func _hits_in_attack(combat: Combat, at: int) -> Array[Dictionary]:
	return Kit.between(combat, at, Kit.next_attack(combat, at), "hit")


func _first_attack_by(combat: Combat, uid: int) -> int:
	return Kit.index_of(combat, "attack", {"uid": uid})


# --- Tier 1 -------------------------------------------------------------------------------------


func test_needle_page_piles_on_first_and_the_attacker_takes_nothing() -> void:
	Kit.wall(game, p, 0, 1, 100)
	CoreKit.put(game, p, "needle-page", 1)
	Kit.wall(game, q, 0, 0, 4)
	var combat: Combat = Kit.fight(game)
	var attacker: int = Kit.uid_at(combat, 0, 0)
	var page: int = Kit.uid_at(combat, 0, 1)
	var target: int = Kit.uid_at(combat, 1, 0)
	var at: int = _first_attack_by(combat, attacker)
	assert_eq(at, Kit.index_of(combat, "attack"), "the wall attacks first")
	var hits: Array[Dictionary] = _hits_in_attack(combat, at)
	assert_eq(hits.size(), 1)
	assert_eq(hits[0]["uid"], page)
	assert_eq(hits[0]["target_uid"], target)
	assert_eq(Kit.damage_by(combat, page), [4] as Array[int])
	assert_eq(Kit.damage_by(combat, attacker), [] as Array[int], "the attack ended at the hit")
	assert_eq(Kit.damage_to(combat, attacker), [] as Array[Dictionary], "nothing struck back")
	var death: Array[Dictionary] = Kit.where(combat, "death", "uid", target)
	assert_eq(death[0]["killer_uid"], page, "the kill is the piler's, not the attacker's")


func test_needle_page_piles_on_from_behind_but_not_from_afar() -> void:
	Kit.wall(game, p, 0, 1, 100)
	CoreKit.put(game, p, "needle-page", 4)
	CoreKit.put(game, p, "needle-page", 3)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var at: int = _first_attack_by(combat, Kit.uid_at(combat, 0, 0))
	var hits: Array[Dictionary] = _hits_in_attack(combat, at)
	assert_eq(hits.size(), 1, "B1 is behind F1; F4 is not a neighbour")
	assert_eq(hits[0]["uid"], Kit.uid_at(combat, 0, 4))


func test_pile_on_answers_another_tribes_attacker_but_not_one_thorns_killed() -> void:
	game = Kit.session(1, true)
	p = game.player(0)
	q = game.player(1)
	Kit.wall(game, p, 0, 1, 1)
	CoreKit.put(game, p, "needle-page", 1)
	CoreKit.put(game, q, "b2_thorny", 0)
	var combat: Combat = Kit.fight(game)
	var at: int = _first_attack_by(combat, Kit.uid_at(combat, 0, 0))
	assert_gt(at, -1)
	assert_eq(_hits_in_attack(combat, at).size(), 0, "Thorns killed the attacker: nobody piles on")


func test_harvest_piper_gives_other_mice_two_attack_when_recruited() -> void:
	var page: Unit = CoreKit.put(game, p, "needle-page", 0)
	var plain: Unit = CoreKit.put(game, p, "t1_plain", 1)
	assert_eq(Kit.buy_and_play(game, p, "harvest-piper", 2), "")
	assert_eq(page.view()["attack"], 6, "a Mouse: +2")
	assert_eq(plain.view()["attack"], 2, "not a Mouse")
	assert_eq(p.board[2].view()["attack"], 3, "not itself")
	var buffs: Array[Dictionary] = CoreKit.log_of(game, "buff")
	assert_eq(buffs.size(), 1)
	assert_eq(buffs[0]["duration"], "permanent")


func test_golden_harvest_piper_gives_four() -> void:
	var page: Unit = CoreKit.put(game, p, "needle-page", 0)
	assert_true(game.recruit._gain(p, Kit.golden_unit(game, "harvest-piper")))
	var played: String = game.act(
		p.id, {"type": "play", "hand": p.hand.size() - 1, "slot": 2, "target": -1}
	)
	assert_eq(played, "")
	assert_eq(page.view()["attack"], 8)


func test_shrew_cutpurse_earns_one_gold_the_first_time_it_piles_on() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	CoreKit.put(game, p, "shrew-cutpurse", 1)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var cutpurse: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.where(combat, "hit", "uid", cutpurse).size(), 1, "Pile on 1")
	var gold: Array[Dictionary] = CoreKit.events_of(combat, "gold")
	assert_eq(gold.size(), 1, "once a fight")
	assert_eq([gold[0]["amount"], gold[0]["next_turn"]], [1, true])
	assert_eq(p.gold_next_turn, 1, "paid at the start of the next turn")


func test_pile_on_hits_land_together_so_a_later_piler_still_counts() -> void:
	Kit.wall(game, p, 0, 1, 100)
	CoreKit.put(game, p, "needle-page", 1)
	Kit.golden(game, p, "shrew-cutpurse", 4)
	Kit.wall(game, q, 0, 0, 3)
	var combat: Combat = Kit.fight(game)
	var at: int = _first_attack_by(combat, Kit.uid_at(combat, 0, 0))
	var hits: Array[Dictionary] = _hits_in_attack(combat, at)
	var who: Array = hits.map(func(e: Dictionary) -> int: return e["uid"])
	who.sort()
	assert_eq(who, [Kit.uid_at(combat, 0, 1), Kit.uid_at(combat, 0, 4)], "both land")
	assert_eq(p.gold_next_turn, 2, "the golden Cutpurse piled on, though the Page's 4 was enough")


# --- Tier 3 -------------------------------------------------------------------------------------


func test_thimble_captain_summons_a_cousin_when_a_neighbour_attacks() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	CoreKit.put(game, p, "thimble-captain", 4)
	Kit.wall(game, p, 5, 0, 1000)
	Kit.wall(game, p, 6, 0, 1000)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var captain: int = Kit.uid_at(combat, 0, 4)
	var at: int = _first_attack_by(combat, Kit.uid_at(combat, 0, 0))
	var summons: Array[Dictionary] = Kit.between(combat, at, Kit.next_attack(combat, at), "summon")
	assert_eq(summons.size(), 1)
	assert_eq(summons[0]["source_uid"], captain)
	assert_eq(summons[0]["slot"], 1, "nearest the Captain: B2 and B3 are taken, F2 is right of F1")
	var hits: Array[Dictionary] = _hits_in_attack(combat, at)
	assert_eq(hits.size(), 0, "a Cousin has Hand-me-down")
	var own: int = _first_attack_by(combat, captain)
	assert_gt(own, -1, "the Captain attacks too")
	var after_own: Array[Dictionary] = Kit.between(
		combat, own, Kit.next_attack(combat, own), "summon"
	)
	assert_eq(after_own.size(), 0, "not on its own attacks")


func test_golden_thimble_captain_has_four_charges_each_fight() -> void:
	Kit.wall(game, p, 0, 1, 10000)
	Kit.golden(game, p, "thimble-captain", 1)
	Kit.wall(game, q, 0, 0, 10000)
	for _fight: int in 2:
		var combat: Combat = Kit.fight(game)
		var summons: Array[Dictionary] = Kit.where(combat, "summon", "id", "cousin")
		assert_eq(summons.size(), 4)
		assert_eq(Kit.where(combat, "uses", "key", "mouse_charge_left").size(), 4)
		for summon: Dictionary in summons:
			assert_false(summon["golden"])
			assert_eq(summon["attack"], 2)


func test_needle_pikeman_hits_when_it_is_attacked_back() -> void:
	CoreKit.put(game, p, "needle-pikeman", 0)
	Kit.wall(game, q, 0, 1, 100)
	var combat: Combat = Kit.fight(game)
	var pikeman: int = Kit.uid_at(combat, 0, 0)
	assert_eq(Kit.where(combat, "attack", "uid", pikeman).size(), 0)
	assert_gt(Kit.damage_by(combat, pikeman).size(), 0, "it still deals its Attack back")


func test_king_speck_fills_every_empty_slot_with_cousins_before_the_exchange() -> void:
	CoreKit.put(game, p, "king-speck", 0)
	Kit.wall(game, p, 2, 0, 1000)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var king: int = Kit.uid_at(combat, 0, 0)
	var at: int = _first_attack_by(combat, king)
	var summons: Array[Dictionary] = Kit.between(combat, at, Kit.next_attack(combat, at), "summon")
	assert_eq(summons.size(), 5, "slots F2, F4, B1, B2, B3")
	var hits: Array[Dictionary] = _hits_in_attack(combat, at)
	assert_eq(hits.size(), 0, "Cousins inherit Attack")
	var exchange: int = Kit.index_of(combat, "damage", {"source_uid": king})
	assert_gt(exchange, combat.events.find(summons[-1]))


func test_golden_king_speck_summons_four_four_cousins() -> void:
	Kit.golden(game, p, "king-speck", 0)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var king: int = Kit.uid_at(combat, 0, 0)
	var made: Array[Dictionary] = Kit.where(combat, "summon", "source_uid", king)
	assert_eq(made.size(), 6)
	assert_true(made.all(func(e: Dictionary) -> bool: return e["golden"]), "golden Cousins")
	assert_eq([made[0]["attack"], made[0]["health"]], [4, 4])
	assert_eq(Kit.where(combat, "buff", "source_uid", king).size(), 0, "no buff stands in")


func test_dame_bodkin_doubles_pile_on_hits_only() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	CoreKit.put(game, p, "needle-page", 1)
	CoreKit.put(game, p, "dame-bodkin", 4)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 1))[0], 8, "a Page's pile-on doubled")
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 4))[0], 12, "her own pile-on doubled")
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 0))[0], 1, "ordinary attack")


func test_golden_dame_bodkin_triples_pile_on_hits() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	CoreKit.put(game, p, "needle-page", 1)
	Kit.golden(game, p, "dame-bodkin", 5)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 1))[0], 12, "a Page's pile-on x3")


func test_cook_feeds_only_other_mice_on_a_partial_board() -> void:
	var cook: Unit = CoreKit.put(game, p, "dormouse-cook", 0)
	var scout: Unit = CoreKit.put(game, p, "hedgerow-scout", 1)
	var wall: Unit = Kit.wall(game, p, 2, 1, 5)
	assert_eq(Kit.end_turn(game), "")
	assert_eq([cook.stats.perm_attack, scout.stats.perm_attack, wall.stats.perm_attack], [0, 3, 0])


func test_aunt_recruits_a_cousin_to_hand() -> void:
	CoreKit.set_shop(game, p, ["hayloft-aunt"] as Array[String])
	p.gold = 10
	assert_eq(game.act(p.id, {"type": "buy", "index": 0, "spell": false}), "")
	assert_eq(p.hand.size(), 2)
	assert_eq(p.hand[0].def.id, &"hayloft-aunt")
	assert_eq(p.hand[1].def.id, &"cousin")
	assert_false(p.hand[1].is_bought())


func test_golden_aunt_adds_two_regular_cousins() -> void:
	assert_true(game.recruit._gain(p, Kit.golden_unit(game, "hayloft-aunt")))
	assert_eq(p.hand.size(), 3)
	for cousin: Unit in p.hand.slice(1):
		assert_eq(cousin.def.id, &"cousin")
		assert_false(cousin.golden)


func test_pikeman_grows_all_pilers_including_itself_each_hit() -> void:
	Kit.wall(game, p, 0, 1, 10000)
	var pike: Unit = CoreKit.put(game, p, "needle-pikeman", 1)
	var page: Unit = CoreKit.put(game, p, "needle-page", 3)
	var scout: Unit = CoreKit.put(game, p, "hedgerow-scout", 6)
	Kit.wall(game, q, 0, 0, 10000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.damage_by(combat, uid), [6, 8, 10, 12, 14] as Array[int])
	assert_eq(
		[pike.stats.perm_attack, page.stats.perm_attack, scout.stats.perm_attack], [10, 10, 0]
	)
	assert_eq(Kit.where(combat, "attack", "uid", uid).size(), 0)


func test_fencing_master_grows_only_itself_after_each_hit() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	var master: Unit = CoreKit.put(game, p, "fencing-master", 1)
	var page: Unit = CoreKit.put(game, p, "needle-page", 4)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "hit", "uid", Kit.uid_at(combat, 0, 1)).size(), 2)
	assert_eq([master.stats.perm_attack, page.stats.perm_attack], [4, 0])


func test_sergeant_adds_one_to_the_adjacent_pages_count() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	CoreKit.put(game, p, "needle-page", 1)
	CoreKit.put(game, p, "drill-sergeant", 2)
	CoreKit.put(game, p, "cousin", 5)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "hit", "uid", Kit.uid_at(combat, 0, 1)).size(), 2)
	var at: int = _first_attack_by(combat, Kit.uid_at(combat, 0, 0))
	assert_eq(_hits_in_attack(combat, at).size(), 1)
	assert_false(combat.unit_at(0, 5).has_mechanic(&"mouse_pile_on"))


func test_simultaneous_pilers_hit_before_the_pikeman_grows_them() -> void:
	Kit.wall(game, p, 0, 1, 100)
	CoreKit.put(game, p, "needle-pikeman", 1)
	CoreKit.put(game, p, "needle-page", 4)
	Kit.wall(game, q, 0, 0, 100)
	game.config.attack_limit = 1
	var combat: Combat = Kit.fight(game)
	var page: int = Kit.uid_at(combat, 0, 4)
	assert_eq(Kit.damage_by(combat, page), [4] as Array[int])
	assert_eq(p.board[4].attack(), 6)


func test_golden_sergeant_grants_two_extra_paid_cutpurse_hits() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	CoreKit.put(game, p, "shrew-cutpurse", 1)
	Kit.golden(game, p, "drill-sergeant", 2)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "hit", "uid", Kit.uid_at(combat, 0, 1)).size(), 3)
	assert_eq(p.gold_next_turn, 3)


func test_golden_pikeman_grows_a_mouse_with_only_granted_pile_on() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	Kit.golden(game, p, "needle-pikeman", 1)
	CoreKit.put(game, p, "drill-sergeant", 6)
	var cousin: Unit = CoreKit.put(game, p, "cousin", 5)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.where(combat, "hit", "uid", Kit.uid_at(combat, 0, 1)).size(), 5)
	assert_eq(cousin.stats.perm_attack, 5 * 4)
