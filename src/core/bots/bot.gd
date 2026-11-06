class_name Bot
extends RefCounted
## The bot policy of SPEC section 8. Bots play the same Recruit Phase actions as the human
## through RecruitRules, on their own player state, with the player's own bot RNG.

const GREEDY: String = "greedy"
const WIDE: String = "wide"
const TRIBE: String = "tribe"
const BALANCED: String = "balanced"
const TIER_UP_TURNS: Dictionary = {
	"wide": [4, 7, 10],
	"tribe": [3, 5, 7, 9],
	"balanced": [3, 5, 7, 9, 11],
}
const MAX_REFRESHES: int = 3
const SWAP_MARGIN: int = 3
const SPELL_CHANCE: float = 0.5

var personality: String = BALANCED
## The tribe a tribe bot follows from turn 3 ("" until picked).
var favoured_tribe: String = ""
var _round: int = 1


## A level name makes a BotBrain ("hard", "hard:hedgerow_parish"); the older personalities stay
## for GameConfig.defaults() and the bare rules.
static func create(bot_personality: String) -> Bot:
	var brain: BotBrain = BotBrain.from_name(bot_personality)
	if brain != null:
		return brain
	var bot := Bot.new()
	bot.personality = bot_personality
	return bot


## One whole Recruit Phase of actions (not the start or end of the phase).
func play_turn(player: PlayerState, rules: RecruitRules, round_number: int) -> void:
	_round = round_number
	_pick_tribe(player, round_number)
	_tier_up(player, rules, round_number)
	_play_cards(player, rules)
	_buy_all(player, rules)
	var refreshes: int = 0
	while refreshes < MAX_REFRESHES and _wants_refresh(player, rules):
		if rules.refresh(player) != "":
			break
		refreshes += 1
		_resolve_choices(player, rules)
		_buy_all(player, rules)
	_play_all(player, rules)
	_buy_spells(player, rules)
	_play_cards(player, rules)
	_use_power(player, rules)
	_play_all(player, rules)
	_resolve_choices(player, rules)
	place(player)


## 2.2.1: naive: a random hero of the offer.
func pick_hero(offer: PackedStringArray, player: PlayerState) -> int:
	return player.bot_rng.randi_range(0, offer.size() - 1)


## Naive spell use: units come first, then a spell if gold is left over. Strong bots replace this.
func _buy_spells(player: PlayerState, rules: RecruitRules) -> void:
	_resolve_choices(player, rules)
	var index: int = player.shop_spells.size() - 1
	while index >= 0:
		var item: HandItem = player.shop_spells[index]
		if player.gold - item.cost() >= _reserve(player) and player.bot_rng.randf() < SPELL_CHANCE:
			rules.buy_spell(player, index)
		index -= 1


## Plays every card it can at once, aimed at its strongest unit.
func _play_cards(player: PlayerState, rules: RecruitRules) -> void:
	_resolve_choices(player, rules)
	var index: int = player.items.size() - 1
	while index >= 0 and index < player.items.size():
		var item: HandItem = player.items[index]
		var slot: int = _aim_slot(player, item.aim())
		rules.play_item(player, index, slot)
		_resolve_choices(player, rules)
		index -= 1


## Naive power use: whenever it can pay and has somewhere to aim.
func _use_power(player: PlayerState, rules: RecruitRules) -> void:
	var power: Dictionary = HeroRules.power_of(player.hero)
	if str(power.get("kind", "")) != HeroRules.ACTIVATED:
		return
	var cost: int = CoreUtil.to_int(power.get("cost", 0))
	if player.gold - cost >= _reserve(player):
		rules.use_power(player, _aim_slot(player, str(power.get("aim", HandItem.AIM_NONE))))
		_resolve_choices(player, rules)


func _aim_slot(player: PlayerState, aim: String) -> int:
	match aim:
		HandItem.AIM_UNIT:
			return _strongest_slot(player)
		HandItem.AIM_EMPTY_SLOT:
			return player.first_empty_slot()
		HandItem.AIM_ANY_SLOT:
			var slot: int = _strongest_slot(player)
			return slot if slot >= 0 else 0
	return -1


func _strongest_slot(player: PlayerState) -> int:
	var best: int = -1
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null:
			continue
		if best < 0 or unit_score(unit) > unit_score(player.board[best]):
			best = slot
	return best


