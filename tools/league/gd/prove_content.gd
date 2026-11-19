extends SceneTree
## Full plain/golden card state and pure mechanic metadata oracle; -- [out=<raw JSON path>].


func _initialize() -> void:
	var content: GameContent = GameContent.load_default()
	if not content.errors.is_empty():
		printerr("content proof: ", content.errors)
		quit(1)
		return
	var game: GameSession = content.new_session(42)
	var states: Array = []
	var metadata: Array = []
	for card_id: StringName in content.library.ids():
		var card: UnitDef = content.library.get_card(card_id)
		for golden: bool in [false, true]:
			var unit: Unit = game.new_unit(card, golden)
			states.append(RecordState.value(unit))
			for bound: BoundMechanic in unit.mechanics:
				var mechanic: Mechanic = bound.mechanic
				metadata.append({
					"unit": unit.uid,
					"id": String(bound.id),
					"golden": golden,
					"param_kinds": mechanic.param_kinds(),
					"has_aura": mechanic.has_aura(),
					"has_ability": mechanic.has_ability(),
					"has_death_effect": mechanic.has_death_effect(),
					"play_target": mechanic.play_target(bound.params),
					"start_of_combat_priority": mechanic.start_of_combat_priority(bound.params),
					"return_priority": mechanic.return_priority(bound.params),
					"return_as_recruit": mechanic.return_as_recruit(bound.params),
				})
	var text: String = JSON.stringify({"units": states, "metadata": metadata})
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			var file := FileAccess.open(arg.substr(4), FileAccess.WRITE)
			if file == null:
				printerr("content proof: could not open ", arg.substr(4))
				quit(1)
				return
			file.store_string(text)
			file.close()
	var summary: Dictionary = {
		"cards": content.library.ids().size(),
		"units": states.size(),
		"bindings": metadata.size(),
		"bytes": text.to_utf8_buffer().size(),
		"sha256": text.sha256_text(),
	}
	print("BRAMBLE_CONTENT_VECTORS=" + JSON.stringify(summary))
	quit(0)
