class_name PausePanel
extends Control
## The pause panel (docs/ideation-track-2/mockups/pause.html), opened with Escape or the cog over
## whatever is showing: Resume, Quit to start, Quit, and the settings (GameSettings): whether a
## carried card drops where the pointer is or where the card's middle is (STAND-IN, 17 Nov), the
## one on lit; and the sound's volume and mute (STAND-IN, 21 Nov), Mute lit while on. The pane is
## taller than the mock-up's to fit the sound row. It takes every click while open.

signal resume_requested
signal quit_to_start_requested
signal quit_requested

const PANE: Rect2 = Rect2(740, 220, 440, 660)
const DIM: Color = Color(0, 0, 0, 0.55)
const CHOICE_W: float = 185.0

## The game's seed, shown small so a game the owner hits a bug in can be replayed; -1 for none.
var game_seed: int = -1
var _pointer: GlassBox
var _middle: GlassBox
var _mute: GlassBox
var _volume: VolumeSlider


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
	GlassUi.title(stage, "Paused", 960, 255, 48)
	GlassUi.button(stage, "Resume", Vector2(810, 340), 300, resume_requested.emit)
	GlassUi.button(stage, "Quit to start", Vector2(810, 420), 300, quit_to_start_requested.emit)
	GlassUi.button(stage, "Quit", Vector2(810, 500), 300, quit_requested.emit)
	GlassUi.title(stage, "Cards drop by", 960, 590, 22, GlassUi.MUTED)
	_pointer = GlassUi.button(
		stage, "Pointer", Vector2(770, 626), CHOICE_W, func() -> void: choose_middle(false)
	)
	_middle = GlassUi.button(
		stage, "Card middle", Vector2(965, 626), CHOICE_W, func() -> void: choose_middle(true)
	)
	_light_choice()
	GlassUi.title(stage, "Sound", 960, 716, 22, GlassUi.MUTED)
	_mute = GlassUi.button(
		stage, "Mute", Vector2(1040, 752), 110, func() -> void: set_muted(not GameSettings.muted())
	)
	_volume = VolumeSlider.new()
	_volume.name = "Volume"
	_volume.position = Vector2(770, 752)
	_volume.size = Vector2(255, _mute.box_size.y)
	_volume.value = GameSettings.volume()
	_volume.changed.connect(func(v: float) -> void: set_volume(v, false))
	_volume.released.connect(func(v: float) -> void: set_volume(v, true))
	stage.add_child(_volume)
	_light_mute()
	if game_seed >= 0:
		GlassUi.title(stage, "Seed %d" % game_seed, 960, 832, 18, GlassUi.MUTED)


## Sets where a carried card drops (saved at once) and lights the choice.
func choose_middle(on: bool) -> void:
	GameSettings.set_drop_by_middle(on)
	_light_choice()


## Sets the volume and applies it; save also writes it and plays a hit at the new level.
func set_volume(value: float, save: bool = true) -> void:
	GameSettings.set_volume(value, save)
	if save and GameSettings.muted():
		set_muted(false)
	Sound.apply_settings()
	if save:
		Sound.play("fight.hit.medium")


func set_muted(on: bool) -> void:
	GameSettings.set_muted(on)
	Sound.apply_settings()
	_light_mute()


func _light_mute() -> void:
	_set_lit(_mute, GameSettings.muted())


func _set_lit(box: GlassBox, on: bool) -> void:
	var lit: Node = box.get_node_or_null("Lit")
	if lit != null:
		box.remove_child(lit)
		lit.queue_free()
	if on:
		GlassParts.add_lit(box, GlassParts.round_poly(box.box_size))


func _light_choice() -> void:
	var on: bool = GameSettings.drop_by_middle()
	for pair: Array in [[_pointer, not on], [_middle, on]]:
		var box: GlassBox = pair[0]
		var lit_on: bool = pair[1]
		_set_lit(box, lit_on)
