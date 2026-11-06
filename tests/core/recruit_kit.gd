extends RefCounted
## Helpers for the recruit trigger and effect tests: one player, its rules and test-only cards.
@warning_ignore_start("unsafe_call_argument")

var library: UnitLibrary
var config: GameConfig
var pool: UnitPool
var rules: RecruitRules
var player: PlayerState


func setup(game_config: GameConfig = null) -> void:
	library = UnitLibrary.load_dir()
	config = game_config if game_config != null else GameConfig.defaults()
	pool = UnitPool.create(library, config)
	rules = RecruitRules.create(library, config, pool)
	player = PlayerState.new()
	player.shop_rng.seed = 11
	player.effect_rng.seed = 12
	player.discover_rng.seed = 13
	player.spell_rng.seed = 14
	rules.setup_player(player)


## Registers a test unit with these mechanics and returns its id. Text isn't checked here.
func card(
	id: String, mechanics: Array, tribes: Array = [], attack: int = 1, health: int = 1
) -> String:
	var problem: String = (
		library
		. register_unit(
			{
				"id": id,
				"name": id,
				"tier": 1,
				"attack": attack,
				"health": health,
				"tribes": tribes,
				"text": "",
				"golden_text": "",
				"mechanics": mechanics,
				"keywords": [],
				"row_hint": null,
				"pool": false,
				"priority": null,
				"skeleton": false,
			}
		)
	)
	assert(problem == "", problem)
	return id


## A unit instance on the board (slot >= 0) or in hand (slot < 0). Created, so it holds no copy.
func put(id: String, slot: int = -1, golden: bool = false) -> RecruitUnit:
	var unit := RecruitUnit.make(library.get_unit(id), rules.new_iid(), golden)
	unit.origin = RecruitUnit.ORIGIN_CREATED
	if slot >= 0:
		player.board[slot] = unit
	else:
		player.hand.append(unit)
	return unit


## Fills the shop with one unit from the pool.
func shop(id: String) -> RecruitUnit:
	var unit := RecruitUnit.make(library.get_unit(id), rules.new_iid())
	player.shop.append(unit)
	return unit


## Registers a test spell or item and returns its id.
func spell(id: String, step: Dictionary, aim: String = "none", extra: Dictionary = {}) -> String:
	var raw: Dictionary = {
		"id": id,
		"name": id,
		"kind": "spell",
		"tier": 1,
		"cost": 1,
		"aim": aim,
		"text": "",
		"do": step
	}
	raw.merge(extra, true)
	library.register_card(raw)
	return id


## A one-entry data effect.
static func effect(trigger: String, step: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = {"id": "effect", "trigger": trigger, "do": step}
	entry.merge(extra)
	return entry


## A combat fight from {slot: id or spec} boards using this kit's library.
func fight(board_0: Dictionary, board_1: Dictionary, fight_seed: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(library, config, rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([_board(board_0), _board(board_1)], tiers, ids, 0)


## 8.5 runs a fight with slot effects: `slots` per side, {slot: [effects]}.
func fight_with_slots(
	board_0: Dictionary, board_1: Dictionary, slots: Array, hero_effects: Array = [[], []]
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(library, config, rng)
	combat.slot_effects = [_slot_rows(slots[0]), _slot_rows(slots[1])]
	combat.hero_effects = hero_effects
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([_board(board_0), _board(board_1)], tiers, ids, 0)


static func _slot_rows(by_slot: Dictionary) -> Array:
	var rows: Array = []
	for slot: int in BoardGeometry.SLOTS:
		var effects: Array = by_slot.get(slot, [])
		rows.append(effects)
	return rows


static func _board(units: Dictionary) -> Array:
	var out: Array = []
	out.resize(BoardGeometry.SLOTS)
	for slot: Variant in units:
		var entry: Variant = units[slot]
		out[slot] = {"def_id": entry} if typeof(entry) == TYPE_STRING else entry
	return out


static func of_type(result: Dictionary, type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var events: Array[Dictionary] = result["events"]
	for event: Dictionary in events:
		if event["type"] == type:
			out.append(event)
	return out
