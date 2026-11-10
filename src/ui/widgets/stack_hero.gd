extends "res://src/ui/widgets/hero_plaque.gd"
## A round portrait and power at the centre of the shared bar, with live Health and armor.

var _health: ShapeBadge
var _health_value: Label
var _armor: ShapeBadge
var _armor_value: Label


func _init() -> void:
	super()
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


func show_health(health: int, armor: int) -> void:
	_health_value.text = str(health)
	_armor_value.text = str(armor)
	_armor.visible = armor > 0


func _layout() -> void:
	if _art == null:
		return
	_panel.hide()
	_name.hide()
	_art.radius = 62
	_art.position = Vector2(0, -22)
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
