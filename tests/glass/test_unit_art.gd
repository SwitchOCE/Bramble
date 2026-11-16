extends GutTest
## Every unit and token in a tribe's units.json has its card art at assets/units/<tribe>/<id>.jpg,
## in card space at half size (560 x 1000), as the card art recipe's fixed crop makes it.

## Tribes whose art has been delivered. Add a tribe here when its pictures land.
const TRIBES: Array[String] = ["thorn"]
const UNITS_JSON: String = "res://docs/ideation-track-2/tribes/%s/units.json"
const ART: String = "res://assets/units/%s/%s.jpg"
const SIZE: Vector2 = Vector2(560, 1000)


func test_every_unit_has_art_at_card_size() -> void:
	for tribe: String in TRIBES:
		var text: String = FileAccess.get_file_as_string(UNITS_JSON % tribe)
		assert_ne(text, "", "%s units.json reads" % tribe)
		var data: Dictionary = JSON.parse_string(text)
		var ids: Array[String] = []
		for entry: Dictionary in data.get("units", []) + data.get("tokens", []):
			ids.append(str(entry["id"]))
		assert_gt(ids.size(), 0, "%s lists units" % tribe)
		for id: String in ids:
			var path: String = ART % [tribe, id]
			assert_true(ResourceLoader.exists(path), "%s has art" % path)
			if ResourceLoader.exists(path):
				var tex: Texture2D = load(path) as Texture2D
				assert_eq(tex.get_size(), SIZE, "%s is 560 x 1000" % path)
