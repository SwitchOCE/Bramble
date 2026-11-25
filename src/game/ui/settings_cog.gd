class_name SettingsCog
extends Control
## STAND-IN (owner, 17 Nov: "we need a settings button in general ... Just a cog"): a round .btn
## with a cog in the fight screen's left light. Recruit uses its L1 roundel
## (docs/ideation-track-2/mockups/menus.js, cog(); stand-ins.html ?m=cog and ?m=fightcog). A click
## on it opens the pause panel, as Escape does; the panel's dim covers it, and while the game is
## paused it takes nothing (it pauses with the game). It reads the pointer in _input, ahead of the
## screens, and does nothing while a card is held.

signal pressed

## menus.js's COG and COG_ICON.
const AT: Vector2 = Vector2(94, 72)
const SIDE: float = 58.0
const ICON: String = (
	'<svg viewBox="0 0 24 24"><path d="M10.43 5.59 L10.81 2.88 L13.19 2.88 L13.57 5.59 '
	+ "L15.42 6.36 L17.61 4.71 L19.29 6.39 L17.64 8.58 L18.41 10.43 L21.12 10.81 L21.12 13.19 "
	+ "L18.41 13.57 L17.64 15.42 L19.29 17.61 L17.61 19.29 L15.42 17.64 L13.57 18.41 L13.19 21.12 "
	+ "L10.81 21.12 L10.43 18.41 L8.58 17.64 L6.39 19.29 L4.71 17.61 L6.36 15.42 L5.59 13.57 "
	+ 'L2.88 13.19 L2.88 10.81 L5.59 10.43 L6.36 8.58 L4.71 6.39 L6.39 4.71 L8.58 6.36Z"/>'
	+ '<circle cx="12" cy="12" r="2.8"/></svg>'
)

## Whether a card is held now (the cog then takes no press and shows no hover); none: never.
var held: Callable = Callable()
var _icon: TextureRect
var _l1_face: TextureRect
var _box: GlassBox
var _pressing: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = AT
	size = Vector2(SIDE, SIDE)
	_box = GlassBox.new()
	_box.name = "Button"
	_box.box_size = size
	_box.use_css("stage", ".btn")
	_box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".btn", "border-radius"), size)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.refresh()
	add_child(_box)
	var px: int = GlassPieces.as_int(GlassPieces.rule_number("stage", ".btn svg", "width"))
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.size = Vector2(px, px)
	_icon.position = ((size - _icon.size) / 2.0).round()
	add_child(_icon)
	_l1_face = L1ColumnArt.roundel("right.settings", L1ColumnArt.COG)
	_l1_face.position = Vector2.ZERO
	_l1_face.hide()
	add_child(_l1_face)
	_tint(false)
	visibility_changed.connect(_forget_press)


func place(recruit: bool) -> void:
	var rect: Rect2 = L1Layout.rect("right.settings") if recruit else Rect2(AT, Vector2.ONE * SIDE)
	position = rect.position
	size = rect.size
	_box.visible = not recruit
	_icon.visible = not recruit
	_l1_face.visible = recruit
	_tint(false)


func _notification(what: int) -> void:
	# paused between a press and its release (Escape): the release is not the cog's
	if what == NOTIFICATION_PAUSED:
		_pressing = false
		_tint(false)


## Hidden between a press and its release: the release is not the cog's.
func _forget_press() -> void:
	if not is_visible_in_tree():
		_pressing = false
		_tint(false)


## Whether a stage point (this node's parent's) is on the cog.
func covers(at: Vector2) -> bool:
	return at.distance_to(position + size / 2.0) <= size.x / 2.0


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var mouse: InputEventMouse = event as InputEventMouse
	if mouse == null:
		return
	var at: Vector2 = (get_parent() as CanvasItem).make_canvas_position_local(mouse.position)
	var over: bool = covers(at)
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null:
		_tint(over and (_pressing or not _busy()))
		return
	if click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.pressed:
		if over and not _holding():
			_pressing = true
			get_viewport().set_input_as_handled()
		return
	if _pressing:
		_pressing = false
		get_viewport().set_input_as_handled()
		if over:
			pressed.emit()


func _holding() -> bool:
	return held.is_valid() and held.call() == true


## A card held, or the button down on something else (no hover then).
func _busy() -> bool:
	return _holding() or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _pressing)


func _tint(hot: bool) -> void:
	if _icon == null:
		return
	var colour: Color = (
		GlassUi.GO if hot else GlassPieces.rule_colour("stage", ".btn svg", "stroke")
	)
	if _l1_face.visible:
		var icon: TextureRect = _l1_face.get_node("Icon")
		icon.texture = L1ColumnArt.icon_texture(
			L1ColumnArt.COG,
			GlassUi.GO if hot else L1ColumnArt.CREAM,
			int(icon.size.x),
			L1Layout.number("right.settings.stroke")
		)
	else:
		var stroke: float = GlassPieces.rule_number("stage", ".btn svg", "stroke-width")
		_icon.texture = GlassPieces.svg_icon(ICON, colour, int(_icon.size.x), stroke)
