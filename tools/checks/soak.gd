extends SceneTree
## QA soak: plays bot-only full games on the full pool and checks rules invariants after every
## fight and every round. Crashes and rules bugs only; no balance numbers.
## Seeds take turns: seed % 3 == 0 plays GameConfig.defaults() on the old library; 1 plays the real
## game, full_game() with the slice's cards, half its players on SoakBot (random legal play), and
## reports which slice cards and keywords never fired (one such game in three hands out extra
## Acorns, since a game rarely reaches a Stash on its own); 2 plays spells and heroes with
## SoakContent, so every trigger, effect, Discover and slot effect comes up.
## Usage: godot --headless -s res://tools/checks/soak.gd -- [games=200] [first_seed=1] [plant=fault]
## A planted fault (SoakPlant) must turn the run red: tools/checks/soak_plant.sh proves each one.
## tools/checks/soak.sh wraps it and also fails on any ERROR / SCRIPT ERROR line in the log.
## Exit code 1 if any violation was found.

const MAX_TURNS: int = 60
const VALID_REASONS: PackedStringArray = [
	Combat.REASON_BOARD_EMPTY,
	Combat.REASON_NO_ATTACKS,
	Combat.REASON_ATTACK_LIMIT,
	Combat.REASON_TRIGGER_LIMIT,
]
## Events after which every unit still on the board must have Health above 0.
const SETTLED_EVENTS: PackedStringArray = ["attack", "pass", "skip", "whistle", "combat_end"]
## A fight that hits the attack limit is a real stall only if no unit died in this many of
## its last events.
const STALL_WINDOW: int = 400

var _library: UnitLibrary
var _plain_library: UnitLibrary
var _full_library: UnitLibrary
var _plant: String = ""
var _chaos_rng := RandomNumberGenerator.new()
## Coverage of the recruit side: how often each log type and each named effect happened.
var _recruit_log: Dictionary = {}
var _coverage := SoakCoverage.new()
## The game being played, for the hero of a player whose log line arrives. Cleared after each game.
var _session: GameSession = null
## Whether this game plays the slice, so its cards count toward coverage.
var _slice_game: bool = false
var _violations: Array[String] = []
var _limit_fights: Array[String] = []
var _game_seed: int = 0
var _fights: int = 0
var _max_events: int = 0
var _max_events_at: String = ""
var _reasons: Dictionary = {}
## Coverage: how often each mechanic fired (trigger events) and each event type appeared.
var _triggers: Dictionary = {}
var _event_types: Dictionary = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var games: int = 200 if args.size() < 1 else args[0].to_int()
	var first_seed: int = 1 if args.size() < 2 else args[1].to_int()
	_plant = "" if args.size() < 3 else args[2]
	BoardUpkeep.aura_observer = _coverage.note_aura
	_plain_library = UnitLibrary.load_dir()
	for problem: String in SoakCopyCheck.problems(_plain_library):
		_violation(0, problem)
	for problem: String in SoakBogCheck.problems(_plain_library):
		_violation(0, problem)
	for problem: String in SoakHunterCheck.problems(_plain_library):
		_violation(0, problem)
	print("soak: directed copy/text-transfer, bog and Hunter checks complete")
	_full_library = SoakContent.build()
	_library = _plain_library
	_check_golden_params()
	_library = _full_library
	_check_golden_params()
	var rounds: int = 0
	var slowest_ms: int = 0
	var started: int = Time.get_ticks_msec()
	for game_seed: int in range(first_seed, first_seed + games):
		var game_started: int = Time.get_ticks_msec()
		rounds += _play(game_seed)
		slowest_ms = maxi(slowest_ms, Time.get_ticks_msec() - game_started)
	var total_ms: int = Time.get_ticks_msec() - started
	if _fights == 0:
		_violation(0, "no fights ran")
	print("soak: games %d (seeds %d-%d)" % [games, first_seed, first_seed + games - 1])
	print("soak: rounds %d, fights %d, reasons %s" % [rounds, _fights, str(_reasons)])
	print("soak: max events per fight %d (%s)" % [_max_events, _max_events_at])
	print(
		(
			"soak: time %.1f s, %.0f ms per game, slowest %d ms"
			% [total_ms / 1000.0, float(total_ms) / maxi(1, games), slowest_ms]
		)
	)
	print("soak: triggers %s" % str(_sorted(_triggers)))
	print("soak: events %s" % str(_sorted(_event_types)))
	print("soak: recruit %s" % str(_sorted(_recruit_log)))
	print("soak: not reached this run (report only) %s" % str(_coverage_gaps()))
	print(
		(
			"soak: engines fired %s; never fired %s"
			% [str(_coverage.engine_counts()), str(_coverage.engines_silent())]
		)
	)
	print("soak: slice cards fired %s" % str(_sorted(_coverage.card_counts())))
	print("soak: slice units bought %s" % str(_sorted(_coverage.purchase_counts())))
	print(
		(
			"soak: pennywort_snail purchases %d, savings gains %d (slice games)"
			% [
				CoreUtil.to_int(_coverage.purchase_counts().get("pennywort_snail", 0)),
				_coverage.snail_gains()
			]
		)
	)
	print("soak: slice cards never fired %s" % str(_coverage.cards_silent(_plain_library)))
	print("soak: slice keywords never fired %s" % str(_coverage.keywords_silent()))
	for line: String in _limit_fights:
		print("soak: no-winner fight: %s" % line)
	print("soak: violations %d" % _violations.size())
	for line: String in _violations.slice(0, 50):
		print("soak: VIOLATION %s" % line)
	quit(1 if not _violations.is_empty() else 0)


