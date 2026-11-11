extends "res://src/ui/widgets/interactive.gd"
## Art and changing state shared by shop, hand, board, scout and combat tiles.
## Full rules, identity and counter breakdowns are in CardDetail. Only units without
## distinguishable portraits retain a short name; spells and items keep their cost knot.

enum Mode { SHOP, BOARD, MINI }

const CombatFace := preload("res://src/ui/widgets/combat_face.gd")
const PoachedBadge := preload("res://src/ui/widgets/poached_badge.gd")
const HedgeMarks := preload("res://src/ui/widgets/hedgerow_marks.gd")
const OozeMarks := preload("res://src/ui/widgets/ooze_marks.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const Settings := preload("res://src/ui/settings.gd")

const SHOP_WIDTH: float = 270.0
const SHOP_HEIGHT: float = SHOP_WIDTH / HexShape.RATIO
const BOARD_RATIO: float = 1.0 / HexShape.RATIO
const LINE: int = 4
const EDGE: float = 4.0
## Highcrown's cream light enters from upper right; the thin edge shades lower left.
const PAPER: Color = Color("eee5ca")
const BARK_EDGE: Color = Color("899078")
const PAPER_INK: Color = UiTheme.INK
const PAPER_LIGHT: Color = Color("fff4d9")
const CONTACT: Color = Color(0.06, 0.12, 0.10, 0.18)
## Public portrait floor used by layout checks.
const ART_MIN: float = 40.0
const ART_SHARE: float = 0.68
## Every shipped portrait is now distinct; future look-alike exceptions would live here.
const NAME_EXCEPTIONS: Dictionary[String, String] = {}

## def_id -> true for units whose mechanics are not built; the reader names them.
static var unbuilt: Dictionary = {}
## Tests set this to try a window shape. Zero reads the real window.
static var window_override: Vector2 = Vector2.ZERO

var unit: Dictionary = {}
## The size this card is laid out for (see LEARNINGS, 4 Nov: size lags behind the minimum size).
var card_size: Vector2 = Vector2(SHOP_WIDTH, SHOP_HEIGHT)
var mode: Mode = Mode.SHOP
## Combat limits trigger glyphs to abilities that can fire during the fight.
var combat_face: bool = false:
	set(value):
		combat_face = value
		_refresh()
var selected: bool = false:
	set(value):
		selected = value
		if _hedge_marks != null:
			_hedge_marks.show_state(unit, selected)
		queue_redraw()
## Scout selection differs from a target pulse and from a golden unit's rim.
var selection_color: Color = UiTheme.SELECT
## A ring round the tile: the drop-target moss, an attacker's acorn or a target's red.
var outline: Color = Color.TRANSPARENT:
	set(value):
		outline = value
		queue_redraw()
## Frozen in the shop: frost rim, rime over the art only. Stats stay clear.
var frost: bool = false:
	set(value):
		frost = value
		_art.frozen = value
		queue_redraw()
## Legacy state accepted from callers; counter pips and the reader carry it visually.
var turns_shown: String = "":
	set(value):
		turns_shown = value
		_place_turns()

## Legacy caller flag. Word chips are absent in every mode.
var chip_hidden: bool = false
## Historical diagnostics remain empty now that rules are read on demand.
var chip_shown: String = ""
## Full rules are always one tap away.
var rules_shown: bool = false

var _focus_rim: Control
var _combat_marks: CombatFace
var _poached_badge: PoachedBadge
var _hedge_marks: HedgeMarks
var _ooze_marks: OozeMarks
var _art: ArtFrame
var _chip: Panel
var _rules: Label
var _name_label: Label
var _type_label: Label
var _tier_badge: ShapeBadge
var _tier_label: Label
var _attack_badge: ShapeBadge
var _attack_label: Label
var _health_badge: ShapeBadge
var _health_label: Label
var _pending_tag: Panel
var _turns: Label
var _status_tag: Panel
var _frost_tag: Panel
var _star: TextureRect
var _hover_tween: Tween
var _hovering: bool = false


static func size_for(width: float, _card_mode: Mode = Mode.SHOP) -> Vector2:
	return Vector2(width, width / HexShape.RATIO)


## Tiles are read through art and state; full rules live in CardDetail.
static func chip_text(_view: Dictionary) -> String:
	return ""


## Shared portraits need a short name until their own art is distinguishable.
static func needs_name(view: Dictionary) -> bool:
	if is_spell(view):
		return false
	var id: String = Data.s(view, "portrait_id", Data.s(view, "def_id"))
	return NAME_EXCEPTIONS.has(id) or not ResourceLoader.exists(UiTheme.UNIT_PORTRAIT_DIR % id)


static func short_name(view: Dictionary) -> String:
	var id: String = Data.s(view, "portrait_id", Data.s(view, "def_id"))
	return Data.s(
		view, "short_name", str(NAME_EXCEPTIONS.get(id, Data.s(view, "name").get_slice(",", 0)))
	)


static func is_spell(view: Dictionary) -> bool:
	return Data.s(view, "kind") in ["spell", "item"]


## The word on a non-unit card: "Spell", "Item", or the view's own type_word ("Hero").
static func card_word(view: Dictionary) -> String:
	return Data.s(view, "type_word", Data.s(view, "kind").capitalize())


## Whether this window is phone-shaped, where everything keeps to the phone's minimum text size.
static func is_phone() -> bool:
	var window: Vector2 = window_override
	if window == Vector2.ZERO:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		window = Vector2(tree.root.size) if tree != null else Vector2(1920, 1080)
	return window.x / maxf(window.y, 1.0) > 2.0


static func is_unbuilt(view: Dictionary) -> bool:
	return unbuilt.has(Data.s(view, "def_id"))


static func set_unbuilt(ids: PackedStringArray) -> void:
	unbuilt.clear()
	for id: String in ids:
		unbuilt[id] = true


func _init() -> void:
	super()
	_build()


## Sets the unit and redraws. Pass the view dictionary straight from the state or event log.
func show_unit(view: Dictionary, card_mode: Mode = mode) -> void:
	unit = view
	mode = card_mode
	_refresh()


func set_card_width(width: float) -> void:
	set_card_size(size_for(width, mode))


## Lays the card out for this exact size.
func set_card_size(new_size: Vector2) -> void:
	card_size = new_size
	custom_minimum_size = card_size
	size = card_size
	pivot_offset = card_size / 2.0
	_refresh()


## Current Attack and Health shown on the card (combat playback updates these).
func set_stats(attack: int, health: int, max_health: int) -> void:
	unit["attack"] = attack
	unit["health"] = health
	unit["max_health"] = max_health
	_refresh_stats()


func set_statuses(statuses: Array) -> void:
	unit["statuses"] = statuses
	_refresh_status()


## Animation anchors stay on the tile, so pulses follow lunges and borrowed units.
func trigger_glyph() -> Control:
	if _combat_marks.counter.visible:
		return _combat_marks.counter
	return _combat_marks.glyph


func belly_point() -> Vector2:
	return _combat_marks.get_global_transform() * _combat_marks.belly_point()


func attack_bead() -> Control:
	return _attack_badge


func health_bead() -> Control:
	return _health_badge


## Queued permanent gains are separate from the unit's current combat stats.
func set_pending_gains(attack: int, health: int) -> void:
	unit["pending_attack"] = attack
	unit["pending_health"] = health
	_refresh_pending()


func set_kisses(count: int, period: int) -> void:
	unit["kisses"] = count
	unit["recruit_kisses"] = count
	unit["bog_kiss_period"] = period
	_refresh_chip()
	_refresh_pending()


func show_ooze_share() -> void:
	_ooze_marks.share_landed()


func uid() -> int:
	return Data.i(unit, "uid", -1)


## Kept for existing callers; rime and the frost rim carry frozen state.
func show_frost_tag(_on: bool) -> void:
	if _frost_tag != null:
		_frost_tag.visible = false


func _build() -> void:
	_art = ArtFrame.new()
	_art.hexagonal = true
	add_child(_art)
	_hedge_marks = HedgeMarks.new()
	_art.add_child(_hedge_marks)
	_ooze_marks = OozeMarks.new()
	_art.add_child(_ooze_marks)
	_name_label = UiTheme.head("", UiTheme.FONT_BODY)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_constant_override("line_spacing", -16)
	add_child(_name_label)
	_rules = UiTheme.label("", UiTheme.FONT_SMALL)
	_rules.add_theme_font_override("font", UiTheme.bold_font())
	_rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rules.set_meta("desktop_text", true)
	add_child(_rules)
	_type_label = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_type_label.add_theme_font_override("font", UiTheme.head_font())
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_type_label)
	_chip = Panel.new()
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.add_theme_stylebox_override("panel", UiTheme.slip_box())
	add_child(_chip)
	_tier_badge = ShapeBadge.new("knot")
	add_child(_tier_badge)
	_tier_label = _badge_label(_tier_badge, UiTheme.INK, UiTheme.FONT_SMALL)
	_attack_badge = ShapeBadge.new("nut")
	add_child(_attack_badge)
	_attack_label = _badge_label(_attack_badge, UiTheme.INK, 45)
	_health_badge = ShapeBadge.new("rosehip")
	add_child(_health_badge)
	_health_label = _badge_label(_health_badge, UiTheme.CREAM, 45)
	_pending_tag = Panel.new()
	_pending_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pending_tag.add_theme_stylebox_override("panel", UiTheme.slip_box(UiTheme.ACORN))
	add_child(_pending_tag)

	_status_tag = Panel.new()
	_status_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_tag.visible = false
	add_child(_status_tag)
	_star = TextureRect.new()
	_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_star.visible = false
	add_child(_star)
	_poached_badge = PoachedBadge.new()
	add_child(_poached_badge)
	_focus_rim = Control.new()
	_focus_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_rim.z_index = 24
	_focus_rim.draw.connect(_draw_focus)
	add_child(_focus_rim)
	_combat_marks = CombatFace.new()
	add_child(_combat_marks)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _badge_label(badge: ShapeBadge, colour: Color, font_size: int) -> Label:
	var node: Label = UiTheme.number("", font_size, colour)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(node)
	return node


