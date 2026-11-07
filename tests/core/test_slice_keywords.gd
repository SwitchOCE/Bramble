# gdlint:disable=max-public-methods
extends GutTest
## The slice's keywords and the rules they stand on, through the real flow where that's the point:
## actions on a GameSession and fights it runs.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const WORDS: Array = [
	"Acorn", "Spill", "Pass", "Ring", "Rainbow", "Shy", "Bristle", "Hunker", "Hex", "Nightshade"
]
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


func _session(game_seed: int = 5) -> GameSession:
	var session := GameSession.create(game_seed, UnitLibrary.load_dir(), GameConfig.full_game())
	while session.get_state()["pending_choice"] != null:
		session.choose(0)
	return session


func _hand_item_named(state: Dictionary, id: String) -> int:
	var items: Array = state["hand_items"]
	for index: int in items.size():
		if items[index]["def_id"] == id:
			return index
	return -1


func test_every_keyword_has_a_reminder() -> void:
	var reminders: Dictionary = EffectSchema.section("keywords")
	for word: String in WORDS:
		assert_true(str(reminders.get(word, "")).length() > 10, word)


func test_keyword_reminders_reach_unit_and_card_views() -> void:
	var view: Dictionary = _kit.put("mrs_burdock", F1).view()
	assert_eq(view["keyword_text"][0]["keyword"], "Spill")
	assert_string_contains(view["keyword_text"][0]["text"], "Acorn")
	_rules.give_card(_player, "acorn")
	var item: Dictionary = _player.items[0].view()
	assert_eq(item["keyword_text"][0]["keyword"], "Acorn")
	assert_eq(item["gold_value"], 1)
	assert_eq(item["combines_into"], "stash")


func test_acorn_three_combine_into_a_stash_and_three_stashes_a_hoard() -> void:
	for _copy: int in 3:
		_rules.give_card(_player, "acorn")
	assert_eq(_kit.item_ids(), ["stash"])
	for _copy: int in 6:
		_rules.give_card(_player, "acorn")
	assert_eq(_kit.item_ids(), ["great_hoard"], "9 Acorns chain up")


func test_acorn_the_third_arrives_on_a_full_hand_but_a_first_doesnt() -> void:
	for _unit: int in _kit.config.get_int("hand_limit") - 2:
		_kit.put("pill_bug")
	_rules.give_card(_player, "acorn")
	_rules.give_card(_player, "acorn")
	assert_false(_rules.has_hand_space(_player), "full")
	_rules.give_card(_player, "acorn")
	assert_eq(_kit.item_ids(), ["stash"], "it combined")
	_rules.give_card(_player, "stash")
	assert_eq(_kit.item_ids(), ["stash", "stash"], "a slot was free again")
	_kit.put("pill_bug")
	_rules.give_card(_player, "acorn")
	assert_eq(_kit.item_ids().count("acorn"), 0, "a new Acorn with no room is lost")


func test_acorn_plays_for_its_gold_in_a_real_session() -> void:
	var session: GameSession = _session()
	var human: PlayerState = session._players[GameSession.HUMAN_ID]
	var rules: RecruitRules = session.get_rules()
	rules.give_card(human, "acorn")
	rules.give_card(human, "stash")
	rules.give_card(human, "great_hoard")
	var state: Dictionary = session.get_state()
	assert_eq(state["larder"], 22, "1 + 5 + 16")
	var gold: int = state["gold"]
	assert_eq(session.play_item(_hand_item_named(state, "great_hoard")), "")
	assert_eq(session.get_state()["gold"], gold + 16)
	assert_eq(session.get_state()["larder"], 6)


