extends "res://src/ui/widgets/interactive.gd"
## One unit or spell tile, as in the mock (.wc-tile). Renders a recruit unit view (SPEC 6.2) or a
## combat unit view (6.3): art, keyword chip, name, tribe, tier disc, hexagon Attack and round
## Health, with golden, frozen, token and status looks. Laid out by hand at any size.
##
## A SHOP tile carries the rules text whenever it fits: always at desktop size, and at the phone
## minimum for the short ones. Otherwise the tile says the keyword, and the full text is one tap or
## hover away (CardDetail). A tile never shows reminder text (what a keyword means): it opens on a
## ReminderSlip when the player hovers or taps the keyword in the details. See the wording guide
## (docs/ideation/wording-guide.md).
##
## Modes: SHOP is the tall tile with the name and tribe (shop, hand with one card); BOARD fills a
## pocket with art, chip and stats; MINI is the smallest, for a crowded hand: art and stats only.

enum Mode { SHOP, BOARD, MINI }

const PoachedBadge := preload("res://src/ui/widgets/poached_badge.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

const SHOP_WIDTH: float = 270.0
const SHOP_HEIGHT: float = 297.0
const BOARD_RATIO: float = 102.0 / 112.0
## Tribe text needs this much clear width between the stat beads.
const TRIBE_MIN_WIDTH: float = 248.0
const LINE: int = 5
const EDGE: float = 12.0
## Rules text sizes on a tile: the phone never goes under the minimum; a desktop reads smaller.
const DESKTOP_RULES: Array[int] = [24, 22]
const PHONE_RULES: Array[int] = [UiTheme.MIN_FONT]
const RULES_LINE_GAP: int = -3
const ART_TOP: float = 19.0
## Keep a recognizable portrait; longer rules stay one tap away.
const ART_MIN: float = 40.0
## The bottom of a SHOP tile: the stat beads and the tribe or card word.
const SHOP_BOTTOM: float = 56.0
## Unit names and rules also clear the stat beads that rise above the tribe line.
const SHOP_UNIT_BOTTOM: float = 70.0
## A one-line name's label is this tall at least, whatever size it is given.
const NAME_BOX: float = 52.0

## A keyword that is the whole point of the card, so its name beats saying when it happens.
const TAG_KEYWORDS: PackedStringArray = [
	"Hex", "Nightshade", "Rainbow", "Shy", "Bristle", "Hunker", "Quarry", "Mire"
]
## Rules pattern -> the tile's short tag, first match wins. Both lines of a tag fit a board tile.
const RULE_TAGS: Dictionary[String, String] = {
	"^sells for": "Sale grows",
	"^each turn on your board:.*sell for": "Sale grows",
	"^has .*for each nest": "Per Nest",
	"^your eggs have": "Eggs grow",
	"^birds flying from beside this": "Longer trips",
	"^after a mired enemy dies: get": "Mired gold",
	"^after a mired enemy dies: the unit that": "Maker grows",
	"^after a mired enemy attacks": "Hit growth",
	"^after you play a stash": "Hoard feeds",
	"^after you summon a unit": "Summons grow",
	"^a bought unit inside": "Belly golden",
	"^your units have.*while joining": "Pack power",
	"^your snap units": "Snap power",
	"^all your summons spill": "Spill",
	"^your summons spill": "Spill",
	"^an enemy this damages": "Delayed kill",
	"^after each fight: your next tier up": "Take reward",
	"^spells you aim at this": "Spell echo",
	"^when a spell gives": "Spells inside",
	"^after a unit on a ring attacks": "Ring dance",
	"^after a bird comes home": "Homecoming",
	"^when this comes home": "Homecoming",
	"^your (two|four) biggest birds away": "Eggs grow",
	"^your (biggest|two biggest) other birds?": "Bird guard",
	"^after you tier up": "On tier-up",
	"^after one of your hunters makes a take": "Take growth",
	"get (\\d+) acorns?": "$1 Acorns",
	"^acorns played on this": "Acorns",
	"held acorns": "Per Acorn",
	"get an acorn": "Acorns",
	"^when this dies": "On death",
	"^whenever this is attacked": "When hit",
	"^after this attacks": "On attack",
	"^after you cast": "On spell",
	"^after a friendly unit dies": "Ally dies",
	"^every (\\d+\\w\\w) end of turn": "Every $1",
	"^start of turn": "Start of Turn",
	"^on a nest": "On a Nest",
	"^after 2 turns in a row without": "No refresh",
	"^skips its attacks": "Waits",
	"^when a unit on a nest": "On a Nest",
	"^when a unit comes out": "Comes out",
	"^after you spend": "On spend",
	"^every \\d+ gold you spend": "On spend",
	"^start of combat": "Start of Combat",
	"^end of turn": "End of Turn",
	"^(on play|when played)": "On play",
	"^in your back row": "Back row",
	"^the enemy across": "Across",
}

## def_id -> true for units whose mechanics aren't built yet; they say so on the chip.
static var unbuilt: Dictionary = {}
## Tests set this to try a window shape. Zero reads the real window.
static var window_override: Vector2 = Vector2.ZERO
static var _regexes: Dictionary = {}

var unit: Dictionary = {}
## The size this card is laid out for (see LEARNINGS, 4 Nov: size lags behind the minimum size).
var card_size: Vector2 = Vector2(SHOP_WIDTH, SHOP_HEIGHT)
var mode: Mode = Mode.SHOP
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
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
## The slip for a card that counts turns in its slot ("2/3"); "" hides it.
var turns_shown: String = "":
	set(value):
		turns_shown = value
		_place_turns()

## No keyword chip on this tile, however big: the scouting tray is too small for one.
var chip_hidden: bool = false
## The chip's text as shown (read by tests).
var chip_shown: String = ""
## The rules text is on the tile (read by tests); when false it is a tap away.
var rules_shown: bool = false

var _poached_badge: PoachedBadge
var _art: ArtFrame
var _chip: Panel
var _chip_lines: Array[Label] = []
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
var _pending_label: Label
var _turns: Label
var _status_tag: Panel
var _status_icon: TextureRect
var _status_label: Label
var _frost_tag: Panel
var _frost_tag_on: bool = false
var _star: TextureRect


static func size_for(width: float, card_mode: Mode = Mode.SHOP) -> Vector2:
	match card_mode:
		Mode.SHOP:
			return Vector2(width, SHOP_HEIGHT)
		Mode.BOARD:
			return Vector2(width, roundf(width * BOARD_RATIO))
	return Vector2(width, width)


## The tile's short tag: what the card does, or when, read from its current rules so it can't go
## stale. "Peck 2", "Ring +1/+1", "Nightshade", "When hit". "" for no text.
static func chip_text(view: Dictionary) -> String:
	var original: String = _rules_chip(view)
	var preview: PackedStringArray = []
	if view.has("recruit_bitter"):
		preview.append("Bitter %d" % Data.i(view, "recruit_bitter"))
	if view.has("recruit_kisses") or view.has("bog_kiss_period"):
		var count: int = Data.i(view, "recruit_kisses", Data.i(Data.d(view, "counters"), "kisses"))
		var period: int = maxi(1, Data.i(view, "bog_kiss_period", 3))
		preview.append(
			"Kiss %d/%d" % [count % period if view.has("bog_kiss_period") else count, period]
		)
	if preview.is_empty():
		return original
	# Two readable lines fit above a board tile's stat beads. Keep its original tag when
	# there is one number; both current numbers take precedence when a frog borrows Bitter.
	if preview.size() == 1 and not original.is_empty() and not original.begins_with("Bitter"):
		preview.insert(0, original)
	return "\n".join(preview)


static func _rules_chip(view: Dictionary) -> String:
	var rules: String = Data.s(view, "text")
	if is_unbuilt(view):
		return "Not built"
	if rules.is_empty():
		return ""
	var keywords: Array = Data.a(view, "keywords")
	if not keywords.is_empty():
		var word: String = str(keywords[0])
		if rules.begins_with(word):
			var rest: String = rules.substr(word.length())
			var count: RegExMatch = _regex("^ \\(?(\\d+)\\)?[. ]").search(rest + " ")
			return "%s %s" % [word, count.get_string(1)] if count != null else word
		var with_number: String = _keyword_number(rules, word)
		if not with_number.is_empty():
			return with_number
		if word in TAG_KEYWORDS:
			return word
	return _rules_tag(rules)


## "Ring +1/+1" from "Ring this slot +1/+1".
static func _keyword_number(rules: String, word: String) -> String:
	var found: RegExMatch = _regex(word + "[^.:+-]*([+-]\\d+(/[+-]\\d+)?)").search(rules)
	return "%s %s" % [word, found.get_string(1)] if found != null else ""


## Authored rule tags, explicit short headings, or a generic tag that roster tests reject.
static func _rules_tag(rules: String) -> String:
	for pattern: String in RULE_TAGS:
		var found: RegExMatch = _regex("(?i)" + pattern).search(rules)
		if found != null:
			var tag: String = RULE_TAGS[pattern]
			return tag.replace("$1", found.get_string(1)) if found.get_group_count() > 0 else tag
	var colon: int = rules.find(":")
	if colon > 0 and colon <= 14:
		return rules.left(colon)
	if rules.length() <= 12:
		return rules.trim_suffix(".")
	return "Ability"


static func _regex(pattern: String) -> RegEx:
	if not _regexes.has(pattern):
		_regexes[pattern] = RegEx.create_from_string(pattern)
	return _regexes[pattern]


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


## Queued permanent gains are separate from the unit's current combat stats.
func set_pending_gains(attack: int, health: int) -> void:
	unit["pending_attack"] = attack
	unit["pending_health"] = health
	_refresh_pending()


func set_kisses(count: int, period: int) -> void:
	unit["recruit_kisses"] = count
	unit["bog_kiss_period"] = period
	_refresh_chip(is_spell(unit))
	_refresh_pending()


func uid() -> int:
	return Data.i(unit, "uid", -1)


## Shows the "Frozen, kept next turn" tag on this tile (the first frozen offer carries it).
func show_frost_tag(on: bool) -> void:
	_frost_tag_on = on
	if on and _frost_tag == null:
		_build_frost_tag()
	if _frost_tag != null:
		_frost_tag.visible = on


func _build() -> void:
	_art = ArtFrame.new()
	add_child(_art)
	_name_label = UiTheme.head("", UiTheme.FONT_BODY)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_constant_override("line_spacing", -16)
	add_child(_name_label)
	_rules = UiTheme.label("", UiTheme.FONT_SMALL)
	_rules.add_theme_font_override("font", UiTheme.bold_font())
	_rules.add_theme_constant_override("line_spacing", RULES_LINE_GAP)
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
	for i: int in 2:
		var line: Label = UiTheme.label("", UiTheme.FONT_SMALL)
		line.add_theme_font_override("font", UiTheme.bold_font())
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_chip.add_child(line)
		_chip_lines.append(line)
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
	_pending_label = UiTheme.label("", 31, UiTheme.INK)
	_pending_label.add_theme_font_override("font", UiTheme.bold_font())
	_pending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pending_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pending_tag.add_child(_pending_label)

	_status_tag = Panel.new()
	_status_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_tag.visible = false
	add_child(_status_tag)
	_status_icon = TextureRect.new()
	_status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_status_icon.texture = Icons.icon("berry", 36.0)
	_status_tag.add_child(_status_icon)
	_status_label = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_status_label.add_theme_font_override("font", UiTheme.bold_font())
	_status_tag.add_child(_status_label)
	_star = TextureRect.new()
	_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_star.texture = Icons.icon("spark", 30.0)
	_star.visible = false
	add_child(_star)
	_poached_badge = PoachedBadge.new()
	add_child(_poached_badge)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _badge_label(badge: ShapeBadge, colour: Color, font_size: int) -> Label:
	var node: Label = UiTheme.number("", font_size, colour)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(node)
	return node


func _build_frost_tag() -> void:
	_frost_tag = Panel.new()
	_frost_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frost_tag.add_theme_stylebox_override("panel", UiTheme.slip_box(UiTheme.FROST))
	add_child(_frost_tag)
	var snow: TextureRect = TextureRect.new()
	snow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snow.texture = Icons.icon("freeze", 38.0)
	snow.position = Vector2(8, 11)
	snow.size = Vector2(38, 38)
	_frost_tag.add_child(snow)
	var word: Label = UiTheme.burned("Frozen", UiTheme.FONT_SMALL)
	word.position = Vector2(52, 2)
	_frost_tag.add_child(word)
	var note: Label = UiTheme.label("kept next turn", UiTheme.FONT_SMALL)
	note.add_theme_font_override("font", UiTheme.bold_font())
	note.position = Vector2(52, 38)
	_frost_tag.add_child(note)
	var note_font: Font = UiTheme.bold_font()
	var note_w: float = (
		note_font.get_string_size(note.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FONT_SMALL).x
	)
	var width: float = 52.0 + note_w + 16.0
	_frost_tag.size = Vector2(width, 88)
	_frost_tag.position = Vector2((card_size.x - width) / 2.0, -66)
	_frost_tag.z_index = 5


func _refresh() -> void:
	if _art == null:
		return
	var tribes: Array = Data.a(unit, "tribes")
	var spell: bool = is_spell(unit)
	var golden: bool = Data.b(unit, "golden", false)
	_art.texture = UiTheme.portrait_for(Data.s(unit, "def_id"), tribes)
	_art.gilded = golden
	_star.visible = golden
	_name_label.text = Data.s(unit, "name")
	_type_label.text = card_word(unit) if spell else UiTheme.short_tribe(tribes)
	_tier_label.text = str(Data.i(unit, "cost", 1) if spell else Data.i(unit, "tier", 1))
	_tier_badge.shape = "knot_gold" if spell or golden else "knot"
	_tier_badge.visible = Data.s(unit, "type_word").is_empty()
	var worth: int = Data.i(unit, "gold_value", 0)
	if worth > 0:
		# An Acorn item: its gold value where a spell's cost goes.
		_tier_label.text = str(worth)
	_attack_badge.visible = not spell
	_health_badge.visible = not spell
	_place_parts(spell)
	_refresh_chip(spell)
	_refresh_stats()
	_refresh_status()
	_refresh_pending()
	_place_turns()
	if _frost_tag != null:
		_frost_tag.position.x = (card_size.x - _frost_tag.size.x) / 2.0 + 14.0
	queue_redraw()


## Positions every part for card_size and mode.
func _place_parts(spell: bool) -> void:
	var w: float = card_size.x
	var h: float = card_size.y
	var knot: float = 57.0
	_name_label.visible = mode == Mode.SHOP
	_art.visible = true
	_type_label.visible = mode == Mode.SHOP
	_rules.visible = false
	rules_shown = false
	match mode:
		Mode.SHOP:
			var name_room: float = _name_height(w - 12.0)
			var bottom: float = SHOP_BOTTOM if spell else SHOP_UNIT_BOTTOM
			var art_room: float = h - ART_TOP - 8.0 - maxf(name_room, NAME_BOX) - bottom
			var art_h: float = minf(124.0 if spell else 145.0, art_room)
			_art.radius = 44.0 if spell else 15.0
			_place(_art, Rect2(19, ART_TOP, w - 38, art_h))
			_place(_name_label, Rect2(6, ART_TOP + art_h + 8, w - 12, name_room))
			_place_rules(art_h)
			var clear: bool = w >= TRIBE_MIN_WIDTH or spell
			_type_label.visible = clear
			_place(_type_label, Rect2(0, h - 56, w, 44))
		Mode.BOARD:
			knot = 52.0
			_art.radius = 15.0
			_place(_art, Rect2(15, 15, w - 30, h - 30))
		Mode.MINI:
			knot = 48.0
			_art.radius = 12.0
			_place(_art, Rect2(10, 10, w - 20, h - 20))
	_place(_tier_badge, Rect2(-knot * 0.3, -knot * 0.3, knot, knot))
	_tier_label.add_theme_font_size_override("font_size", 34 if knot > 50.0 else UiTheme.FONT_SMALL)
	_place_beads()
	_star.position = Vector2(w - 40, 10)
	_star.size = Vector2(30, 30)
	_poached_badge.visible = Data.b(unit, "poached")
	_poached_badge.cost = Data.i(unit, "cost")
	_poached_badge.position = Vector2(card_size.x - 120, 2)
	_poached_badge.size = Vector2(120, 40)
	_poached_badge.queue_redraw()


## Puts rules below the name only when a portrait still fits. Otherwise the tile keeps
## its picture and keyword chip, with full rules available in CardDetail.
func _place_rules(art_h: float) -> void:
	var words: String = Data.s(unit, "text")
	if words.is_empty():
		return
	var wide: float = card_size.x - 20.0
	var name_h: float = _name_height(card_size.x - 12.0)
	var bottom: float = SHOP_BOTTOM if is_spell(unit) else SHOP_UNIT_BOTTOM
	var room: float = card_size.y - ART_TOP - name_h - bottom
	var sizes: Array[int] = PHONE_RULES if is_phone() else DESKTOP_RULES
	for font_size: int in sizes:
		var tall: float = _rules_height(words, wide, font_size)
		var art_room: float = room - tall - 10.0
		if art_room < ART_MIN:
			continue
		var art_now: float = minf(art_room, art_h)
		_art.size.y = art_now
		var y: float = ART_TOP + art_now + 4.0
		_place(_name_label, Rect2(6, y, card_size.x - 12.0, name_h))
		_rules.text = words
		_rules.add_theme_font_size_override("font_size", font_size)
		_place(_rules, Rect2(10, y + name_h + 2.0, wide, tall))
		_rules.visible = true
		rules_shown = true
		return


func _name_height(wide: float) -> float:
	var font: Font = UiTheme.head_font()
	var font_size: int = UiTheme.FONT_BODY
	if not is_phone():
		for candidate: int in range(UiTheme.FONT_BODY, UiTheme.MIN_FONT - 1, -1):
			font_size = candidate
			var fits: bool = true
			for word: String in Data.s(unit, "name").split(" "):
				fits = (
					fits
					and (
						font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, candidate).x
						<= wide
					)
				)
			if fits:
				break
	_name_label.add_theme_font_size_override("font_size", font_size)
	# Match AUTOWRAP_WORD_SMART, including a long word that must split to fit.
	var break_flags: int = (
		TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	)
	var text_size: Vector2 = font.get_multiline_string_size(
		Data.s(unit, "name"), HORIZONTAL_ALIGNMENT_CENTER, wide, font_size, -1, break_flags
	)
	var lines: int = maxi(1, roundi(text_size.y / font.get_height(font_size)))
	return maxf(40.0, text_size.y - (lines - 1) * 16.0 + 4.0)


