extends GutTest
## One test or more for each Mouse unit and the Cousin token, proving its text through the core:
## a real fight or a real Recruit Phase action, read from the fight log or the views.
## Slots: F1-F4 are 0-3, B1-B3 are 4-6. A back slot neighbours the two front slots it sits
## between (4: 0 and 1; 5: 1 and 2; 6: 2 and 3).

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const Kit := preload("res://tests/content/mouse/mouse_kit.gd")
## Two of each, so no triple forms on a full board.
const SIX_MICE: Array[String] = [
	"needle-page",
	"needle-page",
	"hedgerow-scout",
	"hedgerow-scout",
	"shrew-cutpurse",
	"shrew-cutpurse"
]

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


func test_hedgerow_scout_summons_a_cousin_that_piles_on_in_the_same_attack() -> void:
	CoreKit.put(game, p, "hedgerow-scout", 0)
	Kit.wall(game, q, 0, 0, 100)
	var combat: Combat = Kit.fight(game)
	var scout: int = Kit.uid_at(combat, 0, 0)
	var at: int = _first_attack_by(combat, scout)
	var summoned: int = Kit.index_of(combat, "summon", {"source_uid": scout})
	assert_gt(summoned, at)
	var cousin: Dictionary = combat.events[summoned]
	assert_eq(cousin["id"], "cousin")
	assert_eq(cousin["slot"], 1, "the empty slot nearest the Scout")
	var hit: int = Kit.index_of(combat, "hit", {"uid": cousin["uid"]})
	var scout_damage: int = Kit.index_of(combat, "damage", {"source_uid": scout})
	assert_true(summoned < hit and hit < scout_damage, "summon, then pile-on, then the exchange")


func test_golden_hedgerow_scout_summons_two_cousins() -> void:
	Kit.golden(game, p, "hedgerow-scout", 0)
	Kit.wall(game, q, 0, 0, 100)
	var combat: Combat = Kit.fight(game)
	var scout: int = Kit.uid_at(combat, 0, 0)
	var at: int = _first_attack_by(combat, scout)
	var summons: Array[Dictionary] = Kit.between(combat, at, Kit.next_attack(combat, at), "summon")
	assert_eq(summons.size(), 2)


func test_cousin_is_a_two_two_mouse_token_with_pile_on() -> void:
	var card: UnitDef = game.library.get_card(&"cousin")
	assert_true(card.token, "never in the pool")
	CoreKit.put(game, p, "hedgerow-scout", 0)
	Kit.wall(game, q, 0, 0, 100)
	var combat: Combat = Kit.fight(game)
	var made: Dictionary = Kit.where(combat, "summon", "id", "cousin")[0]
	assert_eq([made["attack"], made["health"]], [2, 2])
	var keywords: Array = made["keywords"]
	assert_true(keywords.has("mouse_pile_on"))
	assert_true(card.has_tribe("Mouse"))


# --- Tier 2 -------------------------------------------------------------------------------------


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


func test_whetstone_vole_sharpens_its_slot_at_the_end_of_the_turn() -> void:
	CoreKit.put(game, p, "whetstone-vole", 2)
	Kit.golden(game, p, "whetstone-vole", 5)
	assert_eq(Kit.end_turn(game), "")
	var slots: Array = p.view()["slots"]
	assert_eq(slots[2]["attack"], 3)
	assert_eq(slots[2]["health"], 0, "Attack only")
	assert_eq(slots[5]["attack"], 6, "golden +6")
	assert_eq(slots[1]["attack"], 0)


func test_shrew_cutpurse_earns_one_gold_the_first_time_it_piles_on() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	CoreKit.put(game, p, "shrew-cutpurse", 1)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var cutpurse: int = Kit.uid_at(combat, 0, 1)
	assert_gt(Kit.where(combat, "hit", "uid", cutpurse).size(), 1, "it piled on many times")
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
	assert_eq(hits.size(), 1, "the Cousin next to the attacker piles on in this attack")
	assert_eq(hits[0]["uid"], summons[0]["uid"])
	var own: int = _first_attack_by(combat, captain)
	assert_gt(own, -1, "the Captain attacks too")
	var after_own: Array[Dictionary] = Kit.between(
		combat, own, Kit.next_attack(combat, own), "summon"
	)
	assert_eq(after_own.size(), 0, "not on its own attacks")


func test_golden_thimble_captain_summons_two_cousins() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	Kit.golden(game, p, "thimble-captain", 1)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var at: int = _first_attack_by(combat, Kit.uid_at(combat, 0, 0))
	var summons: Array[Dictionary] = Kit.between(combat, at, Kit.next_attack(combat, at), "summon")
	assert_eq(summons.size(), 2)


