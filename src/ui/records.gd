extends RefCounted
## One best placement and win count, saved to user://. Old level sections migrate once and remain
## in the file so existing history and unrelated settings are preserved.

const SECTION: String = "overall"
const VERSION: int = 1
const LEGACY_SECTIONS: PackedStringArray = ["easy", "normal", "hard"]
const MAX_COUNT: int = 9223372036854775807

static var path: String = "user://records.cfg"


static func best_placement() -> int:
	return _read("best")


static func wins() -> int:
	return _read("wins")


static func games() -> int:
	return _read("games")


## Invalid placements do not create a game or change the save. A best is reported only if saved.
static func add_game(placement: int) -> bool:
	if placement < 1 or placement > 8:
		return false
	var file: ConfigFile = _loaded()
	if file == null:
		return false
	var best: int = _best(file.get_value(SECTION, "best", 0))
	var improved: bool = best == 0 or placement < best
	file.set_value(SECTION, "best", placement if improved else best)
	file.set_value(SECTION, "games", _plus(_count(file.get_value(SECTION, "games", 0)), 1))
	var count: int = _count(file.get_value(SECTION, "wins", 0))
	file.set_value(SECTION, "wins", _plus(count, 1) if placement == 1 else count)
	return file.save(path) == OK and improved


## No level or saved text enters the displayed record.
static func summary() -> String:
	var best: int = best_placement()
	var count: int = wins()
	if best == 0 and count == 0 and games() == 0:
		return "Not played yet"
	var place: String = _ordinal(best) if best > 0 else "unrecorded"
	return "Best %s · %d %s" % [place, count, "win" if count == 1 else "wins"]


static func _ordinal(n: int) -> String:
	var ends: PackedStringArray = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"]
	return "%d%s" % [n, ends[n % 10]]


static func _read(key: String) -> int:
	var file: ConfigFile = _loaded()
	if file == null:
		return 0
	var value: Variant = file.get_value(SECTION, key, 0)
	return _best(value) if key == "best" else _count(value)


static func _loaded() -> ConfigFile:
	var file: ConfigFile = ConfigFile.new()
	var result: Error = file.load(path)
	if result != OK and result != ERR_FILE_NOT_FOUND:
		return null
	var version: Variant = file.get_value(SECTION, "version", 0)
	if version is int and version == VERSION:
		return file
	var best: int = 0
	var total_wins: int = 0
	var total_games: int = 0
	for section: String in LEGACY_SECTIONS:
		var candidate: int = _best(file.get_value(section, "best", 0))
		if candidate > 0 and (best == 0 or candidate < best):
			best = candidate
		total_wins = _plus(total_wins, _count(file.get_value(section, "wins", 0)))
		total_games = _plus(total_games, _count(file.get_value(section, "games", 0)))
	file.set_value(SECTION, "best", best)
	file.set_value(SECTION, "wins", total_wins)
	file.set_value(SECTION, "games", total_games)
	file.set_value(SECTION, "version", VERSION)
	file.save(path)
	return file


static func _best(value: Variant) -> int:
	if value is int and value >= 1 and value <= 8:
		return value
	return 0


static func _count(value: Variant) -> int:
	return value if value is int and value >= 0 else 0


static func _plus(left: int, right: int) -> int:
	return left + mini(right, MAX_COUNT - left)