func _play(game_seed: int) -> int:
	_game_seed = game_seed
	var slice: bool = game_seed % 3 == 1
	var synthetic: bool = game_seed % 3 == 2
	var full: bool = slice or synthetic
	_chaos_rng.seed = game_seed
	_library = _full_library if synthetic else _plain_library
	var config := GameConfig.full_game() if full else GameConfig.defaults()
	if synthetic:
		config.set_value("pool_filter", "all")
		config.set_value(
			"pool_copies_by_tier", GameConfig.defaults().get_value("pool_copies_by_tier")
		)
	config.set_value("human_bot", "balanced")
	var session := GameSession.create(game_seed, _library, config)
	_session = session
	_slice_game = slice
	session.fight_observer = _check_fight
	session.get_rules().choice_observer = _check_discover
	for player: PlayerState in session._players:
		player.log_observer = _note_recruit.bind(player.id)
		if slice:
			_coverage.note_hero(player.hero)
	if synthetic:
		_check_heroes(session)
	if slice:
		_seat_soak_bots(session)
	var start_total: int = _copies_accounted(session)
	var start_spells: int = _spell_copies(session)
	var turns: int = 0
	while not session.is_over() and turns < MAX_TURNS:
		var round_number: int = session.get_state()["round"]
		if full:
			_chaos(session)
		if slice and game_seed % 9 == 1:
			_hand_out_acorns(session)
		_plant_fault(session)
		var error: String = session.end_turn()
		turns += 1
		if error != "":
			_violation(round_number, "end_turn returned '%s'" % error)
			break
		if _copies_accounted(session) != start_total:
			_violation(round_number, "pool copies not conserved (5.3)")
		if _spell_copies(session) != start_spells:
			_violation(round_number, "spell copies not conserved (5.3.7)")
		for player: PlayerState in session._players:
			_check_player(round_number, player, config)
			if slice:
				_coverage.note_board(player)
	if not session.is_over():
		_violation(turns, "game not over after %d turns" % MAX_TURNS)
	else:
		_check_log(session)
	_session = null
	return turns


## Enough to reach a Great Hoard: the Larder's cards need one in play to be tested at all.
func _hand_out_acorns(session: GameSession) -> void:
	for player: PlayerState in session._players:
		if player.alive and session._bots[player.id] is SoakBot:
			for _acorn: int in 3:
				session.get_rules().give_card(player, "acorn")


