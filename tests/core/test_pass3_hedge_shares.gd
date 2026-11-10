extends GutTest
## Exact source shares and capped item counts for both qualities; fixed boards only.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.player.round_number = 1
	kit.player.gold = 100


func _end() -> void:
	kit.rules.end_phase(kit.player)
	kit.player.round_number += 1


func test_committee_normal_and_golden_share_runt_with_the_whole_hedgerow_run() -> void:
	for golden: bool in [false, true]:
		before_each()
		var committee: RecruitUnit = kit.put("standing_committee", 4, golden)
		committee.add_permanent(20, 20)
		var runt: RecruitUnit = kit.put("field_vole", 0)
		runt.add_permanent(6, 5)
		var neighbour: RecruitUnit = kit.put("field_vole", 1)
		neighbour.add_permanent(6, 5)
		var outsider: RecruitUnit = kit.put("pill_bug", 5)
		_end()
		var share: int = 4 if golden else 2
		assert_eq(Vector2i(runt.attack, runt.health), Vector2i(8 + share, 8 + share))
		assert_eq(neighbour.perm_attack, 6 + share)
		assert_eq(committee.perm_attack, 20 + share)
		assert_eq(outsider.perm_attack, 0)


func test_lollop_normal_and_golden_reads_biggest_other_tribe_once_at_start() -> void:
	for golden: bool in [false, true]:
		before_each()
		var big: RecruitUnit = kit.put("pill_bug", 1)
		big.add_permanent(100 - big.attack, 120 - big.health)
		var friend: RecruitUnit = kit.put("field_vole", 0)
		var lollop: RecruitUnit = kit.put("squire_lollop", 4, golden)
		kit.rules.board_changed(kit.player)
		Pass3Hedgerow.start_turn(kit.rules, kit.player)
		var share: Vector2i = Vector2i(20, 24) if golden else Vector2i(10, 12)
		assert_eq(Vector2i(friend.perm_attack, friend.perm_health), share)
		assert_eq(Vector2i(lollop.perm_attack, lollop.perm_health), share)
		assert_eq(Vector2i(big.attack, big.health), Vector2i(100, 120))


func test_mast_normal_and_golden_caps_pay_five_or_ten_actual_acorns() -> void:
	for golden: bool in [false, true]:
		before_each()
		kit.put("old_mother_mast", 4, golden)
		for _item: int in 4:
			kit.rules.give_card(kit.player, "great_hoard")
		kit.rules.events.fire(kit.player, "start_of_turn")
		assert_eq(
			kit.player.larder(),
			81 if golden else 71,
			"combining ten acorns yields a Hoard and Acorn"
		)


func test_lollop_normal_and_golden_can_read_a_shy_biggest_without_buffing_it() -> void:
	for golden: bool in [false, true]:
		before_each()
		kit.card("big_shy_source", [{"id": "shy", "gold": 2}], ["Fairies"], 205, 307)
		var source: RecruitUnit = kit.put("big_shy_source", 1)
		var recipient: RecruitUnit = kit.put("field_vole", 0)
		var lollop: RecruitUnit = kit.put("squire_lollop", 4, golden)
		kit.rules.board_changed(kit.player)
		var expected: Vector2i = Vector2i(41, 61) if golden else Vector2i(20, 30)
		assert_eq(lollop.get_meta("hedgerow_preview"), expected)
		Pass3Hedgerow.start_turn(kit.rules, kit.player)
		assert_eq(Vector2i(recipient.perm_attack, recipient.perm_health), expected)
		assert_eq(Vector2i(lollop.perm_attack, lollop.perm_health), expected)
		assert_eq(Vector2i(source.attack, source.health), Vector2i(205, 307))
		assert_eq(Vector2i(source.perm_attack, source.perm_health), Vector2i.ZERO)


func test_recruit_growth_uses_strongest_printed_or_borrowed_text_with_guard_off_proof() -> void:
	for guarded: bool in [true, false]:
		before_each()
		kit.config.set_value("pass3_loop_guards", guarded)
		kit.player.pass3_loop_guards = guarded
		var entry: Dictionary = {
			"id": "pass3_hedgerow", "ability": "mrs_clover", "factor": 1, "share": 1.0
		}
		var id: String = kit.card("shared_clover", [entry], ["Hedgerow folk"], 10, 20)
		var clover: RecruitUnit = kit.put(id, 6)
		clover.grants.append({"entry": entry.duplicate(true), "golden": true})
		kit.play("mrs_burdock", 0)
		var summoned: RecruitUnit = kit.player.board[4]
		assert_not_null(summoned)
		assert_eq(summoned.def_id(), "kit")
		assert_eq(summoned.attack, 21 if guarded else 31)
		assert_eq(summoned.health, 41 if guarded else 61)
