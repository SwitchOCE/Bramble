# gdlint:disable=max-public-methods
extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const K := preload("res://tests/core/recruit_kit.gd")
const C := preload("res://tests/core/combat_kit.gd")
const View := preload("res://src/ui/screens/recruit_view.gd")
var _kit: K


func before_each() -> void:
	_kit = K.new()
	_kit.setup(GameConfig.full_game(), true)
	_kit.rules.start_phase(_kit.player, 1)


func test_chaser_seven_slots_caps_body_and_halves_sale_for_both_sizes() -> void:
	for golden: bool in [false, true]:
		var kit := K.new()
		kit.setup(GameConfig.full_game(), true)
		var chaser: RecruitUnit = kit.play("rainbow_chaser", 0, golden)
		for slot: int in range(1, 7):
			kit.play("pill_bug", slot)
		assert_eq([chaser.attack, chaser.health], [8, 10] if golden else [4, 5])
		kit.player.gold = 0
		assert_eq(kit.rules.sell(kit.player, 0), "")
		assert_eq(kit.player.gold, 10 if golden else 5)
		assert_eq(kit.player.band_count(), 0)


func test_ring_spell_loses_overflow_and_full_target_does_not_spend_card() -> void:
	BoardUpkeep.add_ring(_kit.player, 0, {"attack": 3, "health": 3})
	assert_eq(_kit.cast("spore_cloud", 0), "")
	assert_eq(BoardUpkeep.ring_stats(_kit.player.slot_effects[0]), Vector2i(4, 4))
	_kit.rules.give_card(_kit.player, "spore_cloud")
	var item: HandItem = _kit.player.items[0]
	assert_ne(_kit.rules.item_aim_problem(_kit.player, item, 0), "")
	assert_ne(_kit.rules.play_item(_kit.player, 0, 0), "")
	assert_eq(_kit.player.items.size(), 1, "rejected aim retains the spell")
	assert_eq(_kit.rules.play_item(_kit.player, 0, 1), "")


func test_ring_preview_reports_partial_loss_and_full_slots() -> void:
	var marks: Array = []
	for slot: int in BoardGeometry.SLOTS:
		marks.append([])
	var cap: int = BoardUpkeep.RING_CAP
	marks[0] = [{"name": "Ring", "attack": cap - 1, "health": cap - 1}]
	marks[1] = [{"name": "Ring", "attack": cap, "health": cap}]
	var state: Dictionary = {"slot_effects": marks}
	var item: Dictionary = {"aim": "any_slot", "ring_add": [2, 2]}
	assert_eq(View.ring_preview(state, item, 0), "+1/+1, 1 lost")
	assert_eq(View.ring_preview(state, item, 1), "Full")
	assert_false(View.item_lands(item, {}, 1, state))
	assert_true(View.item_lands(item, {}, 0, state))
	assert_true(
		View.item_lands({"aim": "any_slot"}, {}, 1, state), "other slot spells remain legal"
	)


func test_sally_skips_nearest_empty_slot_when_its_ring_is_full() -> void:
	_kit.put("sally_spore", 0)
	BoardUpkeep.add_ring(_kit.player, 1, {"attack": 4, "health": 4})
	_kit.rules.end_phase(_kit.player)
	assert_eq(BoardUpkeep.ring_stats(_kit.player.slot_effects[1]), Vector2i(4, 4))
	assert_eq(BoardUpkeep.ring_stats(_kit.player.slot_effects[2]), Vector2i(1, 1))


func test_monarch_adds_above_the_recruit_ring_cap() -> void:
	var fairy: RecruitUnit = _kit.put("wisp", 0)
	_kit.put("fairy_monarch", 1)
	BoardUpkeep.add_ring(_kit.player, 0, {"attack": 9, "health": 9})
	_kit.rules.board_changed(_kit.player)
	assert_eq(BoardUpkeep.ring_stats(_kit.player.slot_effects[0]), Vector2i(4, 4))
	assert_eq([fairy.attack, fairy.health], [6, 6], "base + capped Ring + Monarch")