## Half the table plays at random from LegalActions, the other half keeps the real bots.
func _seat_soak_bots(session: GameSession) -> void:
	for player: PlayerState in session._players:
		if player.id % 2 == 0:
			var bot := SoakBot.new()
			bot.state_of = _state_of
			bot.on_refused = _note_refused
			session._bots[player.id] = bot


func _state_of(player_id: int) -> Dictionary:
	return _session.get_state(player_id)


func _note_refused(action: Dictionary, reason: String) -> void:
	_violation(0, "LegalActions listed %s and the rules said '%s'" % [str(action), reason])


## The actions bots don't take, at random, with the real rules: selling, moving, tiering, freezing.
func _chaos(session: GameSession) -> void:
	var rules: RecruitRules = session.get_rules()
	for player: PlayerState in session._players:
		if not player.alive or _chaos_rng.randf() > 0.3 or session._bots[player.id] is SoakBot:
			continue
		match _chaos_rng.randi_range(0, 3):
			0:
				rules.sell(player, _chaos_rng.randi_range(0, BoardGeometry.SLOTS - 1))
			1:
				var slot: int = _chaos_rng.randi_range(0, BoardGeometry.SLOTS - 1)
				rules.move(player, slot, _chaos_rng.randi_range(0, BoardGeometry.SLOTS - 1))
			2:
				rules.refresh(player)
			3:
				rules.tier_up(player)
		while player.is_choosing():
			rules.choose(player, 0)


## 2.2.1: no hero offered twice while the roster lasts, so no two players share one.
func _check_heroes(session: GameSession) -> void:
	var seen: Dictionary = {}
	for player: PlayerState in session._players:
		var id: String = str(player.hero.get("id", ""))
		if id == "":
			_violation(0, "player %d has no hero" % player.id)
		elif seen.has(id):
			_violation(0, "hero %s went to two players (2.2.1)" % id)
		seen[id] = true


## 6.2.1, 6.2.2: options are different cards, in tier, no more than asked.
func _check_discover(_player: PlayerState, pick: CardPick, options: PackedStringArray) -> void:
	var seen: Dictionary = {}
	var checked: PackedStringArray = options.duplicate()
	if _plant == "discover_repeat":
		checked.append(options[0])
	for id: String in checked:
		if seen.has(id):
			_violation(0, "Discover offered %s twice (6.2.2)" % id)
		seen[id] = true
		var tier: int = _discover_tier(id)
		if _plant == "discover_tier":
			tier = pick.max_tier + 1
		if tier < pick.min_tier or tier > pick.max_tier:
			_violation(0, "Discover offered %s at tier %d (6.2.1)" % [id, tier])


func _discover_tier(id: String) -> int:
	var unit: Dictionary = _library.get_unit(id)
	var card: Dictionary = unit if not unit.is_empty() else _library.get_card(id)
	return CoreUtil.to_int(card.get("tier", 0))


func _note_recruit(type: String, fields: Dictionary, player_id: int) -> void:
	_recruit_log[type] = CoreUtil.to_int(_recruit_log.get(type, 0)) + 1
	if _slice_game:
		_coverage.note_recruit(_hero_id(player_id), type, fields)
	if type == "trigger":
		var key: String = str(fields.get("mechanic", ""))
		_recruit_log[key] = CoreUtil.to_int(_recruit_log.get(key, 0)) + 1


func _hero_id(player_id: int) -> String:
	if player_id < 0:
		return ""
	var player: PlayerState = _session._players[player_id]
	return str(player.hero.get("id", ""))


## What came up, as a report: which triggers and effects a run reaches depends on the seeds and
## the cards, so a gap isn't a rules breach. test_recruit_triggers and test_effects_in_combat
## prove each one.
func _coverage_gaps() -> PackedStringArray:
	return SoakCoverage.gaps(_recruit_log, _triggers, _event_types)


