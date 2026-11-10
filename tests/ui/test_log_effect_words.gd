extends GutTest
## The combat log names what fired in the card's own words, and only the ability that fired:
## every trigger id in the rules core is run against every card that has it, plain and golden.

const CombatLog := preload("res://src/ui/screens/combat_log.gd")

## Trigger ids whose card has no rules sentence for them: the log says the ability went off,
## which is vague but true. Each needs a reason.
const NO_SENTENCE: Dictionary[String, String] = {
	"back_strike": "Ballooning Spider's rule has no trigger sentence",
	"bridge_toad": "Mire's target choice; the Mire line follows",
	"bufo": "Madame Bufo's aura has no trigger sentence",
	"bystander": "Fox Notary's rule has no trigger sentence",
	"elder_ooze": "Elder Ooze's rule has no trigger sentence",
	"larder_stats": "the Treasurer's rule has no trigger sentence",
	"nightshade_on_hit": "Bitter Toad's rule has no trigger sentence",
	"skip_across": "the Scarecrow's rule has no trigger sentence",
}


## Every literal `trigger(unit, "id")` in src/core, plus the ids held in constants.
func _trigger_ids() -> PackedStringArray:
	var ids: PackedStringArray = ["syllabub", "beadle", "reel_mistress"]
	var pattern := RegEx.new()
	pattern.compile('trigger\\([a-z_]+, "([a-z_]+)"\\)')
	var dirs: PackedStringArray = ["res://src/core"]
	while not dirs.is_empty():
		var dir_path: String = dirs[dirs.size() - 1]
		dirs.remove_at(dirs.size() - 1)
		for sub: String in DirAccess.get_directories_at(dir_path):
			dirs.append(dir_path.path_join(sub))
		for file: String in DirAccess.get_files_at(dir_path):
			if not file.ends_with(".gd"):
				continue
			var code: String = FileAccess.get_file_as_string(dir_path.path_join(file))
			for found: RegExMatch in pattern.search_all(code):
				if not ids.has(found.get_string(1)):
					ids.append(found.get_string(1))
	return ids


## The cards that carry a mechanic id, as their own mechanic or a data effect's name.
func _cards_with(library: UnitLibrary, id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Dictionary in library.all_units():
		for entry: Variant in card["mechanics"]:
			var mech: Dictionary = entry
			var own: String = str(mech["id"])
			if own == "effect":
				own = str(mech.get("name", mech.get("trigger", "")))
			if own == id and not out.has(card):
				out.append(card)
	return out


func test_every_trigger_id_logs_its_own_card_words() -> void:
	var library: UnitLibrary = TestLibraries.current()
	var ids: PackedStringArray = _trigger_ids()
	assert_gt(ids.size(), 40, "found the core's trigger ids")
	for id: String in ids:
		if CombatLog.NAMED_TRIGGERS.has(id) or CombatLog.TRIGGER_LINES.has(id):
			continue
		for card: Dictionary in _cards_with(library, id):
			var keywords: Array = card["keywords"]
			if not CombatLog.keyword_for(keywords, id).is_empty():
				continue
			for key: String in ["text", "golden_text"]:
				var said: String = CombatLog.effect_words(card, str(card[key]), id)
				if NO_SENTENCE.has(id):
					assert_eq(
						said, "", "%s %s: no sentence, so no borrowed words" % [card["id"], id]
					)
					continue
				assert_false(said.is_empty(), "%s %s %s finds its sentence" % [card["id"], key, id])
				var trigger: String = CombatLog.MECHANIC_TRIGGERS.get(id, "")
				for sentence: String in str(card[key]).split(". ", false):
					if said in sentence and ": " in sentence:
						var before: String = sentence.substr(0, sentence.find(": ")).to_lower()
						assert_true(
							trigger.is_empty() or trigger in before,
							"%s %s logs the %s sentence, not another" % [card["id"], id, trigger]
						)


func test_data_effects_log_the_sentence_of_their_trigger() -> void:
	var library: UnitLibrary = TestLibraries.current()
	for card: Dictionary in library.all_units():
		for entry: Variant in card["mechanics"]:
			var mech: Dictionary = entry
			var on: String = str(mech.get("trigger", ""))
			if str(mech["id"]) != "effect" or not CombatLog.EFFECT_TRIGGERS.has(on):
				continue
			var fired: String = str(mech.get("name", on))
			var said: String = CombatLog.effect_words(card, str(card["text"]), fired)
			assert_false(said.is_empty(), "%s %s finds its sentence" % [card["id"], fired])


func test_hasty_release_and_a_lent_pounce_say_what_really_happened() -> void:
	var library: UnitLibrary = LegacyBog.library()
	var pudding: Dictionary = library.get_unit("hasty_pudding")
	var release: String = CombatLog.trigger_words(pudding, str(pudding["text"]), "hasty_release")
	assert_eq(release, " lets its prisoners go.")
	var swallow: String = CombatLog.effect_words(pudding, str(pudding["text"]), "hasty")
	assert_true(swallow.begins_with("if this has room"), swallow)
	var burdock: Dictionary = library.get_unit("mrs_burdock")
	assert_eq(
		CombatLog.effect_words(burdock, str(burdock["text"]), "pounce"), "", "not its own ability"
	)
	assert_eq(CombatLog.NAMED_TRIGGERS["pounce"], "Pounce")
	var highness: Dictionary = library.get_unit("his_highness")
	assert_eq(
		CombatLog.effect_words(highness, str(highness["text"]), "kiss"), "get a kiss, once a fight"
	)