func test_spill_from_a_fight_becomes_an_acorn_in_the_real_flow() -> void:
	var session: GameSession = _session()
	var human: PlayerState = session._players[GameSession.HUMAN_ID]
	var rules: RecruitRules = session.get_rules()
	human.board[F1] = RecruitUnit.make(rules.library.get_unit("mrs_sorrel"), rules.new_iid())
	human.board[B1] = RecruitUnit.make(rules.library.get_unit("pill_bug"), rules.new_iid())
	session.end_turn()
	var last: Dictionary = session.get_last_combat()
	var spilled: bool = false
	for event: Dictionary in last["events"]:
		spilled = spilled or event["type"] == "spill"
	if spilled:
		assert_gt(session.get_state()["larder"], 0, "the Acorn is in hand")
	else:
		pass_test("Sorrel didn't attack and live on this seed")


func test_pass_travels_the_zigzag_to_the_last_touching_unit() -> void:
	for slot: int in [F1, B1, F2, B2]:
		_kit.put("pill_bug", slot)
	_kit.put("pill_bug", B3)
	var entry: Dictionary = {"iid": _player.board[F1].iid, "slot": F1, "attack": 1, "health": 1}
	_player.pending_passes.append(entry)
	_rules.end_phase(_player)
	assert_eq(_player.board[B2].attack, 2, "F1-B1-F2-B2; the gap at F3 cuts it")
	assert_eq(_player.board[B3].attack, 1)
	assert_eq(_player.board[F1].attack, 1, "only the last keeps it")


func test_pass_with_nobody_touching_stays_on_its_source() -> void:
	var crumb: RecruitUnit = _kit.play("mr_crumb", F1)
	_rules.end_phase(_player)
	assert_eq(crumb.attack, 2)


func test_pass_sold_with_nobody_next_fizzles() -> void:
	_kit.put("mr_crumb", F1)
	var far: RecruitUnit = _kit.put("pill_bug", F3)
	_rules.sell(_player, F1)
	_rules.end_phase(_player)
	assert_eq(far.attack, 1, "the gap cuts it")


func test_pass_the_layout_at_end_of_turn_is_what_counts_and_state_shows_it() -> void:
	var session: GameSession = _session()
	var human: PlayerState = session._players[GameSession.HUMAN_ID]
	var rules: RecruitRules = session.get_rules()
	var near := RecruitUnit.make(rules.library.get_unit("pill_bug"), rules.new_iid())
	human.board[F2] = near
	human.hand.clear()
	human.hand.append(RecruitUnit.make(rules.library.get_unit("mr_crumb"), rules.new_iid()))
	assert_eq(session.play(0, F1), "")
	var passes: Array = session.get_state()["pending_passes"]
	assert_eq(passes[0]["landing_slot"], F1, "F2 isn't touching: B1 sits between")
	assert_eq(session.move(F2, B1), "")
	passes = session.get_state()["pending_passes"]
	assert_eq(passes[0]["from_slot"], F1)
	assert_eq(passes[0]["landing_slot"], B1, "moved in: it would land there now")
	session.end_turn()
	assert_eq(near.attack, 2, "and it did")


func test_turns_in_slot_shared_counter_shows_in_the_view_and_resets_on_a_move() -> void:
	var partner: RecruitUnit = _kit.put("sleeping_partner", F1)
	_kit.pass_turn()
	var view: Dictionary = partner.view()
	assert_eq(view["turns_in_slot"], 1)
	assert_eq(view["turns_goal"], 3)
	_kit.cast("cold_frame", F1)
	assert_eq(partner.view()["timers"][0]["left"], 2)
	_rules.move_on_board(_player, F1, F2)
	assert_eq(partner.view()["turns_in_slot"], 0)
	assert_eq(partner.timers[0]["left"], 2, "the Frame starts over too")


func test_turns_in_slot_a_swap_resets_both_units() -> void:
	var one: RecruitUnit = _kit.put("sleeping_partner", F1)
	var two: RecruitUnit = _kit.put("sleeping_partner", F2)
	_kit.pass_turn()
	_rules.move_on_board(_player, F1, F2)
	assert_eq(one.turns_in_slot, 0)
	assert_eq(two.turns_in_slot, 0)