## The review log agrees with the players it describes.
func _check_log(session: GameSession) -> void:
	var game_log: Dictionary = session.get_game_log()
	var rows: Array = game_log["players"]
	if _plant == "log":
		var tampered: Dictionary = rows[1]
		tampered["placement"] = 99
	var placements: Dictionary = {}
	for value: Variant in rows:
		var row: Dictionary = value
		var player: PlayerState = session._players[CoreUtil.to_int(row["player_id"])]
		placements[row["placement"]] = true
		if row["placement"] != player.placement:
			_violation(0, "log places player %d at %s" % [player.id, row["placement"]])
		var spent: int = 0
		var rounds: Array = row["rounds"]
		for round_value: Variant in rounds:
			var round_row: Dictionary = round_value
			spent += CoreUtil.to_int(round_row["gold_spent"])
		if (
			CoreUtil.to_int(row["gold_spent"]) != player.gold_spent_game
			or spent != player.gold_spent_game
		):
			_violation(0, "log's gold for player %d is off" % player.id)
	if placements.size() != rows.size():
		_violation(0, "log's placements aren't one each")


## Planted faults: each breaks one thing a check above or below watches.
func _plant_fault(session: GameSession) -> void:
	var player: PlayerState = session._players[1]
	var board: Array[RecruitUnit] = player.owned_units()
	match _plant:
		"copies":
			if not board.is_empty():
				board[0].pool_copies += 1
		"spell_copies":
			if session._rules.spell_pool != null:
				session._rules.spell_pool.give_back(session._rules.spell_pool.ids()[0])
		"hero_repeat":
			player.hero = session._players[0].hero
			_check_heroes(session)
		"pending":
			session.fight_observer = _plant_pending.bind(session)
		"hand_items":
			for _index: int in 12:
				player.items.append(HandItem.make(_library.get_card("sample_acorn"), 9000 + _index))
		"armor":
			player.armor = -1
		"gold":
			player.gold = -1
		"iid":
			if board.size() > 1:
				board[1].iid = board[0].iid
		"slots":
			player.slot_effects.append([])


func _plant_pending(
	round_number: int, id_a: int, id_b: int, result: Dictionary, session: GameSession
) -> void:
	_check_fight(round_number, id_a, id_b, result)
	session._players[2].pending.append(
		{"kind": "discover", "options": PackedStringArray(["hoglet_mother"]), "spells": false}
	)


## Copies in the pool plus every copy a player holds in shop, hand or board.
## A swap comes as two events, and the first overwrites the second's old slot: only this uid's goes.
static func _relocate_slot(slots: Dictionary, event: Dictionary) -> void:
	for key: Variant in slots.keys():
		if slots[key] == event["uid"]:
			slots.erase(key)
	var side: int = CoreUtil.to_int(event["side"])
	var slot: int = CoreUtil.to_int(event["slot"])
	slots[_slot_key(side, slot)] = event["uid"]


static func _copies_accounted(session: GameSession) -> int:
	var total: int = session._pool.total_copies()
	for player: PlayerState in session._players:
		total += _waiting_unit_copies(player)
		for unit: RecruitUnit in player.all_units():
			total += unit.pool_copies
		for unit: RecruitUnit in player.shop:
			total += unit.pool_copies
	return total


## A Discover waiting on a bird that came home holds its options' copies out of the pool.
static func _waiting_unit_copies(player: PlayerState) -> int:
	var total: int = 0
	for choice: Dictionary in player.pending:
		if not CoreUtil.to_bool(choice.get("spells", true)):
			var options: PackedStringArray = choice["options"]
			total += options.size()
	return total


## 5.3.7 the same for spells: the pool plus every spell in a shop or in hand.
static func _spell_copies(session: GameSession) -> int:
	if session._rules.spell_pool == null:
		return 0
	var total: int = session._rules.spell_pool.total_copies()
	for player: PlayerState in session._players:
		for item: HandItem in player.items:
			total += item.pool_copies
		for item: HandItem in player.shop_spells:
			total += item.pool_copies
	return total