func test_hex_banks_spells_and_tiering_releases_them_for_plain_and_golden() -> void:
	for golden: bool in [false, true]:
		var witch: RecruitUnit = _kit.put("hedge_witch", 0, golden)
		witch.counters["hex"] = 12
		_kit.rules.board_changed(_kit.player)
		var low_cap: int = 3 if golden else 1
		assert_eq(witch.view()["hex_amount"], low_cap)
		var stored: int = 14 if golden else 13
		assert_eq(witch.view()["hex_stored"], stored)
		assert_eq(View.tile_slip(witch.view()), "Hex %d (%d stored)" % [low_cap, stored])
		_kit.player.tier = 6
		_kit.rules.board_changed(_kit.player)
		var high_cap: int = 8 if golden else 6
		assert_eq(witch.view()["hex_amount"], high_cap)
		var result: Dictionary = _kit.fight_board({0: C.plain(30, 100)})
		assert_eq(C.of_type(result, "slot_hex")[0]["amount"], high_cap)
		_kit.player.tier = 1


func test_busker_refunds_only_first_spell_immediately_and_resets_next_turn() -> void:
	for golden: bool in [false, true]:
		_kit.player.board.fill(null)
		_kit.put("cricket_busker", 0, golden)
		_kit.player.gold = 0
		assert_eq(_kit.cast("pinch_of_dust", 0), "")
		var refund: int = 2 if golden else 1
		assert_eq(_kit.player.gold, refund)
		assert_eq(_kit.player.gold_next_turn, 0)
		assert_eq(_kit.cast("pinch_of_dust", 0), "")
		assert_eq(_kit.player.gold, refund)
		_kit.pass_turn()
		_kit.player.gold = 0
		assert_eq(_kit.cast("pinch_of_dust", 0), "")
		assert_eq(_kit.player.gold, refund)


func test_snail_golden_health_and_sale_growth_stop_after_three_board_turns() -> void:
	var snail: RecruitUnit = _kit.put("pennywort_snail", 0, true)
	snail.origin = RecruitUnit.ORIGIN_BOUGHT
	for turn: int in range(1, 6):
		_kit.pass_turn()
		assert_eq(snail.health, 6 + 2 * mini(turn, 3))
		assert_eq(_kit.rules.sell_value(snail, _kit.player), 1 + 2 * mini(turn, 3))


func test_bracken_scales_with_tier_caps_at_five_and_stops_at_six_units() -> void:
	HeroRules.assign(_kit.player, _kit.library.get_hero("brother_bracken"))
	for tier: int in [1, 3, 6]:
		for count: int in [5, 6, 7]:
			_kit.player.board.fill(null)
			_kit.player.tier = tier
			for slot: int in count:
				_kit.put("pill_bug", slot)
			var result: Dictionary = _kit.fight_board({0: C.plain(0, 100)})
			var gained: int = 0
			for event: Dictionary in C.of_type(result, "stats"):
				if event.get("source", -1) == null and int(event.get("attack_delta", 0)) > 0:
					gained += int(event["attack_delta"])
			assert_eq(gained, count * mini(tier, 5) if count <= 5 else 0)


func test_mousewife_replaces_only_two_non_mouse_front_deaths_even_with_full_back_row() -> void:
	HeroRules.assign(_kit.player, _kit.library.get_hero("old_mother_mousewife"))
	_kit.player.tier = 3
	for slot: int in BoardGeometry.SLOTS:
		_kit.put("pill_bug", slot)
	BoardUpkeep.add_ring(_kit.player, 0, {"attack": 2, "health": 2})
	var result: Dictionary = _kit.fight_board({0: C.plain(99, 1000)})
	var mice: Array[Dictionary] = C.of_type(result, "summon")
	assert_eq(mice.size(), 2)
	for event: Dictionary in mice:
		assert_eq(event["unit"]["def_id"], "mouse")
		assert_true(BoardGeometry.is_front(int(event["slot"])))
	assert_true(C.of_type(result, "no_room").is_empty())


func test_money_spider_is_tier_three() -> void:
	assert_eq(_kit.library.get_unit("money_spider")["tier"], 3)


func test_nip_take_grows_permanently_without_gold_in_pass_two() -> void:
	for golden: bool in [false, true]:
		_kit.player.board.fill(null)
		_kit.player.gold_next_turn = 0
		var nip: RecruitUnit = _kit.put("little_nip", 0, golden)
		_kit.fight_board({0: C.plain(0, 1)})
		var rate: int = 2 if golden else 1
		assert_eq([nip.perm_attack, nip.perm_health], [rate, rate])
		assert_eq(_kit.player.gold_next_turn, 0)


