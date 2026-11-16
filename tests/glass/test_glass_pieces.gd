extends GutTest
## The glass mock-ups' pieces in assets/glass load, and say where they came from.

const CardSheet: PackedScene = preload("res://src/glass/card_sheet.tscn")
## Every layout key the Godot side reads. A re-pull that drops one fails here.
const KEYS_USED: Array[String] = [
	"card.outline",
	"card.num.one_digit_scale",
	"card.num.two_digit_scale",
	"card.num.weight",
	"card.num.colour",
	"card.num.letter_spacing_em",
	"card.num.padding_top_em",
	"card.num.glow",
	"card.num.glow_em",
	"card.num.hurt.colour",
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
	"stage.width",
	"stage.height",
	"stage.recruit.card_h",
	"stage.recruit.gap",
	"stage.recruit.hand_step_per_w",
]


func test_six_frames_load_at_card_size() -> void:
	for tier: int in range(1, GlassPieces.TIERS + 1):
		var tex: Texture2D = GlassPieces.frame(tier)
		assert_not_null(tex, "tier %d frame loads" % tier)
		assert_eq(tex.get_size(), GlassPieces.CARD_UNITS, "tier %d frame is 560 x 1000" % tier)


func test_card_data_has_each_tiers_discs() -> void:
	for tier: int in range(1, GlassPieces.TIERS + 1):
		for which: String in ["attack", "health"]:
			var disc: Vector3 = GlassPieces.disc(tier, which)
			assert_gt(disc.z, 40.0, "tier %d %s disc has a radius" % [tier, which])
			assert_true(
				Rect2(Vector2.ZERO, GlassPieces.CARD_UNITS).has_point(Vector2(disc.x, disc.y)),
				"tier %d %s disc is on the card" % [tier, which]
			)
	var attack: Vector3 = GlassPieces.disc(1, "attack")
	assert_lt(attack.x, GlassPieces.disc(1, "health").x, "Attack is on the left")


func test_art_window_and_outline_are_hexagons() -> void:
	assert_eq(GlassPieces.art_polygon().size(), 6)
	assert_eq(GlassPieces.outline().size(), 6)


func test_layout_has_every_key_used_and_says_where_each_came_from() -> void:
	for key: String in KEYS_USED:
		assert_true(GlassPieces.has_value(key), "layout.json has %s" % key)
	for key: String in GlassPieces.layout():
		var entry: Dictionary = GlassPieces.layout()[key]
		assert_ne(str(entry.get("from", "")), "", "%s names its source file" % key)
		assert_ne(str(entry.get("source", "")), "", "%s quotes its source" % key)


func test_layout_values_match_the_mockups_card_template() -> void:
	assert_eq(GlassPieces.number("card.num.one_digit_scale"), 1.2)
	assert_eq(GlassPieces.number("card.num.two_digit_scale"), 0.95)
	assert_eq(GlassPieces.colour("card.num.colour"), Color.html("#150e08"))
	assert_eq(GlassPieces.css_colour("0,0,0,.6"), Color(0, 0, 0, 0.6))


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
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