## Takes the highest-scoring option of every waiting Discover.
func _resolve_choices(player: PlayerState, rules: RecruitRules) -> void:
	while player.is_choosing():
		var options: PackedStringArray = player.pending[0]["options"]
		var best: int = 0
		var best_score: int = -1
		for index: int in options.size():
			var unit_def: Dictionary = rules.library.get_unit(options[index])
			if unit_def.is_empty():
				continue
			var score: int = (
				10 * CoreUtil.to_int(unit_def["tier"])
				+ CoreUtil.to_int(unit_def["attack"])
				+ CoreUtil.to_int(unit_def["health"])
			)
			if score > best_score:
				best = index
				best_score = score
		rules.choose(player, best)


## Step 1.
func _tier_up(player: PlayerState, rules: RecruitRules, round_number: int) -> void:
	if personality == GREEDY:
		while round_number >= 2 and player.tier < UnitLibrary.TIERS:
			if rules.tier_up(player) != "":
				return
		return
	var turns: Array = TIER_UP_TURNS.get(personality, [])
	if turns.has(round_number):
		rules.tier_up(player)


## Step 2: buy the best-scoring unit while gold is above the reserve and the hand has room.
## Prototype pick: with no room left on the board, only a unit that would be swapped in (step 4)
## is bought, so a bot's hand doesn't fill with units it never plays.
func _buy_all(player: PlayerState, rules: RecruitRules) -> void:
	var cost: int = rules.config.get_int("unit_cost")
	while not player.shop.is_empty() and player.gold - cost >= _reserve(player):
		var best: int = _best_shop_index(player)
		var unit: RecruitUnit = player.shop[best]
		var room: int = BoardGeometry.SLOTS - player.board_count() - player.hand.size()
		if room <= 0 and buy_score(player, unit) <= _lowest_board_score(player) + SWAP_MARGIN:
			return
		if rules.buy(player, best) != "":
			return


## Step 3: refresh when nothing in the shop beats the weakest board unit.
func _wants_refresh(player: PlayerState, rules: RecruitRules) -> bool:
	if player.gold - rules.refresh_cost(player) <= _reserve(player):
		return false
	var lowest: int = _lowest_board_score(player)
	for unit: RecruitUnit in player.shop:
		if buy_score(player, unit) > lowest:
			return false
	return true


## Step 4: play every hand unit; on a full board, swap out the weakest when the new one is
## more than 3 better.
func _play_all(player: PlayerState, rules: RecruitRules) -> void:
	var index: int = 0
	while index < player.hand.size():
		var unit: RecruitUnit = player.hand[index]
		var slot: int = player.first_empty_slot()
		if slot < 0:
			var weakest: int = _weakest_sellable_slot(player)
			if weakest < 0 or unit_score(unit) <= unit_score(player.board[weakest]) + SWAP_MARGIN:
				index += 1
				continue
			rules.sell(player, weakest)
			slot = weakest
		if rules.play(player, index, slot) != "":
			index += 1
		_resolve_choices(player, rules)


## Step 5: re-place the whole board. Back-row hints go to the back, others to the front; Both
## Ends units take the row's ends; Sett Warden takes F2 or F3; the highest-Health front units
## take F2 and F3. Overflow goes to the other row.
func place(player: PlayerState) -> void:
	var units: Array[RecruitUnit] = []
	for unit: RecruitUnit in player.board:
		if unit != null:
			units.append(unit)
	_shuffle(units, player.bot_rng)
	units.sort_custom(func(a: RecruitUnit, b: RecruitUnit) -> bool: return a.health > b.health)
	var front: Array[RecruitUnit] = []
	var back: Array[RecruitUnit] = []
	for unit: RecruitUnit in units:
		if unit.row_hint() == "back":
			back.append(unit)
		else:
			front.append(unit)
	while front.size() > BoardGeometry.FRONT.size():
		var to_back: RecruitUnit = front.pop_back()
		back.append(to_back)
	while back.size() > BoardGeometry.BACK.size():
		var to_front: RecruitUnit = back.pop_back()
		front.append(to_front)
	var board: Array[RecruitUnit] = []
	board.resize(BoardGeometry.SLOTS)
	_fill_row(board, front, [0, 3], [1, 2], [1, 2, 0, 3])
	_fill_row(board, back, [4, 6], [], [4, 5, 6])
	player.board = board


