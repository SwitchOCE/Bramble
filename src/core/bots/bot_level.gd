class_name BotLevel
extends RefCounted
## What each difficulty does differently. The brain reads these and nothing else about its level.

const NAIVE: String = "naive"
const EASY: String = "easy"
const NORMAL: String = "normal"
const HARD: String = "hard"
const ALL: PackedStringArray = ["naive", "easy", "normal", "hard"]
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
const DEFAULT_CURVE: Array = [3, 5, 7, 9, 11]
## First spreads: tempo beats tiers in this slice. Hard climbs slower until it has a build.
const HARD_CURVE: Array = [4, 7, 9, 12, 14]
## Easy climbs late and never early: a fast climb is the strongest plan in the game.
const EASY_CURVE: Array = [5, 8, 11, 14, 16]

var name: String = NAIVE
var place: String = PLACE_RANDOM
var search_budget: int = 0
## Follows a named build; reads the shop for the best one every turn.
var uses_builds: bool = false
var reads_shop_for_build: bool = false
## Refreshes a turn at most; every level but Hard stops early.
var max_refreshes: int = 0
## Reads card hints for what the text is worth.
var reads_text: bool = false
var cash_at_once: bool = true
var uses_freeze: bool = false
## Adjusts its tier plan to its health and what it scouted.
var reads_pressure: bool = false
var picks_hero: bool = false
## Lays out the board so End of Turn Passes land on the carry and aims position spells.
var plans_position: bool = false
## Reads what the scouting rule shows. False for Easy and in the bench's test arms.
var scouts: bool = true
## How far a unit's worth may swing when choosing what to buy: a poor eye, not a plan.
var buy_noise: float = 0.0
## How much better a unit must be before this level replaces one on a full board.
var replace_margin: float = 3.0
## Opens with a plan for rounds 1-2 rather than just buying the best unit.
var plans_opening: bool = false
## Teaching opponents make ordinary legal choices, with less planning as the level falls.
var buys_economy: bool = true
var hunts_triples: bool = true
var buys_spells: bool = true
var max_replacements: int = 60
var max_tier: int = 6
## Successful spell purchases per turn, including opening spells; -1 means unlimited.
var max_spell_buys: int = -1
var spell_from_round: int = 1


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
		EASY:
			level.place = PLACE_SIMPLE
			level.max_refreshes = 1
			level.buys_economy = false
			level.hunts_triples = false
			level.max_spell_buys = 1
			level.max_replacements = 1
			level.max_tier = 5
			level.scouts = false
			level.buy_noise = 0.6
			level.replace_margin = 8.0
		NORMAL:
			level.place = PLACE_RULE
			level.uses_builds = true
			level.max_spell_buys = 1
			level.spell_from_round = 12
			level.max_refreshes = 1
			level.buys_economy = false
			level.max_replacements = 2
			level.plans_opening = true
			level.reads_text = true
			level.cash_at_once = false
			level.uses_freeze = true
			level.picks_hero = true
		HARD:
			level.place = PLACE_SEARCH
			level.search_budget = HARD_SEARCH_BUDGET
			level.uses_builds = true
			level.reads_shop_for_build = true
			level.max_refreshes = 30
			level.plans_opening = true
			level.reads_text = true
			level.cash_at_once = false
			level.uses_freeze = true
			level.reads_pressure = true
			level.plans_position = true
			level.picks_hero = true
	return level
