extends RefCounted
## Shared set-up for the Briar tests: a session on the thorn folder and the neutral test units,
## live fights between two players' real boards, and Compost and log helpers.

const CoreKit := preload("res://tests/core/core_kit.gd")
const HEAP: StringName = &"thorn_compost"


## A session with the Briars, the shared keywords and the neutral test units (no bridge cards).
static func session(game_seed: int = 1) -> GameSession:
	var made: GameSession = CoreKit.content(["thorn"], false).session(game_seed)
	made.start_round()
	return made


## A fight between two players' real boards, both live (they write back) unless `live_b` is false.
static func fight(
	game: GameSession, p: PlayerState, q: PlayerState, fight_seed: int = 1, live_b: bool = true
) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([p.board, q.board], [p.id, q.id], [p, q], [true, live_b], [p.hand, q.hand])
	return combat


## Puts entries straight into a player's Compost (test set-up only).
static func fill(game: GameSession, player: PlayerState, ids: Array[String]) -> void:
	for card_id: String in ids:
		var wanted := StringName(card_id)
		player.heap(HEAP).add(wanted, game.library.get_card(wanted).tier)


## The ids in a player's Compost, oldest first.
static func compost_ids(player: PlayerState) -> Array[String]:
	var out: Array[String] = []
	for entry: Dictionary in player.heap(HEAP).entries:
		out.append(str(entry["id"]))
	return out


## A neutral unit with these stats on a recruit board.
static func wall(
	game: GameSession, player: PlayerState, slot: int, attack: int, health: int
) -> Unit:
	var made: Unit = CoreKit.put(game, player, "t1_plain", slot)
	made.stats.set_attack = attack
	made.stats.set_health = health
	return made


## Fight events of one type, on one side (-1: both).
static func events(combat: Combat, kind: String, side: int = -1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in combat.events:
		if event["type"] == kind and (side < 0 or CoreUtil.to_int(event["side"]) == side):
			out.append(event)
	return out


## Fight events of one type about one fight uid.
static func about(combat: Combat, kind: String, uid: int) -> Array[Dictionary]:
	return events(combat, kind).filter(
		func(e: Dictionary) -> bool: return CoreUtil.to_int(e["uid"]) == uid
	)


static func triggers(combat: Combat, mechanic: String) -> Array[Dictionary]:
	return events(combat, "trigger").filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == mechanic
	)


## The fight uid of a recruit unit, from the combat_start boards (-1 if it wasn't there).
static func uid_of(combat: Combat, unit: Unit) -> int:
	return CoreUtil.to_int(start_view(combat, unit).get("uid", -1))


## The combat_start view of a recruit unit ({} if it wasn't there).
static func start_view(combat: Combat, unit: Unit) -> Dictionary:
	var boards: Array = combat.events[0]["boards"]
	for board: Variant in boards:
		for view: Variant in board:
			var shown: Dictionary = view
			if CoreUtil.to_int(shown["recruit_uid"]) == unit.uid:
				return shown
	return {}


## The Thorns total an aura gave a unit at the start of the fight (0 if none).
static func granted(view: Dictionary, mechanic: String, param: String) -> int:
	for grant: Variant in view.get("grants", []):
		var given: Dictionary = grant
		if given["mechanic"] == mechanic:
			return CoreUtil.to_int(given[param])
	return 0


## An ability action for a board unit's mechanic aimed at a shop index.
static func bury(unit: Unit, mechanic: String, shop_index: int) -> Dictionary:
	return {"type": "ability", "uid": unit.uid, "mechanic": mechanic, "target": shop_index}


## Makes a shop of these unit ids for the player.
static func shop(game: GameSession, player: PlayerState, ids: Array[String]) -> void:
	CoreKit.set_shop(game, player, ids)
