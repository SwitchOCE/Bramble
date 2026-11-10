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
const SHOP_HEIGHT: float = 297.0
const BOARD_RATIO: float = 102.0 / 112.0
const LINE: int = 5
const EDGE: float = 12.0
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


static func size_for(width: float, card_mode: Mode = Mode.SHOP) -> Vector2:
	match card_mode:
		Mode.SHOP:
			return Vector2(width, SHOP_HEIGHT)
		Mode.BOARD:
			return Vector2(width, roundf(width * BOARD_RATIO))
	return Vector2(width, width)


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
	_art.gilded = golden
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
func _place_parts(spell: bool) -> void:
	var w: float = card_size.x
	var h: float = card_size.y
	var knot: float = 57.0
	var named: bool = not combat_face and needs_name(unit)
	_name_label.visible = named
	_name_label.text = short_name(unit)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.add_theme_font_size_override("font_size", UiTheme.MIN_FONT)
	_art.visible = true
	_type_label.visible = false
	_rules.visible = false
	rules_shown = false
	_art.radius = 44.0 if spell else 15.0
	if named:
		# Legacy shared portraits keep the reserved name line until their own art arrives.
		_place(_art, Rect2(12, 12, w - 24, h - 104))
	else:
		# A responsive rim keeps small faces recognisable and leaves a calm foot below
		# the portrait. Stat/target/defence anchors remain independent of the art crop.
		var inset: float = clampf(minf(w, h) * 0.05, 6.0, 12.0)
		var art_width: float = w - inset * 2.0
		var art_height: float = clampf(w * h * ART_SHARE / art_width, ART_MIN, h - inset * 2.0)
		_place(_art, Rect2(inset, inset, art_width, art_height))
	_place(_name_label, Rect2(4, h - 98, w - 8, 40))
	_place(_tier_badge, Rect2(-knot * 0.2, -knot * 0.2, knot, knot))
	_tier_label.add_theme_font_size_override("font_size", UiTheme.MIN_FONT)
	_place_beads()
	_poached_badge.visible = false


## Compact first; only the smallest beads need a bounded width increase at the font minimum.
func _place_beads() -> void:
	var bead: float = 84.0
	if mode == Mode.BOARD:
		bead = clampf(card_size.x * 0.46, 60.0, 84.0)
	elif mode == Mode.MINI:
		bead = 62.0
	var stat_font: int = maxi(UiTheme.MIN_FONT, roundi(bead * 0.54))
	var attack: int = Data.i(unit, "attack", 0)
	var health: int = maxi(Data.i(unit, "health", 0), 0)
	var needed: float = maxf(
		StatNumbers.preferred_width(attack, _attack_label.get_theme_font("font"), 84.0 * 0.74),
		StatNumbers.preferred_width(health, _health_label.get_theme_font("font"), 84.0 * 0.74)
	)
	bead = maxf(bead, minf(84.0, ceilf(needed / 0.74)))
	var w: float = card_size.x
	var h: float = card_size.y
	for number: Label in [_attack_label, _health_label]:
		number.add_theme_font_size_override("font_size", stat_font)
	# Keep a clear center even on the narrowest supported card (96 canvas units).
	var inset: float = minf(bead * 0.76, (w - 4.0) / 2.0)
	_place_bead(_attack_badge, Vector2(inset - bead, h - bead * 0.72), bead, _attack_label, attack)
	_place_bead(_health_badge, Vector2(w - inset, h - bead * 0.72), bead, _health_label, health)


func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size


## Stat numerals compact before fitting, and never fall below the shared font minimum.
func _place_bead(
	badge: ShapeBadge, top_left: Vector2, bead: float, number: Label, value: int
) -> void:
	badge.size = Vector2(bead, bead)
	badge.position = top_left
	StatNumbers.fit(number, badge.inner_width(), number.get_theme_font_size("font_size"), value)
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
	_combat_marks.setup(
		unit, card_size, combat_face, _attack_badge.get_rect(), _health_badge.get_rect()
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
	return UiTheme.BIRCH


func _tile_box(fill: Color, line: Color, width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = UiTheme.flat_box(fill, line, width, 24)
	if is_spell(unit):
		box.corner_radius_top_left = 70
		box.corner_radius_top_right = 70
		box.corner_detail = 12
	return box


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, card_size)
	var golden: bool = Data.b(unit, "golden", false)
	if golden:
		draw_style_box(_tile_box(Color(UiTheme.GILT, 0.55), Color.TRANSPARENT, 0), rect.grow(12))
	if frost:
		draw_style_box(_tile_box(UiTheme.RIME, Color.TRANSPARENT, 0), rect.grow(10))
	var ring: Color = selection_color if selected else outline
	if ring.a > 0.0:
		draw_style_box(_tile_box(UiTheme.INK, Color.TRANSPARENT, 0), rect.grow(19))
		draw_style_box(_tile_box(ring, Color.TRANSPARENT, 0), rect.grow(15))
	var under: Color = UiTheme.BRASS if golden else UiTheme.CARVE
	if frost:
		under = UiTheme.RIME
	elif is_spell(unit):
		under = UiTheme.NIGHTSHADE
	var shadow := UiTheme.flat_box(Color(0, 0, 0, 0.22), Color.TRANSPARENT, 0, 24)
	shadow.shadow_color = Color(0, 0, 0, 0.2)
	shadow.shadow_size = 22 if _hovering else 12
	draw_style_box(shadow, Rect2(rect.position + Vector2(0, EDGE + 6), rect.size))
	var drop: Rect2 = Rect2(Vector2(0, EDGE), card_size)
	draw_style_box(_tile_box(under, UiTheme.INK, LINE), drop)
	draw_style_box(_tile_box(_face(), UiTheme.INK, LINE), rect)


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
