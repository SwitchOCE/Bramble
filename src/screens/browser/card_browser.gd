class_name CardBrowser
extends GlassScreen
## The compendium is its own screen; its hover is GlassTips, exactly as the shop's base hover.
## Filters and scrolling only affect these view nodes, never the live game beneath the layer.

signal close_requested

var content: GameContent
var in_game: bool = false
var spells: bool = false
var golden: bool = false
var tribe: String = ""
var tier: int = 0
var query: String = ""
var catalog: BrowserCatalog
var scroll: ScrollContainer
var search: LineEdit
var _list: Control
var _layout_spec: Dictionary


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit)
	if content == null:
		content = GameContent.load_default()
	catalog = BrowserCatalog.new(content)
	state = {"display": content.display_table()}
	_layout_spec = BrowserLook.INSIDE if in_game else BrowserLook.OUTSIDE
	super()


func _geom() -> Dictionary:
	var g: Dictionary = GlassPieces.recruit_geom().duplicate()
	g.merge(BrowserLook.BACKGROUND, true)
	return g


func _make_tips() -> GlassTips:
	var tips: GlassTips = super()
	tips.content = content
	return tips


func _build() -> void:
	if in_game:
		var dim: ColorRect = ColorRect.new()
		dim.name = "Dim"
		dim.color = BrowserLook.DIM
		dim.size = _stage.size
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_back.add_child(dim)
		var pane: GlassBox = GlassUi.pane(_back, BrowserLook.PANE)
		pane.radii = Vector4.ONE * BrowserLook.PANE_RADIUS
		pane.refresh()
	else:
		_add_window()
	if in_game:
		var entry: CardsButton = CardsButton.new()
		entry.name = "OpenCardsEntry"
		entry.pressed.connect(close_requested.emit)
		_front.add_child(entry)
		var button: GlassBox = entry.get_node("CardsButton")
		StartScreen._ring(button)
	_build_filters()
	var title_at: Vector2 = _layout_spec["title"]
	GlassUi.text_at(_front, "Cards", title_at, BrowserLook.TITLE_PX)
	_build_search()
	_build_scroll()
	if not in_game:
		_add_vignette()
		(_front.get_node("Vignette") as CanvasItem).modulate.a = BrowserLook.VIGNETTE_ALPHA


func select_kind(show_spells: bool) -> void:
	spells = show_spells
	tribe = ""
	_redraw_filters()


func select_tribe(value: String) -> void:
	tribe = value
	_redraw_filters()


func select_tier(value: int) -> void:
	tier = value
	_redraw_filters()


func toggle_golden() -> void:
	golden = not golden
	_redraw_filters()


func set_query(value: String) -> void:
	query = value
	_fill_grid()


func _redraw_filters() -> void:
	var focus_search: bool = search != null and search.has_focus()
	_layout()
	if focus_search:
		search.grab_focus()