func _rules_height(words: String, wide: float, font_size: int) -> float:
	var font: Font = UiTheme.bold_font()
	var line: float = font.get_height(font_size)
	var text_size: Vector2 = font.get_multiline_string_size(
		words, HORIZONTAL_ALIGNMENT_CENTER, wide, font_size
	)
	var lines: int = roundi(text_size.y / line)
	return lines * (line + RULES_LINE_GAP) - RULES_LINE_GAP + 2.0


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


func _refresh_chip(spell: bool) -> void:
	var words: String = "" if spell or mode == Mode.MINI or chip_hidden else chip_text(unit)
	chip_shown = words
	_chip.visible = not words.is_empty() and not rules_shown
	if not _chip.visible:
		return
	# On a small tile "Gives Nightshade" would take two lines over the face; a tap has the rest.
	var font_check: Font = UiTheme.bold_font()
	var room: float = card_size.x - 28.0 - 22.0
	if mode == Mode.BOARD and words.begins_with("Gives "):
		var wide_all: float = (
			font_check.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FONT_SMALL).x
		)
		if wide_all > room:
			words = words.trim_prefix("Gives ")
	var lines: PackedStringArray = words.split("\n")
	var one_line: float = (
		UiTheme
		. bold_font()
		. get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FONT_SMALL)
		. x
	)
	if lines.size() == 1 and one_line + 22.0 > card_size.x - 28.0 and words.contains(" "):
		var space: int = words.find(" ")
		lines = [words.left(space), words.substr(space + 1)]
	var font: Font = UiTheme.bold_font()
	var widest: float = 0.0
	for i: int in _chip_lines.size():
		var line: Label = _chip_lines[i]
		line.visible = i < lines.size()
		if not line.visible:
			continue
		line.text = lines[i]
		var colour: Color = UiTheme.NIGHTSHADE if lines[i].contains("Nightshade") else UiTheme.INK
		line.add_theme_color_override("font_color", colour)
		var wide: float = font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 31).x
		widest = maxf(widest, wide)
	var line_h: float = 35.0
	var chip_w: float = widest + 22.0
	var chip_h: float = line_h * lines.size() + 8.0
	_chip.size = Vector2(chip_w, chip_h)
	for i: int in lines.size():
		var line: Label = _chip_lines[i]
		line.position = Vector2(0, 2 + line_h * i - 2)
		line.size = Vector2(chip_w, line_h)
	# On the tile's top edge, so it costs the art as little as it can: the face stays clear.
	var chip_y: float = 0.0
	if mode == Mode.BOARD and not Data.a(unit, "statuses").is_empty():
		chip_y = 22.0
	if mode == Mode.SHOP:
		chip_y = ART_TOP + _art.size.y - chip_h + 16.0
	var chip_x: float = (card_size.x - chip_w) / 2.0
	if mode == Mode.BOARD and chip_w > card_size.x - 56.0:
		chip_x = card_size.x - chip_w - 2.0
	elif mode == Mode.BOARD:
		chip_x = maxf(chip_x, 32.0)
	_chip.position = Vector2(chip_x, chip_y)
	_chip.z_index = 1 if chip_w > card_size.x - 56.0 else 0


