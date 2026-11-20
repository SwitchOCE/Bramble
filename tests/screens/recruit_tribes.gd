extends Control
## The recruit screen with real tribe cards: a game state from the shipped content (all five
## tribes on the board and in hand), through the game flow's own converter
## (ViewAdapter.recruit_state), for tools/glass/compare.py against
## docs/ideation-track-2/mockups/recruit-tribes.html.
##
## The page draws the same state from mockups/recruit_tribes.json. To write that file again after
## the content changes, run this scene with BRAMBLE_WRITE_TRIBES set to the file's path:
##   BRAMBLE_WRITE_TRIBES=docs/ideation-track-2/mockups/recruit_tribes.json \
##     godot --headless res://tests/screens/recruit_tribes.tscn --quit-after 2

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")
const BOARD: Dictionary = {
	0: "hedge-knight",
	1: "needle-pikeman",
	2: "nettle-skirmisher",
	3: "hopper",
	4: "lance-corporal",
	5: "hedge-layer",
	6: "brock-cub",
}
const HAND: Array[String] = [
	"master-at-arms", "thimble-captain", "gorger", "old-campaigner", "sp_sharpen"
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var content: GameContent = GameContent.load_default()
	var flow: GameFlow = FlowFixture.live(content, 3)
	flow.start_round()
	var me: PlayerState = flow.human()
	me.gold = 8
	for slot: Variant in BOARD:
		CoreKit.put(flow.session, me, str(BOARD[slot]), CoreUtil.to_int(slot))
	for card_id: String in HAND:
		me.hand.append(CoreKit.unit(flow.session, card_id))
	var state: Dictionary = ViewAdapter.recruit_state(flow)
	var screen: RecruitScreen = SCREEN.instantiate()
	screen.state = state
	add_child(screen)
	var path: String = OS.get_environment("BRAMBLE_WRITE_TRIBES")
	if path != "":
		_write(state, path)


## The state as the page reads it, each unit with the pill words the screen draws (`pills`), so
## the page need not know the card terms.
static func _write(state: Dictionary, path: String) -> void:
	var out: Dictionary = state.duplicate(true)
	var table: Dictionary = state.get("display", {})
	for row: String in ["shop_units", "board", "hand"]:
		for value: Variant in out.get(row, []):
			if value is Dictionary:
				var unit: Dictionary = value
				var words: Array[String] = []
				for shown: Dictionary in CardTerms.pills(unit, table):
					words.append(str(shown["words"]))
				unit["pills"] = words
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(out, " ", false) + "\n")
