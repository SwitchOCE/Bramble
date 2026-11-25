extends GutTest
## The glass mock-ups' pieces in assets/glass load, and say where they came from.

const CardSheet: PackedScene = preload("res://src/glass/card_sheet.tscn")
## Every card.* layout key src/glass reads. A re-pull that drops one fails here. The stage.* and
## css/stage/* keys the recruit screen reads fail tests/screens/test_recruit_screen.gd instead.
const KEYS_USED: Array[String] = [
	"card.units.w",
	"card.units.h",
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


func test_card_silhouette_is_the_l1_hexagon() -> void:
	var box: Vector2 = GlassCard.card_size(250.0)
	var points: PackedVector2Array = L1CardFace.unit_outline(box)
	assert_eq(box, Vector2(140, 250))
	assert_eq(points.size(), 6)
	assert_eq(points[0], Vector2(70, 0))
	assert_almost_eq(points[1], Vector2(140, 40.4), Vector2.ONE * 0.02)
	assert_almost_eq(points[2], Vector2(140, 209.6), Vector2.ONE * 0.02)
	assert_eq(points[3], Vector2(70, 250))
	assert_almost_eq(points[4], Vector2(0, 209.6), Vector2.ONE * 0.02)
	assert_almost_eq(points[5], Vector2(0, 40.4), Vector2.ONE * 0.02)
	var mask: Image = L1CardFace.silhouette().get_image()
	assert_eq(mask.get_pixel(0, 0).a, 0.0, "the corners stay outside the foil and shadow mask")
	assert_eq(mask.get_pixel(mask.get_width() >> 1, mask.get_height() >> 1).a, 1.0)


func test_cards_share_fixed_stat_disc_positions() -> void:
	var attack: Vector3 = GlassCard.stat_disc("attack")
	var health: Vector3 = GlassCard.stat_disc("health")
	assert_almost_eq(Vector2(attack.x, attack.y), Vector2(26.1, 205.5), Vector2.ONE * 0.01)
	assert_almost_eq(Vector2(health.x, health.y), Vector2(113.9, 205.5), Vector2.ONE * 0.01)
	assert_eq(attack.z, 17.0)
	assert_eq(health.z, 17.0)


func test_art_window_uses_the_l1_inset_and_crop() -> void:
	assert_eq(L1Layout.number("card.lead.width"), 5.0)
	assert_eq(L1Layout.rect("card.art"), Rect2(28, 52, 504, 900))


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
		if key.ends_with("_colour"):
			assert_true(Color.html_is_valid(str(entry.get("value"))), "%s is a colour" % key)
		else:
			assert_true(entry.get("value") is float, "%s is numeric" % key)
		assert_not_null(source.search(str(entry.get("from", ""))), "%s names a spec section" % key)


func test_layout_values_match_the_l1_stat_template() -> void:
	assert_eq(L1Layout.number("card.stat.font_px"), 20.0)
	assert_eq(L1Layout.colour("card.stat.raised_colour"), Color("#1f6b34"))
	assert_eq(L1Layout.colour("card.stat.lowered_colour"), Color("#b02a1c"))
	assert_eq(L1Layout.number("card.stat.baseline_em"), 0.04)
	assert_eq(L1Layout.number("card.stat.rim") + L1Layout.number("card.stat.outline"), 4.0)
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