func _build_filters() -> void:
	var at: Vector2 = _layout_spec["filters"]
	var y: float = at.y
	BrowserLook.filter_button(
		_front,
		"Close" if in_game else "Back",
		Vector2(at.x, y),
		BrowserLook.FILTER_WIDTH,
		close_requested.emit,
		false,
		true
	)
	y += BrowserLook.BUTTON_HEIGHT + BrowserLook.GAP
	y = _filter_label("Show", at.x, y)
	var half: float = (BrowserLook.FILTER_WIDTH - BrowserLook.GAP) / 2.0
	BrowserLook.filter_button(
		_front,
		"Units",
		Vector2(at.x, y),
		half,
		select_kind.bind(false),
		not spells,
		true,
		BrowserLook.KIND_PX
	)
	BrowserLook.filter_button(
		_front,
		"Spells",
		Vector2(at.x + half + BrowserLook.GAP, y),
		half,
		select_kind.bind(true),
		spells,
		true,
		BrowserLook.KIND_PX
	)
	y += BrowserLook.BUTTON_HEIGHT + BrowserLook.GAP
	if not spells:
		BrowserLook.filter_button(
			_front, "Golden", Vector2(at.x, y), BrowserLook.FILTER_WIDTH, toggle_golden, golden
		)
		y += BrowserLook.BUTTON_HEIGHT + BrowserLook.GAP
		y = _filter_label("Tribe", at.x, y)
		BrowserLook.filter_button(
			_front,
			"All tribes",
			Vector2(at.x, y),
			BrowserLook.FILTER_WIDTH,
			select_tribe.bind(""),
			tribe == ""
		)
		y += BrowserLook.BUTTON_HEIGHT + BrowserLook.GAP
		for folder: String in BrowserCatalog.TRIBE_ORDER:
			if not content.tribe_ids().has(folder):
				continue
			var words: String = content.tribe_name(folder)
			# The start screen's plural labels, matching the approved browser.
			words = (
				{
					"Badger": "Badgers",
					"Mouse": "Mice",
					"Pigeon": "Pigeons",
					"Locust": "Locusts",
					"Briar": "Briars"
				}
				. get(words, words)
			)
			BrowserLook.filter_button(
				_front,
				words,
				Vector2(at.x, y),
				BrowserLook.FILTER_WIDTH,
				select_tribe.bind(folder),
				tribe == folder
			)
			y += BrowserLook.BUTTON_HEIGHT + BrowserLook.GAP
	y = _filter_label("Tier", at.x, y)
	BrowserLook.filter_button(
		_front,
		"All tiers",
		Vector2(at.x, y),
		BrowserLook.FILTER_WIDTH,
		select_tier.bind(0),
		tier == 0,
		true
	)
	y += BrowserLook.BUTTON_HEIGHT + BrowserLook.GAP
	var width: float = (BrowserLook.FILTER_WIDTH - 2.0 * BrowserLook.GAP) / 3.0
	for t: int in range(1, 7):
		var col: int = (t - 1) % 3
		var row: int = floori((t - 1) / 3.0)
		var box: GlassBox = BrowserLook.filter_button(
			_front,
			str(t),
			Vector2(
				at.x + col * (width + BrowserLook.GAP),
				y + row * (BrowserLook.BUTTON_HEIGHT + BrowserLook.GAP)
			),
			width,
			select_tier.bind(t),
			tier == t,
			true
		)
		box.name = "Tier_%d" % t
		var text: GlassText = box.get_child(0) as GlassText
		var icon: TextureRect = TextureRect.new()
		icon.texture = GlassPieces.icon(
			"tier", text.colour, BrowserLook.TIER_ICON_PX, BrowserLook.ICON_STROKE
		)
		icon.size = Vector2.ONE * BrowserLook.TIER_ICON_PX
		var whole: float = icon.size.x + BrowserLook.TIER_ICON_GAP + text.size.x
		icon.position = Vector2(
			(width - whole) / 2.0, (BrowserLook.BUTTON_HEIGHT - icon.size.y) / 2.0
		)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
		text.position.x = icon.position.x + icon.size.x + BrowserLook.TIER_ICON_GAP


func _filter_label(words: String, x: float, y: float) -> float:
	var text: GlassText = BrowserLook.label(
		_front,
		words,
		Vector2(x, y + BrowserLook.LABEL_TOP),
		BrowserLook.LABEL_PX,
		true,
		BrowserLook.LABEL_COLOUR
	)
	return text.position.y + text.size.y + BrowserLook.GAP


