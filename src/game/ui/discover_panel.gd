class_name DiscoverPanel
extends Control
## STAND-IN Discover picker until the recruit screen draws the state's `discover` itself (the
## screens worker is adding one, from its own HTML mock-up): the options as cards on a pane over
## the recruit screen; clicking one picks it. Delete this when the screen's picker lands.

signal picked(index: int)

const CARD_H: float = 300.0
const GAP: float = 40.0

## {prompt, options: [unit]} from the view state.
var discover: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var stage: Control = GlassUi.stage(self)
	var dim: ColorRect = ColorRect.new()
	dim.color = PausePanel.DIM
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.size = stage.size
	stage.add_child(dim)
	var options: Array = discover.get("options", [])
	var card_size: Vector2 = GlassCard.card_size(CARD_H)
	var width: float = options.size() * (card_size.x + GAP) + GAP
	var left: float = 960.0 - width / 2.0
	GlassUi.pane(stage, Rect2(left, 260, width, CARD_H + 220))
	GlassUi.title(stage, str(discover.get("prompt", "Discover")), 960, 290, 40)
	for i: int in options.size():
		var unit: Dictionary = options[i]
		var card: GlassCard = GlassCard.new()
		card.name = "Option_%d" % i
		card.tier = CoreUtil.to_int(unit.get("tier", 1))
		card.art = GlassPieces.art(str(unit.get("art", "")))
		card.attack = CoreUtil.to_int(unit.get("attack", 0))
		card.health = CoreUtil.to_int(unit.get("health", 0))
		card.card_height = CARD_H
		card.position = Vector2(left + GAP + i * (card_size.x + GAP), 360)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(_on_card_input.bind(i))
		card.mouse_entered.connect(card.set_hot.bind(true))
		card.mouse_exited.connect(card.set_hot.bind(false))
		stage.add_child(card)
		# GlassCard ignores the pointer from its _ready; this one is a button
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		GlassUi.title(
			stage, str(unit.get("name", "")), card.position.x + card_size.x / 2.0, 670, 22
		)


func _on_card_input(event: InputEvent, index: int) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		picked.emit(index)