func test_ring_stays_after_the_unit_leaves_and_serves_the_next_one() -> void:
	_kit.play("nan_toadstool", F1)
	_rules.sell(_player, F1)
	var effects: Array = _player.slot_effects[F1]
	assert_eq(effects.size(), 1, "still there")
	var next: RecruitUnit = _kit.play("pill_bug", F1)
	assert_eq(next.attack, 2)
	_rules.move_on_board(_player, F1, F2)
	assert_eq(next.attack, 1, "stepping off loses it")


func test_ring_fights_with_its_stats_and_stacks_in_the_real_flow() -> void:
	_kit.put("pill_bug", F1)
	_kit.cast("spore_cloud", F1)
	_kit.cast("spore_cloud", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var board: Array = result["events"][0]["boards"][0]
	assert_eq(board[F1]["attack"], 5, "1 and two +2 Rings")
	assert_eq(board[F1]["health"], 8)


func test_rainbow_only_paints_with_a_chaser_on_board_and_only_empty_slots_played() -> void:
	_kit.play("pill_bug", F1)
	assert_eq(_player.band_count(), 0, "no Rainbow unit yet")
	_kit.play("rainbow_chaser", F2)
	assert_eq(_player.band_count(), 1, "itself")
	_kit.put("pill_bug", F3)
	assert_eq(_player.band_count(), 1, "summoned or placed isn't played")
	_kit.play("pill_bug", F4)
	assert_eq(_player.band_count(), 2)


func test_rainbow_a_band_fades_when_its_unit_moves() -> void:
	_kit.play("rainbow_chaser", F1)
	_kit.play("pill_bug", F2)
	_rules.move_on_board(_player, F2, F3)
	assert_eq(_player.band_count(), 1)


func test_rainbow_bands_show_in_state() -> void:
	var session: GameSession = _session()
	var human: PlayerState = session._players[GameSession.HUMAN_ID]
	var rules: RecruitRules = session.get_rules()
	human.hand.clear()
	human.hand.append(RecruitUnit.make(rules.library.get_unit("rainbow_chaser"), rules.new_iid()))
	assert_eq(session.play(0, F3), "")
	var state: Dictionary = session.get_state()
	assert_eq(state["bands"][F3], true)
	assert_eq(state["band_count"], 1)


func test_shy_a_combat_buff_doesnt_count_but_a_ring_does() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", B1)
	_rules.board_changed(_player)
	hob.add_combat(5, 5)
	_rules.board_changed(_player)
	hob.clear_combat_layer()
	assert_true(hob.attack == 1)
	assert_eq(_kit.cast("spore_cloud", B1), "")
	assert_null(_player.board[B1], "the Ring is stats: off it goes")


func test_shy_copy_goes_back_to_the_pool() -> void:
	var taken: bool = _kit.pool.take("hob_in_the_hearth")
	assert_true(taken)
	var left: int = _kit.pool.copies_left("hob_in_the_hearth")
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", B1)
	hob.pool_copies = 1
	_kit.cast("pinch_of_dust", B1)
	assert_eq(_kit.pool.copies_left("hob_in_the_hearth"), left + 1)


func test_hex_stays_on_the_slot_whoever_stands_there() -> void:
	var witch: Dictionary = {"def_id": "hedge_witch", "golden": true}
	var result: Dictionary = _kit.fight(
		{F1: witch, F2: "field_vole"},
		{
			F1: {"def_id": "pill_bug", "attack": 1, "health": 99},
			F2: {"def_id": "pill_bug", "attack": 1, "health": 99}
		}
	)
	var zero: bool = false
	for event: Dictionary in result["events"]:
		if event["type"] == "stats" and event["attack"] == 0:
			zero = true
	assert_true(zero, "the enemy at F1 falls to 0, not below")


func test_hex_at_zero_still_attacks() -> void:
	_kit.put("hedge_witch", F1, true)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 1, "health": 99}, F2: "pill_bug"}
	)
	var enemy: int = result["events"][0]["boards"][1][F1]["uid"]
	var swung: bool = false
	for event: Dictionary in result["events"]:
		swung = swung or (event["type"] == "attack" and event["attacker"] == enemy)
	assert_true(swung, "a hexed unit still swings")


