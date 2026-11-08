extends RefCounted
## What a keyword means, in the player's words. The game's list comes from the schema
## (content/schema/effects.json); the older library's keywords are worded here, because a raw
## source.note in a unit file is a designer's note and never goes on screen.

const TRIBE_BONUS_TEXT: String = "The tribe icon shows the bonus."

const HELP_WORDS: Dictionary[String, String] = {
	"Behind": "Each back slot is behind two front slots: B1 behind F1 and F2.",
	"Beside": "The slots left and right in the same row.",
	"Touching": "An unbroken run of units along F1-B1-F2-B2-F3-B3-F4.",
	"Bell": "The start of a fight, before other Start of Combat effects.",
	"Cycle": "One pass through a side's attack order.",
	"*": "Golden: made from three copies, with stronger stats and text.",
}

const LIBRARY_WORDS: Dictionary[String, String] = {
	"Peck": "Its Attack is split across several strikes on the target.",
	"Quick": "Deals its damage first. If that kills, it takes none.",
	"First Bite": "Quick in this unit's first exchange each fight.",
	"Mark": "Start of Combat: marks the enemy slot across; units entering it take damage.",
	"Bystander": "When an enemy attacks another of your units, this gains +1/+1.",
	"Shell": "The first damage this takes each fight is capped.",
	"Bide": "Skips its attacks and grows each time it skips, until hurt.",
	"Both Ends": "Partners at both ends of a row grow and guard each other.",
	"Whistle": "Never attacks. The strongest enemy's next attack does half damage.",
	"Pin": "An enemy this hurts skips its next attack.",
	"Fast": "End of Turn: counts up if you didn't pay to refresh, else resets.",
	"Swarm": "When a Swarm unit attacks, others in its row join in.",
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
		for help: String in terms_in(text(word)):
			_note(out, help)
	return out


## The help terms (Behind, Touching, Cycle...) a reminder uses, so they can be explained with it.
static func terms_in(reminder: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var lower: String = reminder.to_lower()
	for help: String in HELP_WORDS:
		if help == "*":
			continue
		if RegEx.create_from_string("\\b%ss?\\b" % help.to_lower()).search(lower) != null:
			out.append(help)
	return out


static func _note(into: PackedStringArray, keyword: String) -> void:
	if not into.has(keyword) and not text(keyword).is_empty():
		into.append(keyword)