func _refresh_stats() -> void:
	var health: int = Data.i(unit, "health", 0)
	var max_health: int = unit.get("max_health", health)
	_health_badge.shape = "rosehip_hurt" if health < max_health else "rosehip"
	_place_beads()


## Only the queued numbers occupy the portrait; the existing one-tap reader explains timing.
func _refresh_pending() -> void:
	var attack: int = Data.i(unit, "pending_attack")
	var health: int = Data.i(unit, "pending_health")
	_pending_tag.visible = mode == Mode.BOARD and (attack != 0 or health != 0)
	if not _pending_tag.visible:
		return
	var font: Font = _pending_label.get_theme_font("font")
	var room: float = card_size.x - 12.0
	var words: String = ""
	var width: float = INF
	for attack_text: String in StatNumbers.candidates(absi(attack)):
		for health_text: String in StatNumbers.candidates(absi(health)):
			var candidate: String = "+%s/+%s" % [attack_text, health_text]
			var measured: float = (
				font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 31).x
			)
			if measured < width:
				words = candidate
				width = measured
			if measured <= room - 12.0:
				break
		if width <= room - 12.0:
			break
	_pending_label.text = words
	_pending_label.position = Vector2(6, 0)
	_pending_label.size = Vector2(width, 38)
	_pending_tag.size = Vector2(width + 12, 38)
	var top: float = 40.0
	if _chip.visible:
		top = maxf(top, _chip.position.y + _chip.size.y + 4.0)
	_pending_tag.position = Vector2((card_size.x - _pending_tag.size.x) / 2.0, top)


