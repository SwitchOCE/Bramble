extends SceneTree

func _initialize() -> void:
	var content: GameContent = GameContent.load_default()
	var game: GameSession = content.new_session(42)
	var player: PlayerState = game.player(0)
	var card: UnitDef = content.library.drawable_cards(false)[0]
	var first: Unit = game.new_unit(card, false)
	var second: Unit = game.new_unit(card, true)
	player.place(first, 0)
	player.place(second, 1)
	var ctx := RecruitContext.new(game, game.recruit, player)
	var states: Array = []
	states.append(RecordState.state_hash(game))
	ctx.buff(first, 3, -2, true, second)
	ctx.buff(second, -1, 4, false, null)
	ctx.gain_gold(7, first)
	ctx.gain_gold(-20, null)
	ctx.add_turn_counter(first, &"badger_proof_turn", 2, second)
	ctx.add_unit_counter(second, &"badger_proof_unit", 3, null)
	ctx._limit = 1
	var triggers: Array = [ctx.trigger(first, &"proof"), ctx.trigger(null, &"proof")]
	var chosen: Unit = ctx.random_of(ctx.select(first, "others"))
	states.append(RecordState.state_hash(game))
	var result: Dictionary = {"hashes": states, "triggers": triggers, "chosen": chosen.uid, "actions_hash": JSON.stringify(LegalActions.of(game, player)).sha256_text(), "view_hash": JSON.stringify(player.view()).sha256_text()}
	print("PROOF=" + JSON.stringify(result))
	quit()
