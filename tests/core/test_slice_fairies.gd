# gdlint:disable=max-public-methods
extends GutTest
## Frozen pass 2 design regression; current pool rules are tested in test_pass3_*.
## The slice's Fairies (docs/ideation/content/SLICE.md, fairies.md): each card's text.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const F1: int = 0
const F2: int = 1
const F3: int = 2
const F4: int = 3
const B1: int = 4
const B2: int = 5
const B3: int = 6

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game(), true)
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)


func _ring(slot: int) -> Dictionary:
	var effects: Array = _player.slot_effects[slot]
	return {} if effects.is_empty() else effects[0]


func test_nan_toadstool_rings_this_slot_and_stands_on_it() -> void:
	var nan: RecruitUnit = _kit.play("nan_toadstool", F1)
	assert_eq(_ring(F1)["attack"], 1)
	assert_eq(nan.attack, 3, "2 and the Ring")
	assert_eq(nan.health, 2)


func test_nan_toadstool_golden_rings_plus_two() -> void:
	var nan: RecruitUnit = _kit.play("nan_toadstool", F1, true)
	assert_eq(_ring(F1)["attack"], 2)
	assert_eq(nan.attack, 4 + 2)


func test_sally_spore_rings_the_empty_slot_nearest_this_at_end_of_turn() -> void:
	_kit.put("sally_spore", F1)
	_rules.end_phase(_player)
	assert_eq(_ring(F2)["attack"], 1, "8.4.2 tries F2 first from F1")


func test_sally_spore_stacks_on_the_same_slot_and_golden_doubles() -> void:
	_kit.put("sally_spore", F1, true)
	_kit.pass_turn()
	_rules.end_phase(_player)
	assert_eq(_ring(F2)["attack"], 4, "two End of Turns at +2")
	var effects: Array = _player.slot_effects[F2]
	assert_eq(effects.size(), 1, "one Ring, stacked")


func test_sally_spore_with_a_full_board_does_nothing() -> void:
	for slot: int in BoardGeometry.SLOTS:
		_kit.put("sally_spore" if slot == F1 else "pill_bug", slot)
	_rules.end_phase(_player)
	for slot: int in BoardGeometry.SLOTS:
		assert_true(_ring(slot).is_empty(), "no slot Ringed")


## What each summoned unit's Attack settles at, by slot: it arrives, then its slot's Ring lands.
func _summoned_attack(result: Dictionary) -> Dictionary:
	var by_uid: Dictionary = {}
	var out: Dictionary = {}
	for event: Dictionary in result["events"]:
		if event["type"] == "summon":
			by_uid[event["unit"]["uid"]] = event["slot"]
			out[event["slot"]] = event["unit"]["attack"]
		elif event["type"] == "stats" and by_uid.has(event["target"]):
			out[by_uid[event["target"]]] = event["attack"]
			by_uid.erase(event["target"])
	return out


func test_will_o_the_wisp_fills_each_empty_ring() -> void:
	_kit.put("will_o_the_wisp", B1)
	assert_eq(_kit.cast("spore_cloud", F3), "")
	assert_eq(_kit.cast("spore_cloud", F4), "")
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var wisps: Dictionary = _summoned_attack(result)
	assert_eq(wisps.size(), 2)
	assert_eq(wisps[F3], 3, "1 and the Ring's 2")


func test_will_o_the_wisp_golden_makes_2_2_wisps() -> void:
	_kit.put("will_o_the_wisp", B1, true)
	_kit.cast("spore_cloud", F3)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	assert_eq(_summoned_attack(result)[F3], 4, "2 and the Ring's 2")


func test_hedge_witch_lowers_the_enemy_across_by_one() -> void:
	_kit.put("hedge_witch", F2)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 3, "health": 50}}
	)
	var hexes: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "slot_hex":
			hexes.append(event)
	assert_eq(hexes.size(), 1)
	assert_eq(hexes[0]["slot"], F2, "across is the same slot")
	assert_eq(hexes[0]["total"], 1)


