extends RefCounted
## Shared set-up for the core tests: the neutral test library, sessions, hand-built boards and
## fights.

const NEUTRAL: String = "res://tests/core/content/neutral"
const TEST_CARDS: String = "res://tests/core/content/test"
const LIBRARY_PATH: String = NEUTRAL + "/units.json"


static func registry() -> MechanicRegistry:
	return MechanicRegistry.with_built_ins()


static func library(mechanics: MechanicRegistry) -> UnitLibrary:
	return UnitLibrary.from_file(LIBRARY_PATH, mechanics)


## Content through the game's one loader (ContentSet): the shared folder and the tribes named in
## `tribes` (empty = every tribe under src/content, ["none"] = none), then the neutral test units
## and, with `test_cards`, the bridge test cards.
static func content(
	tribes: PackedStringArray = ["none"], test_cards: bool = true, neutral: bool = true
) -> ContentSet:
	var folders: PackedStringArray = ContentSet.folders_in(ContentSet.ROOT, tribes)
	if neutral:
		folders.append(NEUTRAL)
	if test_cards:
		folders.append(TEST_CARDS)
	return ContentSet.load_folders(folders)


## A session on the neutral and bridge test cards, where every player's sales feed the test heap.
static func bridge_session(game_seed: int = 1) -> GameSession:
	return content().session(game_seed)


static func session(game_seed: int = 1, config: GameConfig = null) -> GameSession:
	var mechanics: MechanicRegistry = registry()
	return GameSession.create(game_seed, library(mechanics), mechanics, config)


## A Bought unit made outside the shop (no pool copy taken), for boards built by hand.
static func unit(game: GameSession, card_id: String, golden: bool = false) -> Unit:
	var made: Unit = game.new_unit(game.library.get_card(StringName(card_id)), golden)
	made.bought_copies = 1
	return made


## A board from {slot: card id}, as an Array of Unit or null per slot.
static func board(game: GameSession, spec: Dictionary) -> Array[Unit]:
	var out: Array[Unit] = []
	out.resize(game.geometry.slot_count)
	for key: Variant in spec:
		var slot: int = CoreUtil.to_int(key)
		var made: Unit = unit(game, str(spec[key]))
		made.slot = slot
		out[slot] = made
	return out


## Replaces the unit in `slot` with a plain unit of these stats ("set to" layer).
static func dummy(
	board_units: Array[Unit], game: GameSession, slot: int, attack: int, health: int
) -> Unit:
	var made: Unit = unit(game, "t1_plain")
	made.stats.set_attack = attack
	made.stats.set_health = health
	made.slot = slot
	board_units[slot] = made
	return made


## Puts a unit on a player's recruit board.
static func put(game: GameSession, player: PlayerState, card_id: String, slot: int) -> Unit:
	var made: Unit = unit(game, card_id)
	player.place(made, slot)
	return made


static func fight(
	game: GameSession, board_a: Array[Unit], board_b: Array[Unit], fight_seed: int = 1
) -> Combat:
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, fight_seed
	)
	combat.run([board_a, board_b], [0, 1])
	return combat


static func events_of(combat: Combat, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in combat.events:
		if event["type"] == kind:
			out.append(event)
	return out


static func log_of(game: GameSession, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in game.events:
		if event["type"] == kind:
			out.append(event)
	return out


## The attacking slots of one side, in order.
static func attack_slots(combat: Combat, side: int) -> Array[int]:
	var out: Array[int] = []
	for event: Dictionary in events_of(combat, "attack"):
		if CoreUtil.to_int(event["side"]) == side:
			out.append(CoreUtil.to_int(event["slot"]))
	return out


## Sets a player's shop to these unit ids (taking them from the pool) after returning the old.
static func set_shop(game: GameSession, player: PlayerState, ids: Array[String]) -> void:
	for card_id: StringName in player.shop_units:
		game.units.give_back(card_id)
	player.shop_units.clear()
	for card_id: String in ids:
		var wanted := StringName(card_id)
		game.units.take(wanted)
		player.shop_units.append(wanted)
