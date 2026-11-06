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
## Fights a turn. A bot turn on a phone-speed core stays near 140 ms: docs/ideation/evidence.
const HARD_SEARCH_BUDGET: int = 30
const DEFAULT_CURVE: Array = [3, 5, 7, 9, 11]
const EASY_CURVE: Array = [4, 6, 8, 10, 12]

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


static func of(level_name: String) -> BotLevel:
	var level := BotLevel.new()
	level.name = level_name
	match level_name:
		EASY:
			level.place = PLACE_SIMPLE
			level.max_refreshes = 1
		NORMAL:
			level.place = PLACE_RULE
			level.uses_builds = true
			level.max_refreshes = 4
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
			level.reads_text = true
			level.cash_at_once = false
			level.uses_freeze = true
			level.reads_pressure = true
			level.plans_position = true
			level.picks_hero = true
	return level