func _fill_row(
	board: Array[RecruitUnit],
	units: Array[RecruitUnit],
	ends: Array[int],
	centre: Array[int],
	order: Array[int]
) -> void:
	var rest: Array[RecruitUnit] = []
	for unit: RecruitUnit in units:
		var wanted: Array[int] = []
		if _has_mechanic(unit, "both_ends"):
			wanted = ends
		elif unit.def_id() == "sett_warden":
			wanted = centre
		var placed: bool = false
		for slot: int in wanted:
			if board[slot] == null:
				board[slot] = unit
				placed = true
				break
		if not placed:
			rest.append(unit)
	for unit: RecruitUnit in rest:
		for slot: int in order:
			if board[slot] == null:
				board[slot] = unit
				break


## 10 × tier + Attack + Health, plus the buying bonuses of section 8.
func buy_score(player: PlayerState, unit: RecruitUnit) -> int:
	var score: int = unit_score(unit)
	if _copies_owned(player, unit.def_id()) >= 2:
		score += 15
	if favoured_tribe != "" and unit.tribes().has(favoured_tribe):
		score += 12
	if _row_fits(player, unit):
		score += 4
	if personality == WIDE and unit.tier() <= 2 and player.first_empty_slot() >= 0:
		score += 6
	return score


static func unit_score(unit: RecruitUnit) -> int:
	return 10 * unit.tier() + unit.attack + unit.health


func _reserve(player: PlayerState) -> int:
	if personality == BALANCED:
		return 0 if _round <= 1 else 2
	if personality == GREEDY and player.tier < UnitLibrary.TIERS:
		var short: int = player.upgrade_cost - player.gold
		if short > 0 and short <= 3:
			return player.gold
	return 0


func _best_shop_index(player: PlayerState) -> int:
	var best: int = 0
	var best_score: int = -1
	for index: int in player.shop.size():
		var score: int = buy_score(player, player.shop[index])
		if score > best_score:
			best = index
			best_score = score
	return best


func _lowest_board_score(player: PlayerState) -> int:
	var lowest: int = -1
	for unit: RecruitUnit in player.board:
		if unit != null and (lowest < 0 or unit_score(unit) < lowest):
			lowest = unit_score(unit)
	return lowest


## The weakest board unit the bot may sell (a tribe bot never sells its tribe); -1 if none.
func _weakest_sellable_slot(player: PlayerState) -> int:
	var weakest: int = -1
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or (favoured_tribe != "" and unit.tribes().has(favoured_tribe)):
			continue
		if weakest < 0 or unit_score(unit) < unit_score(player.board[weakest]):
			weakest = slot
	return weakest


## Tribe bots pick, from turn 3, the tribe they have most of (ties by RNG).
func _pick_tribe(player: PlayerState, round_number: int) -> void:
	if personality != TRIBE or round_number < 3 or favoured_tribe != "":
		return
	var counts: Dictionary = {}
	for unit: RecruitUnit in player.owned_units():
		for tribe: Variant in unit.tribes():
			counts[tribe] = CoreUtil.to_int(counts.get(tribe, 0)) + 1
	if counts.is_empty():
		return
	var top: int = 0
	for tribe: Variant in counts:
		top = maxi(top, CoreUtil.to_int(counts[tribe]))
	var tied: Array[String] = []
	for tribe: Variant in counts:
		if CoreUtil.to_int(counts[tribe]) == top:
			tied.append(str(tribe))
	tied.sort()
	favoured_tribe = tied[player.bot_rng.randi_range(0, tied.size() - 1)]


func _row_fits(player: PlayerState, unit: RecruitUnit) -> bool:
	var slots: Array[int] = BoardGeometry.BACK if unit.row_hint() == "back" else BoardGeometry.FRONT
	for slot: int in slots:
		if player.board[slot] == null:
			return true
	return false


static func _copies_owned(player: PlayerState, def_id: String) -> int:
	var count: int = 0
	for unit: RecruitUnit in player.owned_units():
		if unit.def_id() == def_id and not unit.golden:
			count += 1
	return count


static func _has_mechanic(unit: RecruitUnit, mechanic_id: String) -> bool:
	var mechanics: Array = unit.def["mechanics"]
	for mechanic: Variant in mechanics:
		var entry: Dictionary = mechanic
		if str(entry.get("id", "")) == mechanic_id:
			return true
	return false


## Fisher-Yates with the bot's RNG (never the global one).
static func _shuffle(units: Array[RecruitUnit], rng: RandomNumberGenerator) -> void:
	for i: int in range(units.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: RecruitUnit = units[i]
		units[i] = units[j]
		units[j] = swap