func test_needle_pikeman_never_attacks_and_grows_after_each_pile_on_five_a_fight() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	var pikeman: Unit = CoreKit.put(game, p, "needle-pikeman", 1)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var uid: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.where(combat, "attack", "uid", uid).size(), 0, "can't attack")
	var dealt: Array[int] = Kit.damage_by(combat, uid)
	assert_eq(
		dealt.slice(0, 7), [4, 7, 10, 13, 16, 19, 19] as Array[int], "the gain follows the hit"
	)
	var gains: Array[Dictionary] = Kit.where(combat, "buff", "source_uid", uid)
	assert_eq(gains.size(), 5)
	assert_true(gains.all(func(e: Dictionary) -> bool: return e["permanent"]))
	assert_eq(pikeman.view()["attack"], 19, "kept on the recruit board")
	var uses: Array[Dictionary] = Kit.where(combat, "uses", "uid", uid)
	var left: Array = uses.map(func(e: Dictionary) -> int: return e["left"])
	assert_eq(left, [4, 3, 2, 1, 0], "the screen sees the gains left this fight")
	assert_true(uses.all(func(e: Dictionary) -> bool: return e["key"] == "mouse_pikeman_gains"))


func test_golden_needle_pikeman_gains_six_still_five_times() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	var pikeman: Unit = Kit.golden(game, p, "needle-pikeman", 1)
	Kit.wall(game, q, 0, 0, 100000)
	Kit.fight(game)
	assert_eq(pikeman.view()["attack"], 8 + 5 * 6)


func test_needle_pikeman_hits_when_it_is_attacked_back() -> void:
	CoreKit.put(game, p, "needle-pikeman", 0)
	Kit.wall(game, q, 0, 1, 100)
	var combat: Combat = Kit.fight(game)
	var pikeman: int = Kit.uid_at(combat, 0, 0)
	assert_eq(Kit.where(combat, "attack", "uid", pikeman).size(), 0)
	assert_gt(Kit.damage_by(combat, pikeman).size(), 0, "it still deals its Attack back")


func test_toothpick_ballista_hits_the_enemy_with_the_least_health_at_the_start() -> void:
	CoreKit.put(game, p, "toothpick-ballista", 0)
	Kit.wall(game, q, 0, 0, 20)
	Kit.wall(game, q, 1, 0, 5)
	Kit.wall(game, q, 4, 0, 9)
	var combat: Combat = Kit.fight(game)
	var ballista: int = Kit.uid_at(combat, 0, 0)
	var hit: int = Kit.index_of(combat, "hit", {"uid": ballista})
	assert_lt(hit, Kit.index_of(combat, "attack"), "before anyone attacks")
	assert_eq(combat.events[hit]["target_slot"], 1)
	assert_eq(Kit.damage_by(combat, ballista)[0], 8)
	assert_gt(_first_attack_by(combat, ballista), hit, "it attacks as normal afterwards")


func test_golden_toothpick_ballista_hits_twice_choosing_again() -> void:
	Kit.golden(game, p, "toothpick-ballista", 0)
	Kit.wall(game, q, 0, 0, 40)
	Kit.wall(game, q, 1, 0, 5)
	Kit.wall(game, q, 4, 0, 9)
	var combat: Combat = Kit.fight(game)
	var ballista: int = Kit.uid_at(combat, 0, 0)
	var hits: Array[Dictionary] = Kit.between(combat, 0, Kit.index_of(combat, "attack"), "hit")
	assert_eq(hits.map(func(e: Dictionary) -> int: return e["target_slot"]), [1, 4])
	assert_true(hits.all(func(e: Dictionary) -> bool: return e["uid"] == ballista))


func test_shrew_harrier_attacks_twice_back_to_back() -> void:
	CoreKit.put(game, p, "shrew-harrier", 0)
	Kit.wall(game, p, 4, 0, 50)
	Kit.wall(game, q, 0, 1, 100)
	var combat: Combat = Kit.fight(game)
	var attacks: Array[Dictionary] = CoreKit.events_of(combat, "attack")
	var harrier: int = Kit.uid_at(combat, 0, 0)
	assert_eq([attacks[0]["uid"], attacks[1]["uid"]], [harrier, harrier])
	assert_eq(attacks[2]["side"], 1)


# --- Tier 4 -------------------------------------------------------------------------------------


