extends RefCounted
## "How far can I get": the best placement, wins and games played per difficulty, saved to user://.

const DIFFICULTIES: PackedStringArray = ["easy", "normal", "hard"]
const TITLES: Dictionary[String, String] = {"easy": "Easy", "normal": "Normal", "hard": "Hard"}

static var path: String = "user://records.cfg"


static func best_placement(difficulty: String) -> int:
	return _read(difficulty, "best", 0)


static func wins(difficulty: String) -> int:
	return _read(difficulty, "wins", 0)


static func games(difficulty: String) -> int:
	return _read(difficulty, "games", 0)


## Records one finished game. Returns true when it beat the old best placement.
static func add_game(difficulty: String, placement: int) -> bool:
	var file: ConfigFile = ConfigFile.new()
	file.load(path)
	var best: int = _int(file.get_value(difficulty, "best", 0))
	var improved: bool = placement > 0 and (best == 0 or placement < best)
	if improved:
		file.set_value(difficulty, "best", placement)
	file.set_value(difficulty, "games", _int(file.get_value(difficulty, "games", 0)) + 1)
	if placement == 1:
		file.set_value(difficulty, "wins", _int(file.get_value(difficulty, "wins", 0)) + 1)
	file.save(path)
	return improved


## "Best 3rd · 2 wins", or that no game has been played yet.
static func summary(difficulty: String) -> String:
	var best: int = best_placement(difficulty)
	if best == 0:
		return "Not played yet"
	var count: int = wins(difficulty)
	var place: String = _ordinal(best)
	return "Best %s · %d %s" % [place, count, "win" if count == 1 else "wins"]


static func _ordinal(n: int) -> String:
	var ends: PackedStringArray = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
	return "%d%s" % [n, ends[n % 10]]


static func _read(difficulty: String, key: String, default: int) -> int:
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return default
	return _int(file.get_value(difficulty, key, default))


static func _int(value: Variant) -> int:
	return value if value is int else 0