## A choice this turn's start just raised (a bird home) is fair; an older one was left unmade.
static func _left_from_last_turn(player: PlayerState) -> bool:
	for choice: Dictionary in player.pending:
		if CoreUtil.to_int(choice.get("round", -1)) < player.round_number:
			return true
	return false


func _check_player(round_number: int, player: PlayerState, config: GameConfig) -> void:
	var who: String = "player %d" % player.id
	if player.board.size() != BoardGeometry.SLOTS:
		_violation(round_number, "%s board has %d slots" % [who, player.board.size()])
	if player.hand.size() + player.items.size() > config.get_int("hand_limit"):
		_violation(round_number, "%s hand over the limit (7.1.1)" % who)
	if player.gold < 0:
		_violation(round_number, "%s gold %d" % [who, player.gold])
	if player.armor < 0:
		_violation(round_number, "%s armor %d (2.2.6)" % [who, player.armor])
	if _left_from_last_turn(player):
		_violation(round_number, "%s has a choice left over (6.2)" % who)
	if player.slot_effects.size() != BoardGeometry.SLOTS:
		_violation(round_number, "%s has %d slot lists (8.5)" % [who, player.slot_effects.size()])
	if not player.alive:
		return
	var seen: Dictionary = {}
	var copies: Dictionary = {}
	var held: Array[RecruitUnit] = player.all_units()
	held.append_array(player.shop)
	for unit: RecruitUnit in held:
		if seen.has(unit.iid):
			_violation(round_number, "%s holds iid %d twice" % [who, unit.iid])
		seen[unit.iid] = true
		_check_recruit_unit(round_number, who, unit)
	for unit: RecruitUnit in player.owned_units():
		if not unit.golden and not unit.plain_copy:
			copies[unit.def_id()] = CoreUtil.to_int(copies.get(unit.def_id(), 0)) + 1
	for def_id: Variant in copies:
		if CoreUtil.to_int(copies[def_id]) >= 3 and player.alive:
			_violation(round_number, "%s holds 3 copies of %s untripled (7.3.1)" % [who, def_id])


func _check_recruit_unit(round_number: int, who: String, unit: RecruitUnit) -> void:
	var base_attack: int = CoreUtil.to_int(unit.def["attack"])
	var base_health: int = CoreUtil.to_int(unit.def["health"])
	var factor: int = 2 if unit.golden else 1
	if unit.health < 1 or unit.attack < 0:
		_violation(round_number, "%s %s at %d/%d" % [who, unit.def_id(), unit.attack, unit.health])
	# The base layer, not the total: a recruit-phase damage effect can take Health below it.
	var doubled: bool = (
		unit.base_attack_now() == base_attack * factor
		and unit.base_health_now() == base_health * factor
	)
	if unit.golden and not doubled:
		_violation(
			round_number,
			(
				"%s golden %s at %d/%d, below double base"
				% [who, unit.def_id(), unit.attack, unit.health]
			)
		)


## 7.3.5: every "number" parameter doubles on golden, every other parameter keeps its value.
func _check_golden_params() -> void:
	for unit_def: Dictionary in _library.all_units():
		var entries: Array = unit_def["mechanics"]
		for entry: Dictionary in entries:
			var mechanic_id: String = str(entry["id"])
			if not MechanicRegistry.is_built(mechanic_id):
				_violation(0, "%s uses unbuilt mechanic %s" % [unit_def["id"], mechanic_id])
				continue
			var kinds: Dictionary = EffectSchema.mechanic_params(mechanic_id)
			var normal: Dictionary = MechanicRegistry.params_for(entry, false)
			var golden: Dictionary = MechanicRegistry.params_for(entry, true)
			if mechanic_id == "effect":
				_check_golden_steps(str(unit_def["id"]), normal, golden)
				continue
			for key: Variant in normal:
				var want: Variant = normal[key]
				if str(kinds.get(key, "")) == "number":
					want = CoreUtil.to_int(normal[key]) * 2
				if golden[key] != want:
					_violation(
						0, "%s %s.%s golden %s" % [unit_def["id"], mechanic_id, key, golden[key]]
					)


