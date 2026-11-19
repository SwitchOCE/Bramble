extends GutTest
## Every card the game ships (each tribe folder under src/content) has its card art at
## assets/units/<tribe>/<id>.jpg, in card space at half size, with mipmaps so it stays smooth
## when a card is drawn small. A card on the waiting list (tools/art/waiting.txt) has no art yet
## and is drawn with its tribe's stand-in panel instead; the list fails once its art lands.

const CONTENT: String = "res://src/content"
const WAITING: String = "res://tools/art/waiting.txt"
const FAKE_ID: String = "fake-card-waiting-for-art"
const SHARED: String = "res://src/content/shared"


## The card ids on a waiting list: one a line, skipping blank lines and lines starting with #.
static func waiting_ids(text: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for line: String in text.split("\n"):
		var id: String = line.strip_edges()
		if id != "" and not id.begins_with("#"):
			out.append(id)
	return out


## What is wrong with one shipped card's art, "" for nothing.
static func art_problem(tribe: String, id: String, tex: Texture2D, waiting: bool) -> String:
	if waiting:
		if tex != null:
			return "%s/%s has art: take it off %s" % [tribe, id, WAITING]
		if not ResourceLoader.exists(GameContent.PANEL_PATH % tribe):
			return "%s/%s waits for art, but %s has no stand-in panel" % [tribe, id, tribe]
		return ""
	if tex == null:
		return "%s/%s has no art (add it, or list it in %s)" % [tribe, id, WAITING]
	if tex.get_size() != GlassPieces.card_units():
		return "%s/%s is not card size" % [tribe, id]
	if not tex.get_image().has_mipmaps():
		return "%s/%s has no mipmaps" % [tribe, id]
	return ""


## tribe folder -> its card ids, for every tribe folder with a units.json.
static func shipped_cards() -> Dictionary:
	var out: Dictionary = {}
	for tribe: String in DirAccess.get_directories_at(CONTENT):
		var path: String = "%s/%s/units.json" % [CONTENT, tribe]
		if not FileAccess.file_exists(path):
			continue
		var ids: PackedStringArray = []
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			var data: Dictionary = parsed
			for card: Dictionary in data.get("cards", []):
				ids.append(str(card.get("id", "")))
		out[tribe] = ids
	return out


func test_every_shipped_card_has_art_at_card_size_with_mipmaps() -> void:
	assert_true(FileAccess.file_exists(WAITING), "the waiting list exists")
	var waiting: PackedStringArray = waiting_ids(FileAccess.get_file_as_string(WAITING))
	var cards: Dictionary = shipped_cards()
	var shipped: PackedStringArray = []
	for tribe: String in cards:
		var ids: PackedStringArray = cards[tribe]
		assert_gt(ids.size(), 0, "%s lists cards" % tribe)
		for id: String in ids:
			shipped.append(id)
			var tex: Texture2D = GlassPieces.unit_art(tribe, id)
			var problem: String = art_problem(tribe, id, tex, waiting.has(id))
			assert_eq(problem, "", "%s/%s art" % [tribe, id])
	for id: String in waiting:
		assert_true(shipped.has(id), "%s on the waiting list is a shipped card" % id)
	assert_eq(cards.size(), 5, "five tribes ship")


func test_the_waiting_list_reads_ids_and_skips_comments() -> void:
	var text: String = "# header\n\nfirst-card\n  second-card  \n# note\n"
	assert_eq(waiting_ids(text), PackedStringArray(["first-card", "second-card"]))


func test_a_waiting_card_passes_without_art_and_fails_once_it_has_art() -> void:
	assert_eq(art_problem("pigeon", FAKE_ID, null, true), "", "waiting, no art: passes")
	assert_ne(art_problem("pigeon", FAKE_ID, null, false), "", "not waiting, no art: fails")
	var cards: Dictionary = shipped_cards()
	var ids: PackedStringArray = cards.get("pigeon", PackedStringArray())
	assert_gt(ids.size(), 0, "a pigeon card to try")
	if ids.is_empty():
		return
	var tex: Texture2D = GlassPieces.unit_art("pigeon", ids[0])
	assert_not_null(tex, "%s has art" % ids[0])
	assert_ne(art_problem("pigeon", ids[0], tex, true), "", "waiting, with art: fails")


func test_a_waiting_card_draws_its_tribe_panel() -> void:
	var content: GameContent = GameContent.load_folders(PackedStringArray([SHARED]))
	content._folder_of[FAKE_ID] = "pigeon"
	assert_eq(content.art_for(FAKE_ID), GameContent.PANEL_ART % "pigeon", "the tribe's panel")
	assert_not_null(GlassPieces.art(content.art_for(FAKE_ID)), "it draws")
