extends RefCounted
## What a keyword means, in the player's words. The game's list comes from the schema
## (content/schema/effects.json); the older library's keywords are worded here, because a raw
## source.note in a unit file is a designer's note and never goes on screen.

const TRIBE_BONUS_TEXT: String = (
	"The tribe icon records the bonus. It also reaches your hand, units inside Bellies, "
	+ "units away and later arrivals. A unit with two tribes gets both bonuses, "
	+ "and Supper raises both. Becoming golden does not double the bonus."
)

const HELP_WORDS: Dictionary[String, String] = {
	"Behind":
	(
		"B1 is behind F1 and F2; B2 behind F2 and F3; B3 behind F3 and F4. "
		+ "So F2 has both B1 and B2 behind it."
	),
	"Beside":
	(
		"The slots immediately left and right in the same row. F2 has F1 and F3 beside it. "
		+ "A gap stays a gap."
	),
	"Touching":
	(
		"An unbroken run of units along F1-B1-F2-B2-F3-B3-F4, including this unit. "
		+ "An empty slot breaks the run; units in the same row do not touch directly."
	),
	"Bell":
	(
		"The opening of a fight, when Mire patches and Quarry marks are set. This happens "
		+ "after “first of all” text and before the other Start of Combat effects."
	),
	"Cycle":
	(
		"One pass through a side's attack order, F1 to F4 then B1 to B3. "
		+ "Its next cycle starts when no eligible unit has an unused attack. "
		+ "Each side counts its own cycles."
	),
	"*":
	(
		"A golden unit, usually made by combining three ordinary copies. "
		+ "Its stronger stats and text are already shown."
	),
}

const LIBRARY_WORDS: Dictionary[String, String] = {
	"Peck": "Its attack strikes the target several times, its Attack split between the strikes.",
	"Quick": "Deals its damage first. If that kills, it takes none.",
	"First Bite": "Quick in this unit's first exchange each fight.",
	"Mark": "Start of Combat: marks the enemy slot across. Units that enter it later take damage.",
	"Bystander": "When an enemy attacks one of your other units, this gains +1/+1 for this fight.",
	"Shell": "The first time this takes damage in a fight, that damage is capped.",
	"Bide": "Skips its attacks and grows each time its side's order passes it, until it is hurt.",
	"Both Ends": "With a partner at both ends of a row, each gets stronger and guards the other.",
	"Whistle": "Never attacks. It warns the strongest enemy, whose next attack does half damage.",
	"Pin": "An enemy this hurts skips its next attack.",
	"Fast": "End of Turn: with no paid refresh this turn, the count goes up, else back to 0.",
	"Swarm": "When a Swarm unit attacks, the others in its row join in on the same target.",
}


## "" for a word that isn't a keyword.
static func text(keyword: String) -> String:
	if HELP_WORDS.has(keyword):
		return HELP_WORDS[keyword]
	var game_words: Dictionary = EffectSchema.section("keywords")
	if game_words.has(keyword):
		return str(game_words[keyword])
	return LIBRARY_WORDS.get(keyword, "")


## Every keyword on this card that has a reminder: the ones it lists, then any its rules name, so a
## spell or a "gives" card explains what it hands out. In order, without repeats.
static func named_on(card: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for value: Variant in card.get("keywords", []):
		_note(out, str(value))
	var entries: Array = card.get("keyword_text", [])
	for value: Variant in entries:
		var entry: Dictionary = value
		_note(out, str(entry.get("keyword", "")))
	var rules: String = str(card.get("text", ""))
	var words: Array = EffectSchema.section("keywords").keys()
	words.append_array(LIBRARY_WORDS.keys())
	words.append_array(HELP_WORDS.keys())
	for value: Variant in words:
		var word: String = str(value)
		if word == "*":
			if rules.contains("*") or card.get("golden", false):
				_note(out, word)
		elif RegEx.create_from_string("(?i)\\b%ss?\\b" % word).search(rules) != null:
			_note(out, word)
	# A keyword's reminder can introduce another term, such as Pack's cycle or Pass's touching.
	for word: String in out.duplicate():
		var reminder: String = text(word).to_lower()
		for help: String in HELP_WORDS:
			if (
				help != "*"
				and (
					RegEx.create_from_string("\\b%ss?\\b" % help.to_lower()).search(reminder)
					!= null
				)
			):
				_note(out, help)
	return out


static func _note(into: PackedStringArray, keyword: String) -> void:
	if not into.has(keyword) and not text(keyword).is_empty():
		into.append(keyword)
