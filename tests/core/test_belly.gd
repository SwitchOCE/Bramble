# gdlint: disable=max-public-methods
extends GutTest
## Belly's rules (docs/ideation/content/oozes.md): getting in, what happens inside, getting out in
## the Recruit Phase, triples, and coming out in a fight.
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
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)
	_player.shop.clear()
	_player.gold = 10


func _swallow_from_hand(id: String, slot: int) -> RecruitUnit:
	var unit: RecruitUnit = _kit.put(id)
	assert_eq(_rules.swallow(_player, HeldUnits.HAND, _player.hand.find(unit), slot), "")
	return unit


func _logged(type: String) -> int:
	var count: int = 0
	for entry: Dictionary in _player.recruit_log:
		if entry["type"] == type:
			count += 1
	return count


func _summons(result: Dictionary) -> Array[Dictionary]:
	return KIT.of_type(result, "summon")


## A wall in the back so the enemy's blow lands on the front unit and the fight goes on.
func _hold_fight(enemy_attack: int = 50) -> Dictionary:
	return _kit.fight_board({F1: {"def_id": "pill_bug", "attack": enemy_attack, "health": 100}})


func test_a_shop_unit_goes_in_for_its_price() -> void:
	_kit.put("mrs_posset", F1)
	var bought: RecruitUnit = _kit.shop("pill_bug")
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F1), "")
	assert_eq(_player.gold, 7, "the usual 3 gold")
	assert_eq(_player.board[F1].held, [bought] as Array[RecruitUnit])
	assert_eq(_player.shop.size(), 0, "it left the shop")
	assert_eq(bought.origin, RecruitUnit.ORIGIN_BOUGHT)
	assert_eq(_player.units_bought, 1, "counted as a buy")


func test_buying_in_needs_the_gold_and_a_buy() -> void:
	_kit.put("mrs_posset", F1)
	_kit.shop("pill_bug")
	_player.gold = 2
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F1), "Not enough gold")
	assert_eq(_player.shop.size(), 1, "nothing moved")
	_player.gold = 3
	_player.rule_handlers.append({"query": "buys_per_turn", "op": "set", "value": 0})
	assert_string_contains(_rules.swallow(_player, HeldUnits.SHOP, 0, F1), "two units")


func test_buying_in_ignores_a_full_hand() -> void:
	_kit.put("mrs_posset", F1)
	_kit.shop("pill_bug")
	for _index: int in _kit.config.get_int("hand_limit"):
		_kit.put("field_vole")
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F1), "")
	assert_eq(_player.board[F1].held.size(), 1)


func test_little_dollop_takes_a_gold_off_units_bought_into_it() -> void:
	_kit.put("little_dollop", F1)
	_kit.shop("pill_bug")
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F1), "")
	assert_eq(_player.gold, 8, "3 less 1")


func test_golden_dollop_takes_2_off_and_holds_2() -> void:
	_kit.put("little_dollop", F1, true)
	_kit.shop("pill_bug")
	_kit.shop("pill_bug")
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F1), "")
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F1), "", "Belly 2")
	assert_eq(_player.gold, 8, "1 gold each")


func test_dollop_discount_is_only_for_units_bought_into_it() -> void:
	_kit.put("little_dollop", F1)
	_kit.put("mrs_posset", F2)
	_kit.shop("pill_bug")
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F2), "")
	assert_eq(_player.gold, 7, "Posset gives no discount")


func test_a_full_belly_takes_no_more() -> void:
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("pill_bug", F1)
	_kit.put("field_vole")
	assert_eq(_rules.swallow(_player, HeldUnits.HAND, 0, F1), "That Belly is full")
	assert_eq(_player.hand.size(), 1)


func test_only_a_belly_swallows() -> void:
	_kit.put("pill_bug", F1)
	_kit.put("field_vole")
	assert_eq(_rules.swallow(_player, HeldUnits.HAND, 0, F1), "That unit has no Belly")
	assert_eq(_rules.swallow(_player, HeldUnits.HAND, 0, F2), "No unit there")


func test_from_the_board_leaves_the_slot_empty() -> void:
	_kit.put("mrs_posset", F1)
	var unit: RecruitUnit = _kit.put("pill_bug", F2)
	assert_eq(_rules.swallow(_player, HeldUnits.BOARD, F2, F1), "")
	assert_null(_player.board[F2])
	assert_true(_player.board[F1].held.has(unit))


