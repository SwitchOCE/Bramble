class_name BotLevel
extends RefCounted
## The best-player profile and the Naive tools-only yardstick.

const NAIVE: String = "naive"
const HARD: String = "hard"
const ALL: PackedStringArray = ["naive", "hard"]
## Placing: at random; sturdy in front as they arrive; by rule; by rule, then a search.
const PLACE_RANDOM: String = "random"
const PLACE_SIMPLE: String = "simple"
const PLACE_RULE: String = "rule"
const PLACE_SEARCH: String = "search"
## Test arm: by rule, then a random layout every turn.
const PLACE_SHUFFLED: String = "shuffled"
## Test arms: no scouting at all, placing by rule or at random. They judge the scouting rule.
const PLACE_BLIND: String = "blind"
const PLACE_SHUFFLED_BLIND: String = "shuffled_blind"
## Fights a turn. A bot turn on a phone-speed core stays near 140 ms: docs/ideation/evidence.
const HARD_SEARCH_BUDGET: int = 20
## First spreads: tempo beats tiers in this slice. Hard climbs slower until it has a build.
const HARD_CURVE: Array = [4, 7, 9, 12, 14]

var name: String = NAIVE
var place: String = PLACE_RANDOM
var search_budget: int = 0
## Follows a named build; reads the shop for the best one every turn.
var uses_builds: bool = false
var reads_shop_for_build: bool = false
var max_refreshes: int = 0
## Reads card hints for what the text is worth.
var reads_text: bool = false
var uses_freeze: bool = false
## Adjusts its tier plan to its health and what it scouted.
var reads_pressure: bool = false
var picks_hero: bool = false
## Lays out the board so End of Turn Passes land on the carry and aims position spells.
var plans_position: bool = false
var scouts: bool = true
var replace_margin: float = 3.0
## Opens with a plan for rounds 1-2 rather than just buying the best unit.
var plans_opening: bool = false


## How this bot places, from the name after "@".
func set_place(place_name: String) -> void:
	scouts = place_name != PLACE_BLIND and place_name != PLACE_SHUFFLED_BLIND
	match place_name:
		PLACE_BLIND:
			place = PLACE_RULE
		PLACE_SHUFFLED_BLIND:
			place = PLACE_SHUFFLED
		_:
			place = place_name


static func of(level_name: String) -> BotLevel:
	var level := BotLevel.new()
	level.name = level_name
	match level_name:
		HARD:
			level.place = PLACE_SEARCH
			level.search_budget = HARD_SEARCH_BUDGET
			level.uses_builds = true
			level.reads_shop_for_build = true
			level.max_refreshes = 30
			level.plans_opening = true
			level.reads_text = true
			level.uses_freeze = true
			level.reads_pressure = true
			level.plans_position = true
			level.picks_hero = true
	return level
