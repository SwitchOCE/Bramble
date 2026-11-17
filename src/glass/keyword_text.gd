class_name KeywordText
extends Control
## Wrapped rules text with real mark rectangles for nested hover hit tests. All card words stay.
var marks: Array[KeywordMark] = []


static func make(
	words: String,
	table: Dictionary,
	width: float,
	totals: Array[Dictionary] = [],
	exclude: String = ""
) -> KeywordText:
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
	var cursor: int = 0
	var parts: Array[Control] = []
	if not entries.is_empty():
		for hit: RegExMatch in regex.search_all(words):
			node._plain(parts, words.substr(cursor, hit.get_start() - cursor))
			var entry: Dictionary = entries[hit.get_string(1).to_lower()]
			var number: String = hit.get_string(3) + hit.get_string(4)
			var reminder: String = str(entry["reminder"])
			if number != "":
				reminder = CardTerms.fill(reminder, number.trim_prefix("+"))
			elif CardTerms.has_n(reminder):
				var before: String = CardTerms.number_before(words, hit.get_string(1))
				reminder = (
					CardTerms.fill(reminder, before) if before != "" else CardTerms.general(entry)
				)
			var said: String = hit.get_string()
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
			parts.append(mark)
			node.marks.append(mark)
			cursor = hit.get_end()
	node._plain(parts, words.substr(cursor))
	var at: Vector2 = Vector2.ZERO
	for part: Control in parts:
		if at.x > 0.0 and at.x + part.size.x > width:
			at = Vector2(0, at.y + KeywordStyle.LINE_H)
		part.position = at + Vector2(0, (KeywordStyle.LINE_H - part.size.y) / 2.0)
		node.add_child(part)
		at.x += part.size.x
	node.size = Vector2(width, at.y + KeywordStyle.LINE_H if not parts.is_empty() else 0.0)
	return node


func _plain(parts: Array[Control], words: String) -> void:
	var regex: RegEx = RegEx.create_from_string("\\s+|[^\\s]+")
	for hit: RegExMatch in regex.search_all(words):
		var label: GlassText = GlassText.from_rule("stage", "#tip .r", hit.get_string())
		label.font_px = KeywordStyle.BODY_PX
		label.colour = KeywordStyle.WORD
		label.refresh()
		parts.append(label)
