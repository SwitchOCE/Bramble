extends Control
## Floor state: Ring dots with a stack count, a Rainbow band, Nest twigs and combat sigils.
## Counts stay on your own board; scouting shows only the wordless floor pictures.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")
const Settings := preload("res://src/ui/settings.gd")
const RingTravel := preload("res://src/ui/widgets/ring_travel.gd")

const HexShape := preload("res://src/ui/widgets/hex_shape.gd")

const BAND_COLOURS: Array[Color] = [
	Color("c8372d"),
	Color("e2852b"),
	Color("e8c63a"),
	Color("4f9a3c"),
	Color("2f7fc1"),
	Color("47479c"),
	Color("8a4aa8"),
]
const RING_DOTS: int = 26
const RING: Color = Color("e9c75a")
const HEX: Color = Color("5b3a8a")
const TWIG: Color = Color("8a5a2b")
const TWIG_DARK: Color = Color("4a2f16")
const EGG_ART: String = "res://assets/portraits/nest_egg.jpg"
const NEST_TWIGS: int = 22
const EGG_BEAD: float = 84.0
## A pocket this short (the scout's) has no room between its badges.
const SMALL_POCKET: float = 150.0

## One entry per slot: {"ring": "+1/+1" or "", "has_ring", "band"} (RecruitView.slot_marks).
var marks: Array = []
## Legacy preview input, retained while callers migrate. It never creates a standing mark.
var pass_slot: int = -2:
	set(value):
		pass_slot = value
		_place()

var board: Control

var _ring_labels: Array[Label] = []
var _pass_label: Label
var _hex_labels: Dictionary[int, Label] = {}
var _hex_values: Dictionary[int, Dictionary] = {}
var _trap_labels: Dictionary[int, Label] = {}
var _nest_labels: Array[Label] = []
var _egg_stats: Array[Control] = []
var _egg_attack: Array[Label] = []
var _egg_health: Array[Label] = []
var _egg: Texture2D
var _ring_reveal: Dictionary[int, float] = {}
var _band_reveal: Dictionary[int, float] = {}
var _mark_tweens: Dictionary[int, Tween] = {}


func _init(owner_board: Control) -> void:
	board = owner_board
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3
	for i: int in 7:
		var label: Label = UiTheme.number("", UiTheme.FONT_SMALL, UiTheme.INK)
		label.add_theme_stylebox_override("normal", UiTheme.slip_box(RING, 3, 8))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.visible = false
		add_child(label)
		_ring_labels.append(label)
		var nest_label: Label = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.CREAM)
		nest_label.add_theme_font_override("font", UiTheme.bold_font())
		var nest_face: StyleBoxFlat = UiTheme.slip_box(TWIG_DARK, 3, 8)
		nest_face.content_margin_top = 0
		nest_face.content_margin_bottom = 0
		nest_label.add_theme_stylebox_override("normal", nest_face)
		nest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nest_label.visible = false
		add_child(nest_label)
		_nest_labels.append(nest_label)
		var stats: Control = Control.new()
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats.visible = false
		add_child(stats)
		_egg_stats.append(stats)
		_egg_attack.append(_egg_number(stats, "nut", UiTheme.INK))
		_egg_health.append(_egg_number(stats, "rosehip", UiTheme.CREAM))
	_pass_label = UiTheme.head("Pass lands", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_pass_label.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.MOSS, 3, 8))
	_pass_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pass_label.visible = false
	add_child(_pass_label)


