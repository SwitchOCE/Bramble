extends RefCounted
## Every animation treatment the comparison fight can play, by the name a scenario gives
## ("treatment": "today"). To add one: a script extending fight_treatment.gd, and one line here.

const ALL: Dictionary = {
	"today": preload("res://tests/screens/feel/fight_compare/fight_treatment.gd"),
	"best": preload("res://tests/screens/feel/fight_compare/best.gd"),
	"pilot": preload("res://tests/screens/feel/fight_compare/pilot.gd"),
}


## A new treatment by name, or null for a name not listed.
static func make(treatment_name: String) -> RefCounted:
	if not ALL.has(treatment_name):
		return null
	var script: GDScript = ALL[treatment_name]
	return script.new()
