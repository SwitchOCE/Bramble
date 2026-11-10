class_name LineBrain
extends BotBrain
## Hard's legal actions, text values, heroes, Bellies and economy, with a fixed scripted line.
## Blind placement is deliberate: each captured layout is fixed independently of the field.

var line_id: String = "line_fast"
var profile: Dictionary = {}
var fallback_from: String = ""
## These belong to the original seat and deliberately survive configure_line switches.
var starting_line: String = ""
var banned_cards: PackedStringArray = []
var ban_failure: String = ""
var banned_plays: PackedStringArray = []
var banned_acquisitions: PackedStringArray = []
var _previous_log_observer: Callable


func configure_line(id: String) -> void:
	if starting_line.is_empty():
		starting_line = id
	line_id = id
	var entry: Dictionary = LinePolicies.profiles()[id]
	profile = entry.duplicate(true)
	pinned_strategy = id
	value.strategy = LinePolicies.strategy(id)
	var engine_pieces: Array = profile.get("engine_pieces", [])
	value.strategy["line_engine_pieces"] = engine_pieces.duplicate()
	level.set_place(BotLevel.PLACE_BLIND)


func play_turn(player: PlayerState, rules: RecruitRules, round_number: int) -> void:
	BotHedgerow.remember_scout(player, rules, value)
	var switch: Dictionary = profile.get("switch_to", {})
	if not switch.is_empty() and round_number >= CoreUtil.to_int(switch["round"]):
		configure_line("line_" + str(switch["line"]))
	var tribe: String = str(profile["tribe"])
	if tribe != "" and not rules.lobby_tribes.is_empty() and not rules.lobby_tribes.has(tribe):
		fallback_from = line_id
		configure_line("line_fast")
	if banned_cards.is_empty():
		super.play_turn(player, rules, round_number)
		return
	if player.log_observer == _observe_banned_play:
		if ban_audit(player)["failure"] == "":
			super.play_turn(player, rules, round_number)
		return
	_previous_log_observer = player.log_observer
	player.log_observer = _observe_banned_play
	if ban_audit(player)["failure"] == "":
		super.play_turn(player, rules, round_number)
	player.log_observer = _previous_log_observer
	_previous_log_observer = Callable()


func _choose_build() -> void:
	# Committed from the start; Hard still reads live text, spells and reachable purchases.
	pass


func _open_with_a_plan() -> void:
	if BotHedgerow.first_partner_offer(self):
		_opening_plan = "tempo"
		return
	_opening_plan = "economy" if CoreUtil.to_bool(profile["engine"]) else "tempo"
	super._open_with_a_plan()


func _target_round(tier: int) -> int:
	var schedule: Array = profile["climb_schedule"]
	return CoreUtil.to_int(schedule[clampi(tier - 1, 0, schedule.size() - 1)])


func _climb(leftover: bool) -> void:
	# The shared brain's leftover climb is one round early. A line follows its stated schedule.
	if not leftover:
		super._climb(false)


func _held_back() -> int:
	if BotHedgerow.build(value):
		return BotHedgerow.climb_reserve(self)
	var reserve: int = super._held_back()
	if str(profile["tribe"]) == "Oozes":
		if (
			_player.tier < UnitLibrary.TIERS
			and _round_now <= CoreUtil.to_int(profile["save_until"])
			and _round_now + 1 == _target_round(_player.tier)
		):
			return maxi(reserve, CoreUtil.to_int(profile["save_threshold"]))
		return reserve
	if (
		CoreUtil.to_bool(profile["engine"])
		and _round_now <= CoreUtil.to_int(profile["save_until"])
		and _player.board_count() >= 3
		and _player.health > LOW_HEALTH
	):
		reserve = maxi(reserve, CoreUtil.to_int(profile["save_threshold"]))
	return reserve


func configure_banned_cards(cards: Array, player: PlayerState = null) -> void:
	banned_cards = PackedStringArray(cards)
	if player != null and not banned_cards.is_empty():
		_previous_log_observer = player.log_observer
		player.log_observer = _observe_banned_play


func is_banned(card: String) -> bool:
	return banned_cards.has(card)


