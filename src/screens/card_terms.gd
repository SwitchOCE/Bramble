class_name CardTerms
extends RefCounted
## What a card's keywords are and what its words mean, from the card entry and the state's display
## table (docs/ideation-track-2/SCREEN-CONTRACT.md). The screens draw these; nothing here is a rule.
## Every term is looked up by its id: display names repeat ("Hopper" is five ids), so a name is
## never a key.
##   pills: the card's printed keywords with their numbers ("Thorns 4", "Fury 1"),
##     then its shown counters ("Medal 2"). A keyword with no number comes from `keywords`; one
##     with a number is a mechanic the card has (`mechanics`) whose display name starts a sentence
##     of its text, the number read from the text, so a golden's doubled number shows. Where the
##     card's `amounts` give a mechanic's summed number (a Fury given on top of its own), that
##     number is shown, and a mechanic given to a card that does not print it gets a pill too.
##   reminders: one "Name: reminder" line for every term the card uses: its pills, the rest of its
##     own mechanics, every shown display name its text mentions ("Medal", "Cousin", "Hit"), the
##     flow's own lines (`reminders`: card data reminders, a token's stats), then every name those
##     reminders mention ("Outnumbered" in Fury's). A number the card prints fills the reminder's N;
##     with no number, the rule is said in general, with no letter N.
## Card fields read: text, keywords [id], counters [{id, value}], mechanics [id] (optional),
## amounts {id: number} (optional), reminders [String] (optional).

## How many pills a card shows; with more, the last place says how many more ("+2").
const MAX_PILLS: int = 3
## The shared display entry for an Active, an effect bought with gold ("1: Give ..."). It is
## hidden: no card prints its name; the cost shows as a gold coin, and its reminder is the coin's.
const ACTIVE: String = "active"
## The coin mark's name inside the screens, never drawn.
const ACTIVE_NAME: String = "Active"


