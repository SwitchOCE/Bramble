class_name PlayGame
extends RefCounted
## One game for tools/play: a seed, a difficulty and the list of actions so far. The save holds
## only those; every call replays them, so the tool can't drift from the rules.
## Shop and hand numbers run on through units and then spells, as the player sees them.

## Command word -> how many arguments it takes at most.
const COMMANDS: Dictionary = {
	"buy": 1,
	"play": 2,
	"move": 2,
	"sell": 1,
	"swallow": 2,
	"refresh": 0,
	"freeze": 0,
	"tier": 0,
	"power": 1,
	"choose": 1,
	"end": 0,
}

var seed_value: int = 0
var difficulty: String = "normal"
var actions: Array = []
var session: GameSession
var _library: UnitLibrary


static func start(game_seed: int, level: String) -> PlayGame:
	var game := PlayGame.new()
	game.seed_value = game_seed
	game.difficulty = level
	game._begin()
	return game


static func from_save(data: Dictionary) -> PlayGame:
	var game := PlayGame.start(CoreUtil.to_int(data["seed"]), str(data["difficulty"]))
	var saved: Array = data["actions"]
	for value: Variant in saved:
		var list: Array = value
		var words: PackedStringArray = PackedStringArray(list)
		var problem: String = game.run(words)
		if problem != "":
			push_error("Replay refused %s: %s" % [" ".join(words), problem])
	return game


func to_save() -> Dictionary:
	return {"seed": seed_value, "difficulty": difficulty, "actions": actions}


## Runs one command and records it; "" or why it was refused.
func run(words: PackedStringArray) -> String:
	if words.is_empty() or not COMMANDS.has(words[0]):
		return "Unknown command. One of: %s" % ", ".join(PackedStringArray(COMMANDS.keys()))
	var args: PackedStringArray = words.slice(1)
	if args.size() > CoreUtil.to_int(COMMANDS[words[0]]):
		return "Too many arguments for %s" % words[0]
	var problem: String = _apply(words[0], args)
	if problem == "":
		actions.append(Array(words))
	return problem


func _begin() -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("bots", BotLobby.seats(difficulty))
	_library = UnitLibrary.load_dir()
	session = GameSession.create(seed_value, _library, config)


func _apply(word: String, args: PackedStringArray) -> String:
	match word:
		"buy":
			return _buy(args)
		"play":
			return _play(args)
		"move":
			return _move(args)
		"sell":
			return (
				session.sell(slot_of(args[0])) if args.size() == 1 else "sell needs a slot: sell B1"
			)
		"power":
			return _power(args)
	return _one_arg_or_none(word, args)


func _one_arg_or_none(word: String, args: PackedStringArray) -> String:
	match word:
		"swallow":
			return _swallow(args)
		"choose":
			return _choose(args)
	return _no_arg(word)


func _no_arg(word: String) -> String:
	match word:
		"refresh":
			return session.refresh()
		"freeze":
			return session.toggle_freeze()
		"tier":
			return session.tier_up()
		"end":
			return session.end_turn()
	return "Unknown command"


## swallow <what> <Ooze's slot>: a shop number, "h" and a hand number, or a board slot.
## "swallow 2 F1" buys shop number 2 into F1, "swallow h0 F1" takes hand number 0, "swallow B2 F1"
## takes the unit in B2.
func _swallow(args: PackedStringArray) -> String:
	if args.size() != 2:
		return "swallow needs what and where: swallow 2 F1, swallow h0 F1 or swallow B2 F1"
	var into: int = slot_of(args[1])
	if into < 0:
		return "No such slot: %s" % args[1]
	var what: String = args[0].to_lower()
	if what.is_valid_int():
		return session.swallow(HeldUnits.SHOP, what.to_int(), into)
	if what.begins_with("h") and what.substr(1).is_valid_int():
		return session.swallow(HeldUnits.HAND, what.substr(1).to_int(), into)
	if slot_of(what) >= 0:
		return session.swallow(HeldUnits.BOARD, slot_of(what), into)
	return "swallow takes a shop number, h and a hand number, or a board slot"


func _power(args: PackedStringArray) -> String:
	if args.is_empty():
		return session.use_power(-1)
	return (
		session.use_power(slot_of(args[0]))
		if slot_of(args[0]) >= 0
		else "No such slot: %s" % args[0]
	)


func _choose(args: PackedStringArray) -> String:
	if args.size() != 1 or not args[0].is_valid_int():
		return "choose needs a number: choose 1"
	return session.choose(args[0].to_int())


func _move(args: PackedStringArray) -> String:
	if args.size() != 2:
		return "move needs two slots: move F1 B2"
	return session.move(slot_of(args[0]), slot_of(args[1]))


func _buy(args: PackedStringArray) -> String:
	if args.size() != 1 or not args[0].is_valid_int():
		return "buy needs a shop number: buy 2"
	var number: int = args[0].to_int()
	var state: Dictionary = session.get_state()
	var units: Array = state["shop"]
	if number < units.size():
		return session.buy(number)
	return session.buy_spell(number - units.size())


func _play(args: PackedStringArray) -> String:
	if args.is_empty() or not args[0].is_valid_int():
		return "play needs a hand number: play 0 F2"
	var number: int = args[0].to_int()
	var state: Dictionary = session.get_state()
	var hand: Array = state["hand"]
	var items: Array = state["hand_items"]
	var item_index: int = number - hand.size()
	if args.size() == 2 and args[1].is_valid_int() and aims_shop(items, item_index):
		return session.play_item(item_index, args[1].to_int())
	var slot: int = slot_of(args[1]) if args.size() == 2 else -1
	if args.size() == 2 and slot < 0:
		return "No such slot: %s" % args[1]
	if number < hand.size():
		return session.play(number, slot) if args.size() == 2 else "play needs a slot: play 0 F2"
	return session.play_item(item_index, slot)


## Shake the Tree aims a card in the shop: play 3 1 keeps shop number 1.
static func aims_shop(items: Array, index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var item: Dictionary = items[index]
	return str(item["aim"]) == HandItem.AIM_SHOP_UNIT


## "F2" or "b1" to a slot index; -1 if it isn't one.
static func slot_of(word: String) -> int:
	return BoardGeometry.LABELS.find(word.to_upper())


## A card's name by its id, for what the rules log; "" if there's no such card.
func card_name(card_id: String) -> String:
	var unit: Dictionary = _library.get_unit(card_id)
	if not unit.is_empty():
		return str(unit["name"])
	var card: Dictionary = _library.get_card(card_id)
	return str(card["name"]) if not card.is_empty() else ""
