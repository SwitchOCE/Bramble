class_name GlassUi
extends RefCounted
## The few glass pieces the game flow's plain screens are made of, each from the mock-ups' own
## CSS rules (stage.css through GlassPieces): the stone window, the leaderboard's pane, .btn,
## .lbl, portraits, Health badges. The places are in docs/ideation-track-2/mockups/menus.js and
## each screen's page there.

const MUTED: Color = Color("c9bda6")
const GO: Color = Color("ffb24a")

static var _icons: Dictionary = {}


## An icon drawn as stage.js's ICON are (a 24 box, stroked, no fill), `px` square.
static func svg_icon(svg: String, tint: Color, px: int, stroke: float) -> Texture2D:
	var key: String = "%s/%s/%d/%s" % [svg.hash(), tint.to_html(), px, stroke]
	if not _icons.has(key):
		var attrs: String = (
			(
				'<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="none" '
				+ 'stroke="#%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" '
			)
			% [tint.to_html(false), stroke]
		)
		var image: Image = Image.new()
		var err: Error = image.load_svg_from_string(svg.replace("<svg ", attrs), float(px) / 24.0)
		assert(err == OK, "icon does not load")
		image.generate_mipmaps()
		_icons[key] = ImageTexture.create_from_image(image)
	var tex: Texture2D = _icons[key]
	return tex


## A 1920 x 1080 stage that takes no input itself.
static func stage(parent: Control) -> Control:
	var out: Control = Control.new()
	out.name = "Stage"
	out.mouse_filter = Control.MOUSE_FILTER_IGNORE
	out.size = Vector2(GlassPieces.number("stage.width"), GlassPieces.number("stage.height"))
	parent.add_child(out)
	return out


## The stone window at the fight screen's geometry, with the field behind its lights.
static func backdrop(on: Control) -> void:
	var window: StoneWindow = StoneWindow.new()
	window.name = "Window"
	on.add_child(window)
	window.build(GlassPieces.fight_geom())


static func vignette(on: Control) -> void:
	var vig: GlassBox = GlassBox.new()
	vig.name = "Vignette"
	vig.box_size = on.size
	vig.use_css("stage", "#vig").refresh()
	on.add_child(vig)


## #lbpane at a place and size.
static func pane(on: Control, rect: Rect2) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.name = "Pane"
	box.box_size = rect.size
	box.use_css("stage", "#lbpane")
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", "#lbpane", "border-radius"), rect.size)
	box.position = rect.position
	box.refresh()
	on.add_child(box)
	return box


## A .lbl of `px` centred on cx, its top at y.
static func title(
	on: Control, words: String, cx: float, y: float, px: float, colour: Color = Color.TRANSPARENT
) -> GlassText:
	var label: GlassText = GlassText.from_rule("stage", ".lbl", words)
	label.font_px = px
	if colour.a > 0.0:
		label.colour = colour
	label.refresh()
	label.position = Vector2(roundf(cx - label.size.x / 2.0), y)
	on.add_child(label)
	return label


## A .lbl of `px` with its top left at `at`.
static func text_at(
	on: Control, words: String, at: Vector2, px: float, colour: Color = Color.TRANSPARENT
) -> GlassText:
	var label: GlassText = GlassText.from_rule("stage", ".lbl", words)
	label.font_px = px
	if colour.a > 0.0:
		label.colour = colour
	label.refresh()
	label.position = at
	on.add_child(label)
	return label


## A .btn `width` wide with its words centred. `pressed` is called on a left click.
static func button(
	on: Control, words: String, at: Vector2, width: float, pressed: Callable, dim: bool = false
) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.name = "Button_" + words.replace(" ", "_")
	box.box_size = Vector2(width, GlassPieces.rule_number("stage", ".btn", "height"))
	box.use_css("stage", ".btn")
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".btn", "border-radius"), box.box_size)
	box.position = at
	box.refresh()
	var label: GlassText = GlassText.new()
	label.words = words
	label.use_font(GlassPieces.rule_font("stage", ".btn"))
	label.colour = GlassPieces.rule_colour("stage", ".btn", "color")
	label.refresh()
	var content: Vector2 = box.padding_rect().size
	label.position = (
		(Vector2(box.border_width, box.border_width) + (content - label.size) / 2.0).round()
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	box.modulate.a = 0.45 if dim else 1.0
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	box.gui_input.connect(
		func(event: InputEvent) -> void:
			var click: InputEventMouseButton = event as InputEventMouseButton
			if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
				pressed.call()
	)
	box.mouse_entered.connect(
		func() -> void:
			label.colour = GO
			label.queue_redraw()
	)
	box.mouse_exited.connect(
		func() -> void:
			label.colour = GlassPieces.rule_colour("stage", ".btn", "color")
			label.queue_redraw()
	)
	on.add_child(box)
	return box


## A leaderboard portrait (.lb .port), with the pale ring for you.
static func portrait(on: Control, picture: String, at: Vector2, side: float, you: bool) -> void:
	var rules: Array = [".lb .port"]
	if you:
		rules.append(".lb .you .port")
	var port: GlassBox = GlassParts.make_portrait(picture, side, rules)
	port.position = at
	on.add_child(port)


## The leaderboard's small Health badge (.hp, .lb .hp).
static func health(on: Control, value: int, at: Vector2) -> void:
	var hp: GlassBox = GlassParts.health_badge(value, [".hp", ".lb .hp"])
	hp.position = at
	on.add_child(hp)


## The leaderboard's place number (.lb .pl).
static func place_number(on: Control, place: int, at: Vector2) -> void:
	var label: GlassText = GlassText.from_rule("stage", ".lb .pl", str(place))
	label.refresh()
	label.position = at
	on.add_child(label)