## A forced grant cannot be discarded legally. Mark the run invalid instead of editing rules.
func ban_audit(player: PlayerState) -> Dictionary:
	var owned: PackedStringArray = []
	for unit: RecruitUnit in player.all_units():
		_audit_unit(unit, owned)
	if not owned.is_empty() and ban_failure.is_empty():
		ban_failure = "banned owned card: " + ", ".join(owned)
	return {
		"starting_line": starting_line,
		"banned_cards": Array(banned_cards),
		"owned_banned": Array(owned),
		"played_banned": Array(banned_plays),
		"acquired_banned": Array(banned_acquisitions),
		"failure": ban_failure,
	}


func _audit_unit(unit: RecruitUnit, owned: PackedStringArray) -> void:
	if is_banned(unit.def_id()) and not owned.has(unit.def_id()):
		owned.append(unit.def_id())
	for held: RecruitUnit in unit.held:
		_audit_unit(held, owned)


func _observe_banned_play(type: String, fields: Dictionary) -> void:
	var card: String = str(fields.get("unit", fields.get("card", "")))
	if type == "play" and is_banned(card):
		banned_plays.append(card)
		ban_failure = "banned card played: " + card
	if type in ["buy", "swallow", "card", "chose", "summon", "triple"] and is_banned(card):
		if not banned_acquisitions.has(card):
			banned_acquisitions.append(card)
		ban_failure = "banned card acquired via " + type + ": " + card
	if _previous_log_observer.is_valid():
		_previous_log_observer.call(type, fields)


func _unit_gain(unit: RecruitUnit) -> float:
	return 0.0 if is_banned(unit.def_id()) or not ban_failure.is_empty() else super._unit_gain(unit)


func _buy_unit(index: int) -> String:
	if not ban_failure.is_empty() or is_banned(_player.shop[index].def_id()):
		return "Line policy forbids this card"
	return super._buy_unit(index)


func _play_hand() -> void:
	if banned_cards.is_empty() or ban_audit(_player)["failure"] == "":
		super._play_hand()


func _best_option(options: PackedStringArray, spells: bool) -> int:
	if banned_cards.is_empty() or spells:
		return super._best_option(options, spells)
	var allowed: PackedStringArray = []
	var indexes: Array[int] = []
	for index: int in options.size():
		if not is_banned(options[index]):
			allowed.append(options[index])
			indexes.append(index)
	if allowed.is_empty():
		ban_failure = "forced choice has no unbanned option: " + ", ".join(options)
		return -1
	return indexes[super._best_option(allowed, false)]


func _settle() -> void:
	if banned_cards.is_empty():
		super._settle()
		return
	for _step: int in MAX_STEPS:
		if ban_audit(_player)["failure"] != "" or not _player.is_choosing():
			return
		var choice: Dictionary = _player.pending[0]
		var options: PackedStringArray = choice["options"]
		# Native empty choices resolve without receiving a card.
		var pick: int = (
			0 if options.is_empty() else _best_option(options, CoreUtil.to_bool(choice["spells"]))
		)
		if pick < 0:
			return
		if _rules.choose(_player, pick) != "":
			ban_failure = "could not resolve line choice"
			return


func _best_offer() -> Dictionary:
	return {} if not ban_failure.is_empty() else super._best_offer()


func _refresh_worth_it() -> bool:
	return ban_failure.is_empty() and BotHedgerow.can_refresh(self) and super._refresh_worth_it()


func _spending_allowed(cost: int, card_def: Dictionary = {}) -> bool:
	return BotHedgerow.spending_allowed(self, cost, card_def)


func _belly_for(unit: RecruitUnit) -> int:
	if BotHedgerow.needs_board(self, unit):
		return -1
	return super._belly_for(unit)


func _shop_loop() -> void:
	var normal: int = level.max_refreshes
	if BotHedgerow.build(value):
		level.max_refreshes = MAX_STEPS
	super._shop_loop()
	level.max_refreshes = normal


func _arrange() -> void:
	super._arrange()
	BotHedgerow.sergeant_cash(self)
	if _player.has_meta(BotHedgerow.SCOUT_META):
		_player.remove_meta(BotHedgerow.SCOUT_META)
