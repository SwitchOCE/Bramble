class_name StartScreen
extends Control
## The start screen (docs/ideation-track-2/mockups/start.html): Play, Quit, and which of the
## available tribes are in the lobby, all by default. With no tribe content there is no picker.

signal play_requested(tribes: PackedStringArray)
signal quit_requested

const PANE: Rect2 = Rect2(580, 200, 760, 680)
const PILL_W: float = 132.0
const PILL_STEP: float = 140.0
## How much shorter the pane is, and how far up its buttons sit, with no tribe picker.
const PICKER_H: float = 120.0

## The tribes the content offers, by id (GameContent.tribe_ids); set before the screen enters the
## tree. `play_requested` passes ids.
var tribes: PackedStringArray = []
## id -> display name for the pills; an id with none is shown as it is.
var names: Dictionary = {}
var _left_out: PackedStringArray = []
var _stage: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## The tribes chosen for the lobby: empty means all of them.
func chosen() -> PackedStringArray:
	if _left_out.is_empty():
		return PackedStringArray()
	var out: PackedStringArray = []
	for tribe: String in tribes:
		if not _left_out.has(tribe):
			out.append(tribe)
	return out


func toggle(tribe: String) -> void:
	if _left_out.has(tribe):
		_left_out.remove_at(_left_out.find(tribe))
	elif _left_out.size() < tribes.size() - 1:
		_left_out.append(tribe)
	_build()


func _build() -> void:
	if _stage != null:
		remove_child(_stage)
		_stage.queue_free()
	_stage = GlassUi.stage(self)
	GlassUi.backdrop(_stage)
	var lift: float = PICKER_H if tribes.is_empty() else 0.0
	GlassUi.pane(_stage, Rect2(PANE.position, PANE.size - Vector2(0, lift)))
	GlassUi.title(_stage, "Bramble", 960, 228, 84)
	GlassUi.title(_stage, "A game against seven bots", 960, 338, 24, GlassUi.MUTED)
	for i: int in GameFlow.PLAYERS.size():
		var player: Dictionary = GameFlow.PLAYERS[i]
		GlassUi.portrait(_stage, str(player["portrait"]), Vector2(701 + i * 66, 392), 56, i == 0)
	if not tribes.is_empty():
		GlassUi.title(_stage, "Tribes in the lobby", 960, 480, 22, GlassUi.MUTED)
		var x0: float = 960.0 - (PILL_STEP * tribes.size() - (PILL_STEP - PILL_W)) / 2.0
		for i: int in tribes.size():
			var tribe: String = tribes[i]
			GlassUi.button(
				_stage,
				str(names.get(tribe, tribe)),
				Vector2(x0 + i * PILL_STEP, 516),
				PILL_W,
				toggle.bind(tribe),
				_left_out.has(tribe)
			)
	GlassUi.button(
		_stage, "Play", Vector2(810, 620 - lift), 300, func() -> void: play_requested.emit(chosen())
	)
	GlassUi.button(_stage, "Quit", Vector2(810, 700 - lift), 300, quit_requested.emit)
	GlassUi.vignette(_stage)