func _build_search() -> void:
	var box: Panel = Panel.new()
	box.name = "SearchBox"
	box.position = _layout_spec["search"]
	box.size = BrowserLook.SEARCH_SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BrowserLook.SEARCH_BG
	style.border_color = BrowserLook.SEARCH_LEAD
	style.set_border_width_all(BrowserLook.SEARCH_BORDER)
	style.set_corner_radius_all(BrowserLook.SEARCH_RADIUS)
	box.add_theme_stylebox_override("panel", style)
	_front.add_child(box)
	var icon: TextureRect = TextureRect.new()
	icon.texture = GlassPieces.svg_icon(
		BrowserLook.SEARCH_ICON,
		BrowserLook.MUTED,
		BrowserLook.SEARCH_ICON_PX,
		BrowserLook.ICON_STROKE
	)
	icon.position = Vector2(BrowserLook.SEARCH_PAD, (box.size.y - BrowserLook.SEARCH_ICON_PX) / 2.0)
	icon.size = Vector2.ONE * BrowserLook.SEARCH_ICON_PX
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	search = LineEdit.new()
	search.name = "Search"
	search.text = query
	search.placeholder_text = "Search cards"
	search.position = Vector2(
		BrowserLook.SEARCH_PAD + BrowserLook.SEARCH_ICON_PX + BrowserLook.SEARCH_GAP, 0
	)
	search.size = Vector2(box.size.x - search.position.x - BrowserLook.SEARCH_PAD, box.size.y)
	search.add_theme_font_override("font", GlassPieces.body_font(400))
	search.add_theme_font_size_override("font_size", int(BrowserLook.BUTTON_PX))
	search.add_theme_color_override("font_color", BrowserLook.LABEL_COLOUR)
	search.add_theme_color_override("font_placeholder_color", BrowserLook.SEARCH_COLOUR)
	for state_name: String in ["normal", "focus", "read_only"]:
		search.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	search.text_changed.connect(set_query)
	box.add_child(search)


func _build_scroll() -> void:
	var area: Rect2 = _layout_spec["grid"]
	scroll = ScrollContainer.new()
	scroll.name = "CardGrid"
	scroll.position = area.position
	scroll.size = area.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_back.add_child(scroll)
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var track: StyleBoxEmpty = StyleBoxEmpty.new()
	track.content_margin_left = BrowserLook.SCROLL_WIDTH
	bar.add_theme_stylebox_override("scroll", track)
	for key: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = BrowserLook.SCROLL_COLOUR
		style.set_corner_radius_all(floori(BrowserLook.SCROLL_WIDTH / 2.0))
		bar.add_theme_stylebox_override(key, style)
	_list = Control.new()
	_list.name = "Cards"
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(_list)
	scroll.scroll_started.connect(_tips.hide)
	_fill_grid()


func _fill_grid() -> void:
	if _list == null:
		return
	_tips.hide()
	_targets.clear()
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var previous: Node = _front.get_node_or_null("Count")
	if previous != null:
		_front.remove_child(previous)
		previous.queue_free()
	var cards: Array[Dictionary] = catalog.matching(spells, tribe, tier, query)
	var noun: String = "spell" if spells else "unit"
	var count_at: Vector2 = _layout_spec["count"]
	var count_label: GlassText = BrowserLook.label(
		_front,
		"%d %s%s" % [cards.size(), noun, "" if cards.size() == 1 else "s"],
		count_at,
		BrowserLook.COUNT_PX
	)
	count_label.name = "Count"
	var width: float = scroll.size.x - BrowserLook.GRID_PADDING.x - BrowserLook.GRID_RIGHT
	var y: float = BrowserLook.GRID_PADDING.y
	for group: int in range(1, 8):
		var members: Array[Dictionary] = []
		for card: Dictionary in cards:
			if (
				(group == 7 and _b(card["token"]))
				or (group != 7 and not _b(card["token"]) and _i(card["tier"]) == group)
			):
				members.append(card)
		if members.is_empty():
			continue
		y += BrowserLook.HEADING_TOP
		var heading: GlassText = BrowserLook.label(
			_list,
			"Tokens" if group == 7 else "Tier %d" % group,
			Vector2(BrowserLook.GRID_PADDING.x, y),
			BrowserLook.HEADING_PX,
			true,
			BrowserLook.HEADING_COLOUR
		)
		var amount: GlassText = BrowserLook.label(
			_list,
			str(members.size()),
			Vector2(
				heading.position.x + heading.size.x + BrowserLook.HEADING_GAP,
				y + BrowserLook.TIER_COUNT_DOWN
			),
			BrowserLook.HEADING_COUNT_PX
		)
		_add_rule(
			Vector2(
				amount.position.x + amount.size.x + BrowserLook.HEADING_GAP,
				y + heading.size.y / 2.0
			),
			width
		)
		y += heading.size.y + BrowserLook.HEADING_BOTTOM
		var columns: int = maxi(
			1,
			floori((width + BrowserLook.CARD_GAP.x) / (BrowserLook.CARD_W + BrowserLook.CARD_GAP.x))
		)
		for i: int in members.size():
			var at: Vector2 = Vector2(
				(
					BrowserLook.GRID_PADDING.x
					+ (i % columns) * (BrowserLook.CARD_W + BrowserLook.CARD_GAP.x)
				),
				y + floori(i / float(columns)) * (BrowserLook.CELL_H + BrowserLook.CARD_GAP.y)
			)
			_add_cell(members[i], at)
		y += (
			ceilf(members.size() / float(columns)) * (BrowserLook.CELL_H + BrowserLook.CARD_GAP.y)
			- BrowserLook.CARD_GAP.y
		)
	if cards.is_empty():
		BrowserLook.label(
			_list,
			"No cards match. Try another search or filter.",
			BrowserLook.GRID_PADDING,
			BrowserLook.COUNT_PX
		)
	_list.custom_minimum_size = Vector2(width, y + BrowserLook.GRID_BOTTOM)
	scroll.scroll_vertical = 0
	# The tooltip is made by GlassScreen after the initial build, and already exists on a filter.
	if _tips.tip != null and pinned_hover != "":
		_tips.pin(pinned_hover)


