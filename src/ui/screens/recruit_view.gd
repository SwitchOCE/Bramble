extends RefCounted
## What the recruit screen reads out of a state, without any nodes: spells merged in with the units,
## aiming rules, hero cards, and the "then fight" note.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")

## The line a Pass travels along, F1-B1-F2-B2-F3-B3-F4 (docs/ideation/content/SLICE.md).
const ZIGZAG: Array[int] = [0, 4, 1, 5, 2, 6, 3]
const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
const FRONT_SLOTS: int = 4
const GHOST_ID: int = -1
## The longest name End turn's second line has room for.
const NOTE_NAME: int = 13


## The state as this screen shows it: spells on the shelf after the units, and spells and items in
## the hand after the units. Each keeps its index in the list the port wants back.
static func with_cards(raw: Dictionary) -> Dictionary:
	var merged: Dictionary = raw.duplicate()
	merged["shop"] = _tagged(raw, "shop", "shop_spells")
	merged["hand"] = _tagged(raw, "hand", "hand_items")
	return merged


static func _tagged(raw: Dictionary, units_key: String, cards_key: String) -> Array:
	var out: Array = Data.a(raw, units_key).duplicate()
	var cards: Array = Data.a(raw, cards_key)
	for i: int in cards.size():
		var source: Dictionary = cards[i]
		var card: Dictionary = source.duplicate()
		card["card_index"] = i
		out.append(card)
	return out


## Whether a spell or power with this aim can land on a board slot. Slot -1 skips the row check.
static func aim_fits(aim: String, has_unit: bool, slot: int = -1) -> bool:
	match aim:
		"unit", "tribe_unit":
			return has_unit
		"front_unit":
			return has_unit and (slot < 0 or slot < FRONT_SLOTS)
		"back_unit":
			return has_unit and (slot < 0 or slot >= FRONT_SLOTS)
		"empty_slot":
			return not has_unit
		"shop_unit", "none":
			return false
	return true


## Whether a hand spell or item can be played onto this board slot: its aim fits, or it is an Acorn
## item and the unit there eats them (`eats_items`).
static func item_lands(item: Dictionary, target: Dictionary, slot: int) -> bool:
	if Data.s(item, "aim") == "tribe_unit" and Data.a(target, "tribes").is_empty():
		return false
	if aim_fits(Data.s(item, "aim", "none"), not target.is_empty(), slot):
		return true
	return Data.i(item, "gold_value", 0) > 0 and Data.b(target, "eats_items", false)


## Why this spell or item can't be aimed anywhere right now; "" if it can, or needs no aim.
static func no_target_note(view: Dictionary, item: Dictionary) -> String:
	if Data.s(item, "def_id") == "harvest_supper" and Data.b(view, "harvest_supper_used"):
		return "Harvest Supper was already cast this turn."
	var aim: String = Data.s(item, "aim", "none")
	if aim == "none":
		return ""
	if aim == "shop_unit":
		for entry: Variant in Data.a(view, "shop"):
			var offer: Dictionary = entry
			if Data.s(offer, "kind") == "":
				return ""
		return "No unit in the shop to aim this at."
	var board: Array = Data.a(view, "board")
	for slot: int in board.size():
		var target: Dictionary = board[slot] if board[slot] is Dictionary else {}
		if item_lands(item, target, slot):
			return ""
	match aim:
		"tribe_unit":
			return "Needs a unit with a tribe."
		"front_unit":
			return "Needs a unit in your front row."
		"back_unit":
			return "Needs a unit in your back row."
		"empty_slot":
			return "Needs an empty slot."
	return "Needs a unit on your board."


## Hero offers as cards for the picker.
static func hero_cards(options: Array) -> Array:
	var cards: Array = []
	for entry: Variant in options:
		var hero: Dictionary = entry
		cards.append(hero_card(hero))
	return cards


static func hero_card(hero: Dictionary) -> Dictionary:
	return {
		"def_id": Data.s(hero, "id"),
		"name": Data.s(hero, "name"),
		"kind": "spell",
		"type_word": "Hero",
		"text": Data.s(hero, "text"),
		"cost": Data.i(hero, "cost", 0),
		"tribes": [],
	}


