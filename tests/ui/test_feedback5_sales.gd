extends GutTest
## Rainbow's on-sell payout belongs in the live sale preview, as well as ordinary sale gold.
@warning_ignore_start("unsafe_call_argument")

const RainbowValue := preload("res://src/core/rainbow_value.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")


func test_chaser_sale_tag_matches_actual_partial_and_full_payouts() -> void:
	var library := UnitLibrary.load_dir()
	for golden: bool in [false, true]:
		for painted: int in [0, 3, 7]:
			for origin: String in [RecruitUnit.ORIGIN_BOUGHT, RecruitUnit.ORIGIN_CREATED]:
				var session := GameSession.create(91827, library)
				var player: PlayerState = session._players[0]
				player.board.fill(null)
				var chaser := RecruitUnit.make(library.get_unit("rainbow_chaser"), 900, golden)
				chaser.origin = origin
				player.board[0] = chaser
				for slot: int in BoardGeometry.SLOTS:
					player.bands[slot] = 900 + slot if slot < painted else 0
				var state: Dictionary = session.get_state()
				var view: Dictionary = state["board"][0]
				var tag_gold: int = RecruitHeld.sell_gold(view, player.round_number)
				var before: int = player.gold
				assert_eq(session._rules.sell(player, 0), "")
				assert_eq(
					tag_gold, player.gold - before, "%s, %d painted, %s" % [golden, painted, origin]
				)
				assert_string_contains(
					RecruitView.full_view("board", view, state)["text"],
					"Sell value: %d gold." % tag_gold
				)
				var lines: PackedStringArray = []
				PlayView._board(state, lines)
				assert_string_contains("\n".join(lines), "sell: %d gold" % tag_gold)


func test_shared_rainbow_rule_handles_disabled_partial_and_complete_paint() -> void:
	assert_eq(RainbowValue.sale_bonus({"gold": 0, "finish": 11}, 7), 0)
	assert_eq(RainbowValue.sale_bonus({"gold": 3, "finish": 11}, 4), 12)
	assert_eq(RainbowValue.sale_bonus({"gold": 3, "finish": 11}, 7), 32)


func test_sale_and_preview_use_shared_rule_with_changed_and_borrowed_rainbow_params() -> void:
	var library := UnitLibrary.load_dir()
	for borrowed: bool in [false, true]:
		for golden: bool in [false, true]:
			var session := GameSession.create(91828, library)
			var player: PlayerState = session._players[0]
			player.board.fill(null)
			var card: Dictionary = library.get_unit("rainbow_chaser").duplicate(true)
			card.erase(MechanicRegistry.COMPILED_KEY)
			card["mechanics"] = [{"id": "rainbow", "gold": 3, "finish": 11, "stats": 1}]
			var chaser := RecruitUnit.make(card, 901, golden)
			var sold: RecruitUnit = chaser
			if borrowed:
				sold = RecruitUnit.make(library.get_unit("frumenty"), 902)
				sold.held.append(chaser)
			player.board[0] = sold
			player.bands.fill(sold.iid)
			var expected: int = (
				session._rules.sell_value(sold, player)
				+ RainbowValue.sale_bonus(
					MechanicRegistry.params_for(card["mechanics"][0], golden), 7
				)
			)
			var view: Dictionary = session.get_state()["board"][0]
			assert_eq(RecruitHeld.sell_gold(view, player.round_number), expected)
			var before: int = player.gold
			assert_eq(session._rules.sell(player, 0), "")
			assert_eq(player.gold - before, expected)
			assert_eq(player.band_count(), 0)
