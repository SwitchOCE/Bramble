class_name UnitText
extends RefCounted
## Card text for the screens. 7.3.5: card data writes its numbers as {param} placeholders
## ("Gain +{attack}/+{health}"), and the text is filled from the unit's bound parameters, which
## are already doubled on a golden (NUMBER) or kept (THRESHOLD). So one text serves both.


## The card text a unit shows: its card's golden_text on a golden copy when the card has one,
## else its text; either filled from the bound parameters.
static func text_of(card: UnitDef, mechanics: Array[BoundMechanic], golden: bool) -> String:
	var raw: String = card.golden_text if golden and card.golden_text != "" else card.text
	return fill(raw, mechanics)


## `text` with each {name} replaced by the first bound mechanic parameter of that name.
static func fill(text: String, mechanics: Array[BoundMechanic]) -> String:
	if not text.contains("{"):
		return text
	var out: String = text
	for bound: BoundMechanic in mechanics:
		var values: Dictionary = bound.params.to_dict()
		for key: Variant in values:
			out = out.replace("{%s}" % str(key), str(values[key]))
	return out


## [{"mechanic": id, ...parameters}] for the unit's own text, golden numbers applied.
static func effects_view(mechanics: Array[BoundMechanic]) -> Array:
	var out: Array = []
	for bound: BoundMechanic in mechanics:
		var values: Dictionary = bound.params.to_dict()
		if values.is_empty():
			continue
		var entry: Dictionary = {"mechanic": String(bound.id)}
		for key: Variant in values:
			entry[str(key)] = values[key]
		out.append(entry)
	return out


static func counters_view(counters: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in counters:
		out[str(key)] = counters[key]
	return out
