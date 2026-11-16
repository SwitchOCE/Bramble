extends RefCounted
## Set-up for the Badger tests: a session on the Badger cards plus the neutral units, real
## players' boards, live fights through the core, and readers for the fight log.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")


static func session(game_seed: int = 1) -> GameSession:
	var game: GameSession = CoreKit.content(["badger"], false).session(game_seed)
	game.start_round()
	return game


## Puts a card on a player's board; `golden` for a golden copy.
static func put(
	game: GameSession, player: PlayerState, card_id: String, slot: int, golden: bool = false
) -> Unit:
	var made: Unit = CoreKit.unit(game, card_id, golden)
	player.place(made, slot)
	game.recruit.refresh_auras(player)
	return made


## A plain neutral unit with these stats ("set to").
static func plain(
	game: GameSession, player: PlayerState, slot: int, attack: int, health: int
) -> Unit:
	var made: Unit = put(game, player, "t1_plain", slot)
	made.stats.set_attack = attack
	made.stats.set_health = health
	game.recruit.refresh_auras(player)
	return made


## A live fight between two players' real boards (both write back).
static func fight(game: GameSession, a: PlayerState, b: PlayerState, fight_seed: int = 1) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([a.board, b.board], [a.id, b.id], [a, b], [true, true], [a.hand, b.hand])
	return combat


static func events(combat: Combat, kind: String) -> Array[Dictionary]:
	return CoreKit.events_of(combat, kind)


## Trigger events of one mechanic, optionally for one fight unit.
static func triggers(combat: Combat, mechanic: String, uid: int = -1) -> Array[Dictionary]:
	return events(combat, "trigger").filter(
		func(e: Dictionary) -> bool:
			return e["mechanic"] == mechanic and (uid < 0 or CoreUtil.to_int(e["uid"]) == uid)
	)


## The fight uid of the unit standing in `slot` on `side` when the fight began.
static func uid_at(combat: Combat, side: int, slot: int) -> int:
	var start: Dictionary = combat.events[0]
	for view: Variant in start["boards"][side]:
		var shown: Dictionary = view
		if CoreUtil.to_int(shown["slot"]) == slot:
			return CoreUtil.to_int(shown["uid"])
	return -1


## The unit view of `slot` on `side` in the combat_start event.
static func shown_at(combat: Combat, side: int, slot: int) -> Dictionary:
	var start: Dictionary = combat.events[0]
	for view: Variant in start["boards"][side]:
		var shown: Dictionary = view
		if CoreUtil.to_int(shown["slot"]) == slot:
			return shown
	return {}


## The first event after `index` that is a buff for `uid`, or {}.
static func next_buff(combat: Combat, index: int, uid: int) -> Dictionary:
	for i: int in range(index + 1, combat.events.size()):
		var event: Dictionary = combat.events[i]
		if event["type"] == "buff" and CoreUtil.to_int(event["uid"]) == uid:
			return event
	return {}


## The index in the fight log of `event`.
static func index_of(combat: Combat, event: Dictionary) -> int:
	return combat.events.find(event)


## The player this player fights this round (start_round paired them).
static func opponent(game: GameSession, player: PlayerState) -> PlayerState:
	return game.player(game.opponent_of(player.id))


## The game-log events of one type for one player.
static func game_log(game: GameSession, player: PlayerState, kind: String) -> Array[Dictionary]:
	return CoreKit.log_of(game, kind).filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e.get("player", -1)) == player.id
	)
