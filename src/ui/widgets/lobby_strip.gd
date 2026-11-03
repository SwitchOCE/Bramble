extends PanelContainer
## The lobby: every player's health, tier and last result, with the next opponent marked.
## Reads SPEC 6.4 standings plus the state's next_opponent_id.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")

## The bar's full length: the highest health this strip has seen in the standings (everyone's
## starting health on turn 1), so no tunable is copied into the UI. Static: it outlives each
## recruit screen.
static var bar_scale: float = 1.0

var _rows: VBoxContainer


func _init() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	box.add_child(UiTheme.label("Lobby", UiTheme.FONT_BODY, UiTheme.TEXT_DIM))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	box.add_child(_rows)


func show_standings(standings: Array, next_opponent_id: int) -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for entry: Variant in standings:
		var seen: Dictionary = entry
		bar_scale = maxf(bar_scale, float(Data.i(seen, "health", 0)))
	for entry: Variant in standings:
		var standing: Dictionary = entry
		var player_id: int = Data.i(standing, "player_id", -1)
		_rows.add_child(_row(standing, player_id == next_opponent_id))
	if next_opponent_id == -1:
		_rows.add_child(UiTheme.label("Next: the ghost", UiTheme.FONT_SMALL, UiTheme.SELECT))


func _row(standing: Dictionary, is_next: bool) -> PanelContainer:
	var alive: bool = Data.b(standing, "alive", true)
	var human: bool = Data.b(standing, "is_human", false)
	var fill: Color = UiTheme.PANEL_LIGHT if alive else UiTheme.OUT_FILL
	var border: Color = UiTheme.SELECT if is_next else (UiTheme.GOLD if human else fill)
	var panel: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = UiTheme.flat_box(fill, border, 3 if (is_next or human) else 0, 8)
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", box)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)
	var top: HBoxContainer = HBoxContainer.new()
	column.add_child(top)
	if UiTheme.has_shape("lobby_tier"):
		top.add_child(_tier_knot(Data.i(standing, "tier", 1)))
	var name_text: String = str(standing.get("name", "?"))
	var name_colour: Color = UiTheme.TEXT if alive else UiTheme.TEXT_DIM
	var name_label: Label = UiTheme.label(name_text, UiTheme.FONT_SMALL, name_colour)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	top.add_child(name_label)
	var health: int = Data.i(standing, "health", 0)
	var health_label: Label = UiTheme.label(
		str(maxi(health, 0)), UiTheme.FONT_BODY, UiTheme.LOBBY_HEALTH
	)
	top.add_child(health_label)
	var bottom: HBoxContainer = HBoxContainer.new()
	column.add_child(bottom)
	var detail: String = "Tier %d" % Data.i(standing, "tier", 1)
	if not alive:
		var placement: Variant = standing.get("placement")
		detail = (
			"Out · %s" % (UiTheme.ordinal(Data.as_int(placement)) if placement != null else "-")
		)
	var result: Variant = standing.get("last_result")
	var result_text: String = ""
	var result_colour: Color = UiTheme.TEXT_DIM
	match str(result) if result != null else "":
		"win":
			result_text = "won"
			result_colour = UiTheme.WIN
		"loss":
			result_text = "lost"
			result_colour = UiTheme.LOSS
		"tie":
			result_text = "tie"
			result_colour = UiTheme.TIE
	var detail_label: Label = UiTheme.label(detail, 16, UiTheme.TEXT_DIM)
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(detail_label)
	if is_next:
		bottom.add_child(UiTheme.label("NEXT  ", 16, UiTheme.SELECT))
	bottom.add_child(UiTheme.label(result_text, 16, result_colour))
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = bar_scale
	bar.value = clampf(float(health), 0.0, bar_scale)
	bar.custom_minimum_size = Vector2(0, 6)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UiTheme.thin_box(UiTheme.BAR_BACK))
	bar.add_theme_stylebox_override(
		"fill", UiTheme.thin_box(UiTheme.HEALTH if alive else UiTheme.BAR_OUT)
	)
	column.add_child(bar)
	return panel


## Woodcraft's tier knot: the player's tier on a small disc, as on the card's tier badge.
func _tier_knot(tier: int) -> Control:
	var knot: ShapeBadge = ShapeBadge.new()
	knot.set_look("circle", UiTheme.TIER_FILL, UiTheme.TIER_BORDER, 2.0)
	knot.custom_minimum_size = Vector2(28, 28)
	knot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var number: Label = UiTheme.label(str(tier), 16, UiTheme.TIER_TEXT)
	number.name = "TierKnot"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	if UiTheme.number_font() != null:
		number.add_theme_font_override("font", UiTheme.number_font())
	knot.add_child(number)
	return knot