func test_lutra_gold_reads_its_own_row_and_growth_does_not() -> void:
	for own_slot: int in [0, 4]:
		for enemy_slot: int in [0, 4]:
			_kit.player.board.fill(null)
			_kit.player.gold_next_turn = 0
			var lutra: RecruitUnit = _kit.put("old_lutra", own_slot)
			var rng := RandomNumberGenerator.new()
			var combat := Combat.create(_kit.library, _kit.config, rng)
			combat._setup([_kit.player.combat_board(), C.board({enemy_slot: C.plain(0, 1)})])
			CombatLanes.bell(combat)
			var hunter: CombatUnit = combat.unit_at(0, own_slot)
			var target: CombatUnit = combat.unit_at(1, enemy_slot)
			# A quarry can change row after being marked; reach permits attacking it there.
			hunter.quarry = target.uid
			combat._attack(hunter, target)
			for change: Dictionary in combat.carry:
				if int(change["side"]) == 0:
					_kit.rules.apply_carry(_kit.player, change)
			assert_eq([lutra.perm_attack, lutra.perm_health], [1, 1])
			assert_eq(_kit.player.gold_next_turn, 1 if own_slot == 4 else 0)


func test_peat_cutter_mires_without_help_and_pays_once() -> void:
	_kit.put("peat_cutter", 0)
	_kit.put("field_vole", 1)
	var result: Dictionary = _kit.fight_board({0: C.plain(0, 1)})
	assert_eq(_kit.player.gold_next_turn, 1)
	var mired: bool = false
	for event: Dictionary in C.of_type(result, "status"):
		mired = mired or (event.get("status", "") == "mired" and event.get("on", false))
	assert_true(mired, "the Cutter provides its own Mire")


func test_reel_moves_a_whole_ring_above_cap_without_changing_recruit_slots() -> void:
	_kit.put("reel_mistress", 1)
	_kit.put("pill_bug", 0)
	for slot: int in [0, 1]:
		BoardUpkeep.add_ring(_kit.player, slot, {"attack": 4, "health": 4})
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(_kit.library, _kit.config, rng)
	combat.slot_effects = [_kit.player.combat_slots(), []]
	combat._setup([_kit.player.combat_board(), C.board({0: C.plain(0, 100)})])
	combat._recalc_auras(false)
	CombatMoves.dance_rings(combat, combat.unit_at(0, 0))
	assert_eq(BoardUpkeep.ring_stats(combat._slot_effects_at(0, 1)), Vector2i(8, 8))
	assert_eq(BoardUpkeep.ring_stats(_kit.player.slot_effects[0]), Vector2i(4, 4))
	assert_eq(BoardUpkeep.ring_stats(_kit.player.slot_effects[1]), Vector2i(4, 4))


func test_horseshoe_halves_the_recruit_capped_ring() -> void:
	_kit.put("pill_bug", 0)
	BoardUpkeep.add_ring(_kit.player, 0, {"attack": 20, "health": 20})
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(_kit.library, _kit.config, rng)
	var their_slots: Array = []
	for slot: int in BoardGeometry.SLOTS:
		their_slots.append([])
	their_slots[0] = [{"name": "Horseshoe"}]
	combat.slot_effects = [_kit.player.combat_slots(), their_slots]
	CombatRings.prepare(combat)
	combat._setup([_kit.player.combat_board(), C.board({0: C.plain(0, 100)})])
	combat._recalc_auras(false)
	assert_eq(CombatRings.bonus(combat, combat.unit_at(0, 0)), Vector2i(2, 2))


func test_take_growth_survives_a_simultaneous_trade_for_nip_and_lutra() -> void:
	for id: String in ["little_nip", "old_lutra"]:
		for golden: bool in [false, true]:
			var kit := K.new()
			kit.setup(GameConfig.full_game(), true)
			var own_slot: int = 4 if id == "old_lutra" else 0
			var hunter: RecruitUnit = kit.put(id, own_slot, golden)
			var result: Dictionary = kit.fight_board(
				{own_slot: C.plain(hunter.health, hunter.attack)}
			)
			var initial: Dictionary = C.of_type(result, "combat_start")[0]
			var hunter_uid: int = initial["boards"][0][own_slot]["uid"]
			var quarry_uid: int = initial["boards"][1][own_slot]["uid"]
			var deaths: Array = []
			for event: Dictionary in C.of_type(result, "death"):
				deaths.append(event["uid"])
			assert_has(deaths, hunter_uid, "the hunter dies in the exchange")
			assert_has(deaths, quarry_uid, "its quarry dies in the same exchange")
			var rate: int = 2 if golden else 1
			assert_eq([hunter.perm_attack, hunter.perm_health], [rate, rate])
			assert_eq(kit.player.gold_next_turn, rate if id == "old_lutra" else 0)