func set_hex(slot: int, total: int, percent: int = 0) -> void:
	_hex_values[slot] = {"total": total, "percent": percent}
	if not _hex_labels.has(slot):
		var made: Label = UiTheme.number("", UiTheme.FONT_SMALL, UiTheme.CREAM)
		made.add_theme_stylebox_override("normal", UiTheme.slip_box(HEX, 3, 8))
		made.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(made)
		_hex_labels[slot] = made
	var label: Label = _hex_labels[slot]
	if board.get("combat_mode") == true:
		var amounts: PackedStringArray = []
		if total != 0:
			amounts.append("−" + StatNumbers.compact(absi(total)))
		if percent > 0:
			amounts.append("−%d%%" % mini(percent, 100))
		label.text = "\n".join(amounts) if not amounts.is_empty() else "0"
		label.add_theme_stylebox_override("normal", UiTheme.flat_box(HEX, UiTheme.INK, 2, 7))
		label.add_theme_font_size_override("font_size", UiTheme.MIN_FONT)
		label.size = label.get_minimum_size()
		_place_hex(slot)
		queue_redraw()
		return
	var parts: PackedStringArray = []
	if total != 0:
		parts.append(str(-absi(total)))
	if percent > 0:
		parts.append("%d%%" % -mini(percent, 100))
	label.text = "Hex " + " / ".join(parts) if not parts.is_empty() else "Hex 0"
	label.size = label.get_minimum_size()
	var pocket: Vector2 = board.get("pocket")
	var at: Vector2 = board.call("slot_position", slot)
	# Keep the top keyword/name area and bottom slot chip clear. A Hex is a slot
	# total, so its slip sits between the stat beads near the foot of the picture.
	label.position = at + Vector2((pocket.x - label.size.x) / 2.0, pocket.y - label.size.y - 28.0)


func _place_hex(slot: int) -> void:
	var at: Vector2 = board.call("slot_position", slot)
	_hex_labels[slot].position = at + Vector2(38, 48 if _trap_labels.has(slot) else 8)


func set_trap(slot: int, damage: int) -> void:
	if damage <= 0:
		if _trap_labels.has(slot):
			remove_child(_trap_labels[slot])
			_trap_labels[slot].queue_free()
			_trap_labels.erase(slot)
	else:
		if not _trap_labels.has(slot):
			var made: Label = UiTheme.number("", UiTheme.MIN_FONT, UiTheme.CREAM)
			made.add_theme_stylebox_override(
				"normal", UiTheme.flat_box(UiTheme.HEALTH, UiTheme.INK, 2, 7)
			)
			add_child(made)
			_trap_labels[slot] = made
		var label: Label = _trap_labels[slot]
		label.text = StatNumbers.compact(damage)
		label.size = label.get_minimum_size()
		var at: Vector2 = board.call("slot_position", slot)
		label.position = at + Vector2(38, 8)
	if _hex_labels.has(slot) and board.get("combat_mode") == true:
		_place_hex(slot)
	queue_redraw()


func clear_traps() -> void:
	for label: Label in _trap_labels.values():
		remove_child(label)
		label.queue_free()
	_trap_labels.clear()
	queue_redraw()


func clear_hexes() -> void:
	for label: Label in _hex_labels.values():
		remove_child(label)
		label.queue_free()
	_hex_labels.clear()
	_hex_values.clear()
	queue_redraw()


func set_marks(slot_marks: Array) -> void:
	var previous: Array = marks
	marks = slot_marks.duplicate(true)
	_place()
	if previous.is_empty() or not is_inside_tree() or board.get("combat_mode") == true:
		return
	var paired: Array[int] = _recruit_ring_move(previous)
	for slot: int in mini(marks.size(), 7):
		var before: Dictionary = previous[slot] if slot < previous.size() else {}
		var now: Dictionary = marks[slot]
		var ring_changed: bool = Data.i(before, "ring_count") != Data.i(now, "ring_count")
		ring_changed = ring_changed or Data.s(before, "ring") != Data.s(now, "ring")
		ring_changed = ring_changed and not paired.has(slot)
		var painted: bool = Data.b(now, "band") and not Data.b(before, "band")
		if not ring_changed and not painted:
			continue
		if Settings.reduce_motion:
			_ring_reveal[slot] = 1.0
			_band_reveal[slot] = 1.0
			var reached: Array[int] = [slot]
			board.call("show_relations", reached)
			continue
		if _mark_tweens.has(slot) and _mark_tweens[slot].is_valid():
			_mark_tweens[slot].kill()
		var tween: Tween = create_tween().set_parallel(true)
		_mark_tweens[slot] = tween
		var duration: float = 0.3 / maxf(1.0, Settings.fight_speed)
		if ring_changed:
			_ring_reveal[slot] = 0.0
			tween.tween_method(_set_ring_reveal.bind(slot), 0.0, 1.0, duration)
		if painted:
			_band_reveal[slot] = 0.0
			tween.tween_method(_set_band_reveal.bind(slot), 0.0, 1.0, duration)


