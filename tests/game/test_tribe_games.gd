extends GutTest
## A scripted full game per tribe folder present: a lobby of that tribe only plays to eight
## placements through the flow, as the screens would drive it. Every human action goes through
## GameFlow.act after a recruit view is built; every human fight is turned into replay steps.
## Runs over whatever tribe folders are under src/content, plus the core's bridge test cards
## (tests/core/content/test), which use every capability the tribes may use.

const SHARED: String = "res://src/content/shared"
const TEST_CARDS: String = "res://tests/core/content/test"
const SEEDS: Array[int] = [3, 17]

## Whether the game being played compares numbers: not with the core's test cards in it, whose
## fight-only rules (Edge: slots give double Attack in fights; Berserk: while outnumbered) change
## any unit's fight numbers by design, which no shop can show.
var _compare_numbers: bool = true


## The shop against the fight: each of the human's units at the fight's first step shows the
## same pills, reminders and numbers as the recruit screen showed it.
func _same_as_shop(shop_board: Array, first: Dictionary, you: int, label: String) -> void:
	var table: Dictionary = first["display"]
	var rows: Array = first["boards"]
	var row: Array = rows[you]
	var compared: int = 0
	for value: Variant in row:
		if not value is Dictionary:
			continue
		var unit: Dictionary = value
		var slot: int = CoreUtil.to_int(unit.get("slot", -1))
		var in_shop: Variant = shop_board[slot] if slot >= 0 and slot < shop_board.size() else null
		if not in_shop is Dictionary:
			continue
		var shop: Dictionary = in_shop
		if str(shop.get("id", "")) != str(unit.get("id", "")):
			continue
		compared += 1
		var named: String = "%s: %s" % [label, str(unit.get("name", ""))]
		assert_eq(_words(unit, table), _words(shop, table), "%s pills" % named)
		assert_eq(
			CardTerms.reminders(unit, table),
			CardTerms.reminders(shop, table),
			"%s reminders" % named
		)
		if not _compare_numbers:
			continue
		var numbers: Array = [unit.get("attack"), unit.get("health")]
		assert_eq(numbers, [shop.get("attack"), shop.get("health")], "%s numbers" % named)
	var on_board: int = 0
	for value: Variant in shop_board:
		if value is Dictionary:
			on_board += 1
	assert_eq(compared, on_board, "%s: every unit compared" % label)


static func _words(unit: Dictionary, table: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for pill: Dictionary in CardTerms.all_pills(unit, table):
		out.append(str(pill["words"]))
	return out


## The folders to play: each tribe under src/content, then the test cards.
static func _tribe_folders() -> PackedStringArray:
	var out: PackedStringArray = []
	for path: String in ContentSet.folders_in(ContentSet.ROOT):
		if path.get_file() != "shared":
			out.append(path)
	out.append(TEST_CARDS)
	return out


func test_every_tribe_folder_plays_a_whole_game() -> void:
	var folders: PackedStringArray = _tribe_folders()
	gut.p("tribe folders: %s" % ", ".join(folders))
	for folder: String in folders:
		var content: GameContent = GameContent.load_folders([SHARED, folder])
		assert_eq(content.errors, PackedStringArray(), "%s loads clean" % folder)
		if not content.errors.is_empty():
			continue
		var tribe: String = str(content.tribes[0]["folder"])
		_compare_numbers = folder != TEST_CARDS
		for game_seed: int in SEEDS:
			_play(content, PackedStringArray([tribe]), game_seed, folder)


func test_all_tribes_together_play_a_whole_game() -> void:
	var folders: PackedStringArray = [SHARED]
	folders.append_array(_tribe_folders())
	var content: GameContent = GameContent.load_folders(folders)
	assert_eq(content.errors, PackedStringArray(), "all tribes load together")
	# the test cards are in this game too
	_compare_numbers = false
	_play(content, PackedStringArray(), 5, "all")


func _play(content: GameContent, lobby: PackedStringArray, game_seed: int, label: String) -> void:
	var flow: GameFlow = GameFlow.create(content, game_seed, lobby)
	var human := FlowBot.new(Rng.derive(game_seed, "human"))
	var used: Dictionary = {}
	var refused: int = 0
	var replays: int = 0
	for _round: int in 60:
		if flow.is_over() or not flow.human_alive():
			break
		flow.start_round()
		for _step: int in Bot.MAX_ACTIONS:
			if flow.human().turn_ended:
				break
			var state: Dictionary = ViewAdapter.recruit_state(flow)
			if state.has("discover"):
				used["discover"] = CoreUtil.to_int(used.get("discover", 0)) + 1
			var action: Dictionary = human.choose(flow.session, flow.human())
			var kind: String = str(action["type"])
			if kind == "play" and CoreUtil.to_int(action["target"]) >= 0:
				kind = "play_target"
			used[kind] = CoreUtil.to_int(used.get(kind, 0)) + 1
			if flow.act(action) != "":
				refused += 1
				break
		if not flow.human().turn_ended:
			flow.act({"type": "end_turn"})
		var shop_board: Array = ViewAdapter.recruit_state(flow)["board"]
		var fight: Dictionary = flow.finish_round()
		if not fight.is_empty():
			var base: Dictionary = ViewAdapter.fight_base(flow, fight)
			var replay: FightReplay = FightReplay.build(
				base,
				CoreUtil.to_array(fight["events"]),
				ViewAdapter.catalog(content),
				CoreUtil.to_int(fight["damage"])
			)
			assert_gt(replay.steps.size(), 0, "%s: a fight plays as steps" % label)
			_same_as_shop(
				shop_board,
				CoreUtil.to_dict(replay.steps[0].get("state", {})),
				CoreUtil.to_int(fight["you_side"]),
				"%s seed %d round %d" % [label, game_seed, flow.session.round_number]
			)
			replays += 1
	if not flow.is_over():
		flow.play_out()
	gut.p(
		(
			"%s seed %d: round %d, %d fights shown, human used %s"
			% [label, game_seed, flow.session.round_number, replays, used]
		)
	)
	assert_true(flow.is_over(), "%s seed %d: the game ended" % [label, game_seed])
	assert_eq(refused, 0, "%s seed %d: no legal action refused" % [label, game_seed])
	var places: Array = []
	for row: Dictionary in flow.standings():
		places.append(row["place"])
	assert_eq(places, [1, 2, 3, 4, 5, 6, 7, 8], "%s seed %d: eight placements" % [label, game_seed])
	for seat: int in range(1, 8):
		assert_eq(flow.bots[seat].refused, 0, "%s: bot %d had nothing refused" % [label, seat])