func test_hex_view_tracks_real_tier_actions_without_an_extra_board_refresh() -> void:
	for golden: bool in [false, true]:
		var kit := K.new()
		kit.setup(GameConfig.full_game(), true)
		kit.rules.start_phase(kit.player, 1)
		var witch: RecruitUnit = kit.put("hedge_witch", 0, golden)
		witch.counters["hex"] = 12
		kit.rules.board_changed(kit.player)
		var low_cap: int = 3 if golden else 1
		assert_eq(witch.view()["hex_amount"], low_cap)
		kit.player.gold = 100
		assert_eq(kit.rules.tier_up(kit.player), "")
		assert_eq(kit.player.tier, 2)
		assert_eq(
			witch.view()["hex_amount"],
			low_cap + 1,
			"the tier action releases stored Hex immediately"
		)
		kit.rules.tier_down(kit.player)
		assert_eq(kit.player.tier, 1)
		assert_eq(
			witch.view()["hex_amount"], low_cap, "lowering tier immediately restores the lower cap"
		)
		assert_eq(witch.view()["hex_stored"], 14 if golden else 13)


func test_earwig_death_keeps_its_refill_without_spending_a_mousewife_attempt() -> void:
	HeroRules.assign(_kit.player, _kit.library.get_hero("old_mother_mousewife"))
	for slot: int in BoardGeometry.SLOTS:
		_kit.put("earwig_mother" if slot == 0 else "pill_bug", slot)
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(_kit.library, _kit.config, rng)
	combat.hero_effects[0] = HeroRules.effects_of(_kit.player.hero)
	combat._setup([_kit.player.combat_board(), C.board({0: C.plain(1, 100)})])
	combat.deal_effect_damage(null, combat.unit_at(0, 0), 999)
	combat._resolve_deaths(0)
	assert_eq(
		combat.unit_at(0, 0).def_id(), "nymph", "Earwig's Death text gets the free slot first"
	)
	var failed_mice: int = 0
	for event: Dictionary in C.of_type({"events": combat.events}, "no_room"):
		if event.get("mechanic", "") == "mice":
			failed_mice += 1
	assert_eq(failed_mice, 1, "Mousewife reports the occupied replacement slot")
	for slot: int in [1, 2, 3]:
		combat.deal_effect_damage(null, combat.unit_at(0, slot), 999)
		combat._resolve_deaths(0)
	assert_eq(combat.unit_at(0, 1).def_id(), "mouse", "both attempts remain after Earwig")
	assert_eq(combat.unit_at(0, 2).def_id(), "mouse", "the failed attempt did not count")
	assert_null(combat.unit_at(0, 3), "two successful replacements exhaust the limit")


func test_other_slot_stats_do_not_consume_ring_capacity_or_change_its_preview() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", 0)
	_kit.player.slot_effects[0].append({"name": "Paint", "attack": 1, "health": 1})
	BoardUpkeep.add_ring(_kit.player, 0, {"attack": 2, "health": 2})
	assert_false(BoardUpkeep.ring_full(_kit.player.slot_effects[0]))
	_kit.rules.give_card(_kit.player, "spore_cloud")
	var item: HandItem = _kit.player.items[0]
	var state: Dictionary = {"slot_effects": _kit.player.slot_effects}
	assert_eq(View.ring_preview(state, item.view(), 0), "+2/+2")
	assert_eq(_kit.rules.item_aim_problem(_kit.player, item, 0), "")
	assert_eq(_kit.rules.play_item(_kit.player, 0, 0), "")
	assert_eq(BoardUpkeep.ring_value(_kit.player.slot_effects[0]), Vector2i(4, 4))
	assert_eq(BoardUpkeep.ring_stats(_kit.player.slot_effects[0]), Vector2i(5, 5))
	assert_eq([unit.aura_attack, unit.aura_health], [5, 5])
	assert_true(BoardUpkeep.ring_full(_kit.player.slot_effects[0]))
	_kit.player.slot_effects[0][0]["attack"] = 100
	assert_true(
		BoardUpkeep.ring_full(_kit.player.slot_effects[0]), "Paint never changes Ring fullness"
	)