## "then fight Old Tansy" or "then fight a ghost"; "" when the next opponent isn't known.
static func fight_note(view: Dictionary) -> String:
	if Data.i(view, "round_toll") > 0:
		var cap: int = Data.i(view, "damage_cap")
		var note: String = "Toll %d" % Data.i(view, "round_toll")
		return note + (", cap %d" % cap if cap > 0 else "")
	if is_ghost_next(view):
		return "then fight a ghost"
	var opponent: String = next_name(view)
	var words: PackedStringArray = opponent.split(" ", false)
	while " ".join(words).length() > NOTE_NAME and words.size() > 1:
		words = words.slice(1)
	return "" if words.is_empty() else "then fight %s" % " ".join(words)


## A ghost needs someone out. Before the first pairing (the hero offer) the id reads the same.
static func is_ghost_next(view: Dictionary) -> bool:
	return Data.i(view, "next_opponent_id", -2) == GHOST_ID and not ghost_owner(view).is_empty()


## The next opponent's name, for the scouting panel and the fight. "" if unknown.
static func next_name(view: Dictionary) -> String:
	var next_id: int = Data.i(view, "next_opponent_id", -2)
	if next_id == GHOST_ID:
		var owner: Dictionary = ghost_owner(view)
		return "" if owner.is_empty() else "Ghost of %s" % UiTheme.player_name(owner)
	for entry: Variant in Data.a(view, "standings"):
		var standing: Dictionary = entry
		if Data.i(standing, "player_id", -3) == next_id:
			return UiTheme.player_name(standing)
	return ""


## Whose board the ghost is: the last player knocked out, who holds the best place among the out.
static func ghost_owner(view: Dictionary) -> Dictionary:
	var owner: Dictionary = {}
	var best: int = 99
	for entry: Variant in Data.a(view, "standings"):
		var standing: Dictionary = entry
		var placement: Variant = standing.get("placement")
		if Data.b(standing, "alive", true) or placement == null:
			continue
		if Data.as_int(placement) < best:
			best = Data.as_int(placement)
			owner = standing
	return owner


## The card that says what a ghost is.
static func ghost_card(view: Dictionary) -> Dictionary:
	var owner: Dictionary = ghost_owner(view)
	var whose: String = "the last player knocked out"
	if not owner.is_empty():
		whose = UiTheme.player_name(owner)
	return {
		"name": "A ghost",
		"kind": "spell",
		"type_word": "Next fight",
		"text":
		"The last board of %s. It has no Health; if it wins, you still lose Health." % whose,
		"tribes": [],
	}


## The opponent's card for the scouting panel's Who? token: their hero, or what a ghost is.
static func opponent_card(view: Dictionary) -> Dictionary:
	if is_ghost_next(view):
		return ghost_card(view)
	var hero: Dictionary = Data.d(view, "next_opponent_hero")
	return {} if hero.is_empty() else hero_card(hero)


## What a Hex, a turn count or a Cold Frame says on the slip beside a tile. See turns_word.
static func tile_slip(unit: Dictionary) -> String:
	if unit.has("next_acorn"):
		return (
			Data
			. s(unit, "next_acorn")
			. replace("Next Acorn: ", "")
			. replace(" gold", "g")
			. replace(" damage", "")
			. replace("No Acorn to throw", "No ammo")
		)
	var hex: int = Data.i(unit, "hex_amount", Data.i(Data.d(unit, "counters"), "hex", 0))
	if hex > 0:
		return "Hex %d" % hex
	var turns: String = turns_word(unit)
	return turns if not turns.is_empty() else RecruitHeld.belly_slip(unit)


## Non-golden copies of this card you own, so what buying one more would do.
static func triple_warning(view: Dictionary, shop_card: Dictionary) -> String:
	if Data.s(shop_card, "kind") in ["spell", "item"]:
		return ""
	var def_id: String = Data.s(shop_card, "def_id")
	if Data.i(copies(view), def_id, 0) < 2:
		return ""
	var note: String = "Buying this makes a golden %s. " % Data.s(shop_card, "name")
	if _copy_is_waiting(view, def_id):
		note += "Waits start over. "
	return note + "Play it for a Triple Reward."


static func _copy_is_waiting(view: Dictionary, def_id: String) -> bool:
	for entry: Variant in Data.a(view, "board"):
		if entry is Dictionary:
			var unit: Dictionary = entry
			if Data.s(unit, "def_id") != def_id or Data.b(unit, "golden", false):
				continue
			var counting: bool = (
				Data.i(unit, "turns_goal", 0) > 0 and Data.i(unit, "turns_in_slot", 0) > 0
			)
			if counting or not Data.a(unit, "timers").is_empty():
				return true
	return false


