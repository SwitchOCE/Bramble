extends GutTest
## docs/ideation/engine.md is what card designers read: it must name everything the schema knows.

const SECTIONS: PackedStringArray = ["triggers", "selectors", "conditions", "effects"]


func test_every_schema_name_is_in_the_doc() -> void:
	var doc: String = FileAccess.get_file_as_string("res://docs/ideation/engine.md")
	assert_gt(doc.length(), 0, "the doc is there")
	for section: String in SECTIONS:
		for entry: Variant in EffectSchema.section(section):
			assert_string_contains(doc, "`%s`" % entry, "%s: %s" % [section, entry])
	var queries: Array = EffectSchema.data()["queries"]
	for query: Variant in queries:
		assert_string_contains(doc, "`%s`" % query, "query %s" % query)
