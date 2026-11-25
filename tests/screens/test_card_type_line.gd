extends GutTest
## Exercise the card and hover factories against the live catalog, including tokens.


func test_every_unit_type_is_in_the_hover_kind_line_and_not_on_the_card() -> void:
	var content: GameContent = GameContent.load_default()
	var screen: GlassScreen = GlassScreen.new()
	add_child_autofree(screen)
	for id: StringName in content.library.ids():
		var definition: UnitDef = content.library.get_card(id)
		if definition.is_spell():
			continue
		var data: Dictionary = ViewAdapter.printed_unit(content, str(id))
		var expected: String = " ".join(definition.types)
		assert_ne(expected, "", str(id))
		for height: float in [170.0, 250.0, 400.0]:
			var card: GlassCard = screen._unit_card(data, height)
			add_child(card)
			for text: Node in card.find_children("*", "GlassText", true, false):
				assert_false(
					(text as GlassText).words.to_lower().contains(expected.to_lower()),
					"%s prints no type on its face" % id
				)
			card.free()
		data["sell_value"] = 3
		var pane: GlassBox = GlassParts.tip_text(
			data, false, PackedStringArray(), content.display_table()
		)
		var kind: GlassText = pane.get_node("Kind")
		assert_string_contains(kind.words, expected.to_upper(), str(id))
		assert_lte(kind.get_rect().end.x, pane.size.x - kind.position.x, str(id))
		pane.free()


func test_one_word_type_and_spell_metadata() -> void:
	var unit: GlassBox = GlassParts.tip_text({"id": "husk-sentry", "tier": 1}, false)
	var spell: GlassBox = GlassParts.tip_text({"id": "husk-sentry", "cost": 3}, true)
	assert_eq((unit.get_node("Kind") as GlassText).words, "TIER 1 · LOCUST")
	assert_eq((spell.get_node("Kind") as GlassText).words, "SPELL · COSTS 3")
	unit.free()
	spell.free()