## Pair an exact conserved pile transfer; additions and growth retain the ordinary sprout cue.
func _recruit_ring_move(previous: Array) -> Array[int]:
	var decreased: Array[int] = []
	var increased: Array[int] = []
	for slot: int in mini(marks.size(), 7):
		var before: Dictionary = Data.entry(previous, slot)
		var now: Dictionary = Data.entry(marks, slot)
		var delta: int = Data.i(now, "ring_count") - Data.i(before, "ring_count")
		if delta < 0:
			decreased.append(slot)
		elif delta > 0:
			increased.append(slot)
	if decreased.size() != 1 or increased.size() != 1:
		return []
	var from: int = decreased[0]
	var to: int = increased[0]
	var before_from: Dictionary = Data.entry(previous, from)
	var after_from: Dictionary = Data.entry(marks, from)
	var before_to: Dictionary = Data.entry(previous, to)
	var after_to: Dictionary = Data.entry(marks, to)
	var amount: int = Data.i(before_from, "ring_count") - Data.i(after_from, "ring_count")
	if amount != Data.i(after_to, "ring_count") - Data.i(before_to, "ring_count"):
		return []
	travel_ring(from, to, null, Callable(), not Data.b(before_to, "has_ring"), amount)
	return [from, to]


## Combat supplies its overlay and deterministic clock; recruit uses the floor's short cue clock.
func travel_ring(
	from: int,
	to: int,
	host: Control = null,
	clock: Callable = Callable(),
	hide_destination: bool = true,
	moved_count: int = 1,
	speed: float = -1.0
) -> RingTravel:
	var layer: Control = self if host == null else host
	var travel: RingTravel = RingTravel.new()
	travel.name = "RingTravel_%d_%d" % [from, to]
	travel.reduced = Settings.reduce_motion
	travel.set_meta("ring_from", from)
	travel.set_meta("ring_to", to)
	travel.set_meta("moved_ring_count", moved_count)
	layer.add_child(travel)
	var transform: Transform2D = (
		layer.get_global_transform().affine_inverse() * get_global_transform()
	)
	var pocket: Vector2 = board.get("pocket")
	var origin: Vector2 = board.call("slot_position", from)
	var destination: Vector2 = board.call("slot_position", to)
	travel.from_rect = transform * Rect2(origin, pocket).grow(-1.0)
	travel.to_rect = transform * Rect2(destination, pocket).grow(-1.0)
	if hide_destination:
		_ring_reveal[to] = 0.0
		queue_redraw()
	travel.tree_exiting.connect(_ring_arrived.bind(to))
	var tween: Tween = clock.call() if clock.is_valid() else create_tween()
	tween.bind_node(travel)
	var duration: float = 0.3 / maxf(1.0, Settings.fight_speed if speed < 0 else speed)
	travel.set_meta("ring_duration", 0.3 if travel.reduced else duration)
	if travel.reduced:
		duration = 0.3
		tween.tween_interval(duration / 2.0)
		tween.tween_property(travel, "progress", 1.0, 0.0)
		tween.tween_interval(duration / 2.0)
	else:
		tween.tween_property(travel, "progress", 1.0, duration)
	tween.tween_callback(_ring_arrived.bind(to))
	tween.tween_callback(travel.queue_free)
	return travel


func _ring_arrived(slot: int) -> void:
	_ring_reveal[slot] = 1.0
	queue_redraw()


func _set_ring_reveal(value: float, slot: int) -> void:
	_ring_reveal[slot] = value
	_ring_labels[slot].scale = Vector2.ONE * (1.0 + sin(value * PI) * 0.2)
	queue_redraw()


func _set_band_reveal(value: float, slot: int) -> void:
	_band_reveal[slot] = value
	queue_redraw()


func header_width(_slot: int) -> float:
	return 0.0


## The Ring frame shows its presence; exact pile counts are in the one-tap slot reader.
func _ring_words(_mark: Dictionary) -> String:
	return ""


