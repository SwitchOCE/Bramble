extends Control
## The hero's corner on the recruit screen: portrait on an oak plaque, name, and the hero power's
## leaf. Reads state "hero" {id, name, text, kind, cost, uses_left}; a passive power has no leaf.
## With no hero in the state it stays hidden and the brick's corner is simply free.

signal power_pressed
signal portrait_pressed

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")

const LEAF_H: float = 122.0

var power: LeafButton

var _panel: WoodPanel
var _art: ArtFrame
var _name: Label
var _tap: Interactive
var _cost: ShapeBadge
var _cost_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_panel)
	_art = ArtFrame.new()
	_art.radius = 14.0
	add_child(_art)
	_name = UiTheme.head("", UiTheme.FONT_SMALL)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.set_meta("ellipsis_ok", true)
	add_child(_name)
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
	resized.connect(_layout)
	ready.connect(_layout)


## `hero` empty: nothing to show yet.
func show_hero(hero: Dictionary, gold: int = 0) -> void:
	visible = not hero.is_empty()
	if not visible:
		return
	_name.text = Data.s(hero, "name")
	_art.texture = UiTheme.portrait_for(Data.s(hero, "id"), [])
	power.visible = Data.s(hero, "kind") == "activated"
	power.set_face("Power")
	_cost.visible = power.visible
	var cost: int = Data.i(hero, "cost", 0)
	_cost_label.text = str(cost)
	power.disabled = Data.i(hero, "uses_left", 0) <= 0 or cost > gold
	_layout()


func _layout() -> void:
	var leaf: float = LEAF_H if power.visible else 0.0
	var plaque_h: float = size.y - leaf - 10.0
	_panel.size = Vector2(size.x, plaque_h - _panel.edge)
	_art.position = Vector2(14, 14)
	_art.size = Vector2(size.x - 28.0, plaque_h - 80.0)
	_name.position = Vector2(4, plaque_h - 62.0)
	_name.size = Vector2(size.x - 8.0, 44)
	_tap.position = Vector2.ZERO
	_tap.size = Vector2(size.x, plaque_h)
	_cost.position = Vector2(size.x - 44.0, -14)
	_cost.size = Vector2(56, 56)
	power.position = Vector2(-6.0, size.y - leaf)
	power.size = Vector2(size.x + 12.0, leaf)