func test_a_unit_cant_swallow_itself() -> void:
	_kit.put("mrs_posset", F1)
	assert_eq(_rules.swallow(_player, HeldUnits.BOARD, F1, F1), "A unit can't swallow itself")


func test_a_holding_ooze_cant_be_swallowed_so_bellies_dont_nest() -> void:
	_kit.put("mrs_posset", F1)
	_kit.put("little_dollop", F2)
	_swallow_from_hand("pill_bug", F2)
	assert_eq(_rules.swallow(_player, HeldUnits.BOARD, F2, F1), "It's holding units of its own")
	assert_eq(_player.board[F1].held.size(), 0)


func test_an_ooze_inside_has_a_sealed_belly() -> void:
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("little_dollop", F1)
	var inner: RecruitUnit = _player.board[F1].held[0]
	assert_eq(_player.board.find(inner), -1, "not on the board, so nothing can be dropped in it")


func test_swallowing_isnt_playing() -> void:
	_kit.put("mrs_posset", F1)
	var chiff: RecruitUnit = _swallow_from_hand("chiffchaff", F1)
	assert_eq(chiff.played_round, 0)
	assert_eq(_logged("trigger"), 0, "no When played")
	assert_eq(_logged("swallow"), 1)
	assert_true(_player.bands.count(0) == BoardGeometry.SLOTS, "no band painted")


func test_units_inside_have_their_text_off() -> void:
	_kit.card(
		"payer", [KIT.effect("end_of_turn", {"effect": "gold", "amount": 1, "when": "next_turn"})]
	)
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("payer", F1)
	_rules.end_phase(_player)
	assert_eq(_player.gold_next_turn, 0, "its End of Turn stays off inside")
	var inside: RecruitUnit = _player.board[F1].held[0]
	assert_eq(inside.turns_in_slot, 0, "it doesn't count turns inside")


func test_inside_a_ring_gives_nothing() -> void:
	_kit.put("mrs_posset", F1)
	_player.slot_effects[F2] = [{"name": "Ring", "attack": 3, "health": 3}]
	var unit: RecruitUnit = _kit.put("pill_bug", F2)
	_rules.board_changed(_player)
	assert_eq(unit.aura_attack, 3)
	assert_eq(_rules.swallow(_player, HeldUnits.BOARD, F2, F1), "")
	assert_eq(unit.aura_attack, 0, "the Ring stays on the slot")


func test_selling_an_ooze_sends_what_is_inside_to_hand_and_pays_only_its_own_value() -> void:
	var ooze: RecruitUnit = _kit.put("mrs_posset", F1)
	ooze.origin = RecruitUnit.ORIGIN_BOUGHT
	var unit: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	var gold: int = _player.gold
	assert_eq(_rules.sell(_player, F1), "")
	assert_eq(_player.gold, gold + 1, "only the Ooze's own sale")
	assert_true(_player.hand.has(unit))