func _refresh() -> void:
	if _art == null:
		return
	var tribes: Array = Data.a(unit, "tribes")
	var spell: bool = is_spell(unit)
	var golden: bool = Data.b(unit, "golden", false)
	_art.texture = UiTheme.portrait_for(Data.s(unit, "portrait_id", Data.s(unit, "def_id")), tribes)
	_art.portrait_offset = ArtFrame.PORTRAIT_OFFSETS.get(
		Data.s(unit, "portrait_id", Data.s(unit, "def_id")), Vector2.ZERO
	)
	_art.gilded = false
	_star.visible = false
	_name_label.text = Data.s(unit, "name")
	_type_label.text = card_word(unit) if spell else UiTheme.short_tribe(tribes)
	_tier_label.text = str(Data.i(unit, "cost", 1) if spell else Data.i(unit, "tier", 1))
	_tier_badge.shape = "knot_gold" if spell or golden else "knot"
	_tier_badge.visible = (
		(spell and Data.i(unit, "cost", 1) != 1) or (not combat_face and Data.b(unit, "poached"))
	)
	if Data.b(unit, "poached"):
		_tier_label.text = str(Data.i(unit, "cost", 2))
	var worth: int = Data.i(unit, "gold_value", 0)
	if worth > 0:
		# An Acorn item: its gold value where a spell's cost goes.
		_tier_label.text = str(worth)
		_tier_badge.visible = worth != 1
	_attack_badge.visible = not spell
	_health_badge.visible = not spell
	_attack_badge.z_index = int(combat_face)
	_health_badge.z_index = int(combat_face)
	_place_parts(spell)
	_refresh_chip()
	_refresh_stats()
	_refresh_status()
	_refresh_pending()
	_place_turns()
	_hedge_marks.size = _art.size
	_hedge_marks.show_state(unit, selected)
	_ooze_marks.size = _art.size
	_ooze_marks.show_state(unit)

	queue_redraw()


