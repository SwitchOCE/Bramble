extends SceneTree
## Source oracles for Supply triples and the Quartermaster's legal Recruit targets.

const SUPPLY: StringName = &"supply:pigeon_sentry"


func _initialize() -> void:
	var content: GameContent = GameContent.load_default()
	var out: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			out = arg.substr(4)
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null or not content.errors.is_empty():
		printerr("rework_recruit_vectors: expected a writable out= path and valid content")
		quit(1)
		return
	file.store_line(
		JSON.stringify({"supply": _supply(content), "quartermaster": _quartermaster(content)})
	)
	file.close()
	quit(0)


func _supply(content: GameContent) -> Dictionary:
	var game: GameSession = content.new_session(42)
	game.start_round()
	var player: PlayerState = game.player(0)
	var card: UnitDef = game.library.get_card(&"sentry")
	for left: int in [2, 0]:
		var copy: Unit = game.new_unit(card, false)
		copy.counters[SUPPLY] = left
		player.hand.append(copy)
	player.gold = 20
	player.shop_units[0] = &"sentry"
	var bought: String = game.act(0, {"type": "buy", "index": 0, "spell": false, "target": -1})
	var golden: Unit = player.hand[0]
	var snapshot: Dictionary = FightSnapshot.unit(golden)
	game.end_turn(0)
	game.start_round()
	var played: String = game.act(0, {"type": "play", "hand": 0, "slot": 0})
	game.end_turn(0)
	var events: Array = game.events.filter(
		func(e: Dictionary) -> bool: return e["type"] == "renown"
	)
	return {
		"buy": bought,
		"play": played,
		"triple": snapshot,
		"spent": golden.counter(SUPPLY),
		"events": events,
		"hash": RecordState.state_hash(game),
	}


func _quartermaster(content: GameContent) -> Dictionary:
	var game: GameSession = content.new_session(42)
	game.start_round()
	var player: PlayerState = game.player(0)
	for id: StringName in [&"territorial", &"sentry", &"brock-cub"]:
		player.hand.append(game.new_unit(game.library.get_card(id), false))
	player.gold = 20
	player.shop_units[0] = &"quartermaster"
	var before: Array = LegalActions.of(game, player).filter(
		func(a: Dictionary) -> bool:
			return a["type"] == "buy" and a.get("index") == 0 and not a["spell"]
	)
	var bought: String = game.act(0, {"type": "buy", "index": 0, "spell": false})
	var after: Array = LegalActions.of(game, player)
	var source: Unit = player.recruit_choices[0]
	var refusal: String = game.act(0, {"type": "recruit_target", "target": source.uid})
	game.end_turn(0)
	var snapshots: Array = []
	for unit: Unit in player.hand:
		snapshots.append(FightSnapshot.unit(unit))
	return {
		"buy": bought,
		"before": before,
		"after": after,
		"self_refusal": refusal,
		"hand": snapshots,
		"hash": RecordState.state_hash(game),
	}