func test_spoon_catapult_hits_the_weakest_instead_of_attacking() -> void:
	CoreKit.put(game, p, "spoon-catapult", 4)
	Kit.wall(game, p, 0, 0, 50)
	Kit.wall(game, p, 1, 0, 50)
	Kit.wall(game, q, 0, 0, 50)
	Kit.wall(game, q, 1, 0, 3)
	var combat: Combat = Kit.fight(game)
	var catapult: int = Kit.uid_at(combat, 0, 4)
	assert_eq(Kit.where(combat, "attack", "uid", catapult).size(), 0, "it never attacks")
	var turns: Array[Dictionary] = Kit.where(combat, "instead_of_attack", "uid", catapult)
	assert_gt(turns.size(), 0)
	var first: int = Kit.index_of(combat, "instead_of_attack", {"uid": catapult})
	var hits: Array[Dictionary] = Kit.between(combat, 0, first, "hit")
	assert_eq(hits.size(), 1, "one Hit in its turn")
	assert_eq(hits[0]["target_slot"], 1, "the least Health")
	assert_eq(Kit.damage_by(combat, catapult)[0], 12)
	assert_eq(combat.result["attacks"], turns.size(), "each turn counts toward the attack limit")


func test_golden_spoon_catapult_hits_twice_choosing_again() -> void:
	Kit.golden(game, p, "spoon-catapult", 4)
	Kit.wall(game, p, 0, 0, 500)
	Kit.wall(game, q, 0, 0, 500)
	Kit.wall(game, q, 1, 0, 3)
	Kit.wall(game, q, 2, 0, 9)
	var combat: Combat = Kit.fight(game)
	var catapult: int = Kit.uid_at(combat, 0, 4)
	var turn: int = Kit.index_of(combat, "instead_of_attack", {"uid": catapult})
	var hits: Array[Dictionary] = Kit.between(combat, 0, turn, "hit")
	assert_eq(hits.map(func(e: Dictionary) -> int: return e["target_slot"]), [1, 2])


func test_grindstone_miller_sharpens_its_slot_and_its_neighbours() -> void:
	CoreKit.put(game, p, "grindstone-miller", 1)
	assert_eq(Kit.end_turn(game), "")
	var slots: Array = p.view()["slots"]
	var attack: Array = slots.map(func(s: Dictionary) -> int: return s["attack"])
	assert_eq(attack, [2, 2, 2, 0, 2, 2, 0], "F2 and its neighbours F1, F3, B1, B2")


func test_golden_grindstone_miller_gives_four() -> void:
	Kit.golden(game, p, "grindstone-miller", 6)
	assert_eq(Kit.end_turn(game), "")
	var slots: Array = p.view()["slots"]
	var attack: Array = slots.map(func(s: Dictionary) -> int: return s["attack"])
	assert_eq(attack, [0, 0, 4, 4, 0, 4, 4], "B3 and its neighbours B2, F3, F4")


func test_dormouse_cook_feeds_a_board_full_of_mice() -> void:
	var cook: Unit = CoreKit.put(game, p, "dormouse-cook", 0)
	for slot: int in range(1, 7):
		CoreKit.put(game, p, SIX_MICE[slot - 1], slot)
	assert_eq(Kit.end_turn(game), "")
	assert_eq(cook.view()["attack"], 5)
	var others: Array[int] = []
	for slot: int in range(1, 7):
		others.append(p.board[slot].view()["attack"])
	assert_eq(others, [7, 7, 5, 5, 5, 5] as Array[int], "each Mouse +3")


func test_golden_dormouse_cook_gives_six() -> void:
	var cook: Unit = Kit.golden(game, p, "dormouse-cook", 0)
	for slot: int in range(1, 7):
		CoreKit.put(game, p, SIX_MICE[slot - 1], slot)
	assert_eq(Kit.end_turn(game), "")
	assert_eq(cook.view()["attack"], 4 + 6)
	assert_eq(p.board[1].view()["attack"], 4 + 6)


func test_dormouse_cook_does_nothing_with_a_gap_or_another_tribe() -> void:
	var cook: Unit = CoreKit.put(game, p, "dormouse-cook", 0)
	for slot: int in range(1, 6):
		CoreKit.put(game, p, SIX_MICE[slot - 1], slot)
	assert_eq(Kit.end_turn(game), "")
	assert_eq(cook.view()["attack"], 2, "one empty slot")
	var other: GameSession = Kit.session(2)
	var r: PlayerState = other.player(0)
	var cook_two: Unit = CoreKit.put(other, r, "dormouse-cook", 0)
	for slot: int in range(1, 6):
		CoreKit.put(other, r, SIX_MICE[slot - 1], slot)
	CoreKit.put(other, r, "t1_plain", 6)
	assert_eq(Kit.end_turn(other), "")
	assert_eq(cook_two.view()["attack"], 2, "one unit of another tribe")


