class_name PausePanel
extends Control
## The pause panel (docs/ideation-track-2/mockups/pause.html), opened with Escape over whatever
## is showing: Resume, Quit to start, Quit. It takes every click while open.

signal resume_requested
signal quit_to_start_requested
signal quit_requested

const PANE: Rect2 = Rect2(760, 330, 400, 420)
const DIM: Color = Color(0, 0, 0, 0.55)
## Above everything a screen raises (a lunging card, a hit splash, the skip hint).
const Z: int = 200

## The game's seed, shown small so a game the owner hits a bug in can be replayed; -1 for none.
var game_seed: int = -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = Z
	mouse_filter = Control.MOUSE_FILTER_STOP
	var stage: Control = GlassUi.stage(self)
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.size = stage.size
	stage.add_child(dim)
	GlassUi.pane(stage, PANE)
	GlassUi.title(stage, "Paused", 960, 365, 48)
	GlassUi.button(stage, "Resume", Vector2(810, 450), 300, resume_requested.emit)
	GlassUi.button(stage, "Quit to start", Vector2(810, 530), 300, quit_to_start_requested.emit)
	GlassUi.button(stage, "Quit", Vector2(810, 610), 300, quit_requested.emit)
	if game_seed >= 0:
		GlassUi.title(stage, "Seed %d" % game_seed, 960, 712, 18, GlassUi.MUTED)
