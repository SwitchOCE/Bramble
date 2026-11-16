extends RefCounted
## Set-up for the Locust tests: a session on the Locust folder plus the neutral test units (no
## bridge test cards), boards put on real players, live fights and event filters.

const CoreKit := preload("res://tests/core/core_kit.gd")
const TIDE: StringName = &"locust_tide"
const HOPPER_BONUS: StringName = &"locust_hopper_bonus"


static func session(game_seed: int = 1) -> GameSession:
	var game: GameSession = CoreKit.content(["locust"], false, true).session(game_seed)
	game.start_round()
	return game


## A unit on `player`'s recruit board; `golden` for a golden copy.
static func put(
	game: GameSession, player: PlayerState, card_id: String, slot: int, golden: bool = false
) -> Unit:
	var made: Unit = CoreKit.unit(game, card_id, golden)
	player.place(made, slot)
	game.recruit.refresh_auras(player)
	return made


## A plain neutral unit with these stats ("set to" layer) on `player`'s board.
static func wall(
	game: GameSession, player: PlayerState, slot: int, attack: int, health: int
) -> Unit:
	var made: Unit = put(game, player, "t1_plain", slot)
	made.stats.set_attack = attack
	made.stats.set_health = health
	return made


## A fight between the two players' real boards, both live (they write back).
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


static func ctx(game: GameSession, player: PlayerState) -> RecruitContext:
	return RecruitContext.new(game, game.recruit, player)


static func events(combat: Combat, kind: String) -> Array[Dictionary]:
	return CoreKit.events_of(combat, kind)


## Fight events of `kind` whose `key` field equals `value`.
static func where(combat: Combat, kind: String, key: String, value: Variant) -> Array[Dictionary]:
	return events(combat, kind).filter(func(e: Dictionary) -> bool: return e.get(key) == value)


static func triggers(combat: Combat, mechanic: String) -> Array[Dictionary]:
	return where(combat, "trigger", "mechanic", mechanic)


## Summon events for Hoppers on `side`, landed ones included.
static func hopper_summons(combat: Combat, side: int) -> Array[Dictionary]:
	return events(combat, "summon").filter(
		func(e: Dictionary) -> bool: return e["id"] == "hopper" and e["side"] == side
	)


## The fight uid of a recruit unit, from the fight's opening boards.
static func uid_of(combat: Combat, unit: Unit) -> int:
	var start: Dictionary = combat.events[0]
	for board: Variant in start["boards"]:
		for view: Variant in board:
			var seen: Dictionary = view
			if seen["recruit_uid"] == unit.uid:
				return CoreUtil.to_int(seen["uid"])
	return -1


## Damage events dealt by any of `uids`.
static func damage_from(combat: Combat, uids: Array) -> Array[Dictionary]:
	return events(combat, "damage").filter(
		func(e: Dictionary) -> bool: return uids.has(CoreUtil.to_int(e["source_uid"]))
	)


## Damage events an effect dealt: those right after a trigger of `mechanic` (by `uids`, if
## given), up to the next event that is not damage or a stats change.
static func effect_damage(combat: Combat, mechanic: String, uids: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var inside: bool = false
	for event: Dictionary in combat.events:
		if event["type"] == "trigger":
			inside = (
				event["mechanic"] == mechanic
				and (uids.is_empty() or uids.has(CoreUtil.to_int(event["uid"])))
			)
		elif event["type"] == "damage":
			if inside:
				out.append(event)
		elif event["type"] != "stats":
			inside = false
	return out


## Every fight uid a unit had: its own and those of its returns, in order.
static func lineage(combat: Combat, first_uid: int) -> Array[int]:
	var out: Array[int] = [first_uid]
	for event: Dictionary in events(combat, "return"):
		if out.has(CoreUtil.to_int(event["from_uid"])):
			out.append(CoreUtil.to_int(event["uid"]))
	return out


static func count_on_board(player: PlayerState, card_id: String) -> int:
	return (
		player
		. board_units()
		. filter(func(u: Unit) -> bool: return u.def.id == StringName(card_id))
		. size()
	)
