extends GutTest
## The glass mock-ups' pieces in assets/glass load, and say where they came from.

const CardSheet: PackedScene = preload("res://src/glass/card_sheet.tscn")
## Every card.* layout key src/glass reads. A re-pull that drops one fails here. The stage.* and
## css/stage/* keys the recruit screen reads fail tests/screens/test_recruit_screen.gd instead.
const KEYS_USED: Array[String] = [
	"card.units.w",
	"card.units.h",
	"card.num.one_digit_scale",
	"card.num.two_digit_scale",
	"card.num.weight",
	"card.num.colour",
	"card.num.letter_spacing_em",
	"card.num.padding_top_em",
	"card.num.glow",
	"card.num.glow_em",
	"card.shadow.x",
	"card.shadow.y",
	"card.shadow.blur",
	"card.shadow.colour",
	"font.display.ascent",
	"font.display.descent",
	"font.display.line_gap",
	"font.body.ascent",
	"font.body.descent",
	"font.body.line_gap",
	"sheet.art",
	"sheet.numbers",
	"sheet.sizes",
	"sheet.page",
	"sheet.text",
	"sheet.muted",
	"sheet.padding",
	"sheet.row.gap",
	"sheet.row.padding",
	"sheet.row.colour",
	"sheet.row.radius",
]


func test_unit_art_is_null_for_a_unit_with_none() -> void:
	assert_null(GlassPieces.unit_art("locust", "no-such-unit"))


func test_six_frames_load_at_card_size() -> void:
	for tier: int in range(1, GlassPieces.TIERS + 1):
		var tex: Texture2D = GlassPieces.frame(tier)
		assert_not_null(tex, "tier %d frame loads" % tier)
		assert_eq(tex.get_size(), GlassPieces.card_units(), "tier %d frame is 560 x 1000" % tier)


func test_card_data_has_each_tiers_discs() -> void:
	for tier: int in range(1, GlassPieces.TIERS + 1):
		for which: String in ["attack", "health"]:
			var disc: Vector3 = GlassPieces.disc(tier, which)
			assert_gt(disc.z, 40.0, "tier %d %s disc has a radius" % [tier, which])
			assert_true(
				Rect2(Vector2.ZERO, GlassPieces.card_units()).has_point(Vector2(disc.x, disc.y)),
				"tier %d %s disc is on the card" % [tier, which]
			)
	var attack: Vector3 = GlassPieces.disc(1, "attack")
	assert_lt(attack.x, GlassPieces.disc(1, "health").x, "Attack is on the left")


func test_art_window_is_a_hexagon() -> void:
	assert_eq(GlassPieces.art_polygon().size(), 6)


func test_layout_has_every_key_used_and_says_where_each_came_from() -> void:
	for key: String in KEYS_USED:
		assert_true(GlassPieces.has_value(key), "layout.json has %s" % key)
	for key: String in GlassPieces.layout():
		var entry: Dictionary = GlassPieces.layout()[key]
		assert_ne(str(entry.get("from", "")), "", "%s names its source file" % key)
		assert_ne(str(entry.get("source", "")), "", "%s quotes its source" % key)


func test_l1_layout_numbers_name_their_spec_sections() -> void:
	var entries: Dictionary = L1Layout.entries()
	var source: RegEx = RegEx.create_from_string("^buy-screen-l1\\.md §[0-9]+")
	assert_false(entries.is_empty())
	for key: String in entries:
		var entry: Dictionary = entries[key]
		assert_true(entry.get("value") is float, "%s is numeric" % key)
		assert_not_null(source.search(str(entry.get("from", ""))), "%s names a spec section" % key)


func test_layout_values_match_the_mockups_card_template() -> void:
	assert_eq(GlassPieces.number("card.num.one_digit_scale"), 1.2)
	assert_eq(GlassPieces.number("card.num.two_digit_scale"), 0.95)
	assert_eq(GlassPieces.colour("card.num.colour"), Color.html("#150e08"))
	assert_eq(GlassPieces.css_colour("0,0,0,.6"), Color(0, 0, 0, 0.6))


func test_layout_has_no_retired_shop_button_geometry_or_acorn_icon() -> void:
	for key: String in [
		"stage.recruit.button.w",
		"stage.recruit.button.gap",
		"stage.recruit.button.up",
		"stage.recruit.button.step",
		"stage.icon.gold"
	]:
		assert_false(GlassPieces.has_value(key), "%s has no runtime reader" % key)


func test_shop_up_renders_the_owner_selected_svg_through_the_icon_set() -> void:
	var svg: String = (
		'<svg viewBox="0 0 24 24"><path d="M3 9h12l-1.5-4h-9z"/>'
		+ '<path d="M3 9a2 2 0 0 0 4 0a2 2 0 0 0 4 0a2 2 0 0 0 4 0"/>'
		+ '<path d="M4.5 11v8M13.5 11v8M3 19h12"/>'
		+ '<path d="M20.5 19V7M18 9.5l2.5-2.5 2.5 2.5"/></svg>'
	)
	for px: int in [18, 24]:
		var tint: Color = Color("120e0b")
		var icon: Texture2D = GlassPieces.icon("shop_up", tint, px, 2.4)
		assert_same(icon, GlassPieces.svg_icon(svg, tint, px, 2.4), "the exact approved paths")
		assert_eq(icon.get_size(), Vector2.ONE * px, "a square stroked icon at either UI size")
		assert_false(icon.get_image().is_invisible(), "the SVG renders visible strokes")


func test_files_match_the_hashes_the_pull_recorded() -> void:
	var source: Dictionary = GlassPieces.source()
	var commit: String = source.get("mockups_commit", "")
	assert_eq(commit.length(), 40, "source.json names a full commit")
	var files: Dictionary = source.get("files", {})
	assert_gt(files.size(), 10, "source.json lists the pulled files")
	for rel: String in files:
		var path: String = GlassPieces.ROOT + rel
		assert_eq(FileAccess.get_sha256(path), str(files[rel]), "%s is as pulled" % rel)


func test_fonts_load() -> void:
	var display: Font = GlassPieces.display_font(900, true)
	var body: Font = GlassPieces.body_font()
	assert_gt(display.get_string_size("25", HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x, 0.0)
	assert_gt(body.get_string_size("Card", HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, 0.0)


func test_card_sheet_builds_six_cards_per_size() -> void:
	var sheet: Control = CardSheet.instantiate() as Control
	add_child_autofree(sheet)
	var cards: int = 0
	for child: Node in sheet.get_children():
		if child is GlassCard:
			cards += 1
	assert_eq(cards, 18, "6 tiers at 3 sizes")
	var tall: GlassCard = sheet.get_node("Card424_6") as GlassCard
	assert_eq(tall.size, Vector2(424.0 * 0.56, 424.0), "a card is 0.56 as wide as it is tall")
	assert_eq([tall.attack, tall.health], [9, 99], "numbers from cards.html")