func test_hedge_witch_each_spell_adds_one_golden_two() -> void:
	var witch: RecruitUnit = _kit.put("hedge_witch", F1)
	var golden: RecruitUnit = _kit.put("hedge_witch", F2, true)
	_kit.cast("pinch_of_dust", F1)
	assert_eq(witch.counters["hex"], 1)
	assert_eq(golden.counters["hex"], 2)
	var result: Dictionary = _kit.fight_board({F1: "pill_bug", F2: "pill_bug"})
	var totals: Dictionary = {}
	for event: Dictionary in result["events"]:
		if event["type"] == "slot_hex":
			totals[event["slot"]] = event["total"]
	assert_eq(totals[F1], 1, "1 and 1, capped at tier")
	assert_eq(totals[F2], 3, "2 and 2, capped at tier + 2")


func test_hedge_witch_triple_keeps_what_spells_added() -> void:
	var witches: Array = [
		_kit.put("hedge_witch", F1), _kit.put("hedge_witch", F2), _kit.put("hedge_witch", F3)
	]
	witches[0].counters["hex"] = 2
	witches[1].counters["hex"] = 1
	_rules.check_triples(_player)
	var golden: RecruitUnit = _player.hand[0] if not _player.hand.is_empty() else _player.board[F1]
	assert_true(golden.golden)
	assert_eq(golden.counters["hex"], 3)


func test_hob_in_the_hearth_gives_the_units_in_front_health_at_end_of_turn() -> void:
	_kit.put("hob_in_the_hearth", B1)
	var front: RecruitUnit = _kit.put("pill_bug", F1)
	_rules.end_phase(_player)
	assert_eq(front.health, 5)


func test_hob_in_the_hearth_leaves_when_given_stats_paying_2() -> void:
	_kit.put("hob_in_the_hearth", B1)
	_player.gold_next_turn = 0
	assert_eq(_kit.cast("pinch_of_dust", B1), "")
	assert_null(_player.board[B1], "gone")
	assert_eq(_player.gold_next_turn, 2)


func test_hob_in_the_hearth_golden_pays_4_and_gives_2() -> void:
	_kit.put("hob_in_the_hearth", B1, true)
	var front: RecruitUnit = _kit.put("pill_bug", F1)
	_rules.end_phase(_player)
	assert_eq(front.health, 6)
	_player.gold_next_turn = 0
	_kit.cast("pinch_of_dust", B1)
	assert_eq(_player.gold_next_turn, 4)


func test_old_moth_annis_gives_the_units_behind_attack_at_end_of_turn() -> void:
	_kit.put("old_moth_annis", F2)
	var left: RecruitUnit = _kit.put("pill_bug", B1)
	var right: RecruitUnit = _kit.put("pill_bug", B2)
	_rules.end_phase(_player)
	assert_eq(left.attack, 2)
	assert_eq(right.attack, 2)


func test_old_moth_annis_and_hob_the_owners_puzzle() -> void:
	var moth: RecruitUnit = _kit.put("old_moth_annis", F1)
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", B1)
	_rules.end_phase(_player)
	assert_eq(_player.board[B1], hob, "Shy ignores Moth's incidental buff")
	assert_eq(Vector2i(hob.attack, hob.health), Vector2i(1, 3))
	assert_eq(moth.health, 3, "Hob still grows the unit in front")
	assert_eq(_player.gold_next_turn, 0)


func test_old_moth_annis_golden_gives_plus_two() -> void:
	_kit.put("old_moth_annis", F1, true)
	var behind: RecruitUnit = _kit.put("pill_bug", B1)
	_rules.end_phase(_player)
	assert_eq(behind.attack, 3)


func test_rainbow_chaser_sold_pays_per_band_then_washes() -> void:
	_kit.play("rainbow_chaser", F1)
	_kit.play("pill_bug", F2)
	_kit.play("pill_bug", F3)
	assert_eq(_player.band_count(), 3)
	_player.gold = 0
	_rules.sell(_player, F2)
	assert_eq(_player.band_count(), 2, "selling a painter fades its band")
	_kit.play("pill_bug", F2)
	assert_eq(_player.band_count(), 3)
	_player.gold = 0
	_rules.sell(_player, F1)
	assert_eq(_player.gold, 1, "one pair; a Created unit sells for 0")
	assert_eq(_player.band_count(), 0, "washed")


func test_rainbow_chaser_golden_all_seven_pays_double() -> void:
	_kit.play("rainbow_chaser", F1, true)
	for slot: int in [F2, F3, F4, B1, B2, B3]:
		_kit.play("pill_bug", slot)
	assert_eq(_player.band_count(), 7)
	_player.gold = 0
	_rules.sell(_player, F1)
	assert_eq(_player.gold, 10, "6 for three pairs and 4 for all seven, including its own band")


