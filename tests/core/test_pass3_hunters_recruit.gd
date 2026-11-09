extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const READER := preload("res://src/ui/widgets/card_detail.gd")
const VIEW := preload("res://src/ui/screens/recruit_view.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	kit.player.gold = 100


func _pelt(count: int = 1) -> void:
	Pass3Hunters.arrival(
		kit.rules,
		kit.player,
		{
			"card": "pelt",
			"count": count,
			"from_pool": false,
			"attack": 12,
			"health": 17,
			"prey": {"id": "mrs_jay", "name": "Mrs Jay", "attack": 36, "health": 51}
		}
	)


func test_heir_inherits_current_stats_without_the_tribe_bonus() -> void:
	var heir: RecruitUnit = kit.put("young_brock", 1)
	var sold: RecruitUnit = kit.put("little_nip", 0)
	sold.add_permanent(20, 30)
	kit.player.tribe_bonuses["Hunters"] = 9
	kit.rules.board_changed(kit.player)
	var expected := Vector2i(sold.attack - sold.tribe_attack, sold.health - sold.tribe_health)
	var before := Vector2i(heir.perm_attack, heir.perm_health)
	assert_eq(kit.rules.sell(kit.player, 0), "")
	assert_eq(Vector2i(heir.perm_attack, heir.perm_health) - before, expected)


func test_golden_heir_widens_reach_without_doubling_and_ignores_non_hunters() -> void:
	var heir: RecruitUnit = kit.put("young_brock", 5, true)
	var sold: RecruitUnit = kit.put("little_nip", 1)
	sold.add_permanent(10, 20)
	var expected := Vector2i(sold.attack, sold.health)
	assert_eq(kit.rules.sell(kit.player, 1), "")
	assert_eq(Vector2i(heir.perm_attack, heir.perm_health), expected)
	kit.put("field_vole", 1)
	assert_eq(kit.rules.sell(kit.player, 1), "")
	assert_eq(Vector2i(heir.perm_attack, heir.perm_health), expected)


func test_printed_and_borrowed_heir_pay_only_once_per_sale() -> void:
	var heir: RecruitUnit = kit.put("young_brock", 1)
	heir.grants.append(
		{
			"entry": {"id": "pass3_hunter", "ability": "young_brock", "factor": 1},
			"golden": true,
			"keyword": "",
			"combat_only": false
		}
	)
	var sold: RecruitUnit = kit.put("little_nip", 0)
	var expected := Vector2i(sold.attack, sold.health)
	assert_eq(kit.rules.sell(kit.player, 0), "")
	assert_eq(Vector2i(heir.perm_attack, heir.perm_health), expected)


func test_pelt_keeps_prey_portrait_fixed_numbers_and_hunter_only_aim() -> void:
	var hunter: RecruitUnit = kit.put("little_nip", 0)
	kit.put("hob_in_the_hearth", 1)
	_pelt()
	var item: HandItem = kit.player.items.back()
	var view: Dictionary = item.view()
	assert_eq(view["portrait_id"], "mrs_jay")
	assert_eq(view["name"], "Pelt of Mrs Jay")
	assert_eq(view["text"], "Give a Hunter +12/+17 permanently.")
	assert_false(VIEW.item_lands(view, kit.player.board[1].view(), 1))
	assert_true(VIEW.item_lands(view, hunter.view(), 0))
	assert_ne(kit.rules.play_item(kit.player, kit.player.items.size() - 1, 1), "")
	var before := Vector2i(hunter.perm_attack, hunter.perm_health)
	assert_eq(kit.rules.play_item(kit.player, kit.player.items.size() - 1, 0), "")
	assert_eq(
		Vector2i(hunter.perm_attack, hunter.perm_health) - before,
		Vector2i(12, 17),
		"already proportional; board scaling never applies twice"
	)


func test_full_hand_pelts_wait_and_drain_without_loss() -> void:
	kit.put("little_nip", 0)
	while kit.rules.has_hand_space(kit.player):
		kit.rules.give_card(kit.player, "acorn")
	_pelt(2)
	assert_eq(kit.player.item_doorstep.size(), 2)
	assert_eq(kit.rules.play_item(kit.player, 0, -1), "")
	assert_eq(kit.player.item_doorstep.size(), 1)
	var pelt: HandItem = kit.player.items.back()
	assert_eq(pelt.def_id(), "pelt")
	assert_eq(kit.rules.play_item(kit.player, kit.player.items.size() - 1, 0), "")
	assert_eq(kit.player.item_doorstep.size(), 0)
	var last_pelt: HandItem = kit.player.items.back()
	assert_eq(last_pelt.def_id(), "pelt")


func test_full_price_poach_preserves_only_payload_buffs_and_expires_after_refresh() -> void:
	kit.player.tier = 6
	var before: int = kit.pool.copies_left("little_nip")
	HunterRecruit.poach(
		kit.rules,
		kit.player,
		{"card": "little_nip", "discount": 0, "perm_attack": 13, "perm_health": 19}
	)
	assert_eq(kit.pool.copies_left("little_nip"), before - 1)
	var copy: RecruitUnit = kit.player.poached_pending.back()
	assert_false(copy.golden)
	assert_eq(Vector2i(copy.perm_attack, copy.perm_health), Vector2i(13, 19))
	HunterRecruit.start_turn(kit.player)
	assert_true(copy.view()["poached"])
	assert_eq(kit.rules.unit_cost(kit.player, copy), kit.config.get_int("unit_cost"))
	assert_eq(kit.rules.refresh(kit.player), "")
	assert_true(kit.player.shop.has(copy), "refresh keeps the separate next-shop offer")
	var before_expiry: int = kit.pool.copies_left("little_nip")
	HunterRecruit.expire(kit.rules, kit.player)
	assert_false(kit.player.shop.has(copy))
	assert_eq(kit.pool.copies_left("little_nip"), before_expiry + 1)


func test_pelt_legal_actions_match_runtime_and_reader_preview_uses_only_recorded_scout() -> void:
	var hunter: RecruitUnit = kit.put("little_nip", 0)
	kit.put("hob_in_the_hearth", 1)
	_pelt()
	var board: Array = []
	for unit: RecruitUnit in kit.player.board:
		if unit == null:
			board.append(null)
		else:
			board.append(unit.view())
	var actions: Array[Dictionary] = []
	var offered_pelt: HandItem = kit.player.items.back()
	LegalActions._hand(
		{
			"board": board,
			"hand": [],
			"hand_items": [offered_pelt.view()],
			"slot_effects": kit.player.slot_effects
		},
		actions
	)
	assert_eq(actions, [{"action": "play_item", "args": [0, 0]}])
	kit.player.scout = {
		"specs":
		[{"def_id": "field_vole", "attack": 9, "health": 12}, null, null, null, null, null, null],
		"views":
		[
			{"def_id": "field_vole", "name": "Field Vole", "attack": 9, "health": 12},
			null,
			null,
			null,
			null,
			null,
			null
		]
	}
	var rng_before: int = kit.player.effect_rng.state
	Pass3HunterPreview.attach(kit.player, board, kit.config)
	var preview: Dictionary = board[0]["hunter_take_preview"]
	assert_eq([preview["attack"], preview["health"], preview["owner_slot"]], [6, 8, 0])
	assert_string_contains(READER.full_text_bbcode(board[0]), "Take: +6/+8")
	assert_eq(kit.player.effect_rng.state, rng_before)
	assert_eq(hunter.perm_attack, 0)


func test_pelt_remains_a_real_spell_for_echo_without_rescaling_or_thanking_neighbours() -> void:
	kit.card("hunter_echo", [{"id": "echo"}], ["Hunters"], 100, 100)
	var echoed: RecruitUnit = kit.put("little_nip", 0)
	var aimed: RecruitUnit = kit.put("hunter_echo", 1)
	var shy: RecruitUnit = kit.put("hob_in_the_hearth", 2)
	kit.rules.board_changed(kit.player)
	_pelt()
	assert_eq(kit.rules.play_item(kit.player, kit.player.items.size() - 1, 1), "")
	assert_eq([aimed.perm_attack, aimed.perm_health], [12, 17])
	assert_eq([echoed.perm_attack, echoed.perm_health], [12, 17])
	assert_eq([shy.perm_attack, shy.perm_health], [0, 0])
	assert_eq(kit.player.board[2], shy, "the neighbour was never aimed at or thanked")