func _place() -> void:
	var pocket: Vector2 = board.get("pocket")
	for i: int in _ring_labels.size():
		var label: Label = _ring_labels[i]
		var mark: Dictionary = marks[i] if i < marks.size() else {}
		var words: String = _ring_words(mark)
		label.visible = (
			not words.is_empty()
			and board.get("combat_mode") != true
			and board.get("zone") != "scout"
		)
		if label.visible:
			label.text = words
			label.add_theme_stylebox_override(
				"normal", UiTheme.flat_box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0)
			)
			label.add_theme_font_size_override("font_size", UiTheme.MIN_FONT)
			label.size = Vector2(64, 42)
			label.pivot_offset = label.size / 2.0
			var at: Vector2 = board.call("slot_position", i)
			label.position = at + Vector2(-10, -20)
		_place_nest_label(i, mark, pocket)
		_place_egg_stats(i, mark, pocket)
	_pass_label.visible = false
	queue_redraw()


func _pass_landing() -> int:
	if pass_slot != -2:
		return pass_slot
	for slot: int in marks.size():
		var mark: Dictionary = marks[slot]
		if Data.b(mark, "pass_end"):
			return slot
	return -1


## A Nest never repeats its away token's countdown.
func _place_nest_label(slot: int, _mark: Dictionary, _pocket: Vector2) -> void:
	# The away token owns the countdown; a Nest is only its woven floor rim here.
	_nest_labels[slot].visible = false


func _draw() -> void:
	var pocket: Vector2 = board.get("pocket")
	for i: int in mini(marks.size(), 7):
		var mark: Dictionary = marks[i]
		var at: Vector2 = board.call("slot_position", i)
		if mark.get("nest", false) == true:
			_draw_nest(Rect2(at, pocket), i)
		if mark.get("has_ring", false) == true:
			_draw_ring(Rect2(at, pocket).grow(-1.0), i)
			if _ring_labels[i].visible:
				_draw_toadstool(at + Vector2(22, 3))
		if mark.get("horseshoe", false) == true:
			_draw_horseshoe(Rect2(at, pocket))
		if mark.get("band", false) == true:
			var frame: Rect2 = HexShape.fit(Rect2(at, pocket).grow(-4.0))
			var band: PackedVector2Array = HexShape.closed(frame).slice(16, 33)
			var reveal: float = _band_reveal.get(i, 1.0)
			if reveal > 0.0:
				band = band.slice(0, maxi(2, roundi(band.size() * reveal)))
				draw_polyline(band, UiTheme.INK, 6.0, true)
				draw_polyline(band, BAND_COLOURS[i], 3.5, true)

	if board.get("combat_mode") == true:
		_draw_combat_marks()


## The Hex and trap silhouettes stay distinct even on an empty pocket.
func _draw_combat_marks() -> void:
	for slot: int in _hex_values:
		var at: Vector2 = board.call("slot_position", slot)
		var centre: Vector2 = at + Vector2(19, 66 if _trap_labels.has(slot) else 26)
		var points: PackedVector2Array = [
			centre + Vector2(0, -17),
			centre + Vector2(17, 0),
			centre + Vector2(0, 17),
			centre + Vector2(-17, 0),
			centre + Vector2(0, -17),
		]
		draw_polyline(points, UiTheme.INK, 8.0, true)
		draw_polyline(points, Color("b68be2"), 4.0, true)
		draw_line(centre + Vector2(-10, 0), centre + Vector2(10, 0), HEX, 5.0, true)
	for slot: int in _trap_labels:
		var at: Vector2 = board.call("slot_position", slot)
		var centre: Vector2 = at + Vector2(19, 26)
		var points: PackedVector2Array = [
			centre + Vector2(-7, 17),
			centre + Vector2(-7, -5),
			centre + Vector2(0, -17),
			centre + Vector2(7, -5),
			centre + Vector2(7, 17),
		]
		draw_colored_polygon(points, UiTheme.HEALTH)
		draw_polyline(points, UiTheme.INK, 3.0, true)