func test_belladonna_gives_the_two_front_enemies_facing_it_nightshade() -> void:
	_kit.put("belladonna", B2)
	var result: Dictionary = _kit.fight_board(
		{F1: "pill_bug", F2: "pill_bug", F3: "pill_bug", F4: "pill_bug"}
	)
	var on: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "status" and event["status"] == "nightshade" and event["on"]:
			on.append(event["target"])
	assert_eq(on.size(), 2, "F2 and F3 face B2")


func test_belladonna_golden_also_hits_the_enemy_across() -> void:
	_kit.put("belladonna", B2, true)
	var result: Dictionary = _kit.fight_board({F2: "pill_bug", F3: "pill_bug", B2: "pill_bug"})
	var on: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "status" and event["status"] == "nightshade" and event["on"]:
			on.append(event["target"])
	assert_eq(on.size(), 3)


func test_queen_of_elfland_every_3rd_end_of_turn_takes_the_units_behind() -> void:
	_kit.put("queen_of_elfland", F1)
	_kit.put("field_vole", B1)
	var behind: RecruitUnit = _player.board[B1]
	var total_attack: int = behind.attack
	var total_health: int = behind.health
	var a: RecruitUnit = _kit.put("wisp", F2)
	var b: RecruitUnit = _kit.put("wisp", F3)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_not_null(_player.board[B1], "not yet")
	_rules.end_phase(_player)
	assert_null(_player.board[B1], "the third")
	assert_eq(
		a.attack + b.attack,
		2 * a.base_attack_now() + total_attack,
		"what it had goes to the others"
	)
	assert_eq(a.health + b.health, 2 * a.base_health_now() + total_health)


func test_queen_of_elfland_takes_herself_if_none_behind() -> void:
	_kit.put("queen_of_elfland", F1)
	var other: RecruitUnit = _kit.put("wisp", F2)
	for _turn: int in 3:
		_rules.end_phase(_player)
	assert_null(_player.board[F1], "she goes")
	assert_eq(other.attack, other.base_attack_now() + 8, "and her stats split")
	assert_eq(other.health, other.base_health_now() + 8)


func test_queen_of_elfland_golden_splits_double() -> void:
	_kit.put("queen_of_elfland", F1, true)
	_kit.put("field_vole", B1)
	var behind: RecruitUnit = _player.board[B1]
	var attack: int = behind.attack
	var other: RecruitUnit = _kit.put("wisp", F2)
	for _turn: int in 3:
		_rules.end_phase(_player)
	assert_eq(other.attack, other.base_attack_now() + attack * 2)
	assert_not_null(_player.board[F1], "she stays: someone stood behind her")


func test_queen_pools_only_printed_stats_and_permanent_buffs() -> void:
	for golden: bool in [false, true]:
		var kit: KIT = KIT.new()
		kit.setup(GameConfig.full_game())
		var queen: RecruitUnit = kit.put("queen_of_elfland", F1, golden)
		var victim: RecruitUnit = kit.put("wisp", B1)
		var first: RecruitUnit = kit.put("wisp", F2)
		var second: RecruitUnit = kit.put("fairy_monarch", F3)
		victim.add_permanent(2, 4)
		victim.add_combat(5, 6)
		kit.player.tribe_bonuses = {"Fairies": 3}
		BoardUpkeep.add_ring(kit.player, B1, {"attack": 7, "health": 9})
		kit.rules.board_changed(kit.player)
		assert_eq(
			victim.attack, 16, "printed 1 + permanent 2 + tribe 3 + Ring 4 + Monarch 1 + combat 5"
		)
		assert_eq(
			victim.health, 19, "printed 1 + permanent 4 + tribe 3 + Ring 4 + Monarch 1 + combat 6"
		)
		queen.counters["teind"] = 2
		kit.rules.end_phase(kit.player)
		var factor: int = 2 if golden else 1
		assert_eq(
			first.perm_attack + second.perm_attack, 3 * factor, "only printed 1 + permanent 2"
		)
		assert_eq(
			first.perm_health + second.perm_health, 5 * factor, "only printed 1 + permanent 4"
		)
		assert_eq(first.tribe_attack, 3, "the recipients retain their separate owner bonus")
		assert_null(kit.player.board[B1])
