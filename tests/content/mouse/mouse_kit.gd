extends RefCounted
## Set-up for the Mouse tests: a session on the Mice and the neutral units, live fights between
## players 0 and 1, and readers for the fight log. Assertions read the log and the views.

const CoreKit := preload("res://tests/core/core_kit.gd")


## A started session on the Mice plus the neutral units (`test_cards` adds the bridge cards).
static func session(game_seed: int = 1, test_cards: bool = false) -> GameSession:
	var content: ContentSet = CoreKit.content(["mouse"], test_cards)
	var game: GameSession = content.session(game_seed)
	game.start_round()
	return game


## A plain neutral unit with these stats ("set to"), on a player's board.
static func wall(
	game: GameSession, player: PlayerState, slot: int, attack: int, health: int
) -> Unit:
	var made: Unit = CoreKit.put(game, player, "t1_plain", slot)
	made.stats.set_attack = attack
	made.stats.set_health = health
	return made


static func golden(game: GameSession, player: PlayerState, card_id: String, slot: int) -> Unit:
	var made: Unit = CoreKit.unit(game, card_id, true)
	player.place(made, slot)
	return made


## A live fight: players 0 and 1, both writing back.
static func fight(game: GameSession, fight_seed: int = 1) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run(
		[game.player(0).board, game.player(1).board],
		[0, 1],
		[game.player(0), game.player(1)],
		[true, true]
	)
	return combat


## The fight uid of the unit that started in `slot` of `side`.
static func uid_at(combat: Combat, side: int, slot: int) -> int:
	var boards: Array = combat.events[0]["boards"]
	for view: Variant in boards[side]:
		var unit: Dictionary = view
		if CoreUtil.to_int(unit["slot"]) == slot:
			return CoreUtil.to_int(unit["uid"])
	return -1


## The combat_start view of the unit that started in `slot` of `side`.
static func start_view(combat: Combat, side: int, slot: int) -> Dictionary:
	var boards: Array = combat.events[0]["boards"]
	for view: Variant in boards[side]:
		var unit: Dictionary = view
		if CoreUtil.to_int(unit["slot"]) == slot:
			return unit
	return {}


## Events of `kind` whose `field` equals `value`.
static func where(combat: Combat, kind: String, field: String, value: Variant) -> Array[Dictionary]:
	return CoreKit.events_of(combat, kind).filter(
		func(e: Dictionary) -> bool: return e.get(field) == value
	)


## Index in the fight log of the first event matching `kind` and every pair in `fields`; -1.
static func index_of(combat: Combat, kind: String, fields: Dictionary = {}) -> int:
	for i: int in combat.events.size():
		var event: Dictionary = combat.events[i]
		if event["type"] != kind:
			continue
		var ok: bool = true
		for key: Variant in fields:
			if event.get(key) != fields[key]:
				ok = false
		if ok:
			return i
	return -1


## The amounts of damage `source_uid` dealt, in order.
static func damage_by(combat: Combat, source_uid: int) -> Array[int]:
	var out: Array[int] = []
	for event: Dictionary in where(combat, "damage", "source_uid", source_uid):
		out.append(CoreUtil.to_int(event["amount"]))
	return out


## The damage events a unit took.
static func damage_to(combat: Combat, uid: int) -> Array[Dictionary]:
	return where(combat, "damage", "uid", uid)


## The events between two log indexes, of `kind`.
static func between(combat: Combat, from: int, to: int, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in range(maxi(from, 0), mini(to, combat.events.size())):
		if combat.events[i]["type"] == kind:
			out.append(combat.events[i])
	return out


## Index of the attack after the one at `from` (or the log's end).
static func next_attack(combat: Combat, from: int) -> int:
	for i: int in range(from + 1, combat.events.size()):
		if combat.events[i]["type"] == "attack":
			return i
	return combat.events.size()


## Ends player 0's turn through the session.
static func end_turn(game: GameSession, player_id: int = 0) -> String:
	return game.act(player_id, {"type": "end_turn"})


## Buys `card_id` (set as the only shop unit) and plays it into `slot`.
static func buy_and_play(
	game: GameSession, player: PlayerState, card_id: String, slot: int
) -> String:
	CoreKit.set_shop(game, player, [card_id] as Array[String])
	player.gold = 100
	var bought: String = game.act(player.id, {"type": "buy", "spell": false, "index": 0})
	if bought != "":
		return bought
	return game.act(
		player.id, {"type": "play", "hand": player.hand.size() - 1, "slot": slot, "target": -1}
	)
