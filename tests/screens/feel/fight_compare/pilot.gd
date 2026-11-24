extends "res://tests/screens/feel/fight_compare/fight_treatment.gd"
## `pilot`: the animation pilot's cheap options (docs/workstreams/fight-animation-24-nov/pilot/),
## the ones made from existing pieces only, on top of `today` (the game's own motion and replay).
## A scenario picks them: "options": {"CB12": "b", "CB13": "c"}; a decision not named plays
## today's. CB12, damage to the player after a fight: "b" the winner's portrait strikes, "c" in
## place (pilot_hero_damage.gd). CB13, how a single card dies: "b" tip and fall, "c" the light goes
## out (pilot_motion.gd). Both options of a decision share the pilot's ordering changes: CB12's
## result shows the old Health and the loss lands later; CB13's killing number stays on through
## the death and the last death is not cut by the result.
## Exploratory (ideation/fight-animation): nothing here reaches the game.

const PILOT_SCREEN: Script = preload("res://tests/screens/feel/fight_compare/pilot_screen.gd")
const PILOT_MOTION: GDScript = preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")

## Each decision's options, today's first.
const OPTIONS: Dictionary = {"CB12": ["today", "b", "c"], "CB13": ["today", "b", "c"]}

## {CB12: option, CB13: option} from the scenario.
var options: Dictionary = {}
## Keys ("u8") of units that die alone: the only unit leaving the board in their death step.
var solo: Dictionary = {}


func configure(chosen: Dictionary) -> void:
	super(chosen)
	options = chosen.duplicate()


func option(decision: String) -> String:
	var picked: String = str(options.get(decision, "today"))
	var listed: Array = OPTIONS.get(decision, [])
	return picked if picked in listed else "today"


func make_motion(cards: Control) -> FightMotion:
	if option("CB13") == "today":
		return super(cards)
	var made: FightMotion = PILOT_MOTION.new(cards)
	var motion: FightMotion = turned(made)
	motion.set("option", option("CB13"))
	motion.set("solo", solo)
	return motion


func make_replay(base: Dictionary, events: Array, catalog: Dictionary, damage: int) -> FightReplay:
	var made: FightReplay = FightReplay.build(base, events, catalog, damage)
	solo = solo_deaths(made.steps)
	if option("CB12") != "today":
		hold_old_health(made.steps, events, damage)
	return made


func screen_script() -> Script:
	return PILOT_SCREEN


## Keys of the units that leave the board alone in a death step.
static func solo_deaths(steps: Array) -> Dictionary:
	var out: Dictionary = {}
	for i: int in range(1, steps.size()):
		var step: Dictionary = steps[i]
		if str(step.get("kind", "")) != "death":
			continue
		var previous: Dictionary = steps[i - 1]
		var shown_before: Dictionary = previous["state"]
		var shown_after: Dictionary = step["state"]
		var before: Dictionary = _uids(shown_before)
		var after: Dictionary = _uids(shown_after)
		var gone: Array = []
		for uid: Variant in before:
			if not after.has(uid):
				gone.append(uid)
		if gone.size() == 1:
			out["u%d" % _i(gone[0])] = true
	return out


## The result step shows the Health from before the loss (the pilot's ordering change): the loss
## lands later, by the screen's own beat. moment.result.pilot keeps what the beat needs.
static func hold_old_health(steps: Array, events: Array, damage: int) -> void:
	if steps.size() < 2:
		return
	var last_step: Dictionary = steps[steps.size() - 1]
	var before_step: Dictionary = steps[steps.size() - 2]
	var last: Dictionary = last_step["state"]
	var before: Dictionary = before_step["state"]
	var moment: Dictionary = last.get("moment", {})
	if not moment.has("result"):
		return
	var result: Dictionary = moment["result"]
	var winner: int = _i(result.get("winner", -1))
	if winner < 0 or damage <= 0:
		return
	var loser_is_you: bool = winner != _i(last.get("you_side", 0))
	var opponent: Dictionary = last.get("opponent", {})
	var opponent_before: Dictionary = before.get("opponent", {})
	var new_health: int = _i(opponent.get("health", 0))
	var old_health: int = _i(opponent_before.get("health", 0))
	if loser_is_you:
		new_health = _i(last.get("health", 0))
		old_health = _i(before.get("health", 0))
	last["health"] = before.get("health", 0)
	opponent["health"] = opponent_before.get("health", 0)
	var players: Array = before.get("players", [])
	last["players"] = players.duplicate(true)
	var big: bool = big_loss(events)
	var extra: int = GameConfig.new().big_loss_extra
	result["pilot"] = {
		"loser_is_you": loser_is_you,
		"old": old_health,
		"new": new_health,
		"total": damage,
		"base": damage - extra if big else damage,
		"big": big,
	}


## Rulebook 10.1.2: a big loss is one where the loser killed fewer than half of the winner's
## starting units (the log's combat_end carries both counts).
static func big_loss(events: Array) -> bool:
	for value: Variant in events:
		var event: Dictionary = value
		if str(event.get("type", "")) != "combat_end":
			continue
		var winner: int = _i(event.get("winner", -1))
		if winner < 0:
			return false
		var starting: Array = event.get("starting", [0, 0])
		var killed: Array = event.get("killed", [0, 0])
		return _i(killed[winner]) * 2 < _i(starting[winner])
	return false


static func _uids(state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var boards: Array = state.get("boards", [])
	for row: Variant in boards:
		var units: Array = row
		for unit: Variant in units:
			if unit is Dictionary:
				var held: Dictionary = unit
				out[_i(held.get("uid", -1))] = true
	return out


static func _i(value: Variant) -> int:
	return GlassPieces.as_int(value)
