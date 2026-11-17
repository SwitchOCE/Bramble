class_name PausePanel
extends Control
## The pause panel (docs/ideation-track-2/mockups/pause.html), opened with Escape or the cog over
## whatever is showing: Resume, Quit to start, Quit, and the one setting (STAND-IN, 17 Nov):
## whether a carried card drops where the pointer is or where the card's middle is
## (GameSettings), the one on lit. It takes every click while open.

signal resume_requested
signal quit_to_start_requested
signal quit_requested

const PANE: Rect2 = Rect2(740, 270, 440, 540)
const DIM: Color = Color(0, 0, 0, 0.55)
const CHOICE_W: float = 185.0

## The game's seed, shown small so a game the owner hits a bug in can be replayed; -1 for none.
var game_seed: int = -1
var _pointer: GlassBox
var _middle: GlassBox


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var stage: Control = GlassUi.stage(self)
	var dim: ColorRect = ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.size = stage.size
	stage.add_child(dim)
	GlassUi.pane(stage, PANE)
	GlassUi.title(stage, "Paused", 960, 305, 48)
	GlassUi.button(stage, "Resume", Vector2(810, 390), 300, resume_requested.emit)
	GlassUi.button(stage, "Quit to start", Vector2(810, 470), 300, quit_to_start_requested.emit)
	GlassUi.button(stage, "Quit", Vector2(810, 550), 300, quit_requested.emit)
	GlassUi.title(stage, "Cards drop by", 960, 640, 22, GlassUi.MUTED)
	_pointer = GlassUi.button(
		stage, "Pointer", Vector2(770, 676), CHOICE_W, func() -> void: choose_middle(false)
	)
	_middle = GlassUi.button(
		stage, "Card middle", Vector2(965, 676), CHOICE_W, func() -> void: choose_middle(true)
	)
	_light_choice()
	if game_seed >= 0:
		GlassUi.title(stage, "Seed %d" % game_seed, 960, 772, 18, GlassUi.MUTED)


## Sets where a carried card drops (saved at once) and lights the choice.
func choose_middle(on: bool) -> void:
	GameSettings.set_drop_by_middle(on)
	_light_choice()


func _light_choice() -> void:
	var on: bool = GameSettings.drop_by_middle()
	for pair: Array in [[_pointer, not on], [_middle, on]]:
		var box: GlassBox = pair[0]
		var lit: Node = box.get_node_or_null("Lit")
		if lit != null:
			box.remove_child(lit)
			lit.queue_free()
		if pair[1]:
			GlassParts.add_lit(box, GlassParts.round_poly(box.box_size))
