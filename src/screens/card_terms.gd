class_name CardTerms
extends RefCounted
## What a card's keywords are and what its words mean, from the card entry and the state's display
## table (docs/ideation-track-2/SCREEN-CONTRACT.md). The screens draw these; nothing here is a rule.
##   pills: the card's printed keywords with their numbers ("Thorns 4", "Fury 1", "Order (1)"),
##     then its shown counters ("Medal 2"). A keyword with no number comes from `keywords`; one
##     with a number is a mechanic the card has (`mechanics`) whose display name starts a sentence
##     of its text, the number read from the text, so a golden's doubled number shows.
##   reminders: one "Name: reminder" line for every term the card uses: its pills, the rest of its
##     own mechanics, every shown display name its text mentions ("Medal", "Cousin", "Hit"), the
##     flow's own lines (`reminders`: card data reminders, a token's stats), then every name those
##     reminders mention ("Outnumbered" in Fury's). A number the card prints fills the reminder's N.
## Card fields read: text, keywords [id or display name], counters [{id or key or label, value}],
## mechanics [id] (its own, optional), reminders [String] (optional).

## How many pills a card shows; with more, the last place says how many more ("+2").
const MAX_PILLS: int = 3


## The pills a card draws, in text order, capped at MAX_PILLS: [{name, words, reminder}].
static func pills(card: Dictionary, table: Dictionary) -> Array[Dictionary]:
	var all: Array[Dictionary] = all_pills(card, table)
	if all.size() <= MAX_PILLS:
		return all
	var out: Array[Dictionary] = all.slice(0, MAX_PILLS - 1)
	var more: int = all.size() - out.size()
	out.append({"name": "", "words": "+%d" % more, "reminder": "", "more": true})
	return out


## Every pill a card has, uncapped: [{name, words, reminder}] (name is the words, a counter's name
## without its value).
static func all_pills(card: Dictionary, table: Dictionary) -> Array[Dictionary]:
	var text: String = str(card.get("text", ""))
	var marks: Array[Dictionary] = []
	var seen: Dictionary = {}
	for value: Variant in card.get("keywords", []):
		var entry: Dictionary = lookup(str(value), table)
		if entry.is_empty() or seen.has(key_of(str(entry["name"]))):
			continue
		var found: Dictionary = find(text, str(entry["name"]), true, false)
		# named in the text but not as its own keyword ("summon a Pip"): a reference, no pill
		if found.is_empty() and not find(text, str(entry["name"]), false, true).is_empty():
			continue
		var words: String = str(found.get("words", entry["name"]))
		seen[key_of(words)] = true
		(
			marks
			. append(
				{
					"name": words,
					"words": words,
					"reminder": fill(str(entry["reminder"]), str(found.get("number", ""))),
					"at": GlassPieces.as_int(found.get("at", 1 << 20)),
				}
			)
		)
	for value: Variant in card.get("mechanics", []):
		var entry: Dictionary = lookup(str(value), table, false)
		if entry.is_empty() or seen.has(key_of(str(entry["name"]))):
			continue
		var found: Dictionary = find(text, str(entry["name"]), true, true)
		if found.is_empty():
			continue
		seen[key_of(str(found["words"]))] = true
		(
			marks
			. append(
				{
					"name": found["words"],
					"words": found["words"],
					"reminder": fill(str(entry["reminder"]), str(found["number"])),
					"at": GlassPieces.as_int(found["at"]),
				}
			)
		)
	marks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])
	var out: Array[Dictionary] = []
	for mark: Dictionary in marks:
		mark.erase("at")
		out.append(mark)
	for value: Variant in card.get("counters", []):
		if value is Dictionary:
			var chip: Dictionary = value
			var drawn: Dictionary = counter(chip, table)
			if not drawn.is_empty():
				out.append(drawn)
	return out