## 1 for "Pass right", -1 for "Pass left", 0 for a card with no Pass.
static func pass_direction(view: Dictionary) -> int:
	var text: String = Data.s(view, "text")
	if text.contains("Pass right"):
		return 1
	return -1 if text.contains("Pass left") else 0


## The unit a Pass from `slot` ends on: along the zigzag through touching units, and the last one
## keeps it. -1 when the next place along is empty, so a gap is a real cost.
static func pass_landing(board: Array, slot: int, direction: int) -> int:
	var at: int = ZIGZAG.find(slot) + direction
	var landing: int = -1
	while at >= 0 and at < ZIGZAG.size() and board[ZIGZAG[at]] is Dictionary:
		landing = ZIGZAG[at]
		at += direction
	return landing


## Where a card's Pass lands if it goes to `target` (-1: it leaves, and the Pass starts from
## from_slot, the slot it left). -1 when it has no Pass or nobody to land on.
static func pass_preview(board: Array, card: Dictionary, from_slot: int, target: int) -> int:
	var direction: int = pass_direction(card)
	if direction == 0 or board.size() < ZIGZAG.size():
		return -1
	var after: Array = board.duplicate()
	if from_slot >= 0:
		after[from_slot] = after[target] if target >= 0 else null
	if target >= 0:
		after[target] = card
	return pass_landing(after, target if target >= 0 else from_slot, direction)


## One entry per slot from the state: slot_effects (a Ring is one entry, its numbers stacked) and
## bands (one bool a slot).
static func slot_marks(view: Dictionary) -> Array:
	return RecruitHeld.with_nests(_ring_marks(view), Data.a(view, "away"))


static func _ring_marks(view: Dictionary) -> Array:
	var effects: Array = Data.a(view, "slot_effects")
	var bands: Array = Data.a(view, "bands")
	var out: Array = []
	for slot: int in SLOT_NAMES.size():
		var entries: Array = effects[slot] if slot < effects.size() else []
		var attack: int = 0
		var health: int = 0
		var band: bool = slot < bands.size() and bands[slot] == true
		var mark: Dictionary = {"ring": "", "has_ring": false, "band": band, "text": ""}
		for entry: Variant in entries:
			var effect: Dictionary = entry
			if Data.s(effect, "name") == "Horseshoe":
				mark["horseshoe"] = true
			else:
				mark["has_ring"] = true
			attack += Data.i(effect, "attack", 0)
			health += Data.i(effect, "health", 0)
			var line: String = Data.s(effect, "text")
			if not line.is_empty():
				mark["text"] = (str(mark["text"]) + " " + line).strip_edges()
		mark["slot_attack"] = attack
		mark["slot_health"] = health
		if attack != 0 or health != 0:
			mark["ring"] = "%+d/%+d" % [attack, health]
		out.append(mark)
	return out


## What the slip on a tile says about turns: "2/3" for a card that counts them, "2 left" for a Cold
## Frame's timer, "" for neither.
static func turns_word(unit: Dictionary) -> String:
	var goal: int = Data.i(unit, "turns_goal", 0)
	if goal > 0:
		return "%d/%d" % [mini(Data.i(unit, "turns_in_slot", 0), goal), goal]
	var timers: Array = Data.a(unit, "timers")
	return "" if timers.is_empty() else "%d left" % Data.i(Data.entry(timers, 0), "left", 0)


## The unit's view with what its slot gives and how long it has stood there, for the full text.
static func with_slot_note(unit: Dictionary, mark: Dictionary, slot: int) -> Dictionary:
	var view: Dictionary = RecruitHeld.with_inside(unit).duplicate()
	var lines: PackedStringArray = [Data.s(view, "text")]
	var note: String = slot_note(mark, slot)
	if not note.is_empty():
		lines.append(note)
	var goal: int = Data.i(view, "turns_goal", 0)
	if goal > 0:
		lines.append("In this slot for %d of %d turns." % [Data.i(view, "turns_in_slot", 0), goal])
	for entry: Variant in Data.a(view, "timers"):
		var timer: Dictionary = entry
		lines.append(
			(
				"%+d/%+d in %d turns if it stays."
				% [Data.i(timer, "attack", 0), Data.i(timer, "health", 0), Data.i(timer, "left", 0)]
			)
		)
	view["text"] = "\n".join(lines).strip_edges()
	return view


