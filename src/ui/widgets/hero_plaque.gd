extends Control
## The hero portrait, live Health and power sit together beside the formation.

signal power_pressed
signal portrait_pressed

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")

var power: LeafButton

var _art: ArtFrame
var _tap: Interactive
var _cost: ShapeBadge
var _cost_label: Label

var _health: ShapeBadge
var _health_value: Label
var _armor: ShapeBadge
var _armor_value: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = ArtFrame.new()
	_art.radius = 14.0
	add_child(_art)
	_tap = Interactive.new()
	_tap.tapped.connect(func(_zone: String, _index: int) -> void: portrait_pressed.emit())
	add_child(_tap)
	power = LeafButton.new()
	power.pressed.connect(func() -> void: power_pressed.emit())
	add_child(power)
	power.set_label_size(UiTheme.FONT_BODY)
	_cost = ShapeBadge.new("knot_gold")
	add_child(_cost)
	_cost_label = UiTheme.number("", UiTheme.FONT_SMALL)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cost.add_child(_cost_label)
	_health = ShapeBadge.new("rosehip")
	add_child(_health)
	_health_value = UiTheme.number("", 40, UiTheme.CREAM)
	_health_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_health_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_health_value.set_anchors_preset(Control.PRESET_FULL_RECT)
	_health.add_child(_health_value)
	_armor = ShapeBadge.new("knot_out")
	add_child(_armor)
	_armor_value = UiTheme.number("", UiTheme.MIN_FONT)
	_armor_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_armor_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_armor_value.set_anchors_preset(Control.PRESET_FULL_RECT)
	_armor.add_child(_armor_value)
	resized.connect(_layout)
	ready.connect(_layout)


## `hero` empty: nothing to show yet.
func show_hero(hero: Dictionary, gold: int = 0) -> void:
	visible = not hero.is_empty()
	if not visible:
		return
	_art.texture = UiTheme.portrait_for(Data.s(hero, "id"), [])
	power.visible = Data.s(hero, "kind") == "activated"
	power.set_face("", "spark")
	power.tooltip_text = "Hero power"
	_cost.visible = power.visible
	var cost: int = Data.i(hero, "cost", 0)
	_cost_label.text = str(cost)
	var spent: bool = Data.i(hero, "uses_left", 0) <= 0 or not Data.b(hero, "usable", true)
	power.disabled = spent or cost > gold
	_layout()


func _layout() -> void:
	if _art == null:
		return
	_art.radius = 62
	_art.position = Vector2.ZERO
	_art.size = Vector2(120, 120)
	_tap.position = _art.position
	_tap.size = _art.size
	power.position = Vector2(132, 0)
	power.size = Vector2(122, 122)
	_cost.position = Vector2(210, -8)
	_cost.size = Vector2(48, 48)
	if _health != null:
		_health.position = Vector2(72, 49)
		_health.size = Vector2(68, 68)
		_armor.position = Vector2(-10, 50)
		_armor.size = Vector2(48, 48)


func show_health(health: int, armor: int) -> void:
	_health_value.text = str(health)
	_armor_value.text = str(armor)
	_armor.visible = armor > 0