## A status hangs from the tile's top edge, like the Frozen tag; more than one reads "+1".
func _refresh_status() -> void:
	var statuses: Array = Data.a(unit, "statuses")
	_status_tag.visible = not statuses.is_empty() and mode != Mode.SHOP
	if not _status_tag.visible:
		return
	var first: Dictionary = Data.entry(statuses, 0)
	var key: String = Data.s(first, "status")
	var words: String = UiTheme.status_label(key)
	if statuses.size() > 1:
		words += " +%d" % (statuses.size() - 1)
	_status_label.text = words
	_status_tag.add_theme_stylebox_override("panel", UiTheme.slip_box(UiTheme.status_colour(key)))
	var font: Font = UiTheme.bold_font()
	var wide: float = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 31).x
	var has_icon: bool = key == "nightshade"
	_status_icon.visible = has_icon
	var left: float = 38.0 if has_icon else 10.0
	_status_icon.position = Vector2(4, 6)
	_status_icon.size = Vector2(32, 32)
	_status_label.position = Vector2(left, 0)
	_status_label.size = Vector2(wide, 42)
	_status_tag.z_index = 1
	_status_tag.size = Vector2(left + wide + 8.0, 44)
	_status_tag.position = Vector2((card_size.x - _status_tag.size.x) / 2.0, -24)