## The empty Nest shows its Egg; a covering unit leaves only a thin twig rim visible.
func _draw_nest(rect: Rect2, slot: int) -> void:
	var cards: Array = board.get("cards")
	var occupied: bool = cards[slot] != null
	if not occupied:
		if _egg == null:
			_egg = load(EGG_ART)
		var art_rect: Rect2 = HexShape.fit(rect.grow(-14.0))
		var points: PackedVector2Array = HexShape.polygon(art_rect)
		var art: Vector2 = _egg.get_size()
		var fit: float = maxf(art_rect.size.x / art.x, art_rect.size.y / art.y)
		var shown: Vector2 = art_rect.size / fit
		var origin: Vector2 = (art - shown) / 2.0
		var uvs: PackedVector2Array = []
		for point: Vector2 in points:
			uvs.append((origin + (point - art_rect.position) / fit) / art)
		draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, _egg)
	var frame: Rect2 = HexShape.fit(rect.grow(-5.0))
	for twig: int in NEST_TWIGS:
		var fraction: float = float(twig) / NEST_TWIGS
		var mid: Vector2 = HexShape.perimeter_point(frame, fraction)
		var next: Vector2 = HexShape.perimeter_point(frame, fraction + 0.005)
		var across: Vector2 = (next - mid).normalized() * (12.0 if twig % 2 == 0 else -12.0)
		draw_line(mid - across, mid + across, TWIG_DARK, 5.0 if occupied else 7.0)
		draw_line(mid - across, mid + across, TWIG, 2.0 if occupied else 4.0)


func _draw_toadstool(at: Vector2) -> void:
	draw_line(at + Vector2(0, 2), at + Vector2(0, 24), UiTheme.INK, 15.0)
	draw_line(at + Vector2(0, 2), at + Vector2(0, 24), RING, 9.0)
	draw_style_box(
		UiTheme.flat_box(RING, UiTheme.INK, 2, 18), Rect2(at - Vector2(33, 24), Vector2(66, 44))
	)


## Dots stay outside the portrait and read as one quiet floor frame.
func _draw_ring(rect: Rect2, slot: int) -> void:
	var reveal: float = _ring_reveal.get(slot, 1.0)
	var limit: int = roundi(RING_DOTS * reveal)
	for dot: int in limit:
		var point: Vector2 = HexShape.perimeter_point(HexShape.fit(rect), float(dot) / RING_DOTS)
		draw_circle(point, 5.0, UiTheme.INK)
		draw_circle(point, 3.5, RING)


func _egg_number(parent: Control, shape: String, ink: Color) -> Label:
	var badge: ShapeBadge = ShapeBadge.new(shape)
	badge.size = Vector2(EGG_BEAD, EGG_BEAD)
	parent.add_child(badge)
	var number: Label = UiTheme.number("", UiTheme.FONT_SMALL + 3, ink)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(number)
	return number


## Only an empty own Nest exposes the known Egg forecast. Scout cards already show their public
## combat stats; an unknown scout Nest must never infer anything from the hidden Bird.
func _place_egg_stats(slot: int, mark: Dictionary, pocket: Vector2) -> void:
	var stats: Control = _egg_stats[slot]
	var cards: Array = board.get("cards")
	stats.visible = (
		Data.b(mark, "nest")
		and cards[slot] == null
		and board.get("zone") != "scout"
		and mark.has("egg_attack")
		and mark.has("egg_health")
		and board.get("combat_mode") != true
	)
	if not stats.visible:
		return
	_egg_attack[slot].text = str(Data.i(mark, "egg_attack"))
	_egg_health[slot].text = str(Data.i(mark, "egg_health"))
	var at: Vector2 = board.call("slot_position", slot)
	stats.position = at + Vector2(0, pocket.y - EGG_BEAD + 5.0)
	stats.size = Vector2(pocket.x, EGG_BEAD)
	var health: Control = stats.get_child(1) as Control
	health.position.x = pocket.x - EGG_BEAD


## A small iron U distinguishes the one-fight spell from a permanent golden Ring.
func _draw_horseshoe(rect: Rect2) -> void:
	var at: Vector2 = rect.position + Vector2(24, rect.size.y * 0.45)
	var points: PackedVector2Array = [
		at + Vector2(-10, -12),
		at + Vector2(-12, 5),
		at + Vector2(-7, 12),
		at + Vector2(7, 12),
		at + Vector2(12, 5),
		at + Vector2(10, -12),
	]
	draw_polyline(points, UiTheme.INK, 10.0)
	draw_polyline(points, Color("9aaab8"), 5.0)