## A card's shown number for each mechanic, from the core's unit view `totals` ({mechanic:
## {param: n}}, printed, given and granted together: Fury 1 printed + 1 given = 2): {id: n} for
## each mechanic with one number. One with two (an Active's cost and amount) is left out.
static func amounts(totals: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for mechanic: Variant in totals:
		var params: Dictionary = totals[mechanic] if totals[mechanic] is Dictionary else {}
		var numbers: Array = params.values().filter(
			func(v: Variant) -> bool: return v is int or v is float
		)
		if numbers.size() == 1:
			out[str(mechanic)] = GlassPieces.as_int(numbers[0])
	return out


## A unit's shown terms from the core's unit view, the one reading for the shop, hand, board and
## fight alike: {mechanics: [id], amounts: {id: n}}. `printed`: the mechanic ids its card prints;
## the view adds what it was given since (`effects`, its own mechanics with numbers), what an aura
## grants (`grants`) and every mechanic in its `totals`, whose numbers are the amounts.
static func unit_terms(printed: Array, view: Dictionary) -> Dictionary:
	var mechanics: Array = printed.duplicate()
	for key: String in ["effects", "grants"]:
		var listed: Variant = view.get(key, [])
		for value: Variant in listed if listed is Array else []:
			var given: Dictionary = value if value is Dictionary else {}
			var mechanic: String = str(given.get("mechanic", ""))
			if mechanic != "" and not mechanics.has(mechanic):
				mechanics.append(mechanic)
	var totals: Dictionary = view.get("totals", {}) if view.get("totals") is Dictionary else {}
	var numbers: Dictionary = amounts(totals)
	for mechanic: Variant in numbers:
		if not mechanics.has(str(mechanic)):
			mechanics.append(str(mechanic))
	return {"mechanics": mechanics, "amounts": numbers}


## What an Active's cost buys, for its coin's hover: the shared `active` entry's reminder with N
## filled, or its `reminder_free` for a cost of 0; "" when the table lacks the entry.
static func active_reminder(table: Dictionary, cost: String) -> String:
	var entry: Dictionary = table_entry(ACTIVE, table)
	if cost == "0" and entry.has("reminder_free"):
		return str(entry["reminder_free"])
	return fill(str(entry.get("reminder", "")), cost)


## The pills a card draws, in text order, capped at MAX_PILLS: [{name, words, reminder}].
static func pills(card: Dictionary, table: Dictionary, limit: int = MAX_PILLS) -> Array[Dictionary]:
	var all: Array[Dictionary] = all_pills(card, table)
	limit = clampi(limit, 1, MAX_PILLS)
	if all.size() <= limit:
		return all
	var out: Array[Dictionary] = all.slice(0, limit - 1)
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
					"id": str(value),
					"name": words,
					"words": words,
					"reminder": reminder_for(entry, str(found.get("number", ""))),
					"at": GlassPieces.as_int(found.get("at", 1 << 20)),
				}
			)
		)
	var given: Dictionary = card.get("amounts", {}) if card.get("amounts") is Dictionary else {}
	for value: Variant in card.get("mechanics", []):
		var entry: Dictionary = lookup(str(value), table)
		if entry.is_empty() or seen.has(key_of(str(entry["name"]))):
			continue
		var found: Dictionary = find(text, str(entry["name"]), true, true)
		var total: String = ""
		if given.has(str(value)):
			total = GlassScreen.number_words(given[str(value)])
		if found.is_empty():
			# given, not printed (a Fury from a Master-at-Arms): a pill from its summed number, for
			# a numbered term (its reminder has an N) the text does not name at all
			if (
				total == ""
				or not has_n(str(entry["reminder"]))
				or mentions(text, str(entry["name"]))
			):
				continue
			found = {"words": named(str(entry["name"]), total), "number": total, "at": 1 << 19}
		elif total != "" and str(found["number"]) != "" and total != str(found["number"]):
			# its own number and what it was given since, together
			found["words"] = named(str(entry["name"]), total)
			found["number"] = total
		seen[key_of(str(found["words"]))] = true
		(
			marks
			. append(
				{
					"id": str(value),
					"name": found["words"],
					"words": found["words"],
					"reminder": reminder_for(entry, str(found["number"])),
					"at": GlassPieces.as_int(found["at"]),
				}
			)
		)
	marks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])
	var out: Array[Dictionary] = []
	var spent: Array = card.get("spent", []) if card.get("spent") is Array else []
	var ids: Dictionary = {}
	for mark: Dictionary in marks:
		mark.erase("at")
		# used up this fight (a Root that has returned it, a Molt with no charge left): dimmed
		mark["spent"] = spent.has(mark["id"])
		ids[mark["id"]] = true
		out.append(mark)
	for value: Variant in card.get("counters", []):
		if value is Dictionary:
			var chip: Dictionary = value
			# one pill per keyword: a keyword's uses left are its own pill's, not a second one
			if ids.has(str(chip.get("id", ""))):
				continue
			var drawn: Dictionary = counter(chip, table)
			if not drawn.is_empty():
				drawn["id"] = str(chip.get("id", ""))
				drawn["spent"] = false
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
		var entry: Dictionary = lookup(str(value), table)
		if not entry.is_empty():
			var found: Dictionary = find(text, str(entry["name"]), false, false)
			_add_term(lines, have, entry, found, text)
	var entries: Array[Dictionary] = shown_entries(table)
	for entry: Dictionary in entries:
		var found: Dictionary = find(text, str(entry["name"]), false, true)
		if not found.is_empty():
			_add_term(lines, have, entry, found, text)
	for value: Variant in card.get("reminders", []):
		var line: String = str(value)
		var colon: int = line.find(": ")
		if colon > 0:
			var title: String = line.substr(0, colon)
			var words: String = line.substr(colon + 2)
			# "Thorns N: ..." on a card that says "+2 Thorns": the card's own number
			var number: String = number_before(text, key_of(title))
			if number != "" and has_n(title + words):
				title = fill(title, number)
				words = fill(words, number)
			elif has_n(title + words):
				# no number: the term's written general rule, or no line
				words = general(find_entry(title, table))
				title = general_name(title)
			_add(lines, have, title, words)
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
	lines: PackedStringArray,
	have: Dictionary,
	entry: Dictionary,
	found: Dictionary,
	text: String = ""
) -> void:
	var number: String = str(found.get("number", ""))
	var title: String = str(found.get("words", entry["name"]))
	if number == "" and text != "":
		# "+2 Fury": the number before the name
		number = number_before(text, key_of(str(entry["name"])))
		if number != "":
			title = fill(str(entry["name"]), number)
			if not has_n(str(entry["name"])):
				title = "%s %s" % [entry["name"], number]
	var reminder: String = str(entry["reminder"])
	if number != "":
		reminder = fill(reminder, number)
	elif has_n(reminder):
		# no number: the term's written general rule (display `reminder_general`), or no line
		reminder = general(entry)
		title = general_name(title)
	_add(lines, have, title, reminder)


## A pill's reminder: its N filled from the card's number, or with no number the term's general
## rule where it has one ("Pile on." with no count), so a pill never shows a bare letter N.
static func reminder_for(entry: Dictionary, number: String) -> String:
	var reminder: String = str(entry["reminder"])
	if number == "" and has_n(reminder) and general(entry) != "":
		return general(entry)
	return fill(reminder, number)


## A term's rule said in general, for a card that names it with no number ("Your units' Fury is
## doubled"): its display entry's written `reminder_general`, "" (no line) when it has none.
static func general(entry: Dictionary) -> String:
	return str(entry.get("reminder_general", ""))


## The shown display entry whose name is this title's term ("Fury 2" finds Fury), {} for none.
static func find_entry(title: String, table: Dictionary) -> Dictionary:
	for key: Variant in table:
		var raw: Variant = table[key]
		if raw is Dictionary:
			var held: Dictionary = raw
			var entry: Dictionary = shown(held)
			if not entry.is_empty() and key_of(str(entry["name"])) == key_of(title):
				return entry
	return {}


## A display name with its N dropped ("Tide +N" reads "Tide").
static func general_name(title: String) -> String:
	if not has_n(title):
		return title
	var regex: RegEx = RegEx.create_from_string("\\s*(\\(\\s*N\\s*\\)|\\+?N)(?![A-Za-z])")
	return regex.sub(title, "", true).strip_edges()