func _place_turns() -> void:
	if turns_shown.is_empty():
		if _turns != null:
			_turns.visible = false
		return
	if _turns == null:
		_turns = UiTheme.number("", UiTheme.FONT_SMALL, UiTheme.CREAM)
		_turns.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.MOSS, 3, 22))
		_turns.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_turns.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_turns.z_index = 2
		add_child(_turns)
	_turns.visible = true
	_turns.text = turns_shown
	var compact: bool = mode == Mode.BOARD and card_size.x < 180.0
	var wrapped_hex: bool = (
		mode == Mode.BOARD
		and turns_shown.contains(" stored)")
		and _turns.get_minimum_size().x > card_size.x - 16.0
	)
	if Data.i(unit, "hex_stored") > 0 or Data.i(unit, "hex_percent_stored") > 0:
		_refresh_chip(false)
		if wrapped_hex:
			_turns.text = turns_shown.replace(" (", "\n").trim_suffix(")")
			_chip.visible = false
	var face: StyleBoxFlat = _turns.get_theme_stylebox("normal") as StyleBoxFlat
	face.content_margin_left = 8 if compact else 10
	face.content_margin_right = 8 if compact else 10
	face.content_margin_top = 0 if compact else 1
	face.content_margin_bottom = 0 if compact else 3
	_turns.size = Vector2(
		maxf(46.0, _turns.get_minimum_size().x), maxf(46.0, _turns.get_minimum_size().y)
	)
	_turns.position = Vector2(card_size.x + 12.0 - _turns.size.x, card_size.y * 0.34)
	if compact or wrapped_hex:
		_turns.size = Vector2(_turns.get_minimum_size().x, maxf(42.0, _turns.get_minimum_size().y))
		var below_chip: float = _chip.position.y + _chip.size.y + 4.0 if _chip.visible else 8.0
		var above_stats: float = minf(_attack_badge.position.y, _health_badge.position.y) - 4.0
		var top: float = maxf(below_chip, minf(card_size.y * 0.34, above_stats - _turns.size.y))
		_turns.position = Vector2(card_size.x - _turns.size.x - 8.0, top)