## 7.3.5 number parameters double unless the step explicitly keeps a fixed golden rate.
func _check_golden_steps(unit_id: String, normal: Dictionary, golden: Dictionary) -> void:
	var plain_steps: Array = MechanicRegistry.steps_of(normal)
	var golden_steps: Array = MechanicRegistry.steps_of(golden)
	for index: int in plain_steps.size():
		var plain: Dictionary = plain_steps[index]
		var doubled: Dictionary = golden_steps[index]
		var kinds: Dictionary = EffectSchema.effect_params(str(plain.get("effect", "")))
		for key: Variant in plain:
			var scales: bool = (
				str(kinds.get(key, "")) == "number"
				and not CoreUtil.to_bool(plain.get("golden_static", false))
			)
			var factor: int = 2 if scales else 1
			var want: Variant = plain[key]
			if factor == 2:
				want = CoreUtil.to_int(want) * 2
			if str(doubled[key]) != str(want):
				_violation(0, "%s step %s golden %s" % [unit_id, key, doubled[key]])


## Replays one fight's event log: slots hold one unit, settled units have Health above 0,
## Health loss never kills, goldens start at double base, the end reason is valid.
func _check_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	_fights += 1
	var where: String = "fight %d v %d" % [id_a, id_b]
	var events: Array[Dictionary] = result["events"]
	if _slice_game:
		_coverage.note_fight(events, [_hero_id(id_a), _hero_id(id_b)])
	if events.size() > _max_events:
		_max_events = events.size()
		_max_events_at = "seed %d round %d %s" % [_game_seed, round_number, where]
	var reason: String = result["reason"]
	_reasons[reason] = CoreUtil.to_int(_reasons.get(reason, 0)) + 1
	if not VALID_REASONS.has(reason):
		_violation(round_number, "%s ended with reason '%s'" % [where, reason])
	var units: Dictionary = {}
	var slots: Dictionary = {}
	var last_death: int = -1
	for index: int in events.size():
		var event: Dictionary = events[index]
		var type: String = event["type"]
		_event_types[type] = CoreUtil.to_int(_event_types.get(type, 0)) + 1
		if type == "trigger":
			var mechanic: String = event["mechanic"]
			_triggers[mechanic] = CoreUtil.to_int(_triggers.get(mechanic, 0)) + 1
		match type:
			"combat_start":
				var boards: Array = event["boards"]
				for side: int in 2:
					var row: Array = boards[side]
					for slot: int in row.size():
						if row[slot] != null:
							var view: Dictionary = row[slot]
							_enter(round_number, where, units, slots, view, side, slot)
			"summon":
				var unit: Dictionary = event["unit"]
				var side: int = event["side"]
				var slot: int = event["slot"]
				var plain: bool = not event.has("came_out") and not event.has("split")
				_enter(round_number, where, units, slots, unit, side, slot, plain)
			"swallowed":
				slots.erase(
					_slot_key(CoreUtil.to_int(event["side"]), CoreUtil.to_int(event["slot"]))
				)
				units.erase(event["uid"])
			"relocate":
				_relocate_slot(slots, event)
			"whistle":
				# A unit can hold Whistle without it being on its card (a grant).
				_set_stat(units, event["uid"], "whistle", true)
			"death":
				last_death = index
				var uid: int = event["uid"]
				slots.erase(
					_slot_key(CoreUtil.to_int(event["side"]), CoreUtil.to_int(event["slot"]))
				)
				units.erase(uid)
			"damage":
				_set_stat(units, event["target"], "health", event["health_after"])
			"transform":
				var view: Dictionary = event["unit"]
				_set_stat(units, event["target"], "health", view["health"])
				_set_stat(units, event["target"], "attack", view["attack"])
			"stats":
				_set_stat(units, event["target"], "health", event["health"])
				_set_stat(units, event["target"], "attack", event["attack"])
			"health_loss":
				_set_stat(units, event["target"], "health", event["health_after"])
				if CoreUtil.to_int(event["health_after"]) < 1:
					_violation(
						round_number, "%s Health loss took uid %s to 0" % [where, event["target"]]
					)
		if SETTLED_EVENTS.has(type):
			for uid: Variant in units:
				var unit: Dictionary = units[uid]
				var health: int = unit["health"]
				if health <= 0:
					_violation(
						round_number,
						"%s uid %s on the board at %d after '%s'" % [where, uid, health, type]
					)
	if reason == Combat.REASON_NO_ATTACKS:
		for uid: Variant in units:
			var unit: Dictionary = units[uid]
			if CoreUtil.to_int(unit["attack"]) > 0 and not unit["whistle"]:
				_violation(
					round_number, "%s ended no_attacks with uid %s able to attack" % [where, uid]
				)
	if reason != Combat.REASON_BOARD_EMPTY:
		var line: String = (
			"seed %d round %d %s: %s, %d events, last death at event %d, units %s"
			% [_game_seed, round_number, where, reason, events.size(), last_death, _names(events)]
		)
		_limit_fights.append(line)
		var stalled: bool = events.size() - last_death > STALL_WINDOW
		var limit: bool = reason in [Combat.REASON_ATTACK_LIMIT, Combat.REASON_TRIGGER_LIMIT]
		if limit and not stalled:
			_violation(round_number, "%s hit %s while units were still dying" % [where, reason])


