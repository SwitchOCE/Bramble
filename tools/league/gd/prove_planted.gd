extends SceneTree
## Proves which loaded-card changes the source engine's initial hash can observe.
## -- [out=<absolute JSON fixture path>]


func _initialize() -> void:
	var baseline_content: GameContent = GameContent.load_default()
	var attack_content: GameContent = GameContent.load_default()
	var tier_content: GameContent = GameContent.load_default()
	if not baseline_content.errors.is_empty() or not attack_content.errors.is_empty() or not tier_content.errors.is_empty():
		printerr("planted proof: content did not load cleanly")
		quit(1)
		return
	var baseline_card: UnitDef = baseline_content.library.pool_cards(false)[0]
	var attack_card: UnitDef = attack_content.library.pool_cards(false)[0]
	var tier_card: UnitDef = tier_content.library.pool_cards(false)[0]
	attack_card.attack += 1
	tier_card.tier += 1
	var baseline: GameSession = baseline_content.new_session(42)
	var attack: GameSession = attack_content.new_session(42)
	var tier: GameSession = tier_content.new_session(42)
	var initial_hash: String = RecordState.state_hash(baseline)
	var attack_initial_hash: String = RecordState.state_hash(attack)
	var tier_initial_hash: String = RecordState.state_hash(tier)
	_put_first_unit(baseline, baseline_card)
	_put_first_unit(attack, attack_card)
	var result: Dictionary = {
		"card": String(baseline_card.id),
		"initial_hash": initial_hash,
		"attack_initial_hash": attack_initial_hash,
		"tier_initial_hash": tier_initial_hash,
		"unit_hash": RecordState.state_hash(baseline),
		"attack_unit_hash": RecordState.state_hash(attack),
	}
	var text: String = JSON.stringify(result)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			var file := FileAccess.open(arg.substr(4), FileAccess.WRITE)
			if file == null:
				printerr("planted proof: could not open ", arg.substr(4))
				quit(1)
				return
			file.store_string(text)
			file.close()
	print(text)
	var passed: bool = (
		initial_hash == attack_initial_hash
		and initial_hash != tier_initial_hash
		and str(result["unit_hash"]) != str(result["attack_unit_hash"])
	)
	quit(0 if passed else 1)


func _put_first_unit(game: GameSession, card: UnitDef) -> void:
	var unit: Unit = game.new_unit(card, false)
	unit.slot = 0
	game.player(0).board[0] = unit
