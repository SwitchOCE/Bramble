extends GutTest
## Every card the game ships (each tribe folder under src/content) has its card art at
## assets/units/<tribe>/<id>.jpg, in card space at half size, with mipmaps so it stays smooth
## when a card is drawn small.

const CONTENT: String = "res://src/content"


func test_every_shipped_card_has_art_at_card_size_with_mipmaps() -> void:
	var tribes: int = 0
	for tribe: String in DirAccess.get_directories_at(CONTENT):
		var path: String = "%s/%s/units.json" % [CONTENT, tribe]
		if not FileAccess.file_exists(path):
			continue
		tribes += 1
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true(parsed is Dictionary, "%s reads" % path)
		if not parsed is Dictionary:
			continue
		var data: Dictionary = parsed
		var cards: Array = data.get("cards", [])
		assert_gt(cards.size(), 0, "%s lists cards" % tribe)
		for card: Dictionary in cards:
			var id: String = str(card.get("id", ""))
			var tex: Texture2D = GlassPieces.unit_art(tribe, id)
			assert_not_null(tex, "%s/%s has art" % [tribe, id])
			if tex == null:
				continue
			assert_eq(tex.get_size(), GlassPieces.card_units(), "%s/%s is card size" % [tribe, id])
			assert_true(tex.get_image().has_mipmaps(), "%s/%s has mipmaps" % [tribe, id])
	assert_eq(tribes, 5, "five tribes ship")