func test_fencing_master_gives_each_mouse_three_attack_on_its_first_pile_on() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	var page: Unit = CoreKit.put(game, p, "needle-page", 1)
	var master: Unit = CoreKit.put(game, p, "fencing-master", 4)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var master_uid: int = Kit.uid_at(combat, 0, 4)
	var gifts: Array[Dictionary] = Kit.where(combat, "buff", "source_uid", master_uid)
	var to: Array = gifts.map(func(e: Dictionary) -> int: return e["uid"])
	to.sort()
	assert_eq(to, [Kit.uid_at(combat, 0, 1), master_uid], "once for each Mouse, the Master too")
	assert_eq(page.view()["attack"], 7, "permanent")
	assert_eq(master.view()["attack"], 8)


func test_golden_fencing_master_gives_six() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	var page: Unit = CoreKit.put(game, p, "needle-page", 1)
	Kit.golden(game, p, "fencing-master", 4)
	Kit.wall(game, q, 0, 0, 100000)
	Kit.fight(game)
	assert_eq(page.view()["attack"], 10)


# --- Tier 5 -------------------------------------------------------------------------------------


func test_parish_standard_bearer_gives_mice_two_attack_for_each_mouse() -> void:
	CoreKit.put(game, p, "needle-page", 0)
	CoreKit.put(game, p, "needle-page", 1)
	Kit.wall(game, p, 2, 2, 4)
	CoreKit.put(game, p, "parish-standard-bearer", 4)
	Kit.wall(game, q, 0, 0, 100)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.start_view(combat, 0, 0)["attack"], 10, "three Mice: +6")
	assert_eq(Kit.start_view(combat, 0, 4)["attack"], 12, "itself too")
	assert_eq(Kit.start_view(combat, 0, 2)["attack"], 2, "not a Mouse")


func test_golden_parish_standard_bearer_gives_four_for_each() -> void:
	CoreKit.put(game, p, "needle-page", 0)
	Kit.golden(game, p, "parish-standard-bearer", 4)
	Kit.wall(game, q, 0, 0, 100)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.start_view(combat, 0, 0)["attack"], 4 + 8, "two Mice: +8")


func test_master_of_engines_makes_the_back_row_hit_the_weakest() -> void:
	CoreKit.put(game, p, "master-of-engines", 0)
	Kit.wall(game, p, 4, 7, 50)
	Kit.wall(game, p, 5, 9, 50)
	Kit.wall(game, q, 0, 0, 6)
	Kit.wall(game, q, 1, 0, 8)
	Kit.wall(game, q, 2, 0, 20)
	var combat: Combat = Kit.fight(game)
	var hits: Array[Dictionary] = Kit.between(combat, 0, Kit.index_of(combat, "attack"), "hit")
	var who: Array = hits.map(func(e: Dictionary) -> int: return e["uid"])
	assert_eq(who, [Kit.uid_at(combat, 0, 4), Kit.uid_at(combat, 0, 5)], "B1 then B2, not F1")
	var at: Array = hits.map(func(e: Dictionary) -> int: return e["target_slot"])
	assert_eq(at, [0, 1], "least Health, choosing again")


func test_golden_master_of_engines_makes_each_hit_twice() -> void:
	Kit.golden(game, p, "master-of-engines", 0)
	Kit.wall(game, p, 4, 7, 50)
	Kit.wall(game, q, 0, 0, 6)
	Kit.wall(game, q, 1, 0, 8)
	Kit.wall(game, q, 2, 0, 20)
	var combat: Combat = Kit.fight(game)
	var hits: Array[Dictionary] = Kit.between(combat, 0, Kit.index_of(combat, "attack"), "hit")
	assert_eq(hits.map(func(e: Dictionary) -> int: return e["target_slot"]), [0, 1])
	assert_true(hits.all(func(e: Dictionary) -> bool: return e["uid"] == Kit.uid_at(combat, 0, 4)))


