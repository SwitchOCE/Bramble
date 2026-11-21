extends GutTest
## Every spell the game can show has its own picture, not the shared stand-in spell art (fix
## round 20 Nov, step 5). Unit art is checked by tests/glass/test_unit_art.gd.
##
## The art map stays outside the rules fingerprint, so pictures never change the rules version.

const STAND_IN_SPELLS: Array[String] = ["", "spell-1", "spell-2"]


func test_every_spell_has_its_own_picture() -> void:
	var content: GameContent = GameContent.load_default()
	var missing: Array[String] = []
	for id: StringName in content.library.ids():
		var card: UnitDef = content.library.get_card(id)
		if not card.is_spell():
			continue
		var art: String = CardArt.of(content, String(id))
		if STAND_IN_SPELLS.has(art) or GlassPieces.art(art) == null:
			missing.append(String(id))
	assert_eq(missing, [] as Array[String], "spells with no picture of their own")


func test_the_art_map_is_outside_the_rules_files() -> void:
	var content: GameContent = GameContent.load_default()
	for id: String in CardArt.SPELLS:
		assert_true(content.library.has(StringName(id)), "%s is a card" % id)
		assert_ne(
			content.art_for(id),
			str(CardArt.SPELLS[id]),
			"%s's picture is not in the rules files" % id
		)
