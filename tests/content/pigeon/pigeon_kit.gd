extends RefCounted
## Shared set-up for the Pigeon tests: a session on the Pigeon cards and the neutral test units,
## hand-built boards, live fights between players 0 and 1 (with their hands, for Reserve), and
## event filters.

const CoreKit := preload("res://tests/core/core_kit.gd")


static func session(game_seed: int = 1) -> GameSession:
	return CoreKit.content(["pigeon"], false).session(game_seed)


static func put(
	game: GameSession,
	player: PlayerState,
	card: String,
	slot: int,
	attack: int = -1,
	health: int = -1,
	golden: bool = false
) -> Unit:
	var made: Unit = CoreKit.unit(game, card, golden)
	if attack >= 0:
		made.stats.set_attack = attack
	if health >= 0:
		made.stats.set_health = health
	player.place(made, slot)
	game.recruit.refresh_auras(player)
	return made


static func to_hand(game: GameSession, player: PlayerState, card: String) -> Unit:
	var made: Unit = CoreKit.unit(game, card)
	player.hand.append(made)
	return made


static func ctx(game: GameSession, player: PlayerState) -> RecruitContext:
	return RecruitContext.new(game, game.recruit, player)


## A live fight between players 0 and 1, both writing back, with their hands.
static func fight(game: GameSession, fight_seed: int = 1) -> Combat:
	var a: PlayerState = game.player(0)
	var b: PlayerState = game.player(1)
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([a.board, b.board], [0, 1], [a, b], [true, true], [a.hand, b.hand])
	return combat


static func events(combat: Combat, kind: String, side: int = -1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in combat.events:
		if event["type"] != kind:
			continue
		if side >= 0 and CoreUtil.to_int(event.get("side", -1)) != side:
			continue
		out.append(event)
	return out


static func triggers(combat: Combat, mechanic: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in events(combat, "trigger"):
		if event["mechanic"] == mechanic:
			out.append(event)
	return out


## The fight unit standing in `slot` that copies `unit` from the recruit board (null if none).
static func fight_copy(combat: Combat, side: int, unit: Unit) -> CombatUnit:
	for each: CombatUnit in combat.units(side):
		if each.recruit_uid == unit.uid:
			return each
	return null
