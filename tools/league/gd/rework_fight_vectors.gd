extends "res://tools/league/gd/fight_run.gd"
## Reference runner for the small rework vectors, using dev's existing test mechanics.

const RenownOnDeath := preload("res://tests/core/content/test/mechanics/renown_on_death.gd")
const PrivateCall := preload("res://tests/core/content/test/mechanics/private_call.gd")
const Quartermaster := preload("res://tests/core/content/test/mechanics/quartermaster.gd")


func _run(saved: Dictionary) -> Dictionary:
	if not _content.registry.has(&"test_renown_on_death"):
		_content.registry.prefixes.append("test_")
		_content.registry.register(&"test_renown_on_death", RenownOnDeath.new())
		_content.registry.register(&"test_quartermaster", Quartermaster.new())
		_content.registry.register(&"test_private_call", PrivateCall.new())
		var raw: String = FileAccess.get_file_as_string(
			"res://tests/core/content/neutral/units.json"
		)
		var cards: Array = CoreUtil.to_array(CoreUtil.to_dict(JSON.parse_string(raw)).get("cards"))
		for card: Dictionary in cards:
			if card.get("id") == "tk_sprout":
				_content.library.add_cards([card], _content.registry)
				break
	return super._run(saved)