func _face() -> Color:
	if is_spell(unit):
		return UiTheme.SPELL_FACE
	if frost:
		return UiTheme.FROST_FACE
	if Data.b(unit, "golden", false):
		return UiTheme.GILT
	if Data.s(unit, "origin") == "created" or Data.b(unit, "token", false):
		return UiTheme.PINE
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
	if golden or Data.b(unit, "egged"):
		draw_style_box(_tile_box(Color(UiTheme.GILT, 0.55), Color.TRANSPARENT, 0), rect.grow(12))
	if frost:
		draw_style_box(_tile_box(UiTheme.RIME, Color.TRANSPARENT, 0), rect.grow(17))
		draw_style_box(_tile_box(UiTheme.FROST, Color.TRANSPARENT, 0), rect.grow(14))
	var ring: Color = UiTheme.SELECT if selected else outline
	if ring.a > 0.0:
		draw_style_box(_tile_box(UiTheme.INK, Color.TRANSPARENT, 0), rect.grow(19))
		draw_style_box(_tile_box(ring, Color.TRANSPARENT, 0), rect.grow(15))
	var under: Color = UiTheme.BRASS if golden else UiTheme.CARVE
	if frost:
		under = UiTheme.RIME
	elif is_spell(unit):
		under = UiTheme.NIGHTSHADE
	var drop: Rect2 = Rect2(Vector2(0, EDGE), card_size)
	draw_style_box(_tile_box(under, UiTheme.INK, LINE), drop)
	draw_style_box(_tile_box(_face(), UiTheme.INK, LINE), rect)
	if Data.s(unit, "origin") == "created" or Data.b(unit, "token", false):
		_draw_token_edge(rect.grow(-8))


## A created unit's dashed, burned edge.
func _draw_token_edge(rect: Rect2) -> void:
	var corners: PackedVector2Array = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	]
	for i: int in 4:
		draw_dashed_line(corners[i], corners[i + 1], UiTheme.CARVE, 3.0, 9.0)