## A display name with a number: its N filled ("Tide +2"), or the number after it ("Fury 2").
static func named(display: String, number: String) -> String:
	return fill(display, number) if has_n(display) else "%s %s" % [display, number]


## The number written just before a name in a card's text ("+2 Fury" gives "2"), or "".
static func number_before(text: String, name_key: String) -> String:
	if name_key == "":
		return ""
	var regex: RegEx = RegEx.create_from_string("(?i)\\+?(\\d+) %s(?![A-Za-z])" % _escape(name_key))
	var hit: RegExMatch = regex.search(text)
	return hit.get_string(1) if hit != null else ""


static func _add(lines: PackedStringArray, have: Dictionary, title: String, words: String) -> void:
	var key: String = key_of(title)
	if words == "" or title == "" or have.has(key):
		return
	have[key] = true
	lines.append("%s: %s" % [title, words])


## A counter {id, value} as a pill: {name, words ("Name value"), reminder}, or empty when the
## table hides or lacks its id.
static func counter(value: Dictionary, table: Dictionary) -> Dictionary:
	var entry: Dictionary = lookup(str(value.get("id", "")), table)
	if entry.is_empty():
		return {}
	var words: String = (
		("%s %s" % [entry["name"], GlassScreen.number_words(value.get("value", ""))]).strip_edges()
	)
	return {"name": entry["name"], "words": words, "reminder": entry["reminder"]}


## An id's display entry {name, reminder}; empty when hidden or missing.
static func lookup(word: String, table: Dictionary) -> Dictionary:
	if word == "":
		return {}
	return shown(table_entry(word, table))


static func table_entry(word: String, table: Dictionary) -> Dictionary:
	var direct: Variant = table.get(word)
	return direct if direct is Dictionary else {}


static func shown(entry: Dictionary) -> Dictionary:
	var name_words: String = str(entry.get("name", ""))
	if name_words == "" or GlassPieces.as_bool(entry.get("hidden", false)):
		return {}
	var out: Dictionary = {"name": name_words, "reminder": str(entry.get("reminder", ""))}
	if entry.has("reminder_general"):
		out["reminder_general"] = str(entry["reminder_general"])
	return out


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
	var before: String = "(?:^|(?<=[.:!?]\\s))" if lead else "(?<![A-Za-z])"
	var after: String = "s?(?![A-Za-z])" if plural else "(?![A-Za-z])"
	var regex: RegEx = RegEx.create_from_string(before + "(" + body + ")" + after)
	var hit: RegExMatch = regex.search(text)
	if hit == null:
		return {}
	var words: String = hit.get_string(1)
	var number: String = hit.get_string(2)
	# The number in "Guard post +2/+4" or "Fury +1 Attack" belongs to the following
	# stats, not the keyword. Keep that prose out of the mark and its reminder value.
	var stat: RegEx = RegEx.create_from_string("(?i)^\\s*(?:/|Attack\\b|Health\\b)")
	if not numbered and number != "" and stat.search(text.substr(hit.get_end(1))) != null:
		number = ""
	if not numbered and number == "":
		words = display
	return {"words": words, "number": number.trim_prefix("+"), "at": hit.get_start()}


## Whether words mention a display name as a whole word, any case ("outnumbered").
static func mentions(words: String, display: String) -> bool:
	var body: String = _pattern(display).replace("(\\d+)", "(?:\\d+|N)")
	# "Squires" names Squire
	var regex: RegEx = RegEx.create_from_string("(?i)(?<![A-Za-z])" + body + "s?(?![A-Za-z])")
	return regex.search(words) != null


## A reminder with its N filled by the number the card prints ("deal N damage" -> "deal 4").
static func fill(reminder: String, number: String) -> String:
	if number == "":
		return reminder
	var regex: RegEx = RegEx.create_from_string("(?<![A-Za-z])N(?![A-Za-z])")
	return regex.sub(reminder, number, true)


## A name's key for "same term": its number or N dropped, any case ("Tide +2" = "Tide +N").
static func key_of(title: String) -> String:
	var regex: RegEx = RegEx.create_from_string("\\s*(\\(\\s*(\\d+|N)\\s*\\)|\\+?(\\d+|N))$")
	return regex.sub(title, "").strip_edges().to_lower()


static func has_n(words: String) -> bool:
	return RegEx.create_from_string("(?<![A-Za-z])N(?![A-Za-z])").search(words) != null


## A display name as a pattern: special characters escaped, a lone N a number.
static func _escape(words: String) -> String:
	var out: String = ""
	for ch: String in words:
		out += ("\\" + ch) if "\\^$.|?*+()[]{}".contains(ch) else ch
	return out


static func _pattern(display: String) -> String:
	var out: String = ""
	for ch: String in display:
		out += ("\\" + ch) if "\\^$.|?*+()[]{}".contains(ch) else ch
	var lone_n: RegEx = RegEx.create_from_string("(?<![A-Za-z])N(?![A-Za-z])")
	return lone_n.sub(out, "(\\d+)", true)
