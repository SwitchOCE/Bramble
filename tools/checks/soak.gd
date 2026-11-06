extends SceneTree
## QA soak: plays bot-only full games on the full pool and checks rules invariants after every
## fight and every round. Crashes and rules bugs only; no balance numbers.
## Usage: godot --headless -s res://tools/checks/soak.gd -- [games=200] [first_seed=1]
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
	_library = UnitLibrary.load_dir()
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
	for line: String in _limit_fights:
		print("soak: no-winner fight: %s" % line)
	print("soak: violations %d" % _violations.size())
	for line: String in _violations.slice(0, 50):
		print("soak: VIOLATION %s" % line)
	quit(1 if not _violations.is_empty() else 0)


func _play(game_seed: int) -> int:
	_game_seed = game_seed
	var config := GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var session := GameSession.create(game_seed, _library, config)
	session.fight_observer = _check_fight
	var start_total: int = _copies_accounted(session)
	var turns: int = 0
	while not session.is_over() and turns < MAX_TURNS:
		var round_number: int = session.get_state()["round"]
		var error: String = session.end_turn()
		turns += 1
		if error != "":
			_violation(round_number, "end_turn returned '%s'" % error)
			break
		if _copies_accounted(session) != start_total:
			_violation(round_number, "pool copies not conserved (5.3)")
		for player: PlayerState in session._players:
			_check_player(round_number, player, config)
	if not session.is_over():
		_violation(turns, "game not over after %d turns" % MAX_TURNS)
	return turns


## Copies in the pool plus every copy a player holds in shop, hand or board.
static func _copies_accounted(session: GameSession) -> int:
	var total: int = session._pool.total_copies()
	for player: PlayerState in session._players:
		for unit: RecruitUnit in player.owned_units():
			total += unit.pool_copies
		for unit: RecruitUnit in player.shop:
			total += unit.pool_copies
	return total


func _check_player(round_number: int, player: PlayerState, config: GameConfig) -> void:
	var who: String = "player %d" % player.id
	if player.board.size() != BoardGeometry.SLOTS:
		_violation(round_number, "%s board has %d slots" % [who, player.board.size()])
	if player.hand.size() > config.get_int("hand_limit"):
		_violation(round_number, "%s hand over the limit" % who)
	if player.gold < 0:
		_violation(round_number, "%s gold %d" % [who, player.gold])
	var seen: Dictionary = {}
	var copies: Dictionary = {}
	var held: Array[RecruitUnit] = player.owned_units()
	held.append_array(player.shop)
	for unit: RecruitUnit in held:
		if seen.has(unit.iid):
			_violation(round_number, "%s holds iid %d twice" % [who, unit.iid])
		seen[unit.iid] = true
		_check_recruit_unit(round_number, who, unit)
	for unit: RecruitUnit in player.owned_units():
		if not unit.golden:
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
	if unit.golden and (unit.attack < base_attack * factor or unit.health < base_health * factor):
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
			for key: Variant in normal:
				var want: Variant = normal[key]
				if str(kinds.get(key, "")) == "number":
					want = CoreUtil.to_int(normal[key]) * 2
				if golden[key] != want:
					_violation(
						0, "%s %s.%s golden %s" % [unit_def["id"], mechanic_id, key, golden[key]]
					)


## Replays one fight's event log: slots hold one unit, settled units have Health above 0,
## Health loss never kills, goldens start at double base, the end reason is valid.
func _check_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	_fights += 1
	var where: String = "fight %d v %d" % [id_a, id_b]
	var events: Array[Dictionary] = result["events"]
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
				_enter(round_number, where, units, slots, unit, side, slot)
			"death":
				last_death = index
				var uid: int = event["uid"]
				slots.erase(
					_slot_key(CoreUtil.to_int(event["side"]), CoreUtil.to_int(event["slot"]))
				)
				units.erase(uid)
			"damage":
				_set_stat(units, event["target"], "health", event["health_after"])
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
	slot: int
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
	if view["golden"]:
		var attack: int = view["attack"]
		var max_health: int = view["max_health"]
		if (
			attack < 2 * CoreUtil.to_int(unit_def["attack"])
			or max_health < 2 * CoreUtil.to_int(unit_def["health"])
		):
			_violation(
				round_number,
				"%s golden %s starts at %d/%d" % [where, view["def_id"], attack, max_health]
			)


static func _set_stat(units: Dictionary, uid: Variant, stat: String, value: Variant) -> void:
	if units.has(uid):
		var unit: Dictionary = units[uid]
		unit[stat] = CoreUtil.to_int(value)


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
