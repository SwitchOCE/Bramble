extends RefCounted
## Set-up for the cross-tribe tests: every shipped tribe loaded together (CoreKit.all_tribes, no
## test or neutral cards), real players' boards, live fights and readers for the fight log.
## Enemies with set stats are Privates (a Pigeon token with no text) under the "set to" layer.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")
const COMPOST: StringName = &"thorn_compost"
const TIDE: StringName = &"locust_tide"
const HOPPER_BONUS: StringName = &"locust_hopper_bonus"
const MEDAL: StringName = &"pigeon_medal"


## A session on every shipped tribe, round 1 started. `p` and its opponent are the two players a
## test fights with: player 0 and whoever start_round paired with it.
static func session(game_seed: int = 1) -> GameSession:
	var content: ContentSet = CoreKit.all_tribes()
	assert(content.errors.is_empty(), "the shipped set loads clean")
	var game: GameSession = content.session(game_seed)
	game.start_round()
	return game


static func opponent(game: GameSession, player: PlayerState) -> PlayerState:
	return game.player(game.opponent_of(player.id))


## A Bought card on `player`'s board; `golden` for a golden copy.
static func put(
	game: GameSession, player: PlayerState, card_id: String, slot: int, golden: bool = false
) -> Unit:
	var made: Unit = CoreKit.unit(game, card_id, golden)
	player.place(made, slot)
	game.recruit.refresh_auras(player)
	return made


## A Bought card in `player`'s hand.
static func hold(game: GameSession, player: PlayerState, card_id: String) -> Unit:
	var made: Unit = CoreKit.unit(game, card_id)
	player.hand.append(made)
	return made


## A unit with set stats and no text (a Private under the "set to" layer).
static func wall(
	game: GameSession, player: PlayerState, slot: int, attack: int, health: int
) -> Unit:
	var made: Unit = put(game, player, "private", slot)
	made.stats.set_attack = attack
	made.stats.set_health = health
	game.recruit.refresh_auras(player)
	return made


static func ctx(game: GameSession, player: PlayerState) -> RecruitContext:
	return RecruitContext.new(game, game.recruit, player)


## Puts entries straight into a player's Compost (test set-up only).
static func fill(game: GameSession, player: PlayerState, ids: Array[String]) -> void:
	for card_id: String in ids:
		var wanted := StringName(card_id)
		player.heap(COMPOST).add(wanted, game.library.get_card(wanted).tier)


## A live fight between two players' real boards and hands (both write back).
static func fight(
	game: GameSession, a: PlayerState, b: PlayerState, fight_seed: int = 1
) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([a.board, b.board], [a.id, b.id], [a, b], [true, true], [a.hand, b.hand])
	return combat


static func events(combat: Combat, kind: String, side: int = -1) -> Array[Dictionary]:
	return CoreKit.events_of(combat, kind).filter(
		func(e: Dictionary) -> bool: return side < 0 or CoreUtil.to_int(e["side"]) == side
	)


## Fight events of `kind` whose `key` field equals `value`.
static func where(combat: Combat, kind: String, key: String, value: Variant) -> Array[Dictionary]:
	return events(combat, kind).filter(func(e: Dictionary) -> bool: return e.get(key) == value)


## Trigger events of one mechanic, optionally for one fight uid.
static func triggers(combat: Combat, mechanic: String, uid: int = -1) -> Array[Dictionary]:
	return events(combat, "trigger").filter(
		func(e: Dictionary) -> bool:
			return e["mechanic"] == mechanic and (uid < 0 or CoreUtil.to_int(e["uid"]) == uid)
	)


## The combat_start view of a recruit unit ({} if it wasn't on the board).
static func start_view(combat: Combat, unit: Unit) -> Dictionary:
	for board: Variant in combat.events[0]["boards"]:
		for view: Variant in board:
			var shown: Dictionary = view
			if CoreUtil.to_int(shown["recruit_uid"]) == unit.uid:
				return shown
	return {}


## The fight uid of a recruit unit (-1 if it wasn't on the board).
static func uid_of(combat: Combat, unit: Unit) -> int:
	return CoreUtil.to_int(start_view(combat, unit).get("uid", -1))


## Every fight uid a unit had: its own and those of its returns, in order.
static func lineage(combat: Combat, first_uid: int) -> Array[int]:
	var out: Array[int] = [first_uid]
	for event: Dictionary in events(combat, "return"):
		if out.has(CoreUtil.to_int(event["from_uid"])):
			out.append(CoreUtil.to_int(event["uid"]))
	return out


## Index in the fight log of the first event of `kind` matching every field in `fields` at or
## after `from` (-1 if none).
static func index_of(combat: Combat, kind: String, fields: Dictionary = {}, from: int = 0) -> int:
	for i: int in range(from, combat.events.size()):
		var event: Dictionary = combat.events[i]
		if event["type"] != kind:
			continue
		var matches: bool = true
		for key: Variant in fields:
			if event.get(key) != fields[key]:
				matches = false
		if matches:
			return i
	return -1


## The total of one shown mechanic's number on a view (0 if it has none).
static func total(view: Dictionary, mechanic: String, param: String) -> int:
	var totals: Dictionary = view.get("totals", {})
	var numbers: Dictionary = totals.get(mechanic, {})
	return CoreUtil.to_int(numbers.get(param, 0))


## This round's fight record (GameSession.fights) for `player`.
static func fight_of(game: GameSession, player: PlayerState) -> Dictionary:
	for each: Dictionary in game.fights:
		var players: Array = each["players"]
		if players.has(player.id):
			return each
	return {}