## The hover detail's reminder lines for a card: "Name: reminder", each term once.
static func reminders(card: Dictionary, table: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var have: Dictionary = {}
	var text: String = str(card.get("text", ""))
	for mark: Dictionary in all_pills(card, table):
		_add(lines, have, str(mark["name"]), str(mark["reminder"]))
	for value: Variant in card.get("mechanics", []):
		var entry: Dictionary = lookup(str(value), table, false)
		if not entry.is_empty():
			var found: Dictionary = find(text, str(entry["name"]), false, false)
			_add_term(lines, have, entry, found)
	var entries: Array[Dictionary] = shown_entries(table)
	for entry: Dictionary in entries:
		var found: Dictionary = find(text, str(entry["name"]), false, true)
		if not found.is_empty():
			_add_term(lines, have, entry, found)
	for value: Variant in card.get("reminders", []):
		var line: String = str(value)
		var colon: int = line.find(": ")
		if colon > 0:
			_add(lines, have, line.substr(0, colon), line.substr(colon + 2))
		elif line != "" and not have.has(line) and not " ".join(lines).contains(line):
			have[line] = true
			lines.append(line)
	# the names those reminders use ("outnumbered" in Fury's), once over
	var said: String = " ".join(lines)
	for entry: Dictionary in entries:
		if not have.has(key_of(str(entry["name"]))) and mentions(said, str(entry["name"])):
			_add_term(lines, have, entry, {})
	return lines


static func _add_term(
	lines: PackedStringArray, have: Dictionary, entry: Dictionary, found: Dictionary
) -> void:
	var number: String = str(found.get("number", ""))
	var title: String = str(found.get("words", entry["name"]))
	var reminder: String = fill(str(entry["reminder"]), number)
	if number == "" and _has_n(reminder) and not _has_n(title):
		title += " N"
	_add(lines, have, title, reminder)


static func _add(lines: PackedStringArray, have: Dictionary, title: String, words: String) -> void:
	var key: String = key_of(title)
	if words == "" or title == "" or have.has(key):
		return
	have[key] = true
	lines.append("%s: %s" % [title, words])


## A counter {id or key or label, value} as a pill: {name, words ("Name value"), reminder}, or
## empty when hidden.
static func counter(value: Dictionary, table: Dictionary) -> Dictionary:
	var entry: Dictionary
	if value.has("key") or value.has("id"):
		entry = lookup(str(value.get("id", value.get("key", ""))), table)
	else:
		var label: String = str(value.get("label", str(value.get("icon", "")).capitalize()))
		var found: Dictionary = table_entry(label, table)
		entry = shown(found) if not found.is_empty() else {"name": label, "reminder": ""}
		if label == "":
			entry = {}
	if entry.is_empty():
		return {}
	var words: String = (
		("%s %s" % [entry["name"], GlassScreen.number_words(value.get("value", ""))]).strip_edges()
	)
	return {"name": entry["name"], "words": words, "reminder": entry["reminder"]}


## A word's display entry {name, reminder}, by id or by name; empty when hidden or missing. With
## no table, `bare` gives the word itself, an id title-cased.
static func lookup(word: String, table: Dictionary, bare: bool = true) -> Dictionary:
	if word == "":
		return {}
	if table.is_empty():
		return {"name": word.replace("_", " ").capitalize(), "reminder": ""} if bare else {}
	return shown(table_entry(word, table))


static func table_entry(word: String, table: Dictionary) -> Dictionary:
	var direct: Variant = table.get(word)
	if direct is Dictionary:
		return direct
	for key: Variant in table:
		var value: Variant = table[key]
		if value is Dictionary:
			var entry: Dictionary = value
			if str(entry.get("name", "")) == word:
				return entry
	return {}


static func shown(entry: Dictionary) -> Dictionary:
	var name_words: String = str(entry.get("name", ""))
	var hidden: bool = (
		not GlassPieces.as_bool(entry.get("shown", true))
		or GlassPieces.as_bool(entry.get("hidden", false))
	)
	if name_words == "" or hidden:
		return {}
	return {"name": name_words, "reminder": str(entry.get("reminder", ""))}


## The table's shown entries with a reminder, first of each name: [{name, reminder}].
static func shown_entries(table: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var names: Dictionary = {}
	for key: Variant in table:
		var value: Variant = table[key]
		if not value is Dictionary:
			continue
		var raw: Dictionary = value
		var entry: Dictionary = shown(raw)
		if entry.is_empty() or str(entry["reminder"]) == "":
			continue
		var name_key: String = key_of(str(entry["name"]))
		if not names.has(name_key):
			names[name_key] = true
			out.append(entry)
	return out


## Where a display name stands in text: {words ("Thorns 4"), number ("4" or ""), at}, or {}.
## lead: only at the start of a sentence (after a full stop or colon). plural: "Medals" counts.
static func find(text: String, display: String, lead: bool, plural: bool) -> Dictionary:
	if text == "" or display == "":
		return {}
	var body: String = _pattern(display)
	var numbered: bool = body.contains("(\\d+)")
	if not numbered:
		body += "(?: (\\+?\\d+))?"
	var before: String = "(?:^|(?<=[.:!?] ))" if lead else "(?<![A-Za-z])"
	var after: String = "s?(?![A-Za-z])" if plural else "(?![A-Za-z])"
	var regex: RegEx = RegEx.create_from_string(before + "(" + body + ")" + after)
	var hit: RegExMatch = regex.search(text)
	if hit == null:
		return {}
	var words: String = hit.get_string(1)
	var number: String = hit.get_string(2)
	if not numbered and number == "":
		words = display
	return {"words": words, "number": number.trim_prefix("+"), "at": hit.get_start()}


## Whether words mention a display name as a whole word, any case ("outnumbered").
static func mentions(words: String, display: String) -> bool:
	var body: String = _pattern(display).replace("(\\d+)", "(?:\\d+|N)")
	var regex: RegEx = RegEx.create_from_string("(?i)(?<![A-Za-z])" + body + "(?![A-Za-z])")
	return regex.search(words) != null


## A reminder with its N filled by the number the card prints ("deal N damage" -> "deal 4").
static func fill(reminder: String, number: String) -> String:
	if number == "":
		return reminder
	var regex: RegEx = RegEx.create_from_string("(?<![A-Za-z])N(?![A-Za-z])")
	return regex.sub(reminder, number, true)


## A name's key for "same term": its number or N dropped, any case ("Order (1)" = "Order (N)").
static func key_of(title: String) -> String:
	var regex: RegEx = RegEx.create_from_string("\\s*(\\(\\s*(\\d+|N)\\s*\\)|\\+?(\\d+|N))$")
	return regex.sub(title, "").strip_edges().to_lower()


static func _has_n(words: String) -> bool:
	return RegEx.create_from_string("(?<![A-Za-z])N(?![A-Za-z])").search(words) != null


## A display name as a pattern: special characters escaped, a lone N a number.
static func _pattern(display: String) -> String:
	var out: String = ""
	for ch: String in display:
		out += ("\\" + ch) if "\\^$.|?*+()[]{}".contains(ch) else ch
	var lone_n: RegEx = RegEx.create_from_string("(?<![A-Za-z])N(?![A-Za-z])")
	return lone_n.sub(out, "(\\d+)", true)
