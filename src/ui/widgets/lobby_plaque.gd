extends Control
## A portrait with current Health and an opponent tier numeral; full hero state is one tap away.
## The next opponent has a red rim; a ghost is grey and has no Health.

signal scout_requested(player_id: int)
signal hero_requested(standing: Dictionary)

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const Settings := preload("res://src/ui/settings.gd")

static var _hero_portraits: Dictionary = {}
static var _hero_definitions: Dictionary = {}

## On the next opponent's plaque: opens the scouting panel. Taller than the plaque, to hit easily.
var tap: Interactive
var is_me: bool = false
var is_next: bool = false
var is_out: bool = false
var is_ghost: bool = false
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
var _prefix: String = ""
var _font_size: int = UiTheme.FONT_SMALL
var _words: PackedStringArray = []
var _surname: Label
var _name: Label
var _knot: Control
var _hip: Control
var _last_stand: Label
var _next_tag: Label
var _portrait: ArtFrame
var _stand_ready: bool = false
var _stand_used: bool = false
var _ghost_time: float = 0.0
var _stand_mark: Control
var _standing: Dictionary = {}
var _interactive: bool = true


func _init(standing: Dictionary, next_up: bool, ghost: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_standing = standing.duplicate(true)
	_standing["is_ghost"] = ghost
	is_me = Data.b(standing, "is_human", false)
	is_next = next_up
	is_ghost = ghost
	is_out = not Data.b(standing, "alive", true)
	_portrait = ArtFrame.new()
	_portrait.radius = 50.0
	_portrait.texture = UiTheme.portrait_for(_portrait_id(standing), [])
	if is_out:
		_portrait.modulate = Color(0.65, 0.65, 0.65, 0.8)
	add_child(_portrait)
	var ink: Color = UiTheme.INK
	if is_me or (is_next and not is_ghost):
		ink = UiTheme.CREAM
	elif is_out and not is_ghost:
		ink = UiTheme.MUTE
	_knot = ShapeBadge.new("knot_out" if is_out else "knot")
	add_child(_knot)
	var tier: Label = UiTheme.number(str(Data.i(standing, "tier", 1)), UiTheme.FONT_SMALL)
	tier.name = "TierKnot"
	tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier.set_anchors_preset(Control.PRESET_FULL_RECT)
	_knot.add_child(tier)
	_prefix = "Ghost of " if is_ghost else "Next: " if is_next else ""
	_words = UiTheme.player_name(standing).split(" ", false)
	_name = UiTheme.head(_prefix + _words[0], UiTheme.FONT_SMALL, ink)
	_name.add_theme_font_override("font", UiTheme.body_font())
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_name)
	_name.visible = false
	_surname = UiTheme.head(" ".join(_words.slice(1)), UiTheme.FONT_SMALL, ink)
	_surname.add_theme_font_override("font", UiTheme.body_font())
	_surname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_surname.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_surname)
	_surname.visible = false
	_hip = ShapeBadge.new("rosehip_out" if is_out else "rosehip")
	add_child(_hip)
	var health: Label = UiTheme.number(
		str(maxi(Data.i(standing, "health", 0), 0)), UiTheme.FONT_SMALL, UiTheme.CREAM
	)
	health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health.set_anchors_preset(Control.PRESET_FULL_RECT)
	health.offset_top = 5.0
	_hip.add_child(health)
	_hip.visible = not is_me and not is_out and not is_ghost
	_knot.visible = not is_me and not is_out and not is_ghost
	if (
		Data.b(standing, "last_stand_enabled")
		and Data.b(standing, "last_stand_active")
		and not is_out
		and not is_ghost
	):
		_stand_used = Data.b(standing, "last_stand_used")
		_stand_ready = not _stand_used
		var status: String = "used" if _stand_used else "ready"
		_last_stand = UiTheme.label("Last Stand: " + status, UiTheme.FONT_SMALL, UiTheme.INK)
		var tag: StyleBoxFlat = UiTheme.slip_box(UiTheme.BIRCH, 3, 8)
		tag.content_margin_top = 0
		tag.content_margin_bottom = 0
		_last_stand.add_theme_stylebox_override("normal", tag)
		_last_stand.add_theme_font_override("font", UiTheme.body_font())
		_last_stand.name = "LastStand"
		_last_stand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_last_stand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_last_stand)
		_last_stand.visible = false
	if is_next and is_ghost:
		_next_tag = UiTheme.burned("Next", UiTheme.FONT_SMALL, UiTheme.CREAM)
		var face: StyleBoxFlat = UiTheme.slip_box(UiTheme.HEALTH, 3, 9)
		face.content_margin_top = 0
		face.content_margin_bottom = 0
		_next_tag.add_theme_stylebox_override("normal", face)
		_next_tag.z_index = 2
		add_child(_next_tag)
		_next_tag.visible = false
	_stand_mark = Control.new()
	_stand_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stand_mark.draw.connect(_draw_stand_mark)
	add_child(_stand_mark)
	tap = Interactive.new()
	tap.zone = "lobby"
	tap.index = Data.i(standing, "player_id", -1)
	tap.tooltip_text = UiTheme.player_name(standing)
	tap.tapped.connect(_on_tapped)
	tap.hovered.connect(_on_hovered)
	add_child(tap)
	resized.connect(_layout)
	ready.connect(_layout)


## A desktop's canvas is narrower than a phone's, and a smaller name still reads there.
func use_desktop_size(font_size: int) -> void:
	_font_size = font_size
	_name.add_theme_font_size_override("font_size", font_size)
	_name.set_meta("desktop_text", true)
	_surname.add_theme_font_size_override("font_size", font_size)
	_surname.set_meta("desktop_text", true)
	if _last_stand != null:
		_last_stand.add_theme_font_size_override("font_size", font_size)
		_last_stand.set_meta("desktop_text", true)