## A hand unit's text, and what playing it will do: a golden fresh from a triple brings the reward.
static func with_reward_note(unit: Dictionary) -> Dictionary:
	if not Data.b(unit, "reward_pending", false):
		return unit
	var view: Dictionary = unit.duplicate()
	var rules: String = Data.s(view, "text")
	var note: String = "Play this for a Triple Reward: Discover from the tier above."
	view["text"] = ("%s\n%s" % [rules, note]).strip_edges()
	return view


## What lies on a slot in words; "" for a bare slot.
static func slot_note(mark: Dictionary, slot: int) -> String:
	var nest: String = RecruitHeld.nest_note(mark)
	var parts: PackedStringArray = []
	if mark.get("has_ring", false) == true:
		parts.append(("Ring %s" % str(mark.get("ring", ""))).strip_edges())
	if mark.get("horseshoe", false) == true:
		parts.append("Horseshoe (next fight)")
	if mark.get("band", false) == true:
		parts.append("Rainbow band")
	if parts.is_empty():
		return "%s: %s" % [SLOT_NAMES[slot], nest] if not nest.is_empty() else ""
	var note: String = "%s: %s." % [SLOT_NAMES[slot], ", ".join(parts)]
	var extra: String = str(mark.get("text", ""))
	note = note if extra.is_empty() else "%s %s" % [note, extra]
	return note if nest.is_empty() else "%s %s" % [note, nest]


