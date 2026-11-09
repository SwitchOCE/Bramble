extends RefCounted
## Test-only frozen content isolates historical parity fixtures from subsequent content merges.
## The production rules/AI still run; only their content inputs and shared data caches are saved
## and restored. No shipped field library or current-content manifest is involved.

var library: UnitLibrary
var _schema: Dictionary
var _knowledge: BotKnowledge
var _mechanics: Dictionary
var _rates: Dictionary
var _presets: Dictionary
var _default_preset: String


func setup(fixture_path: String = "res://tests/fixtures/field/content-9af89c2.json") -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var files: Dictionary = fixture["files"]
	_schema = EffectSchema._data
	_knowledge = BotKnowledge._shared
	_mechanics = MechanicRegistry._instances
	_rates = Pass3Rates._defaults
	_presets = Pass3Rates._presets
	_default_preset = Pass3Rates._default_preset
	if files.has(Pass3Rates.PATH.trim_prefix("res://")):
		var frozen_rates: Dictionary = files[Pass3Rates.PATH.trim_prefix("res://")]
		var base: Dictionary = frozen_rates.get("rates", frozen_rates)
		var presets: Dictionary = frozen_rates.get("presets", {})
		Pass3Rates._defaults = base.duplicate(true)
		Pass3Rates._presets = presets.duplicate(true)
		Pass3Rates._default_preset = str(frozen_rates.get("default_preset", "B"))
	var frozen_schema: Dictionary = files["content/schema/effects.json"]
	EffectSchema._data = frozen_schema.duplicate(true)
	EffectSchema._resolve_acorn_reminder()
	MechanicRegistry._instances = {}
	var knowledge := BotKnowledge.new()
	var hints: Dictionary = files["content/bots/cards.json"]
	knowledge.cards = hints["cards"]
	knowledge.heroes = hints.get("heroes", {})
	library = UnitLibrary.new()
	for path: String in files:
		var content: Dictionary = files[path]
		if path.begins_with("content/units/"):
			var problem: String = library.register_unit(content)
			assert(problem == "", problem)
		elif path.begins_with("content/spells/"):
			library.register_card(content)
		elif path.begins_with("content/heroes/"):
			library.register_hero(content)
		elif path.begins_with("content/bots/strategies/"):
			knowledge.strategies[str(content["id"])] = content
	BotKnowledge._shared = knowledge
	# load_dir fills keyword reminders on extra cards too.
	UnitLibrary._fill_keyword_text(library.all_cards())
	UnitLibrary._fill_keyword_text(library.all_heroes())


func restore() -> void:
	EffectSchema._data = _schema
	BotKnowledge._shared = _knowledge
	MechanicRegistry._instances = _mechanics
	Pass3Rates._defaults = _rates
	Pass3Rates._presets = _presets
	Pass3Rates._default_preset = _default_preset