func test_selling_an_ooze_on_a_full_hand_leaves_the_rest_on_the_doorstep() -> void:
	_kit.put("sixpenny_pie", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	for _index: int in _kit.config.get_int("hand_limit"):
		_kit.put("field_vole")
	assert_eq(_rules.sell(_player, F1), "")
	assert_true(_player.doorstep.has(inner), "nothing lost")
	assert_false(_player.hand.has(inner))
	assert_eq(_rules.sell(_player, F1), "No unit there")
	assert_eq(_rules.play(_player, 0, F2), "")
	assert_true(_player.hand.has(inner), "room came, in it came")
	assert_eq(_player.doorstep.size(), 0)


func test_a_destroyed_ooze_gives_up_what_is_inside() -> void:
	var ooze: RecruitUnit = _kit.put("mrs_posset", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	_rules.destroy_unit(_player, ooze)
	assert_true(_player.hand.has(inner))


func test_a_shy_ooze_gives_up_what_is_inside_when_it_leaves() -> void:
	_kit.card("shy_pudding", [{"id": "belly", "size": 1}, {"id": "shy", "gold": 2}], ["Oozes"])
	var ooze: RecruitUnit = _kit.put("shy_pudding", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	_rules.board_changed(_player)
	ooze.add_permanent(1, 1)
	_rules.board_changed(_player)
	assert_null(_player.board[F1], "it left")
	assert_true(_player.hand.has(inner))


func test_copies_inside_count_for_triples_and_the_golden_goes_to_hand() -> void:
	_kit.put("mrs_posset", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	_kit.put("pill_bug", F2)
	var third: RecruitUnit = _kit.put("pill_bug")
	_rules.check_triples(_player)
	assert_eq(_player.board[F1].held.size(), 0, "the copy left the Belly")
	assert_false(_player.hand.has(third))
	assert_null(_player.board[F2])
	assert_eq(_player.hand.size(), 1)
	assert_true(_player.hand[0].golden)
	assert_ne(_player.hand[0], inner)


func test_a_lost_timer_inside_is_logged() -> void:
	_kit.put("mrs_posset", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	inner.timers.append({"turns": 2, "left": 2, "attack": 1, "health": 1})
	_kit.put("pill_bug", F2)
	_kit.put("pill_bug")
	_rules.check_triples(_player)
	assert_eq(_logged("timer_lost"), 1)


func test_a_tripled_oozes_contents_go_to_hand() -> void:
	_kit.put("mrs_posset", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	_kit.put("mrs_posset", F2)
	_kit.put("mrs_posset")
	_rules.check_triples(_player)
	assert_true(_player.hand.has(inner))
	assert_true(_player.owned_units().has(inner))


func test_elimination_returns_copies_inside() -> void:
	var left: int = _kit.pool.copies_left("pill_bug")
	_kit.put("mrs_posset", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	assert_true(_kit.pool.take("pill_bug"))
	inner.pool_copies = 1
	_rules.return_everything(_player)
	assert_eq(_kit.pool.copies_left("pill_bug"), left, "the copy came back")


func test_a_buff_after_the_fight_reaches_a_unit_inside_by_its_iid() -> void:
	_kit.put("mrs_posset", F1)
	var inner: RecruitUnit = _swallow_from_hand("pill_bug", F1)
	var before: int = inner.attack
	_rules.apply_carry(_player, {"op": "buff", "iid": inner.iid, "attack": 2, "health": 0})
	assert_eq(inner.attack, before + 2)


func test_scouts_and_screens_see_what_is_inside() -> void:
	var ooze: RecruitUnit = _kit.put("mrs_posset", F1)
	_swallow_from_hand("pill_bug", F1)
	var view: Dictionary = ooze.view()
	assert_eq(view["belly"], 1)
	var held: Array = view["held"]
	assert_eq(str(held[0]["def_id"]), "pill_bug")


# --- In a fight ---------------------------------------------------------------------------------


func test_when_an_ooze_dies_what_is_inside_comes_out_in_its_slot() -> void:
	_kit.put("mrs_posset", F2)
	_swallow_from_hand("pill_bug", F2)
	_kit.put("sett_warden", B3)
	var result: Dictionary = _hold_fight()
	var outs: Array[Dictionary] = _summons(result)
	assert_eq(outs[0]["slot"], F2, "the Ooze's slot")
	assert_true(outs[0]["came_out"])
	assert_eq(str(outs[0]["unit"]["def_id"]), "pill_bug")


func test_last_in_comes_out_first_and_the_rest_take_the_nearest_gap() -> void:
	_kit.put("sixpenny_pie", F2)
	_swallow_from_hand("pill_bug", F2)
	_swallow_from_hand("field_vole", F2)
	_swallow_from_hand("marsh_frog", F2)
	var result: Dictionary = _hold_fight()
	var outs: Array[Dictionary] = _summons(result)
	assert_eq(str(outs[0]["unit"]["def_id"]), "marsh_frog", "last in")
	assert_eq(outs[0]["slot"], F2)
	assert_eq(str(outs[1]["unit"]["def_id"]), "field_vole")
	assert_eq(outs[1]["slot"], BoardGeometry.summon_slot(_occupied_only(F2), F2, false))


func _occupied_only(slot: int) -> Array[bool]:
	var out: Array[bool] = [false, false, false, false, false, false, false]
	out[slot] = true
	return out


func test_with_no_room_a_unit_is_lost_for_the_fight_but_comes_back_afterwards() -> void:
	_kit.put("sixpenny_pie", F1)
	_swallow_from_hand("pill_bug", F1)
	_swallow_from_hand("field_vole", F1)
	for slot: int in [F2, F3, F4, B1, B2, B3]:
		_kit.put("sett_warden", slot)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 3, "health": 100}}
	)
	assert_gt(KIT.of_type(result, "no_room").size(), 0, "the second had no gap")
	assert_eq(_player.board[F1].held.size(), 2, "fights run on a copy: both still inside")


func test_units_inside_dont_fight_or_get_hit_until_out() -> void:
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("pill_bug", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 1, "health": 9}}
	)
	var start: Dictionary = KIT.of_type(result, "combat_start")[0]
	var mine: Array = start["boards"][0]
	assert_eq(str(mine[F1]["def_id"]), "mrs_posset")
	assert_null(mine[F2])
	assert_eq(mine[F1]["held"], 1, "shown as a pip")


func test_units_still_inside_at_the_end_dont_count_for_damage() -> void:
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("old_mother_mast", F1)
	_player.board[F1].add_permanent(50, 50)
	_player.tier = 6
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 0, "health": 1}}
	)
	assert_eq(result["winner"], 0)
	# v05 ignores tier: R1 base 1 + the one starting Posset; its Belly is off the board.
	assert_eq(result["damage"], 2, "round base plus one own starting survivor")
	assert_eq(result["damage_performance"], 1)


