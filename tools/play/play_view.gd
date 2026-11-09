class_name PlayView
extends RefCounted
## What every tools/play call prints: everything a player can see, plain and quick to read.

const CardRulings := preload("res://src/ui/card_rulings.gd")
const FightLog := preload("res://tools/play/play_fight_log.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const Guide := preload("res://src/ui/screens/how_to_play.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

## LegalActions' action names -> what the player types.
const COMMAND_WORDS: Dictionary = {
	"buy_spell": "buy",
	"play_item": "play",
	"use_power": "power",
	"tier_up": "tier",
	"toggle_freeze": "freeze",
	"end_turn": "end",
}


static func text(game: PlayGame, message: String) -> String:
	var state: Dictionary = game.session.get_state()
	var lines: PackedStringArray = []
	if message != "":
		lines.append(message)
	_header(state, lines)
	_choice(state, lines)
	_shop(state, lines)
	_board(state, lines)
	_slice_lines(state, lines)
	_sky(state, lines)
	_hand(state, lines)
	_glossary(state, lines, game.session.get_last_combat())
	_standings(state, lines)
	_scouted(state, lines)
	_this_turn(game, state, lines)
	fight_lines(game.session.get_last_combat(), state, lines)
	_legal(state, lines)
	return "\n".join(lines)


## The whole thing for a program, with the numbers the plain text uses.
static func json(game: PlayGame, message: String) -> String:
	var state: Dictionary = game.session.get_state()
	var payload: Dictionary = {
		"message": message,
		"state": state,
		"last_fight": game.session.get_last_combat(),
		"legal": LegalActions.of(state),
	}
	if game.session.is_over():
		payload["game_log"] = game.session.get_game_log()
	return JSON.stringify(payload, "", false)


## The end-of-game review: placements, per-round boards, tribes.
static func log_text(game: PlayGame) -> String:
	var game_log: Dictionary = game.session.get_game_log()
	var lines: PackedStringArray = ["* marks a golden unit."]
	lines.append("Lobby tribes: %s" % _joined(game_log["lobby_tribes"], "all"))
	var rows: Array = game_log["players"]
	var state: Dictionary = game.session.get_state()
	for value: Variant in rows:
		var row: Dictionary = value
		(
			lines
			. append(
				(
					"%s: place %s, health %s, tier %s, spent %s gold, main tribe %s"
					% [
						_player_name(state, row["player_id"]),
						row["placement"],
						row["health"],
						row["tier"],
						row["gold_spent"],
						row["main_tribe"],
					]
				)
			)
		)
		var rounds: Array = row["rounds"]
		for round_value: Variant in rounds:
			var round_row: Dictionary = round_value
			(
				lines
				. append(
					(
						"  R%s T%s %s spent %s: %s"
						% [
							round_row["round"],
							round_row["tier"],
							round_row["result"],
							round_row["gold_spent"],
							_log_board(round_row["board"]),
						]
					)
				)
			)
	lines.append("Tribes: %s" % JSON.stringify(game_log["tribes"]))
	return "\n".join(lines)


static func _log_board(board_value: Variant) -> String:
	var board: Array = board_value
	var units: PackedStringArray = []
	for slot: int in board.size():
		if board[slot] != null:
			var unit: Dictionary = board[slot]
			var gold: String = "*" if unit["golden"] else ""
			units.append(
				(
					"%s %s%s %s/%s"
					% [
						BoardGeometry.LABELS[slot],
						gold,
						unit["name"],
						unit["attack"],
						unit["health"]
					]
				)
			)
	return ", ".join(units) if not units.is_empty() else "(empty)"


## " [Hex 3]" for a unit that carries one.
static func _hex_mark(unit: Dictionary) -> String:
	var counters: Dictionary = unit.get("counters", {})
	var amount: int = CoreUtil.to_int(unit.get("hex_amount", counters.get("hex", 0)))
	var stored: int = CoreUtil.to_int(unit.get("hex_stored", amount))
	var words: String = "Hex %s" % amount
	if stored > amount:
		words += " (%d stored)" % stored
	return " [%s]" % words if amount > 0 else ""


static func _header(state: Dictionary, lines: PackedStringArray) -> void:
	var armor: int = state["armor"]
	var health: String = str(state["health"]) + ("+%d armor" % armor if armor > 0 else "")
	var next_up: String = (
		"max"
		if CoreUtil.to_int(state["tier"]) >= UnitLibrary.TIERS
		else "up %s" % state["tier_up_cost"]
	)
	var refresh: String = "refresh %s" % state["refresh_cost"]
	if CoreUtil.to_int(state["free_refreshes"]) > 0:
		refresh += " (%s free)" % state["free_refreshes"]
	(
		lines
		. append(
			(
				"Round %s | %s gold%s | tier %s (%s) | health %s | %s%s"
				% [
					state["round"],
					state["gold"],
					(
						" +%s next turn" % state["gold_next_turn"]
						if CoreUtil.to_int(state["gold_next_turn"]) > 0
						else ""
					),
					state["tier"],
					next_up,
					health,
					refresh,
					" | FROZEN" if state["frozen"] else "",
				]
			)
		)
	)
	lines.append(RecruitView.income_note(state))
	lines.append("Help: play.sh help")
	lines.append("Lobby tribes: %s" % _joined(state["lobby_tribes"], "all"))
	var hero: Variant = state["hero"]
	if hero != null:
		var card: Dictionary = hero
		var power: String = ""
		if str(card["kind"]) == HeroRules.ACTIVATED:
			power = " [power: %s gold, %s left this turn]" % [card["cost"], card["uses_left"]]
		lines.append("Hero: %s%s. %s" % [card["name"], power, card["text"]])
	if str(state["phase"]) == "game_over":
		lines.append("GAME OVER. You placed %s. Boards by round: <save> log" % state["placement"])


static func _choice(state: Dictionary, lines: PackedStringArray) -> void:
	var pending: Variant = state["pending_choice"]
	if pending == null:
		return
	var choice: Dictionary = pending
	lines.append("CHOOSE (%s):" % choice["kind"])
	if not str(choice.get("note", "")).is_empty():
		lines.append("  " + str(choice["note"]))
	var options: Array = choice["options"]
	for index: int in options.size():
		var option: Dictionary = options[index]
		lines.append("  %d %s" % [index, _card(option)])


static func _shop(state: Dictionary, lines: PackedStringArray) -> void:
	var units: Array = state["shop"]
	var spells: Array = state["shop_spells"]
	lines.append("SHOP (buy N):")
	for index: int in units.size():
		var unit: Dictionary = units[index]
		lines.append("  %d %s%s" % [index, _card(unit), _triple_mark(state, unit)])
	for index: int in spells.size():
		var spell: Dictionary = spells[index]
		lines.append("  %d %s" % [units.size() + index, _card(spell)])
	if units.is_empty() and spells.is_empty():
		lines.append("  (empty)")


## What buying this one more copy would do, said before it happens.
static func _triple_mark(state: Dictionary, unit: Dictionary) -> String:
	var warning: String = RecruitView.triple_warning(state, unit)
	return "" if warning.is_empty() else " <- " + warning


static func _board(state: Dictionary, lines: PackedStringArray) -> void:
	lines.append("BOARD:")
	var board: Array = state["board"]
	var slots: Array = state["slot_effects"]
	var empty: PackedStringArray = []
	for slot: int in board.size():
		var marks: String = _slot_marks(slots[slot])
		var content: String = "(empty)"
		if board[slot] != null:
			var unit: Dictionary = board[slot]
			content = (
				_card(unit)
				+ " [sell: %d gold]" % RecruitHeld.sell_gold(unit, CoreUtil.to_int(state["round"]))
				+ _belly_marks(unit, CoreUtil.to_int(state["round"]))
			)
		if _nest_on(state, slot):
			marks += " {Nest}"
		if board[slot] == null and marks == "":
			empty.append(BoardGeometry.LABELS[slot])
		else:
			lines.append("  %s %s%s" % [BoardGeometry.LABELS[slot], content, marks])
	if not empty.is_empty():
		lines.append("  empty: %s" % " ".join(empty))


static func _nest_on(state: Dictionary, slot: int) -> bool:
	var away: Array = state["away"]
	for value: Variant in away:
		var bird: Dictionary = value
		if CoreUtil.to_int(bird["nest"]) == slot:
			return true
	return false


## What the slice adds around the board: bands, the Larder, a debt, buys left, Passes on the way.
static func _slice_lines(state: Dictionary, lines: PackedStringArray) -> void:
	var bands: PackedStringArray = []
	var flags: Array = state["bands"]
	for slot: int in flags.size():
		if flags[slot]:
			bands.append(BoardGeometry.LABELS[slot])
	if not bands.is_empty():
		lines.append("  bands (%d): %s" % [bands.size(), " ".join(bands)])
	if CoreUtil.to_int(state["larder"]) > 0:
		lines.append("  held Acorns are worth %s gold" % state["larder"])
	if CoreUtil.to_int(state["debt"]) > 0:
		var debt: int = CoreUtil.to_int(state["debt"])
		var payment: int = mini(debt, CoreUtil.to_int(state.get("debt_payment", debt)))
		lines.append("  next turn you repay %d (%d left)" % [payment, debt])
	if CoreUtil.to_int(state["buys_left"]) >= 0:
		lines.append("  unit buys left this turn: %s" % state["buys_left"])
	var passes: Array = state["pending_passes"]
	for value: Variant in passes:
		var entry: Dictionary = value
		var landing: int = entry["landing_slot"]
		var where: String = BoardGeometry.LABELS[landing] if landing >= 0 else "nobody"
		lines.append(
			(
				"  End of Turn: Pass %+d/%+d from %s lands on %s"
				% [entry["attack"], entry["health"], _label(entry["from_slot"]), where]
			)
		)


## Fly South: who's up, when each lands, which Nest. And who's waiting for room in hand.
static func _sky(state: Dictionary, lines: PackedStringArray) -> void:
	var away: Array = state["away"]
	if not away.is_empty():
		lines.append("AWAY (Fly South; each empty Nest holds an Egg):")
	for value: Variant in away:
		var bird: Dictionary = value
		var nest: int = bird["nest"]
		(
			lines
			. append(
				(
					"  %s %s/%s lands in %s turn(s), %s"
					% [
						bird["name"],
						bird["attack"],
						bird["health"],
						bird["turns_left"],
						"Nest on %s" % _label(nest) if nest >= 0 else "no Nest",
					]
				)
			)
		)
	var waiting: Array = state["doorstep"]
	for value: Variant in waiting:
		var unit: Dictionary = value
		lines.append("  On the doorstep until your hand has room: %s" % unit["name"])


## What a board unit's Sell will do, and what its Belly holds.
static func _belly_marks(card: Dictionary, round_number: int) -> String:
	var out: String = ""
	var size: int = CoreUtil.to_int(card.get("belly", 0))
	if size > 0:
		var names: PackedStringArray = []
		var held: Array = card["held"]
		for value: Variant in held:
			var inner: Dictionary = value
			names.append("%s %s/%s" % [inner["name"], inner["attack"], inner["health"]])
		out += (
			" [Belly %d/%d%s]"
			% [held.size(), size, ": " + ", ".join(names) if not names.is_empty() else ""]
		)
	if CoreUtil.to_int(card.get("fly_south", 0)) > 0 and round_number > 0:
		var flies: bool = CoreUtil.to_int(card.get("played_round", 0)) != round_number
		out += " [sell: flies south]" if flies else " [sell: gone, played this turn]"
	return out


static func _slot_marks(value_list: Variant) -> String:
	var effects: Array = value_list
	if effects.is_empty():
		return ""
	var names: PackedStringArray = []
	for value: Variant in effects:
		var effect: Dictionary = value
		names.append(
			(
				"%s %+d/%+d"
				% [
					str(effect.get("name", "effect")),
					CoreUtil.to_int(effect.get("attack", 0)),
					CoreUtil.to_int(effect.get("health", 0))
				]
			)
		)
	return " [Slot: %s]" % ", ".join(names)


static func _hand(state: Dictionary, lines: PackedStringArray) -> void:
	var hand: Array = state["hand"]
	var items: Array = state["hand_items"]
	lines.append(
		"HAND %d/%s (play @handle [slot]):" % [hand.size() + items.size(), state["hand_limit"]]
	)
	for index: int in hand.size():
		var unit: Dictionary = hand[index]
		lines.append("  @%s (number %d) %s" % [unit["iid"], index, _card(unit)])
	for index: int in items.size():
		var item: Dictionary = items[index]
		lines.append("  @%s (number %d) %s" % [item["iid"], hand.size() + index, _card(item)])


static func _card(card: Dictionary) -> String:
	var rules: String = str(card.get("text", ""))
	for borrowed: Dictionary in card.get("borrowed_rules", []):
		rules += "\nBorrowed from %s: %s" % [borrowed["name"], borrowed["text"]]
	if card.has("attack"):
		var tribes: Array = card["tribes"]
		var golden: String = "GOLDEN " if card.get("golden", false) else ""
		var line: String = (
			"%s%s %s/%s T%s %s"
			% [
				golden,
				card["name"],
				card["attack"],
				card["health"],
				card["tier"],
				_joined(tribes, "neutral")
			]
		)
		if card.has("cost"):
			line += " (%s gold)" % card["cost"]
		if card.get("poached", false):
			line += " [paw: from your last opponent]"
		line += _unit_marks(card)
		return "%s: %s" % [line, rules] if rules != "" else line
	if card.has("uses_per_turn"):
		return "%s (%s): %s" % [card["name"], card["kind"], rules]
	var aim: String = "" if str(card["aim"]) == HandItem.AIM_NONE else ", aim %s" % card["aim"]
	return (
		"%s (%s T%s, %s gold%s): %s"
		% [card["name"], card["kind"], card["tier"], card["cost"], aim, rules]
	)


## A unit's counters: turns in its slot against what it waits for, a Cold Frame, Hex, Shy's price.
static func _unit_marks(card: Dictionary) -> String:
	var marks: PackedStringArray = []
	var goal: int = CoreUtil.to_int(card.get("turns_goal", 0))
	if goal > 0:
		marks.append("%s/%d turns" % [card.get("turns_in_slot", 0), goal])
	var timers: Array = card.get("timers", [])
	for value: Variant in timers:
		var timer: Dictionary = value
		marks.append("%s turns to %+d/%+d" % [timer["left"], timer["attack"], timer["health"]])
	var counters: Dictionary = card.get("counters", {})
	var hex: int = CoreUtil.to_int(card.get("hex_amount", counters.get("hex", 0)))
	if hex > 0:
		marks.append(_hex_mark(card).strip_edges().trim_prefix("[").trim_suffix("]"))
	if counters.has("teind"):
		marks.append("Teind %s/3" % counters["teind"])
	if card.get("reward_pending", false):
		marks.append("play for your Triple Reward")
	return " [%s]" % ", ".join(marks) if not marks.is_empty() else ""


## What each keyword on screen means, by name, once, so nobody has to look it up. That covers what
## is offered in a choice and what the next opponent fought with. Then each card's rulings (its
## details, the GUI panel's second layer), once per card.
static func _glossary(state: Dictionary, lines: PackedStringArray, fight: Dictionary = {}) -> void:
	var seen: PackedStringArray = []
	var notes: PackedStringArray = []
	var rulings: PackedStringArray = []
	var groups: Array = []
	for key: String in [
		"shop", "board", "hand", "hand_items", "shop_spells", "next_opponent_last_board"
	]:
		groups.append(state[key])
	if state["pending_choice"] != null:
		var choice: Dictionary = state["pending_choice"]
		groups.append(choice["options"])
	# Last fight and next Scout can have different units; explain every arrival and text donor.
	var fighters: Array = []
	for event: Dictionary in fight.get("events", []):
		if event.get("type", "") == "combat_start":
			for board: Array in event.get("boards", []):
				fighters.append_array(board)
		if event.get("unit") is Dictionary:
			fighters.append(event["unit"])
	groups.append(fighters)
	for group: Variant in groups:
		var cards: Array = group
		for value: Variant in cards:
			if value == null:
				continue
			var card: Dictionary = value
			var ruling: String = CardRulings.for_view(card)
			var entry: String = "%s: %s" % [card.get("name", "?"), ruling]
			if not ruling.is_empty() and not rulings.has(entry):
				rulings.append(entry)
			for word: String in KeywordRules.named_on(card):
				if not seen.has(word):
					seen.append(word)
					notes.append("%s: %s" % [word, KeywordRules.text(word)])
			for borrowed: Dictionary in card.get("borrowed_rules", []):
				for word: String in KeywordRules.named_on(borrowed):
					if not seen.has(word):
						seen.append(word)
						notes.append("%s: %s" % [word, KeywordRules.text(word)])
	# Scout/log board shorthand uses * rather than the full GOLDEN label.
	var scout: Array = state["next_opponent_last_board"]
	for value: Variant in scout:
		if value is Dictionary:
			var unit: Dictionary = value
			if unit.get("golden", false) and not seen.has("*"):
				notes.append("*: " + KeywordRules.text("*"))
				break
	if not notes.is_empty():
		lines.append("KEYWORDS:")
		for note: String in notes:
			lines.append("  " + note)
	if not rulings.is_empty():
		lines.append("DETAILS:")
		for entry: String in rulings:
			lines.append("  " + entry)


static func _standings(state: Dictionary, lines: PackedStringArray) -> void:
	lines.append("LOBBY:")
	var over: bool = str(state["phase"]) == "game_over"
	var next_id: Variant = null if over else state["next_opponent_id"]
	var ghost_owner: Variant = null if next_id != Matchmaking.GHOST else _ghost_owner(state)
	var rows: Array = state["standings"]
	for value: Variant in rows:
		var row: Dictionary = value
		var marker: String = ""
		if next_id != null and row["player_id"] == next_id:
			marker = " <- next opponent"
		if ghost_owner != null and row["player_id"] == ghost_owner:
			marker = " <- next opponent: their ghost"
		var alive: bool = row.get("alive", true)
		var place: String = "" if alive else " OUT place %s" % row.get("placement", "?")
		lines.append(
			(
				"  %s: health %s, tier %s%s%s"
				% [_row_name(row), row.get("health", "?"), row.get("tier", "?"), place, marker]
			)
		)


## What a player is called: "You", or their hero, as on the screen.
static func _row_name(row: Dictionary) -> String:
	return UiTheme.player_name(row)


## The id of the last player knocked out, whose board the ghost is; null if nobody is out.
static func _ghost_owner(state: Dictionary) -> Variant:
	return RecruitView.ghost_owner(state).get("player_id")


## The scouting rule: the next opponent's board as it fought last round.
static func _scouted(state: Dictionary, lines: PackedStringArray) -> void:
	var field: bool = str(state.get("opponents", "")) == "field"
	if field and RecruitView.is_ghost_next(state) and str(state["phase"]) != "game_over":
		lines.append("Next fight: Field ghost.")
	var ghost: bool = state["next_opponent_id"] == Matchmaking.GHOST and _ghost_owner(state) != null
	if ghost and str(state["phase"]) != "game_over":
		lines.append(
			(
				(
					"Next fight: the ghost of %s, the last player out. "
					% _player_name(state, _ghost_owner(state))
				)
				+ "It can't be hurt, but it can hurt you."
			)
		)
	if state["next_opponent_hero"] != null:
		var hero: Dictionary = state["next_opponent_hero"]
		lines.append("Next opponent's hero: %s. %s" % [hero["name"], hero["text"]])
	var seen: Array = state["next_opponent_last_board"]
	if seen.is_empty():
		lines.append("Next opponent's last board: not seen yet")
		return
	var line: String = _log_board(seen)
	lines.append("Next opponent's last board: %s" % line)
	var nests: Array = state["next_opponent_last_nests"]
	if not nests.is_empty():
		var at: PackedStringArray = []
		for slot: Variant in nests:
			at.append(_label(slot))
		lines.append("  Nests on their %s" % " ".join(at))
	var slots: Array = state["next_opponent_last_slot_effects"]
	for slot: int in slots.size():
		var marks: String = _slot_marks(slots[slot])
		if marks != "":
			lines.append("  On their %s:%s" % [_label(slot), marks])


## What fired during this recruit turn, by card name.
static func _this_turn(game: PlayGame, state: Dictionary, lines: PackedStringArray) -> void:
	var entries: Array = state["recruit_log"]
	if entries.is_empty():
		return
	var words: PackedStringArray = []
	for value: Variant in entries:
		var entry: Dictionary = value
		var notice: String = RecruitView.event_note(entry)
		if not notice.is_empty():
			lines.append(notice)
		if str(entry["type"]) == "trigger":
			var word: String = game.card_name(str(entry.get("source", "")))
			words.append(word if word != "" else "your hero")
	if not words.is_empty():
		lines.append("TRIGGERED THIS TURN: %s" % ", ".join(words))


## The last fight, every event, from the human's side. Anything unknown prints raw so nothing hides.
static func fight_lines(fight: Dictionary, state: Dictionary, lines: PackedStringArray) -> void:
	var events: Array = fight.get("events", [])
	if events.is_empty():
		return
	var start: Dictionary = events[0]
	var ids: Array = start["player_ids"]
	var mine: int = maxi(0, ids.find(GameSession.HUMAN_ID))
	var winner: int = CoreUtil.to_int(fight.get("winner", -1))
	var outcome: String = "Tied" if winner < 0 else ("You won" if winner == mine else "You lost")
	(
		lines
		. append(
			(
				"LAST FIGHT (round %s, against %s): %s, %s damage"
				% [
					fight.get("round", "?"),
					_player_name(state, fight.get("opponent_id")),
					outcome,
					fight.get("damage", 0),
				]
			)
		)
	)
	var names: Dictionary = {}
	for value: Variant in events:
		var event: Dictionary = value
		var line: String = FightLog.event_line(event, names, mine)
		if not line.is_empty():
			lines.append("  " + line)


static func _player_name(state: Dictionary, player_id: Variant) -> String:
	var rows: Array = state["standings"]
	for value: Variant in rows:
		var row: Dictionary = value
		if row["player_id"] == player_id:
			return _row_name(row)
	return "a ghost"


static func _legal(state: Dictionary, lines: PackedStringArray) -> void:
	var groups: Dictionary = {}
	var order: PackedStringArray = []
	for entry: Dictionary in LegalActions.of(state):
		var word: String = str(entry["action"])
		if not groups.has(word):
			order.append(word)
			groups[word] = PackedStringArray()
		var list: PackedStringArray = groups[word]
		var args: Array = entry["args"]
		list.append(_args(word, args, state))
		groups[word] = list
	var parts: PackedStringArray = []
	for word: String in order:
		var list: PackedStringArray = groups[word]
		if word == "buy_spell" and groups.has("buy"):
			continue
		if word == "buy" and groups.has("buy_spell"):
			var spells: PackedStringArray = groups["buy_spell"]
			list.append_array(spells)
		if word == "play" and groups.has("play_item"):
			var items: PackedStringArray = groups["play_item"]
			list.append_array(items)
		if word == "play_item" and groups.has("play"):
			continue
		parts.append(_group(word, list))
	lines.append("LEGAL: %s" % (" | ".join(parts) if not parts.is_empty() else "(none)"))


## An action's args as the commands take them.
static func _args(word: String, args: Array, state: Dictionary) -> String:
	var hand: Array = state["hand"]
	var shop: Array = state["shop"]
	var hand_size: int = hand.size()
	var shop_size: int = shop.size()
	match word:
		"buy", "choose":
			return str(args[0])
		"buy_spell":
			return str(shop_size + CoreUtil.to_int(args[0]))
		"play":
			return "%s %s" % [args[0], _label(args[1])]
		"play_item":
			var slot: int = args[1]
			var number: int = hand_size + CoreUtil.to_int(args[0])
			var items: Array = state["hand_items"]
			if PlayGame.aims_shop(items, CoreUtil.to_int(args[0])):
				return "%d %d" % [number, slot]
			return str(number) if slot < 0 else "%d %s" % [number, _label(slot)]
		"sell":
			return _label(args[0])
		"move":
			return "%s %s" % [_label(args[0]), _label(args[1])]
		"swallow":
			return _swallow_words(args)
		"use_power":
			return "" if CoreUtil.to_int(args[0]) < 0 else _label(args[0])
	return ""


## A listed swallow as tools/play types it: "2 F1" from the shop, "h0 F1", "B2 F1".
static func _swallow_words(args: Array) -> String:
	var index: int = CoreUtil.to_int(args[1])
	match str(args[0]):
		HeldUnits.SHOP:
			return "%d %s" % [index, _label(args[2])]
		HeldUnits.HAND:
			return "h%d %s" % [index, _label(args[2])]
	return "%s %s" % [_label(index), _label(args[2])]


## The command word the player types, with its options, short: moves and plays are folded.
static func _group(word: String, options: PackedStringArray) -> String:
	var command: String = (
		{
			"buy_spell": "buy",
			"play_item": "play",
			"use_power": "power",
			"tier_up": "tier",
			"toggle_freeze": "freeze",
			"end_turn": "end",
		}
		. get(word, word)
	)
	match word:
		"move":
			return "move <unit slot> <any slot>"
		"play":
			return "play " + _fold_first(options)
	if options.size() == 1 and options[0] == "":
		return command
	return "%s %s" % [command, ", ".join(options)]


## "0 F1, 0 F2, 1 F1" as "0 F1/F2, 1 F1".
static func _fold_first(options: PackedStringArray) -> String:
	var first_words: PackedStringArray = []
	var seconds: Dictionary = {}
	for option: String in options:
		var parts: PackedStringArray = option.split(" ")
		if not seconds.has(parts[0]):
			first_words.append(parts[0])
			seconds[parts[0]] = PackedStringArray()
		var list: PackedStringArray = seconds[parts[0]]
		if parts.size() > 1:
			list.append(parts[1])
		seconds[parts[0]] = list
	var out: PackedStringArray = []
	for word: String in first_words:
		var list: PackedStringArray = seconds[word]
		out.append(("%s %s" % [word, "/".join(list)]).strip_edges())
	return ", ".join(out)


static func _label(slot: Variant) -> String:
	return BoardGeometry.LABELS[CoreUtil.to_int(slot)]


static func _joined(values: Variant, when_empty: String) -> String:
	var list: Array = values
	if list.is_empty():
		return when_empty
	return ", ".join(PackedStringArray(list))


static func how_to_play() -> String:
	var lines: PackedStringArray = ["HOW TO PLAY"]
	for page: Dictionary in Guide.PAGES:
		lines.append("\n%s\n%s" % [page["title"], page["text"]])
	lines.append("\nWORDS ON CARDS")
	for word: String in KeywordRules.HELP_WORDS:
		lines.append("%s: %s" % [word, KeywordRules.text(word)])
	lines.append("Pass: " + KeywordRules.text("Pass"))
	return "\n".join(lines)
