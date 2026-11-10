extends Control
## Every Bird remains visible as a portrait token; one tap reads its complete journey state.

signal bird_requested(view: Dictionary, nest: int)

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")

const GAP: int = 10
const SCROLL_GUTTER: float = 18.0

var shown: Dictionary = {}
var tokens: Array[Interactive] = []
var _birds: Array[Dictionary] = []
var _scroll: ScrollContainer
var _row: HBoxContainer
var _signature: String = ""


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", GAP)
	_scroll.add_child(_row)
	resized.connect(_layout)
	ready.connect(_layout)


func token_size() -> float:
	return 122.0 if CardView.is_phone() else 104.0


func row_height() -> float:
	return token_size() + SCROLL_GUTTER


func show_state(state: Dictionary) -> void:
	shown = RecruitHeld.sky_card(state)
	visible = not shown.is_empty()
	var signature: String = JSON.stringify(
		[Data.a(state, "away"), Data.a(state, "doorstep"), token_size()]
	)
	if signature == _signature:
		_layout()
		return
	_signature = signature
	for token: Interactive in tokens:
		_row.remove_child(token)
		token.queue_free()
	tokens.clear()
	_birds.clear()
	for bird: Dictionary in Data.a(state, "away"):
		_add_bird(bird, false)
	for bird: Dictionary in Data.a(state, "doorstep"):
		_add_bird(bird, true)
	_layout()


func _add_bird(bird: Dictionary, waiting: bool) -> void:
	var view: Dictionary = bird.duplicate(true)
	view["doorstep"] = waiting
	_birds.append(view)
	var token := Interactive.new()
	token.zone = "away"
	token.index = tokens.size()
	token.custom_minimum_size = Vector2.ONE * token_size()
	token.tapped.connect(_on_token_tapped)
	token.hovered.connect(
		func(zone: String, index: int, inside: bool) -> void:
			if inside and not CardView.is_phone():
				_on_token_tapped(zone, index)
	)
	_row.add_child(token)
	tokens.append(token)
	var portrait := ArtFrame.new()
	portrait.name = "Portrait"
	portrait.radius = token_size() / 2.0
	portrait.position = Vector2(6, 6)
	portrait.size = Vector2.ONE * (token_size() - 12)
	portrait.texture = UiTheme.portrait_for(
		Data.s(view, "portrait_id", Data.s(view, "def_id")), Data.a(view, "tribes")
	)
	portrait.gilded = Data.b(view, "golden")
	token.add_child(portrait)
	var mark := Control.new()
	mark.name = "JourneyMark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.size = Vector2.ONE * token_size()
	mark.draw.connect(_draw_token.bind(mark, waiting))
	token.add_child(mark)
	if not waiting:
		var countdown: Label = UiTheme.number(
			str(maxi(0, Data.i(view, "turns_left"))), UiTheme.MIN_FONT, UiTheme.CREAM
		)
		countdown.name = "Countdown"
		countdown.set_meta("away_countdown", true)
		countdown.position = Vector2(token_size() - 39, token_size() - 48)
		countdown.size = Vector2(35, 42)
		countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		token.add_child(countdown)


## Motion lands in the portrait, then pulses its moon and countdown separately.
## Positive instance IDs must match exactly when two Birds share a definition.
func arrival_target(unit: Dictionary) -> Dictionary:
	var iid: int = Data.i(unit, "iid", -1)
	for index: int in _birds.size():
		var bird: Dictionary = _birds[index]
		if (
			(iid > 0 and Data.i(bird, "iid", -2) == iid)
			or (iid <= 0 and Data.s(bird, "def_id") == Data.s(unit, "def_id"))
		):
			var token: Interactive = tokens[index]
			return {
				"portrait": token.get_node("Portrait"),
				"countdown": token.get_node_or_null("Countdown"),
				"mark": token.get_node("JourneyMark"),
			}
	return {}


func _draw_token(token: Control, waiting: bool) -> void:
	var side: float = token_size()
	var badge := Rect2(side - 68, side - 48, 64, 44)
	token.draw_style_box(UiTheme.flat_box(UiTheme.NIGHTSHADE_DARK, UiTheme.INK, 3, 20), badge)
	var at: Vector2 = badge.position + Vector2(16, 21)
	if waiting:
		var door := Rect2(badge.position + Vector2(19, 6), Vector2(27, 33))
		token.draw_style_box(UiTheme.flat_box(UiTheme.OAK, UiTheme.CREAM, 2, 7), door)
		token.draw_circle(door.position + Vector2(20, 19), 2.5, UiTheme.INK)
	else:
		token.draw_circle(at, 11, UiTheme.CREAM)
		token.draw_circle(at + Vector2(5, -4), 10, UiTheme.NIGHTSHADE_DARK)


func _on_token_tapped(_zone: String, index: int) -> void:
	var view: Dictionary = reader_for(index)
	if not view.is_empty():
		bird_requested.emit(view, Data.i(view, "nest", -1))


## Copy the entire source view; reader prose uses exact integers, never abbreviated forecasts.
func reader_for(index: int) -> Dictionary:
	if index < 0 or index >= _birds.size():
		return {}
	var bird: Dictionary = _birds[index].duplicate(true)
	var notes: PackedStringArray = []
	if not Data.s(bird, "text").is_empty():
		notes.append(Data.s(bird, "text"))
	if bird.has("attack") and bird.has("health"):
		notes.append(
			"Now: %d Attack / %d Health." % [Data.i(bird, "attack"), Data.i(bird, "health")]
		)
	if bird.has("home_attack") and bird.has("home_health"):
		notes.append(
			(
				"Homecoming: %d Attack / %d Health."
				% [Data.i(bird, "home_attack"), Data.i(bird, "home_health")]
			)
		)
	if Data.b(bird, "doorstep"):
		notes.append("On the doorstep until your hand has room.")
	else:
		var turns: int = Data.i(bird, "turns_left")
		notes.append("Home in %d %s." % [turns, "turn" if turns == 1 else "turns"])
	var nest: int = Data.i(bird, "nest", -1)
	if nest >= 0 and nest < 7:
		notes.append(
			(
				"Its Nest: %s row, %d from the left."
				% ["front" if nest < 4 else "back", nest + 1 if nest < 4 else nest - 3]
			)
		)
	bird["text"] = "\n".join(notes)
	bird["type_word"] = "Bird waiting" if Data.b(bird, "doorstep") else "Bird away"
	return bird


func _layout() -> void:
	if _scroll == null:
		return
	custom_minimum_size.y = row_height() if visible else 0.0
	_scroll.position = Vector2.ZERO
	_scroll.size = Vector2(size.x, minf(size.y, row_height()))
	for token: Interactive in tokens:
		token.queue_redraw()