## Positions every part for card_size and mode.
func _place_parts(_spell: bool) -> void:
	var face: Rect2 = face_rect()
	var named: bool = not combat_face and needs_name(unit)
	_name_label.visible = named
	_name_label.text = short_name(unit)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.add_theme_font_size_override("font_size", UiTheme.MIN_FONT)
	_type_label.visible = false
	_rules.visible = false
	rules_shown = false
	_art.line = float(_ink_width())
	_place(_art, face.grow(-float(_ink_width()) - 3.0))
	_place(
		_name_label,
		Rect2(face.position + Vector2(8, face.size.y * 0.55), Vector2(face.size.x - 16, 40))
	)
	var knot: float = clampf(face.size.x * 0.23, 37.0, 50.0)
	_place(
		_tier_badge,
		Rect2(face.position + Vector2(face.size.x * 0.12, face.size.y * 0.15), Vector2.ONE * knot)
	)
	_tier_label.add_theme_font_size_override("font_size", UiTheme.MIN_FONT)
	_place_beads()
	_poached_badge.visible = false


## The badge widens for three digits; its height and the lower-corner anchors stay stable.
func _place_beads() -> void:
	var face: Rect2 = face_rect()
	var bead: float = clampf(face.size.x * 0.34, 38.0, 76.0)
	var stat_font: int = maxi(UiTheme.MIN_FONT, roundi(bead * 0.60))
	var values: Array[int] = [Data.i(unit, "attack"), maxi(Data.i(unit, "health"), 0)]
	var badges: Array[ShapeBadge] = [_attack_badge, _health_badge]
	var labels: Array[Label] = [_attack_label, _health_label]
	var widths: Array[float] = []
	for i: int in 2:
		var needed: float = StatNumbers.preferred_width(
			values[i], labels[i].get_theme_font("font"), 84.0 * 0.8
		)
		widths.append(maxf(bead, minf(84.0, ceilf(needed / 0.8))))
	var stagger: bool = widths[0] + widths[1] + 4.0 > face.size.x
	for i: int in 2:
		var x: float = face.position.x if i == 0 else face.end.x - widths[i]
		var y: float = face.position.y + face.size.y * 0.79 - bead * 0.5
		# Tiny legacy scout boxes cannot hold two three-digit badges abreast at 31 px.
		# Keep both honest and inside the caller's box by stepping Attack up one bead.
		if stagger:
			y = face.end.y - bead - 5.0 - (bead + 4.0 if i == 0 else 0.0)
		_place_bead(
			badges[i], Vector2(x, y), Vector2(widths[i], bead), labels[i], values[i], stat_font
		)