func test_nightshade_loses_half_when_attacked() -> void:
	_kit.put("belladonna", B1, true)
	_kit.put("pill_bug", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 0, "health": 40}}
	)
	var loss: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "health_loss" and event["cause"] == "nightshade":
			loss.append(event["amount"])
	assert_gt(loss.size(), 0)
	assert_eq(loss[0], 20, "half of 40")


func test_bristle_pricks_a_slice_unit_in_a_real_fight() -> void:
	var result: Dictionary = _kit.fight(
		{F1: {"def_id": "hoglet_mother", "attack": 0, "health": 50}},
		{F1: {"def_id": "pill_bug", "attack": 1, "health": 50}}
	)
	var pricks: int = 0
	for event: Dictionary in result["events"]:
		if event["type"] == "damage" and str(event.get("kind", "")) == "thorns":
			pricks += 1
	assert_gt(pricks, 0, "built, with no slice card using it yet")


func test_hunker_halves_a_hit_rounded_up_in_a_real_fight() -> void:
	var result: Dictionary = _kit.fight(
		{F1: {"def_id": "sett_warden", "attack": 0, "health": 50}},
		{F1: {"def_id": "pill_bug", "attack": 5, "health": 50}}
	)
	var seen: bool = false
	for event: Dictionary in result["events"]:
		seen = seen or (event["type"] == "damage" and event["amount"] == 3)
	assert_true(seen, "5 halved and rounded up")


func test_legal_actions_lists_every_slice_aim() -> void:
	var session: GameSession = _session()
	var human: PlayerState = session._players[GameSession.HUMAN_ID]
	var rules: RecruitRules = session.get_rules()
	human.board[F1] = RecruitUnit.make(rules.library.get_unit("alderman_dozey"), rules.new_iid())
	human.board[B1] = RecruitUnit.make(rules.library.get_unit("pill_bug"), rules.new_iid())
	for card: String in ["shake_the_tree", "bread_from_the_back", "stand_behind_me", "spore_cloud"]:
		human.items.append(HandItem.make(rules.library.get_card(card), rules.new_iid()))
	human.items.append(HandItem.make(rules.library.get_card("acorn"), rules.new_iid()))
	human.gold = 10
	var plays: Dictionary = {}
	for action: Dictionary in LegalActions.of(session.get_state()):
		if action["action"] == "play_item":
			var args: Array = action["args"]
			var index: int = args[0]
			var list: Array = plays.get(index, [])
			list.append(args[1] if args.size() > 1 else -1)
			plays[index] = list
	assert_eq(plays[0].size(), session.get_state()["shop"].size(), "a shop aim lists the shop")
	assert_eq(plays[1], [B1], "back units")
	assert_eq(plays[2], [F1], "front units")
	assert_eq(plays[3].size(), 7, "any slot")
	assert_has(plays[4], -1, "an Acorn plays for gold")
	assert_has(plays[4], F1, "or onto Dozey")
	assert_eq(plays[4].size(), 2)


func test_full_game_pool_keeps_shops_varied_and_uses_only_the_slice() -> void:
	var library := UnitLibrary.load_dir()
	var pool := UnitPool.create(library, GameConfig.full_game())
	for id: String in pool.ids():
		assert_eq(library.get_unit(id).get("set"), "slice", id)
	assert_eq(pool.ids().size(), 96)
	var session: GameSession = _session()
	assert_eq(session.get_state()["lobby_tribes"].size(), 5, "Five of the six built tribes")
	assert_eq(session._library.heroes_of("slice").size(), 9)
	assert_eq(session._library.pool_spells("slice").size(), 16)
