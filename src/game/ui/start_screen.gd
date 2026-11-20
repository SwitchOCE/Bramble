class_name StartScreen
extends Control
## The start screen. Ghost games use the layout without a tribe picker.

signal play_requested(tribes: PackedStringArray)
signal quit_requested
signal cards_requested

const PANE: Rect2 = Rect2(580, 200, 760, 800)
const PILL_W: float = 132.0
const PILL_STEP: float = 140.0
## How much shorter the pane is, and how far up its buttons sit, with no tribe picker.
const PICKER_H: float = 160.0
const PLAY_Y: float = 660.0
## STAND-IN (start.html .btn.in, .btn.out, .only): a tribe that is in has an amber ring; one left
## out is dimmed and struck through; "Only" under each picks that tribe alone.
const RING: float = 3.0
const OUT_ALPHA: float = 0.4
const STRIKE: float = 3.0
const ONLY_Y: float = 584.0
const ONLY_PX: float = 18.0
const ONLY_COLOUR: Color = Color("c9bda6")
const ONLY_STROKE: float = 4.0

## The tribes the content offers, by id (GameContent.tribe_ids); set before the screen enters the
## tree. `play_requested` passes ids.
var tribes: PackedStringArray = []
## id -> display name for the pills; an id with none is shown as it is.
var names: Dictionary = {}
## Shown in place of the lobby description when a game cannot start.
var message: String = ""
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


## These tribes in, the rest out; empty means all. Set before the screen enters the tree.
func choose(chosen_tribes: PackedStringArray) -> void:
	_left_out = PackedStringArray()
	if chosen_tribes.is_empty():
		return
	for each: String in tribes:
		if not chosen_tribes.has(each):
			_left_out.append(each)
	if _left_out.size() == tribes.size():
		_left_out = PackedStringArray()


## That tribe alone in the lobby.
func only(tribe: String) -> void:
	_left_out = PackedStringArray()
	for each: String in tribes:
		if each != tribe:
			_left_out.append(each)
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
	if message.is_empty():
		var description: String = "Play against seven ghosts"
		if not tribes.is_empty():
			description = "A game against seven bots"  # Mock-up fixture with the tribe picker.
		GlassUi.title(_stage, description, 960, 338, 24, GlassUi.MUTED)
	else:
		GlassUi.title(_stage, message, 960, 338, 24, GlassUi.MUTED).name = "StartMessage"
	for i: int in GameFlow.PLAYERS.size():
		var player: Dictionary = GameFlow.PLAYERS[i]
		GlassUi.portrait(_stage, str(player["portrait"]), Vector2(701 + i * 66, 392), 56, i == 0)
	# The ringed portrait is yours.
	GlassUi.title(_stage, "You", 729, 450, 16, GlassUi.MUTED).name = "You"
	if not tribes.is_empty():
		GlassUi.title(_stage, "Tribes in the lobby", 960, 480, 22, GlassUi.MUTED)
		var x0: float = 960.0 - (PILL_STEP * tribes.size() - (PILL_STEP - PILL_W)) / 2.0
		for i: int in tribes.size():
			var tribe: String = tribes[i]
			var out: bool = _left_out.has(tribe)
			var pill: GlassBox = GlassUi.button(
				_stage,
				str(names.get(tribe, tribe)),
				Vector2(x0 + i * PILL_STEP, 516),
				PILL_W,
				toggle.bind(tribe)
			)
			pill.name = "Tribe_%s" % tribe
			if out:
				pill.modulate.a = OUT_ALPHA
				_strike(pill)
			else:
				_ring(pill)
			var link: GlassText = GlassUi.title(
				_stage, "Only", x0 + i * PILL_STEP + PILL_W / 2.0, ONLY_Y, ONLY_PX, ONLY_COLOUR
			)
			link.name = "Only_%s" % tribe
			link.stroke_width = ONLY_STROKE
			link.refresh()
			link.mouse_filter = Control.MOUSE_FILTER_STOP
			link.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			link.gui_input.connect(_on_only.bind(tribe))
	GlassUi.button(
		_stage,
		"Play",
		Vector2(810, PLAY_Y - lift),
		300,
		func() -> void: play_requested.emit(chosen())
	)
	GlassUi.button(_stage, "Quit", Vector2(810, PLAY_Y + 160.0 - lift), 300, quit_requested.emit)
	GlassUi.button(_stage, "Cards", Vector2(810, PLAY_Y + 80.0 - lift), 300, cards_requested.emit)
	GlassUi.vignette(_stage)


func _on_only(event: InputEvent, tribe: String) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		only(tribe)


## .btn.in: an amber ring hugging the pill.
static func _ring(pill: GlassBox) -> void:
	var ring: Panel = Panel.new()
	ring.name = "Ring"
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = GlassUi.GO
	style.set_border_width_all(int(RING))
	style.set_corner_radius_all(int(pill.box_size.y / 2.0 + RING))
	style.anti_aliasing = true
	ring.add_theme_stylebox_override("panel", style)
	ring.position = -Vector2(RING, RING)
	ring.size = pill.box_size + Vector2(RING, RING) * 2.0
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(ring)


## .btn.out: the name struck through.
static func _strike(pill: GlassBox) -> void:
	var label: Control = null
	for child: Node in pill.get_children():
		if child is GlassText:
			label = child
	if label == null:
		return
	var line: ColorRect = ColorRect.new()
	line.name = "Strike"
	line.color = GlassPieces.rule_colour("stage", ".btn", "color")
	line.size = Vector2(label.size.x, STRIKE)
	line.position = label.position + Vector2(0, label.size.y * 0.55 - STRIKE / 2.0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(line)