func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size


## Stat numerals compact before fitting, and never fall below the shared font minimum.
func _place_bead(
	badge: ShapeBadge, top_left: Vector2, extent: Vector2, number: Label, value: int, preferred: int
) -> void:
	badge.size = extent
	badge.position = top_left
	StatNumbers.fit(number, badge.inner_width(), preferred, value)
	# The rosehip's body sits low in its box, under the crown.
	number.offset_top = 4.0 if badge.shape.begins_with("rosehip") else 0.0


func _refresh_chip() -> void:
	chip_shown = ""
	_chip.visible = false
	_refresh_combat_marks()


func _refresh_stats() -> void:
	var health: int = Data.i(unit, "health", 0)
	var max_health: int = unit.get("max_health", health)
	_health_badge.shape = "rosehip_hurt" if health < max_health else "rosehip"
	_place_beads()
	_refresh_combat_marks()


## The transfer lands on the same queued-gain mark in recruit and combat.
func pending_gain_point() -> Vector2:
	return _combat_marks.get_global_transform() * _combat_marks.pending_rect.get_center()


## The queued-gain hourglass replaces the old numeric tag in every phase.
func _refresh_pending() -> void:
	_refresh_combat_marks()
	_pending_tag.visible = false


## Status marks stack without word slips.
func _refresh_status() -> void:
	_refresh_combat_marks()
	_status_tag.visible = false


func _refresh_combat_marks() -> void:
	if _combat_marks == null:
		return
	_combat_marks.position = face_rect().position
	_combat_marks.setup(
		unit,
		face_rect().size,
		combat_face,
		Rect2(_attack_badge.position - face_rect().position, _attack_badge.size),
		Rect2(_health_badge.position - face_rect().position, _health_badge.size)
	)


func _place_turns() -> void:
	if _turns != null:
		_turns.visible = false


func _face() -> Color:
	if is_spell(unit):
		return UiTheme.SPELL_FACE
	if frost:
		return UiTheme.FROST_FACE
	if Data.b(unit, "golden", false):
		return UiTheme.GILT
	return PAPER


## Follow the painted contour's scale without making small cards' outlines too heavy.
func _ink_width() -> int:
	return clampi(roundi(LINE * face_rect().size.x / SHOP_WIDTH), 2, LINE)


