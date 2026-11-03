extends Control
## Title screen: Play, Sandbox, Quit. "Bramble" is a code name.

signal play_requested
signal sandbox_requested
signal quit_requested

const UiTheme := preload("res://src/ui/ui_theme.gd")


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = UiTheme.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var strip: HBoxContainer = HBoxContainer.new()
	strip.set_anchors_preset(Control.PRESET_FULL_RECT)
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 10)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.modulate = Color(1, 1, 1, 0.16)
	add_child(strip)
	for tribe: String in UiTheme.TRIBE_PORTRAITS:
		var art: TextureRect = TextureRect.new()
		art.texture = UiTheme.portrait([tribe])
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(300, 300)
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(art)
	var centre: CenterContainer = CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	centre.add_child(box)
	var title: Label = UiTheme.label("Bramble", UiTheme.FONT_HUGE + 32, UiTheme.GOLD)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", UiTheme.INK)
	title.add_theme_constant_override("outline_size", 16)
	box.add_child(title)
	var subtitle: Label = UiTheme.label(
		"code name  ·  overnight prototype", UiTheme.FONT_BODY, UiTheme.TEXT_DIM
	)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(Control.new())
	box.add_child(_menu_button("Play", play_requested))
	box.add_child(_menu_button("Sandbox", sandbox_requested))
	box.add_child(_menu_button("Quit", quit_requested))


func _menu_button(text: String, on_press: Signal) -> Button:
	var button: Button = UiTheme.button(text, 420, UiTheme.FONT_TITLE)
	button.name = text
	button.custom_minimum_size = Vector2(420, 90)
	button.pressed.connect(func() -> void: on_press.emit())
	return button
