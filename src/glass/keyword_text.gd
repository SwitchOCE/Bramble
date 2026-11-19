class_name KeywordText
extends Control
## Wrapped rules text with real mark rectangles for nested hover hit tests. All card words stay.
## An effect line that starts with a cost ("1: Give ...", an Active) draws the cost as a gold coin
## holding the number, then the colon: a coin mark whose hover says what the cost buys.
## Tuck punctuation's side-bearing against the coloured mark, like adjoining text glyphs.
const PUNCTUATION_INSET: float = 3.0
## The colon after a cost coin sits right against the coin's rim.
const COIN_COLON_GAP: float = 0.0
## A cost at the start of an effect line: its digits, then the colon.
const COST_LEAD: String = "(?m)^(\\d+)(?=:)"

var marks: Array[KeywordMark] = []


## Display text marks effect boundaries explicitly. Sentence punctuation also appears within
## an effect's conditions and explanations, so it must not invent paragraph boundaries.
static func effect_lines(words: String) -> String:
	return words.replace("\r\n", "\n")


static func make(
	words: String,
	table: Dictionary,
	width: float,
	totals: Array[Dictionary] = [],
	exclude: String = ""
) -> KeywordText:
	words = effect_lines(words)
	var node: KeywordText = KeywordText.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var entries: Dictionary = {}
	for value: Variant in table.values():
		if not value is Dictionary:
			continue
		var raw: Dictionary = value
		var entry: Dictionary = CardTerms.shown(raw)
		if not entry.is_empty():
			var key: String = CardTerms.key_of(str(entry["name"]))
			if key != CardTerms.key_of(exclude) and not entries.has(key):
				entries[key] = entry
	var names: Array = entries.keys()
	names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	var patterns: PackedStringArray = PackedStringArray()
	for title: String in names:
		patterns.append(CardTerms._escape(title))
	var regex: RegEx = RegEx.create_from_string(
		(
			"(?i)(?<![A-Za-z])("
			+ "|".join(patterns)
			+ ")(s)?(?![A-Za-z])(?: (\\+?\\d+)| \\((\\d+)\\))?"
		)
	)
	# [{at, end, mark}]: the keyword marks and cost coins, in text order
	var spans: Array[Dictionary] = []
	if not entries.is_empty():
		for hit: RegExMatch in regex.search_all(words):
			var entry: Dictionary = entries[hit.get_string(1).to_lower()]
			var number: String = hit.get_string(3) + hit.get_string(4)
			var reminder: String = str(entry["reminder"])
			var end: int = hit.get_end()
			# A suffix is a keyword count only for a numbered keyword, never the first half
			# of a stat pair or an Attack/Health amount belonging to the following prose.
			if number != "" and not _own_number(entry, words.substr(end)):
				number = ""
				end = hit.get_end(2) if hit.get_string(2) != "" else hit.get_end(1)
			if number != "":
				reminder = CardTerms.fill(reminder, number.trim_prefix("+"))
			elif CardTerms.has_n(reminder):
				var before: String = CardTerms.number_before(words, hit.get_string(1))
				reminder = (
					CardTerms.fill(reminder, before) if before != "" else CardTerms.general(entry)
				)
			var said: String = words.substr(hit.get_start(), end - hit.get_start())
			# An owned numbered term uses its current total, including granted amounts.
			if number != "":
				for total: Dictionary in totals:
					if CardTerms.key_of(str(total["words"])) == CardTerms.key_of(said):
						said = str(total["words"])
						reminder = str(total["reminder"])
			var mark: KeywordMark = (
				KeywordMark
				. make(
					{
						"name": entry["name"],
						"words": said,
						"reminder": reminder,
					}
				)
			)
			spans.append({"at": hit.get_start(), "end": end, "mark": mark})
	for hit: RegExMatch in RegEx.create_from_string(COST_LEAD).search_all(words):
		var cost: String = hit.get_string(1)
		var coin: KeywordMark = (
			KeywordMark
			. make(
				{
					"name": CardTerms.ACTIVE_NAME,
					"words": cost,
					"reminder": CardTerms.active_reminder(table, cost),
					"coin": true,
				},
				false,
				KeywordStyle.COIN_SIDE
			)
		)
		spans.append({"at": hit.get_start(), "end": hit.get_end(), "mark": coin})
	spans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])
	var cursor: int = 0
	var parts: Array[Control] = []
	for span: Dictionary in spans:
		node._plain(parts, words.substr(cursor, GlassPieces.as_int(span["at"]) - cursor))
		var mark: KeywordMark = span["mark"]
		parts.append(mark)
		node.marks.append(mark)
		cursor = GlassPieces.as_int(span["end"])
	node._plain(parts, words.substr(cursor))
	var at: Vector2 = Vector2.ZERO
	for index: int in parts.size():
		var part: Control = parts[index]
		if part is GlassText and (part as GlassText).words == "\n":
			at = Vector2(0, at.y + KeywordStyle.LINE_H)
			part.position = at
			part.size = Vector2.ZERO
			node.add_child(part)
			continue
		var attached: bool = index > 0 and parts[index - 1] is KeywordMark and _punctuation(part)
		var needed: float = part.size.x
		if part is KeywordMark and index + 1 < parts.size() and _punctuation(parts[index + 1]):
			needed += parts[index + 1].size.x - PUNCTUATION_INSET
		if not attached and at.x > 0.0 and at.x + needed > width:
			at = Vector2(0, at.y + KeywordStyle.LINE_H)
		if attached:
			at.x += COIN_COLON_GAP if (parts[index - 1] as KeywordMark).coin else -PUNCTUATION_INSET
		part.position = at + Vector2(0, (KeywordStyle.LINE_H - part.size.y) / 2.0)
		node.add_child(part)
		at.x += part.size.x
	node.size = Vector2(width, at.y + KeywordStyle.LINE_H if not parts.is_empty() else 0.0)
	return node


static func _punctuation(part: Control) -> bool:
	return (
		part is GlassText
		and RegEx.create_from_string("^[.,:;!?)}\\]]").search((part as GlassText).words) != null
	)


static func _own_number(entry: Dictionary, following: String) -> bool:
	if not CardTerms.has_n(str(entry["name"]) + " " + str(entry["reminder"])):
		return false
	var stat: RegEx = RegEx.create_from_string("(?i)^\\s*(?:/|Attack\\b|Health\\b)")
	return stat.search(following) == null


func _plain(parts: Array[Control], words: String) -> void:
	var regex: RegEx = RegEx.create_from_string("\n|[ \t\r]+|[^\\s]+")
	for hit: RegExMatch in regex.search_all(words):
		var label: GlassText = GlassText.from_rule("stage", "#tip .r", hit.get_string())
		label.font_px = KeywordStyle.BODY_PX
		label.colour = KeywordStyle.WORD
		label.refresh()
		parts.append(label)