## Non-golden copies owned (hand and board) per def_id.
static func copies(from_state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for zone: String in ["hand", "board"]:
		for entry: Variant in Data.a(from_state, zone):
			if entry is Dictionary:
				var view: Dictionary = entry
				_count_copy(view, out)
				for inside: Variant in Data.a(view, "held"):
					var held: Dictionary = inside
					_count_copy(held, out)
	return out


## Copies inside a Belly count for triples too.
static func _count_copy(entry: Dictionary, into: Dictionary) -> void:
	if not Data.b(entry, "golden", false) and not Data.b(entry, "plain_copy", false):
		var def_id: String = Data.s(entry, "def_id")
		into[def_id] = Data.i(into, def_id, 0) + 1


## Every slot's Ring, as words: it changes when a Ring lands or grows.
static func ring_words(view: Dictionary) -> String:
	var words: String = ""
	for mark: Dictionary in slot_marks(view):
		words += "%s," % str(mark.get("ring", ""))
	return words


## "Three Acorns made a Stash." when a hand item's next size just arrived and the smaller ones went.
static func combine_note(before: Dictionary, after: Dictionary) -> String:
	for entry: Variant in Data.a(before, "hand"):
		var small: Dictionary = entry
		var big_id: String = Data.s(small, "combines_into")
		if big_id.is_empty():
			continue
		var small_id: String = Data.s(small, "def_id")
		var grew: bool = _held(after, big_id) > _held(before, big_id)
		if grew and _held(after, small_id) < _held(before, small_id):
			return "Three %s made a %s." % [_plural(Data.s(small, "name")), _name_of(after, big_id)]
	return ""


static func _plural(word: String) -> String:
	return word + ("es" if word.ends_with("sh") else "s")


static func _name_of(view: Dictionary, def_id: String) -> String:
	for entry: Variant in Data.a(view, "hand"):
		var item: Dictionary = entry
		if Data.s(item, "def_id") == def_id:
			return Data.s(item, "name")
	return def_id.capitalize()


static func _held(view: Dictionary, def_id: String) -> int:
	var count: int = 0
	for entry: Variant in Data.a(view, "hand"):
		var item: Dictionary = entry
		count += 1 if Data.s(item, "def_id") == def_id else 0
	return count


## Shop to board: buy, then play whatever the buy put in the hand. That is the bought unit
## (same iid), or, if the buy made a triple, the one new hand unit (the golden). Never assumes
## the hand's last slot.
static func buy_and_play(port: GamePort, shop_index: int, slot: int) -> String:
	var before: Dictionary = {}
	for entry: Variant in Data.a(port.get_state(), "hand"):
		var old: Dictionary = entry
		before[Data.i(old, "iid", -1)] = true
	var bought_iid: int = Data.i(
		Data.entry(Data.a(port.get_state(), "shop"), shop_index), "iid", -1
	)
	var reason: String = port.buy(shop_index)
	if not reason.is_empty():
		return reason
	var hand: Array = Data.a(port.get_state(), "hand")
	var new_index: int = -1
	var new_count: int = 0
	for i: int in hand.size():
		var iid: int = Data.i(Data.entry(hand, i), "iid", -1)
		if iid == bought_iid:
			return port.play(i, slot)
		if not before.has(iid):
			new_index = i
			new_count += 1
	if new_count == 1:
		return port.play(new_index, slot)
	return "Bought; it's in your hand"


## Explicit losses from automatic recruit effects, shared by the screen and CLI.
static func event_note(entry: Dictionary) -> String:
	match Data.s(entry, "type"):
		"discover_empty":
			return "Discover found no eligible cards."
		"poached":
			return "Poached %s from your last opponent." % Data.s(entry, "name")
		"poach_returned":
			return "%s returned to the pool when the turn ended." % Data.s(entry, "name")
		"kiss":
			return "A frog gets a kiss (%d/3)." % Data.i(entry, "count")
		"transform":
			return "The frog becomes %s." % Data.s(entry, "name")
		"walk_out":
			return (
				"%s walked out of %s (Shy): +%d gold next turn."
				% [
					Data.s(entry, "name"),
					SLOT_NAMES[Data.i(entry, "slot", 0)],
					Data.i(entry, "gold", 0)
				]
			)
		"nest_replaced":
			return (
				"New Nest replaces %s's at %s. The old bird still returns."
				% [Data.s(entry, "name"), SLOT_NAMES[Data.i(entry, "slot", 0)]]
			)
	return ""


static func change_notices(before: Dictionary, after: Dictionary) -> String:
	var notices: PackedStringArray = []
	var old_log: Array = Data.a(before, "recruit_log")
	var new_log: Array = Data.a(after, "recruit_log")
	var start: int = (
		old_log.size() if Data.i(before, "round", 0) == Data.i(after, "round", 0) else 0
	)
	for i: int in range(start, new_log.size()):
		var entry: Dictionary = new_log[i]
		var note: String = event_note(entry)
		if not note.is_empty():
			notices.append(note)
	if Data.i(after, "buys_left", -1) == 0 and Data.i(before, "buys_left", -1) != 0:
		notices.append("Pipkin's two unit buys are used.")
	return "\n".join(notices)


static func full_view(zone: String, view: Dictionary, state: Dictionary) -> Dictionary:
	if zone == "hand":
		view = with_reward_note(view)
	# Next income sits beside the gold (GoldPlaque), never in a card's rules.
	var notes: PackedStringArray = []
	if zone != "shop" and view.has("sell_value"):
		var flies: bool = (
			zone == "board" and RecruitHeld.sell_word(view, Data.i(state, "round")) == "Fly south"
		)
		notes.append(
			(
				"Fly south: 0 sale gold."
				if flies
				else "Sell value: %d gold." % Data.i(view, "sell_value")
			)
		)
	if zone == "shop" and Data.b(view, "poached"):
		notes.append("Poached. Costs %d gold; stays through refreshes." % Data.i(view, "cost"))
	if zone == "shop":
		var warning: String = triple_warning(state, view)
		if not warning.is_empty():
			notes.append(warning)
	if notes.is_empty():
		return view
	var full: Dictionary = view.duplicate()
	full["text"] = (Data.s(view, "text") + "\n" + "\n".join(notes)).strip_edges()
	return full


## The brick has two diagonals: name the actual slots rather than imply one column.
static func related_slots(card: Dictionary, slot: int) -> Array[int]:
	if not BoardGeometry.is_valid(slot):
		return []
	var words: String = Data.s(card, "text").to_lower()
	if "behind" in words:
		return BoardGeometry.behind(slot)
	if "in front" in words:
		return BoardGeometry.in_front_of(slot)
	if "next to this" in words or "next to a" in words:
		return BoardGeometry.neighbours(slot)
	if "beside this" in words or "beside it" in words:
		return BoardGeometry.adjacent(slot)
	return []


static func geometry_note(card: Dictionary, slot: int) -> String:
	var slots: Array[int] = related_slots(card, slot)
	if slots.is_empty():
		return "Pass lands at End of Turn." if pass_direction(card) != 0 else ""
	var labels: PackedStringArray = []
	for other: int in slots:
		labels.append(SLOT_NAMES[other])
	return "Highlighted: %s." % " and ".join(labels)


## Scheduled round income and already queued gold; later card/hero earnings can add more.
static func income_note(state: Dictionary) -> String:
	if not state.has("next_turn_income"):
		return ""
	var note: String = "Next income: +%d gold" % Data.i(state, "next_turn_income")
	if Data.i(state, "gold_next_turn") > 0:
		note += "; +%d queued" % Data.i(state, "gold_next_turn")
	return note + "."
