extends GutTest
## Rainbow's on-sell payout belongs in the live sale preview, as well as ordinary sale gold.
@warning_ignore_start("unsafe_call_argument")

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