func _add_cell(card: Dictionary, at: Vector2) -> void:
	if golden and not _is_spell(card):
		card = card.duplicate(true)
		card.merge(ViewAdapter.printed_unit(content, str(card["id"]), true), true)
	var cell: Control = Control.new()
	cell.name = "Cell_" + str(card["id"])
	cell.position = at
	cell.size = Vector2(BrowserLook.CARD_W, BrowserLook.CELL_H)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(cell)
	var node: Control
	if _is_spell(card):
		var spell_h: float = BrowserLook.CARD_W / (sqrt(3.0) / 2.0)
		node = _spell_card(card, Vector2(BrowserLook.CARD_W, spell_h))
		node.position.y = (BrowserLook.CARD_H - spell_h) / 2.0
	else:
		node = _unit_card(card, BrowserLook.CARD_H)
	cell.add_child(node)
	var caption: Label = Label.new()
	caption.position = Vector2(0, BrowserLook.CARD_H + BrowserLook.NAME_DOWN)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font", GlassPieces.body_font(700))
	caption.add_theme_font_size_override("font_size", int(BrowserLook.NAME_PX))
	caption.add_theme_color_override("font_color", BrowserLook.CAPTION_COLOUR)
	caption.add_theme_color_override("font_outline_color", BrowserLook.INK)
	caption.add_theme_constant_override("outline_size", BrowserLook.CAPTION_OUTLINE)
	caption.size = Vector2(
		BrowserLook.CARD_W + BrowserLook.CAPTION_OVERHANG, BrowserLook.CAPTION_HEIGHT
	)
	caption.text = str(card["name"])
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(caption)
	_targets.append(
		{
			"kind": "spell" if spells else "shop",
			"index": _targets.size(),
			"node": node,
			"card": card,
			"poly":
			(
				GlassBox.hexagon(Rect2(Vector2.ZERO, node.size), BrowserLook.SPELL_SHOULDER)
				if spells
				else L1CardFace.unit_outline(node.size)
			)
		}
	)


func _target_at(at: Vector2, cards_only: bool) -> Dictionary:
	var area: Rect2 = _layout_spec.get("grid", Rect2())
	return super(at, cards_only) if area.has_point(at) else {}


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_requested.emit()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_pointer = _stage.make_canvas_position_local(motion.position)
		_tips.hover(_pointer)


## No leaderboard shortcut here; Escape is consumed in _input, including from the search field.
func _unhandled_key_input(_event: InputEvent) -> void:
	pass


func _draw() -> void:
	if not in_game:
		super()


func _add_rule(at: Vector2, right: float) -> void:
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([BrowserLook.RULE_COLOUR, Color.TRANSPARENT])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	var rule: TextureRect = TextureRect.new()
	rule.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rule.texture = texture
	rule.position = at
	rule.size = Vector2(right - at.x, BrowserLook.RULE_HEIGHT)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(rule)