func test_edgewright_doubles_slot_attack_even_after_it_dies() -> void:
	CoreKit.put(game, p, "edgewright", 0)
	Kit.wall(game, p, 1, 1, 1000)
	p.slots[1].attack = 5
	Kit.wall(game, q, 0, 100, 100)
	var combat: Combat = Kit.fight(game)
	var edgewright: int = Kit.uid_at(combat, 0, 0)
	var sharp: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.start_view(combat, 0, 1)["attack"], 6, "before the fight starts")
	var died: int = Kit.index_of(combat, "death", {"uid": edgewright})
	var dealt: int = Kit.index_of(combat, "damage", {"source_uid": sharp})
	assert_true(died > -1 and died < dealt, "the Edgewright died first")
	assert_eq(combat.events[dealt]["amount"], 11, "1 + 5 doubled")
	assert_eq(p.view()["slots"][1]["attack"], 5, "the stored buff is unchanged")
	var percent: Array[Dictionary] = CoreKit.events_of(combat, "slot_percent")
	assert_eq(percent.size(), 1)
	assert_eq(percent[0]["percent"], 200)


func test_golden_edgewright_triples_and_two_do_not_stack() -> void:
	Kit.golden(game, p, "edgewright", 0)
	CoreKit.put(game, p, "edgewright", 2)
	Kit.wall(game, p, 1, 1, 1000)
	p.slots[1].attack = 5
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	var sharp: int = Kit.uid_at(combat, 0, 1)
	assert_eq(Kit.damage_by(combat, sharp)[0], 16, "1 + 5 x 3: the bigger applies")


# --- Tier 6 -------------------------------------------------------------------------------------


func test_king_speck_fills_every_empty_slot_with_cousins_before_the_pile_on() -> void:
	CoreKit.put(game, p, "king-speck", 0)
	Kit.wall(game, p, 2, 0, 1000)
	Kit.wall(game, q, 0, 0, 1000)
	var combat: Combat = Kit.fight(game)
	var king: int = Kit.uid_at(combat, 0, 0)
	var at: int = _first_attack_by(combat, king)
	var summons: Array[Dictionary] = Kit.between(combat, at, Kit.next_attack(combat, at), "summon")
	assert_eq(summons.size(), 5, "slots F2, F4, B1, B2, B3")
	var hits: Array[Dictionary] = _hits_in_attack(combat, at)
	assert_eq(hits.size(), 2, "the Cousins in F2 and B1 neighbour the King")
	var exchange: int = Kit.index_of(combat, "damage", {"source_uid": king})
	assert_gt(exchange, Kit.index_of(combat, "hit"))


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
	CoreKit.put(game, p, "toothpick-ballista", 3)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 1))[0], 8, "a Page's pile-on doubled")
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 4))[0], 16, "her own pile-on doubled")
	var ballista: int = Kit.uid_at(combat, 0, 3)
	assert_eq(Kit.damage_by(combat, ballista)[0], 8, "an engine's Hit is not a pile-on")


func test_golden_dame_bodkin_triples_pile_on_hits() -> void:
	Kit.wall(game, p, 0, 1, 100000)
	CoreKit.put(game, p, "needle-page", 1)
	Kit.golden(game, p, "dame-bodkin", 5)
	Kit.wall(game, q, 0, 0, 100000)
	var combat: Combat = Kit.fight(game)
	assert_eq(Kit.damage_by(combat, Kit.uid_at(combat, 0, 1))[0], 12, "a Page's pile-on x3")


func test_kettle_drummer_makes_the_back_row_attack_twice() -> void:
	Kit.wall(game, p, 0, 1, 1000)
	CoreKit.put(game, p, "kettle-drummer", 4)
	Kit.wall(game, q, 0, 1, 100000)
	var combat: Combat = Kit.fight(game)
	assert_eq(CoreKit.attack_slots(combat, 0).slice(0, 4), [0, 4, 4, 0] as Array[int])


func test_kettle_drummer_makes_a_spoon_catapult_hit_twice() -> void:
	CoreKit.put(game, p, "spoon-catapult", 4)
	CoreKit.put(game, p, "kettle-drummer", 5)
	Kit.wall(game, q, 0, 0, 100)
	Kit.wall(game, q, 1, 0, 100)
	Kit.wall(game, q, 2, 0, 100)
	var combat: Combat = Kit.fight(game)
	var catapult: int = Kit.uid_at(combat, 0, 4)
	var turn: int = Kit.index_of(combat, "instead_of_attack", {"uid": catapult})
	var hits: Array[Dictionary] = Kit.between(combat, 0, turn, "hit").filter(
		func(e: Dictionary) -> bool: return e["uid"] == catapult
	)
	assert_eq(hits.size(), 2, "one turn, two Hits")
