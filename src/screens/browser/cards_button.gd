class_name CardsButton
extends Control
## The recruit screen entry and its browser stand-in.

signal pressed

var held: Callable
var l1: bool = false
var at: Vector2 = BrowserLook.BUTTON_AT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if l1:
		var entry: TextureRect = L1ColumnArt.entry("right.library", L1ColumnArt.BOOK, _pressed)
		entry.name = "CardsButton"
		add_child(entry)
		return
	position = at
	var button: GlassBox = GlassUi.button(self, "", Vector2.ZERO, BrowserLook.BUTTON_SIDE, _pressed)
	button.name = "CardsButton"
	button.box_size = Vector2.ONE * BrowserLook.BUTTON_SIDE
	button.refresh()
	var icon: TextureRect = TextureRect.new()
	icon.texture = GlassPieces.svg_icon(
		BrowserLook.CARDS_ICON,
		GlassPieces.rule_colour("stage", ".btn svg", "stroke"),
		BrowserLook.BUTTON_ICON_PX,
		GlassPieces.rule_number("stage", ".btn svg", "stroke-width")
	)
	icon.size = Vector2.ONE * BrowserLook.BUTTON_ICON_PX
	icon.position = ((button.box_size - icon.size) / 2.0).round()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	var label: GlassText = GlassUi.title(
		self,
		"Cards",
		BrowserLook.BUTTON_SIDE / 2.0,
		BrowserLook.BUTTON_SIDE + BrowserLook.BUTTON_LABEL_GAP,
		BrowserLook.BUTTON_LABEL_PX
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _pressed() -> void:
	if not held.is_valid() or held.call() != true:
		pressed.emit()
