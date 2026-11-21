extends SceneTree
## Source oracles for Supply triples, Quartermaster targets, the Grenadier Guard post and sales.

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
	var vectors: Dictionary = {
		"supply": _supply(content),
		"tide_on_sell": _tide_on_sell(content),
		"shop_overflow": _shop_overflow(content),
		"quartermaster": _quartermaster(content),
		"grenadier": _grenadier(content),
		"sell_discover_pick": _sale(content, 1, 0, &"", -1),
		"sell_real_triple": _sale(content, 3, 0, &"", 0),
		"sell_token_triple": _sale(content, 0, 3, &"bramble-runner", -1),
		"sell_bought_token_triple": _sale(content, 0, 2, &"pip", -1),
	}
	file.store_line(JSON.stringify(vectors))
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


func _grenadier(content: GameContent) -> Dictionary:
	var game: GameSession = content.new_session(42)
	game.start_round()
	var player: PlayerState = game.player(0)
	player.gold = 20
	var grenadier: Unit = game.new_unit(game.library.get_card(&"grenadier-guard"), false)
	player.hand.append(grenadier)
	var played: String = game.act(0, {"type": "play", "hand": 0, "slot": 0})
	var action: Dictionary = {
		"type": "ability", "uid": grenadier.uid, "mechanic": "pigeon_grenadier", "target": 0,
	}
	var placed: String = game.act(0, action)
	game.end_turn(0)
	game.start_round()
	action["target"] = 3
	var moved: String = game.act(0, action)
	var slots: Array = player.slots.map(func(slot: SlotState) -> Dictionary: return slot.view())
	var events: Array = game.events.filter(
		func(e: Dictionary) -> bool: return e["type"] in ["slot", "renown"]
	)
	return {
		"play": played,
		"place": placed,
		"move": moved,
		"slots": slots,
		"events": events,
		"hash": RecordState.state_hash(game),
	}


func _sale(
	content: GameContent, picks: int, tokens: int, shop_card: StringName, slot: int
) -> Dictionary:
	var game: GameSession = content.new_session(42)
	game.start_round()
	var player: PlayerState = game.player(0)
	player.gold = 20
	for _i: int in picks:
		player.discover_options = [&"crab-apple"]
		var picked: String = game.act(0, {"type": "pick", "index": 0})
		assert(picked == "", picked)
	var ctx := RecruitContext.new(game, game.recruit, player)
	for _i: int in tokens:
		var summoned: Unit = ctx.summon(&"pip", 0)
		assert(summoned != null)
	if shop_card != &"":
		player.shop_units[0] = shop_card
		var bought: String = game.act(0, {"type": "buy", "index": 0, "spell": false, "target": -1})
		assert(bought == "", bought)
	# The unrelated buy settles the summons. It stays in hand ahead of the triple.
	var hand: int = 1 if shop_card == &"bramble-runner" else 0
	var unit: Unit = player.hand[hand]
	var action: Dictionary = {"type": "sell", "hand": hand}
	if slot >= 0:
		var played: String = game.act(0, {"type": "play", "hand": hand, "slot": slot})
		assert(played == "", played)
		action = {"type": "sell", "slot": slot}
	var snapshot: Dictionary = FightSnapshot.unit(unit)
	var value: int = game.rules.sell_value(player, unit)
	var before: String = RecordState.state_hash(game)
	var gold: int = player.gold
	var result: String = game.act(0, action)
	return {
		"snapshot": snapshot,
		"value": value,
		"before": before,
		"gold_gained": player.gold - gold,
		"result": result,
		"after": RecordState.state_hash(game),
	}


func _tide_on_sell(content: GameContent) -> Dictionary:
	var game: GameSession = content.new_session(42)
	game.start_round()
	var player: PlayerState = game.player(0)
	player.gold = 20
	var levels: Array[int] = []
	var actions: Array[String] = []
	var slot: int = 0
	for id: StringName in [&"horde-runner", &"bumblebee", &"hopper", &"green-recruit"]:
		player.hand.append(game.new_unit(game.library.get_card(id), false))
		actions.append(game.act(0, {"type": "play", "hand": 0, "slot": slot}))
		slot += 1
	for sold: int in [1, 2, 3]:
		actions.append(game.act(0, {"type": "sell", "slot": sold}))
		levels.append(player.counter(&"locust_tide"))
	return {"actions": actions, "levels": levels, "hash": RecordState.state_hash(game)}


func _shop_overflow(content: GameContent) -> Dictionary:
	var game: GameSession = content.new_session(42)
	game.start_round()
	var player: PlayerState = game.player(0)
	player.gold = 20
	for slot: int in game.geometry.slot_count:
		var id: StringName = &"gorger" if slot == 0 else &"bumblebee"
		player.place(game.new_unit(game.library.get_card(id), false), slot)
	var ctx := RecruitContext.new(game, game.recruit, player)
	ctx.give_card(&"green-recruit", null)
	var sold: String = game.act(0, {"type": "sell", "hand": 0})
	return {"sell": sold, "tide": player.counter(&"locust_tide"), "hash": RecordState.state_hash(game)}
