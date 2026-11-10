extends RefCounted
## Helpers for the combat and mechanic tests: build boards, run a fight, pick out events.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const BIG: int = 1000000

static var library: UnitLibrary = TestLibraries.current()


## A board entry; attack/health below 0 keep the unit's own stats.
static func u(
	def_id: String, attack: int = -1, health: int = -1, golden: bool = false
) -> Dictionary:
	var entry: Dictionary = {"def_id": def_id, "golden": golden}
	if attack >= 0:
		entry["attack"] = attack
	if health >= 0:
		entry["health"] = health
	return entry


## A plain stat line (Field Vole, tier 1).
static func plain(attack: int, health: int) -> Dictionary:
	return u("field_vole", attack, health)


static func board(units: Dictionary) -> Array:
	var out: Array = []
	out.resize(BoardGeometry.SLOTS)
	for slot: int in units:
		out[slot] = units[slot]
	return out


static func run(
	board_0: Array, board_1: Array, fight_seed: int = 1, config: GameConfig = null
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(library, GameConfig.defaults() if config == null else config, rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([board_0, board_1], tiers, ids, 0)


static func events(result: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = result["events"]
	return out


static func of_type(result: Dictionary, type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in events(result):
		if event["type"] == type:
			out.append(event)
	return out


static func last(result: Dictionary) -> Dictionary:
	var all: Array[Dictionary] = events(result)
	return all[all.size() - 1]


## The types of the events after the first event matching `type` with `field` == `value`.
static func types_from(result: Dictionary, index: int, count: int) -> Array:
	var all: Array[Dictionary] = events(result)
	var out: Array = []
	for event: Dictionary in all.slice(index, index + count):
		out.append(event["type"])
	return out


## The index of the first event of a type, -1 if none.
static func index_of(result: Dictionary, type: String) -> int:
	var all: Array[Dictionary] = events(result)
	for index: int in all.size():
		if all[index]["type"] == type:
			return index
	return -1


## Status events turning `status` on, as target uids.
static func status_on(result: Dictionary, status: String) -> Array:
	var out: Array = []
	for event: Dictionary in of_type(result, "status"):
		if event["status"] == status and event["on"]:
			out.append(event["target"])
	return out