func wanted_width() -> float:
	return 140.0


func _layout() -> void:
	var diameter: float = minf(86.0, minf(size.x - 24.0, size.y - 20.0))
	if is_out and not is_ghost:
		diameter *= 0.5
	_portrait.size = Vector2.ONE * diameter
	_portrait.position = Vector2((size.x - diameter) / 2.0, (size.y - diameter) / 2.0)
	_knot.size = Vector2(40, 40)
	_knot.position = Vector2(0, _portrait.position.y + diameter - 32)
	_hip.size = Vector2(54, 54)
	_hip.position = Vector2(size.x - 54, _portrait.position.y + diameter - 40)
	_stand_mark.position = _hip.position
	_stand_mark.size = _hip.size
	_stand_mark.queue_redraw()
	# Keep legacy fields available to tooling without displaying standing words.
	_name.position = Vector2.ZERO
	_name.size = size
	_surname.position = Vector2.ZERO
	_surname.size = size
	if _last_stand != null:
		_last_stand.size = Vector2(size.x, 44)
	if tap != null:
		tap.position = Vector2.ZERO
		tap.size = size
	queue_redraw()


func _draw() -> void:
	if _portrait == null:
		return
	var center: Vector2 = _portrait.position + _portrait.size / 2.0
	var radius: float = _portrait.size.x / 2.0 + 5.0
	var rim: Color = UiTheme.HEALTH if is_next else UiTheme.MOSS if is_me else UiTheme.INK
	draw_circle(center + Vector2(0, 5), radius + 3.0, Color(0, 0, 0, 0.18))
	draw_circle(center, radius, rim)
	if selected:
		draw_arc(center, radius + 4.0, 0, TAU, 48, UiTheme.GILT, 3.0, true)


func _draw_stand_mark() -> void:
	if _stand_ready and _hip.visible:
		_stand_mark.draw_arc(
			_hip.size / 2.0, _hip.size.x / 2.0 + 3.0, 0, TAU, 40, UiTheme.GILT, 2.0, true
		)
	if _stand_used and _hip.visible:
		_stand_mark.draw_polyline(
			PackedVector2Array([Vector2(20, 4), Vector2(29, 13), Vector2(24, 18)]),
			UiTheme.INK,
			3.0,
			true
		)


func _process(delta: float) -> void:
	if not is_ghost or Settings.reduce_motion:
		return
	_ghost_time += delta
	_portrait.modulate.a = 0.75 + sin(_ghost_time * PI) * 0.15


## Standings expose hero names; cache their existing portrait identities once for all plaques.
static func _portrait_id(standing: Dictionary) -> String:
	if _hero_portraits.is_empty():
		for file: String in DirAccess.get_files_at("res://content/heroes"):
			if not file.ends_with(".json"):
				continue
			var parsed: Variant = JSON.parse_string(
				FileAccess.get_file_as_string("res://content/heroes/" + file)
			)
			if parsed is Dictionary:
				var hero: Dictionary = parsed
				_hero_portraits[Data.s(hero, "name")] = Data.s(hero, "id")
				_hero_definitions[Data.s(hero, "id")] = hero
	return str(_hero_portraits.get(Data.s(standing, "hero", Data.s(standing, "name")), ""))


func set_interactive(on: bool) -> void:
	_interactive = on
	tap.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	tap.tooltip_text = UiTheme.player_name(_standing) if on else ""


func _on_tapped(_zone: String, _index: int) -> void:
	if not _interactive:
		return
	scout_requested.emit(-1 if is_ghost else Data.i(_standing, "player_id", -1))


func _on_hovered(_zone: String, _index: int, inside: bool) -> void:
	if _interactive and inside and not is_next and not _phone():
		hero_requested.emit(_standing.duplicate(true))


static func _phone() -> bool:
	return preload("res://src/ui/widgets/card_view.gd").is_phone()


## Accept a live hero override when its resolved power text is available in the recruit state.
static func reader_card(standing: Dictionary, hero_override: Dictionary = {}) -> Dictionary:
	var id: String = _portrait_id(standing)
	var hero: Dictionary = hero_override
	if hero.is_empty():
		hero = Data.d(_hero_definitions, id)
	var card: Dictionary = standing.duplicate(true)
	card["def_id"] = Data.s(hero, "id", id)
	card["name"] = Data.s(hero, "name", UiTheme.player_name(standing))
	card["kind"] = "spell"
	card["type_word"] = "Hero"
	card["tribes"] = []
	var notes: PackedStringArray = []
	if not Data.s(hero, "text").is_empty():
		notes.append(Data.s(hero, "text"))
	notes.append("Tier %d." % Data.i(standing, "tier", 1))
	if Data.b(standing, "is_ghost"):
		notes.append("A ghost: no Health.")
	else:
		notes.append("Health %d." % maxi(0, Data.i(standing, "health")))
	if not Data.b(standing, "alive", true):
		notes.append("Eliminated.")
	if Data.b(standing, "last_stand_enabled"):
		notes.append(
			(
				"Last Stand: %s."
				% (
					"used"
					if Data.b(standing, "last_stand_used")
					else "ready" if Data.b(standing, "last_stand_active") else "not active"
				)
			)
		)
	card["text"] = "\n".join(notes)
	if hero.has("configured_details"):
		card["configured_details"] = hero["configured_details"]
	return card
