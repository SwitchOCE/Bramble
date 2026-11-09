extends RefCounted
## What a keyword means, in the player's words. The game's list comes from the schema
## (content/schema/effects.json); the older library's keywords are worded here, because a raw
## source.note in a unit file is a designer's note and never goes on screen.

const TRIBE_BONUS_TEXT: String = "The tribe icon shows the bonus."

const HELP_WORDS: Dictionary[String, String] = {
	"Behind": "Each back slot is behind the two front slots it sits between.",
	"Beside": "The slots left and right in the same row.",
	"Touching":
	"An unbroken chain of units, left to right through both rows. An empty slot breaks it.",
	"Next to": "Beside, in front or behind.",
	"Cycle": "One pass through a side's attack order.",
	"Early Spoils":
	"Rounds 1-4: win a fight and get 1 gold next turn. Ghost wins and ties pay nothing.",
	"Ask for Kin":
	"2 gold, once a turn: refresh with two units sharing your tribes. Nests count as Birds.",
	"Take": "When a unit's quarry dies, that unit makes a Take.",
	"Base": "A card's own stats, without any buffs.",
	"Round base": "Rises each round, up to 13.",
	"Starting survivor": "Your unit that began the fight and survives on your side.",
	"Last Blow": "Both boards fall: the final attack or effect wins.",
	"Last Stand": "Last four: from 2+ Health, survive one lethal hero loss on 1 Health.",
	"*": "Golden: made from three copies, with stronger stats and text.",
}

## Words matched only as written, because the lower-case word is ordinary English ("takes damage").
const EXACT_WORDS: PackedStringArray = ["Take"]
## Keywords a card lists but writes out in plain words, so it gets no link of its own. Bide stays a
## status word in fights ("Waiting"); Fast keeps a reminder for the text tool.
const PLAIN_ON_CARD: PackedStringArray = ["Bide", "Fast"]

const LIBRARY_WORDS: Dictionary[String, String] = {
	"Peck": "Attacks in this many strikes, its Attack split between them.",
	"Quick": "Deals its damage first. If that kills, it takes none.",
	"First Bite": "Quick in this unit's first exchange each fight.",
	"Mark": "Start of Combat: enemies that later enter the slot across take this much damage.",
	"Bystander": "When an enemy attacks another of your units, this gains +1/+1.",
	"Shell": "The first damage this takes each fight is at most this much.",
	"Bide": "Skips its attacks and grows each time it skips, until hurt.",
	"Both Ends":
	"Paired at both ends of a row: gets its bonus, and pricks its partner's attackers first.",
	"Whistle": "Never attacks. On its turn, the strongest enemy's next attack does half damage.",
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
		if not PLAIN_ON_CARD.has(str(value)):
			_note(out, str(value))
	var entries: Array = card.get("keyword_text", [])
	for value: Variant in entries:
		var entry: Dictionary = value
		_note(out, str(entry.get("keyword", "")))
	var rules: String = str(card.get("text", ""))
	# Hunt is the existing Quarry instruction; lenders need the same reader ruling.
	if names(rules, "Hunt"):
		_note(out, "Quarry")
	var words: Array = EffectSchema.section("keywords").keys()
	words.append_array(LIBRARY_WORDS.keys())
	words.append_array(HELP_WORDS.keys())
	for value: Variant in words:
		var word: String = str(value)
		if word == "*":
			if rules.contains("*") or card.get("golden", false):
				_note(out, word)
		elif names(rules, word):
			_note(out, word)
	# A keyword's reminder can introduce another term, such as Pack's cycle.
	for word: String in out.duplicate():
		for help: String in terms_in(text(word)):
			_note(out, help)
	return out


## The help terms (Behind, Touching, Cycle...) a reminder uses, so they can be explained with it.
static func terms_in(reminder: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for help: String in HELP_WORDS:
		if help == "*":
			continue
		if names(reminder, help):
			out.append(help)
	return out


## Whether `said` names `word`: any case, plural allowed; an exact word only as written.
static func names(said: String, word: String) -> bool:
	return RegEx.create_from_string(pattern(word)).search(said) != null


## The regex that finds `word` in rules text, its name in group 1.
static func pattern(word: String) -> String:
	if EXACT_WORDS.has(word):
		return "\\b(%s)()\\b" % word
	return "(?i)\\b(%s)(s?)\\b" % word


static func _note(into: PackedStringArray, keyword: String) -> void:
	if not into.has(keyword) and not text(keyword).is_empty():
		into.append(keyword)
