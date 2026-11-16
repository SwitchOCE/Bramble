class_name ResultScreen
extends Control
## The result screen (docs/ideation-track-2/mockups/result.html): your place, the eight places
## best first with each player's Health at the end, Play again and Quit.

signal play_again_requested
signal quit_requested

const PANE: Rect2 = Rect2(560, 90, 800, 900)
const ROW_TOP: float = 250.0
const ROW_STEP: float = 74.0

## GameFlow.standings(): [{name, portrait, place, health, you}], best first.
var standings: Array[Dictionary] = []
var round_number: int = 0
var _stage: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## "1st", "2nd", "3rd", "4th"...
static func ordinal(n: int) -> String:
	var suffix: String = "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"
	return "%d%s" % [n, suffix]


func your_place() -> int:
	for row: Dictionary in standings:
		if row.get("you", false):
			return CoreUtil.to_int(row["place"])
	return 0


func _build() -> void:
	_stage = GlassUi.stage(self)
	GlassUi.backdrop(_stage)
	GlassUi.pane(_stage, PANE)
	var words: String = "You won" if your_place() == 1 else "You placed %s" % ordinal(your_place())
	GlassUi.title(_stage, words, 960, 125, 56)
	GlassUi.title(_stage, "Round %d" % round_number, 960, 200, 22, GlassUi.MUTED)
	for i: int in standings.size():
		var row: Dictionary = standings[i]
		var y: float = ROW_TOP + i * ROW_STEP
		var you: bool = row.get("you", false)
		GlassUi.place_number(_stage, CoreUtil.to_int(row["place"]), Vector2(636, y + 20))
		GlassUi.portrait(_stage, str(row["portrait"]), Vector2(680, y), 60, you)
		GlassUi.text_at(
			_stage,
			str(row["name"]),
			Vector2(764, y + 12),
			28,
			GlassUi.GO if you else Color.TRANSPARENT
		)
		GlassUi.health(_stage, maxi(0, CoreUtil.to_int(row["health"])), Vector2(1240, y + 14))
	GlassUi.button(_stage, "Play again", Vector2(640, 880), 300, play_again_requested.emit)
	GlassUi.button(_stage, "Quit", Vector2(980, 880), 300, quit_requested.emit)
	GlassUi.vignette(_stage)