func _enter(
	round_number: int,
	where: String,
	units: Dictionary,
	slots: Dictionary,
	view: Dictionary,
	side: int,
	slot: int,
	check_golden: bool = true
) -> void:
	var key: int = _slot_key(side, slot)
	if slots.has(key):
		_violation(
			round_number, "%s slot %d/%d already holds uid %s" % [where, side, slot, slots[key]]
		)
	slots[key] = view["uid"]
	var unit_def: Dictionary = _library.get_unit(str(view["def_id"]))
	var whistle: bool = false
	var entries: Array = unit_def["mechanics"]
	for entry: Dictionary in entries:
		whistle = whistle or str(entry["id"]) == "whistle"
	units[view["uid"]] = {
		"health": CoreUtil.to_int(view["health"]),
		"attack": CoreUtil.to_int(view["attack"]),
		"whistle": whistle,
	}
	if view["golden"] and check_golden:
		var attack: int = view["attack"]
		var max_health: int = view["max_health"]
		# Attack only: a recruit-phase damage effect can leave Health below double base.
		if attack < 2 * CoreUtil.to_int(unit_def["attack"]):
			_violation(
				round_number,
				"%s golden %s starts at %d/%d" % [where, view["def_id"], attack, max_health]
			)


static func _set_stat(units: Dictionary, uid: Variant, stat: String, value: Variant) -> void:
	if units.has(uid):
		var unit: Dictionary = units[uid]
		unit[stat] = value if typeof(value) == TYPE_BOOL else CoreUtil.to_int(value)


static func _slot_key(side: int, slot: int) -> int:
	return side * BoardGeometry.SLOTS + slot


## The def ids on both boards at the start, for limit-fight reports.
static func _names(events: Array[Dictionary]) -> String:
	var out: Array = []
	var boards: Array = events[0]["boards"]
	for side: int in 2:
		var names: Array = []
		var row: Array = boards[side]
		for view: Variant in row:
			if view != null:
				var unit: Dictionary = view
				names.append(unit["def_id"])
		out.append(names)
	return str(out)


static func _sorted(counts: Dictionary) -> Dictionary:
	var keys: Array = counts.keys()
	keys.sort()
	var out: Dictionary = {}
	for key: Variant in keys:
		out[key] = counts[key]
	return out


func _violation(round_number: int, text: String) -> void:
	_violations.append("seed %d round %d: %s" % [_game_seed, round_number, text])
