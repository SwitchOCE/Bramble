extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")


func before_each() -> void:
	BenchSuites.reload_lines(LinePolicies.DEFAULT_PATH)


func _bind(brain: LineBrain, kit: Kit) -> void:
	brain._player = kit.player
	brain._rules = kit.rules
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	brain.value.board_owner = kit.player


func test_banned_high_value_offer_is_skipped_but_other_line_can_buy_it() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	kit.player.gold = 100
	kit.player.shop.clear()
	kit.player.shop_spells.clear()
	var prize := RecruitUnit.make(kit.library.get_unit("mr_redbreast"), kit.rules.new_iid())
	prize.add_permanent(1000, 1000)
	kit.player.shop.append(prize)
	var blocked: LineBrain = BenchSuites.create_bot("birds_homecoming")
	blocked.configure_banned_cards(["mr_redbreast"])
	_bind(blocked, kit)
	assert_eq(blocked._unit_gain(prize), 0.0)
	assert_true(blocked._best_offer().is_empty(), "high stats cannot override a ban")
	assert_ne(blocked._buy_unit(0), "", "direct buy/swallow route is guarded too")
	assert_eq(kit.player.shop.size(), 1)
	var other: LineBrain = BenchSuites.create_bot("birds_tempo")
	_bind(other, kit)
	assert_gt(other._unit_gain(prize), 0.0)
	assert_eq(other._buy_unit(0), "", "another line can buy the same pool card")
	assert_true(kit.player.hand.has(prize))


func test_starting_line_ban_survives_round_seven_profile_switch() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var brain: LineBrain = BenchSuites.create_bot("birds_tempo")
	brain.configure_banned_cards(["mr_redbreast"])
	brain.play_turn(kit.player, kit.rules, 7)
	assert_eq(brain.build_name(), "line_birds_homecoming")
	assert_eq(brain.starting_line, "line_birds_tempo")
	assert_true(brain.is_banned("mr_redbreast"))
	assert_eq(brain.ban_audit(kit.player)["banned_cards"], ["mr_redbreast"])


func test_choice_filter_keeps_original_index_and_forced_choice_fails_once() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var brain: LineBrain = BenchSuites.create_bot("birds_homecoming")
	brain.configure_banned_cards(["mr_redbreast"])
	_bind(brain, kit)
	assert_eq(brain._best_option(["mr_redbreast", "one_swallow"], false), 1)
	kit.player.pending.append({"options": PackedStringArray(["mr_redbreast"]), "spells": false})
	brain._settle()
	assert_string_contains(brain.ban_failure, "forced choice")
	assert_eq(kit.player.pending.size(), 1, "no invented decline or automatic resampling")
	assert_true(kit.player.hand.is_empty())


func test_free_hand_grant_cannot_be_played_and_held_cards_are_audited() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var brain: LineBrain = BenchSuites.create_bot("birds_homecoming")
	brain.configure_banned_cards(["mr_redbreast"])
	_bind(brain, kit)
	var granted := RecruitUnit.make(kit.library.get_unit("mr_redbreast"), kit.rules.new_iid())
	kit.player.hand.append(granted)
	brain._play_hand()
	assert_true(kit.player.hand.has(granted))
	assert_eq(kit.player.board_count(), 0)
	assert_eq(brain.ban_audit(kit.player)["owned_banned"], ["mr_redbreast"])
	kit.player.hand.clear()
	var carrier := RecruitUnit.make(kit.library.get_unit("one_swallow"), kit.rules.new_iid())
	# Nested held cards are checked independently of their carrier's identity.
	carrier.held.append(granted)
	kit.player.board[0] = carrier
	assert_eq(brain.ban_audit(kit.player)["owned_banned"], ["mr_redbreast"])


func test_ban_schema_rejects_alias_unknown_line_unknown_card_and_duplicates() -> void:
	assert_true(
		LinePolicies.validate_banned_cards({"line_birds_tempo": ["mr_redbreast"]}).is_empty()
	)
	for invalid: Variant in [
		[],
		{"birds_tempo": ["mr_redbreast"]},
		{"line_missing": ["mr_redbreast"]},
		{"line_birds_tempo": ["missing_card"]},
		{"line_birds_tempo": ["mr_redbreast", "mr_redbreast"]},
		{"line_birds_tempo": "mr_redbreast"},
	]:
		assert_false(LinePolicies.validate_banned_cards(invalid).is_empty(), str(invalid))


func test_play_audit_keeps_native_bypass_violation_after_card_has_left() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var brain: LineBrain = BenchSuites.create_bot("birds_homecoming")
	brain.configure_banned_cards(["mr_redbreast"], kit.player)
	kit.player.log_event("play", {"unit": "mr_redbreast"})
	var audit: Dictionary = brain.ban_audit(kit.player)
	assert_eq(audit["owned_banned"], [])
	assert_eq(audit["played_banned"], ["mr_redbreast"])
	assert_ne(audit["failure"], "", "native helpers cannot hide a played then sold banned card")