func test_all_first_outs_land_before_any_second_out() -> void:
	_kit.put("sixpenny_pie", F1)
	_swallow_from_hand("pill_bug", F1)
	_swallow_from_hand("field_vole", F1)
	var other: RecruitUnit = _kit.put("mrs_posset", F4)
	other.add_permanent(0, 0)
	_swallow_from_hand("marsh_frog", F4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var combat := Combat.create(_kit.library, _kit.config, rng)
	var f1: CombatUnit = CombatUnit.make(
		_kit.library.get_unit("sixpenny_pie"), _player.board[F1].combat_spec(), 91, 0
	)
	f1.slot = F1
	var f4: CombatUnit = CombatUnit.make(
		_kit.library.get_unit("mrs_posset"), _player.board[F4].combat_spec(), 92, 0
	)
	f4.slot = F4
	combat._setup([[], []])
	var dying: Array[CombatUnit] = [f1, f4]
	CombatHeld.open_bellies(combat, dying)
	var order: Array = []
	for event: Dictionary in combat.events:
		if event["type"] == "summon":
			order.append(str(event["unit"]["def_id"]))
	assert_eq(order, ["field_vole", "marsh_frog", "pill_bug"])


func test_a_unit_coming_out_counts_as_a_summon_for_listeners() -> void:
	_kit.card(
		"listener",
		[
			KIT.effect(
				"on_summon", {"effect": "gold", "amount": 1, "when": "next_turn"}, {"name": "heard"}
			)
		]
	)
	_kit.put("listener", F4)
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("pill_bug", F1)
	var gold_before: int = _player.gold_next_turn
	_hold_fight()
	assert_eq(_player.gold_next_turn, gold_before + 1, "the listener heard it")


func test_a_unit_coming_out_can_attack_if_its_turn_is_coming() -> void:
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("field_vole", F1)
	_kit.put("sett_warden", F2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 1, "health": 200}}
	)
	var out_uid: int = _summons(result)[0]["unit"]["uid"]
	var attacked: bool = false
	for event: Dictionary in KIT.of_type(result, "attack"):
		attacked = attacked or event["attacker"] == out_uid
	assert_true(attacked, "it took its place in the order")


func test_start_of_combat_text_doesnt_fire_when_coming_out() -> void:
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("hedge_witch", F1)
	var result: Dictionary = _hold_fight()
	assert_eq(KIT.of_type(result, "slot_hex").size(), 0)


func test_an_iid_inside_gets_a_permanent_buff_from_the_fight() -> void:
	_kit.card(
		"grower",
		[
			KIT.effect(
				"on_summon",
				{"effect": "buff", "attack": 1, "duration": "permanent"},
				{"subject": "self"}
			)
		]
	)
	_kit.put("mrs_posset", F1)
	var inner: RecruitUnit = _swallow_from_hand("grower", F1)
	var attack: int = inner.attack
	_hold_fight()
	assert_eq(inner.attack, attack + 1, "the fight's copy carried it home")


func test_search_fights_dont_use_up_a_spec() -> void:
	_kit.put("mrs_posset", F1)
	_swallow_from_hand("pill_bug", F1)
	var spec: Dictionary = _player.board[F1].combat_spec()
	var fighter := CombatUnit.make(_kit.library.get_unit("mrs_posset"), spec, 1, 0)
	fighter.held_specs.pop_back()
	var held: Array = spec["held"]
	assert_eq(held.size(), 1, "the spec's list isn't the fighter's")
