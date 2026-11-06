class_name SoakBot
extends Bot
## Random legal play for the soak: takes what LegalActions lists, so every aim and hero power gets
## tried and a listed action that fails is caught. It never shuffles its board, so turn counts
## grow, and it holds Acorns more often than it spends them.

const WEIGHTS: Dictionary = {
	"buy": 8.0,
	"play": 10.0,
	"buy_spell": 4.0,
	"play_item": 4.0,
	"tier_up": 5.0,
	"refresh": 1.0,
	"sell": 0.5,
	"move": 0.2,
	"use_power": 3.0,
	"toggle_freeze": 0.1,
}
const ACTIONS_PER_TURN: int = 14
const ACORN_HOLD: float = 0.75

## Gives the state a player's screen would read (id -> Dictionary).
var state_of: Callable
## Told of any listed action the rules refused (action, args, reason).
var on_refused: Callable


func play_turn(player: PlayerState, rules: RecruitRules, _round_number: int) -> void:
	for _step: int in ACTIONS_PER_TURN:
		_resolve_choices(player, rules)
		var state: Dictionary = state_of.call(player.id)
		var action: Dictionary = _pick(LegalActions.of(state), state, player.bot_rng)
		if action.is_empty():
			break
		var reason: String = _take(action, player, rules)
		if reason != "":
			on_refused.call(action, reason)
	_resolve_choices(player, rules)


func _pick(actions: Array[Dictionary], state: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var total: float = 0.0
	var weights: Array[float] = []
	for action: Dictionary in actions:
		var weight: float = _weight(action, state, rng)
		weights.append(weight)
		total += weight
	var roll: float = rng.randf() * total
	for index: int in actions.size():
		roll -= weights[index]
		if weights[index] > 0.0 and roll <= 0.0:
			return actions[index]
	return {}


## An action's chance; Acorns played for gold mostly wait, or the Larder would never fill.
func _weight(action: Dictionary, state: Dictionary, rng: RandomNumberGenerator) -> float:
	var word: String = action["action"]
	var args: Array = action["args"]
	if word == "play_item":
		var items: Array = state["hand_items"]
		var index: int = args[0]
		var item: Dictionary = items[index]
		if CoreUtil.to_int(item.get("gold_value", 0)) > 0 and rng.randf() < ACORN_HOLD:
			return 0.0
	var weight: float = WEIGHTS.get(word, 0.0)
	return weight


static func _take(action: Dictionary, player: PlayerState, rules: RecruitRules) -> String:
	var args: Array = action["args"]
	var first: int = -1 if args.is_empty() else CoreUtil.to_int(args[0])
	var second: int = -1 if args.size() < 2 else CoreUtil.to_int(args[1])
	match str(action["action"]):
		"buy":
			return rules.buy(player, first)
		"buy_spell":
			return rules.buy_spell(player, first)
		"play":
			return rules.play(player, first, second)
		"play_item":
			return rules.play_item(player, first, second)
		"sell":
			return rules.sell(player, first)
	return _take_other(action, first, second, player, rules)


static func _take_other(
	action: Dictionary, first: int, second: int, player: PlayerState, rules: RecruitRules
) -> String:
	match str(action["action"]):
		"move":
			return rules.move(player, first, second)
		"refresh":
			return rules.refresh(player)
		"toggle_freeze":
			return rules.toggle_freeze(player)
		"tier_up":
			return rules.tier_up(player)
		"use_power":
			return rules.use_power(player, first)
	return "unknown action"