func _paint_hex(
	rect: Rect2, fill: Color, ink: Color = Color.TRANSPARENT, weight: float = 0.0
) -> void:
	draw_colored_polygon(HexShape.polygon(rect), fill)
	if ink.a > 0.0 and weight > 0.0:
		draw_polyline(HexShape.closed(rect), ink, weight, true)


func _draw() -> void:
	var rect: Rect2 = face_rect()
	var golden: bool = Data.b(unit, "golden")
	var ink: float = float(_ink_width())
	# The contour fits its caller's box. A narrow outer rim leaves the tuck's air intact.
	_focus_rim.queue_redraw()
	for spread: int in range(5, 0, -1):
		_paint_hex(
			Rect2(rect.position + Vector2(-2, 4), rect.size).grow(spread), Color(CONTACT, 0.025)
		)
	var under: Color = UiTheme.BRASS if golden else BARK_EDGE
	if frost:
		under = UiTheme.RIME
	elif is_spell(unit):
		under = UiTheme.ACORN if Data.s(unit, "kind") == "item" else UiTheme.NIGHTSHADE
	_paint_hex(Rect2(rect.position + Vector2(-1, 3), rect.size), under, PAPER_INK, ink)
	_paint_hex(rect, _face(), PAPER_INK, ink)
	# Cream light follows the upper-right slope and shoulder.
	var contour: PackedVector2Array = HexShape.polygon(rect.grow(-ink))
	draw_polyline(contour.slice(6, 20), PAPER_LIGHT, maxf(1.0, ink * 0.55), true)
	if golden or is_spell(unit):
		var edge: Color = UiTheme.GILT if golden else under
		draw_polyline(HexShape.closed(rect.grow(-ink - 1)), edge, ink * 1.6, true)
	if Data.s(unit, "kind") == "item":
		# Brass corner rivets distinguish items from the violet double rim of spells.
		for side: float in [0.0, 1.0]:
			draw_circle(
				rect.position + Vector2(rect.size.x * side, rect.size.y * 0.5),
				ink * 1.3,
				UiTheme.GILT
			)


## Paint above neighbouring faces without changing the card's animation z-order.
func _draw_focus() -> void:
	var ring: Color = selection_color if selected or _hovering else outline
	if ring.a <= 0.0:
		return
	var path: PackedVector2Array = HexShape.closed(face_rect().grow(3))
	_focus_rim.draw_polyline(path, UiTheme.INK, float(_ink_width()) + 4.0, true)
	_focus_rim.draw_polyline(path, ring, float(_ink_width()), true)


## A small lift separates the interactive tile from its surface without a standing mark.
func _on_mouse_entered() -> void:
	super()
	_set_hover_lift(true)


func _on_mouse_exited() -> void:
	super()
	_set_hover_lift(false)


func _set_hover_lift(on: bool) -> void:
	if combat_face:
		return
	_hovering = on
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	if Settings.reduce_motion or not is_inside_tree():
		scale = Vector2.ONE
	else:
		_hover_tween = create_tween()
		_hover_tween.tween_property(self, "scale", Vector2.ONE * (1.025 if on else 1.0), 0.1)
	queue_redraw()


## The tag's replacement: frost crosses each offer; unfreeze withdraws it.
func animate_frost(on: bool, delay: float, speed: float, reduced: bool) -> void:
	_art.frost_progress = 0.0 if on else 1.0
	if reduced:
		_art.frost_progress = 1.0 if on else 0.0
		_art.modulate = Color(1.3, 1.5, 1.6)
		create_tween().tween_property(_art, "modulate", Color.WHITE, 0.15).set_delay(delay)
	else:
		(
			create_tween()
			. tween_property(_art, "frost_progress", 1.0 if on else 0.0, 0.25 / maxf(1.0, speed))
			. set_delay(delay)
		)


## Animation values can be wider than either endpoint; refit each displayed frame.
func show_stat(stat: String, value: int) -> void:
	var number: Label = _attack_label if stat == "attack" else _health_label
	var badge: ShapeBadge = _attack_badge if stat == "attack" else _health_badge
	var preferred: int = maxi(UiTheme.MIN_FONT, roundi(badge.size.y * 0.54))
	StatNumbers.fit(number, badge.inner_width(), preferred, maxi(0, value))
