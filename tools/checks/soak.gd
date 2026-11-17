extends SceneTree
## The rules soak: bot-only games on the neutral test units, with rules invariants checked after
## every action, every fight and every round. Crashes and rules bugs only; no balance numbers.
## Half the players are SimpleBot, half RandomBot (random legal play).
## It counts fights, and fights where both boards had units, so a broken load (no cards, no
## fights) can't pass: a run with no real fight in any game is a violation.
## A planted fault must turn it red (tools/checks/soak_plant.sh):
##   plant=pool_leak       a copy silently leaves the pool on every sell
##   plant=empty_library   the card file loads with no units
##   plant=heap_dup        an entry silently enters a heap on every sell
##   plant=slot_leak       a slot buff silently grows on every sell
##   plant=unlogged_damage each fight's damage events are dropped, as if damage went unlogged
##   plant=unplaced_return each fight's return events are dropped, so a returned unit appears
##                         in events with nothing that placed it
## Usage: godot --headless -s res://tools/checks/soak.gd -- [games=300] [first_seed=1] [plant=...]
##   [checks=action|round]  (round: state checks once a round only, faster)
##   [tribes=all|none|badger,mouse]  which tribes under src/content to load (default all)
##   [test_cards=1|0] [neutral=1|0]  the bridge test cards and the neutral test units
## Prints "soak: ..." lines and exits 1 on any violation.

const CoreKit := preload("res://tests/core/core_kit.gd")
const MAX_VIOLATIONS_SHOWN: int = 20
## Fight events that put a unit on a screen's board.
const PLACING: PackedStringArray = ["summon", "reserve", "return"]

var _violations: PackedStringArray = []
var _plant: String = ""
var _fights: int = 0
var _real_fights: int = 0
var _rounds: int = 0
var _actions: int = 0
var _fired: Dictionary = {}
var _reasons: Dictionary = {}
var _game_seed: int = 0
var _every_action: bool = true
## Per player: heap entries and slot stat totals that logged events account for. A heap or slot
## that differs from its ledger changed without an event (a leak or a duplicate).
var _heap_ledger: Dictionary = {}
var _slot_ledger: Dictionary = {}
var _events_seen: int = 0
var _content: ContentSet


func _initialize() -> void:
	GameRecord.directory = "res://build/soak-records"
	var options: Dictionary = {
		"games": "300",
		"first_seed": "1",
		"plant": "",
		"checks": "action",
		"tribes": "all",
		"test_cards": "1",
		"neutral": "1",
	}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		if not options.has(key) or not arg.contains("="):
			printerr("soak: unknown argument %s" % arg)
			quit(2)
			return
		options[key] = arg.get_slice("=", 1)
	_plant = str(options["plant"])
	_every_action = str(options["checks"]) != "round"
	var tribes: PackedStringArray = []
	if str(options["tribes"]) != "all":
		tribes = str(options["tribes"]).split(",")
	_content = CoreKit.content(
		tribes, str(options["test_cards"]) == "1", str(options["neutral"]) == "1"
	)
	print("soak: content %s" % ", ".join(_content.folders))
	var games: int = str(options["games"]).to_int()
	var first: int = str(options["first_seed"]).to_int()
	var started: int = Time.get_ticks_msec()
	for game: int in games:
		_play(first + game)
	_report(games, Time.get_ticks_msec() - started)
	quit(1 if not _violations.is_empty() else 0)


func _play(game_seed: int) -> void:
	_game_seed = game_seed
	if not _content.errors.is_empty():
		_violate("content errors: %s" % ", ".join(_content.errors))
		return
	var session: GameSession = _content.session(game_seed)
	if _plant == "empty_library":
		var registry: MechanicRegistry = MechanicRegistry.with_built_ins()
		session = GameSession.create(game_seed, UnitLibrary.with_system_cards(registry), registry)
	_heap_ledger = {}
	_slot_ledger = {}
	_events_seen = 0
	var bots: Array[Bot] = []
	for id: int in session.config.players:
		var stream: Rng = Rng.derive(game_seed, "bot:%d" % id)
		if id % 2 == 0:
			bots.append(SimpleBot.new(stream))
		else:
			bots.append(RandomBot.new(stream))
	var real_before: int = _real_fights
	while not session.over:
		session.start_round()
		_rounds += 1
		_check_state(session, "round start")
		for player: PlayerState in session.alive_players():
			var after: Callable = func(action: Dictionary) -> void: _after(session, action)
			bots[player.id].take_turn(session, player.id, after)
		for fight: Dictionary in session.finish_round():
			_check_fight(session, fight)
		session.fights.clear()
		_check_state(session, "round end")
		_check_ledgers(session)
		if session.round_number > session.config.round_limit:
			_violate("game ran past the round limit")
			break
	_check_end(session, bots)
	if _real_fights == real_before:
		_violate("no fight had units on both sides")


func _after(session: GameSession, action: Dictionary) -> void:
	_actions += 1
	if _plant == "pool_leak" and action["type"] == "sell":
		for card_id: StringName in session.units.ids():
			if session.units.take(card_id):
				break
	if _plant == "heap_dup" and action["type"] == "sell" and session.player(0).alive:
		session.player(0).heap(&"test_heap").add(&"t1_plain", 1)
	if _plant == "slot_leak" and action["type"] == "sell" and session.player(0).alive:
		session.player(0).slots[0].attack += 1
	if _every_action:
		_check_state(session, "after %s" % action)


# --- Invariants -------------------------------------------------------------------------------


func _check_state(session: GameSession, when: String) -> void:
	_check_pool(session, session.units, false, when)
	_check_pool(session, session.spells, true, when)
	var uids: Dictionary = {}
	for player: PlayerState in session.alive_players():
		var where: String = "p%d %s" % [player.id, when]
		if player.gold < 0:
			_violate("%s: gold %d" % [where, player.gold])
		if player.hand.size() > session.rules.hand_limit(player):
			_violate("%s: hand of %d" % [where, player.hand.size()])
		if player.tier < 1 or player.tier > session.config.max_tier:
			_violate("%s: tier %d" % [where, player.tier])
		if player.board.size() != session.geometry.slot_count:
			_violate("%s: board has %d slots" % [where, player.board.size()])
		for slot: int in player.board.size():
			var unit: Unit = player.board[slot]
			if unit != null and unit.slot != slot:
				_violate(
					(
						"%s: unit %d thinks it is in slot %d, not %d"
						% [where, unit.uid, unit.slot, slot]
					)
				)
		for unit: Unit in player.hand:
			if unit.slot != -1:
				_violate("%s: hand card %d has slot %d" % [where, unit.uid, unit.slot])
		for unit: Unit in player.all_cards():
			if uids.has(unit.uid):
				_violate("%s: uid %d held twice" % [where, unit.uid])
			uids[unit.uid] = true
			if not unit.is_spell() and (unit.attack() < 0 or unit.health() < 1):
				_violate("%s: unit %d is %d/%d" % [where, unit.uid, unit.attack(), unit.health()])


## 5.3: copies left + copies shown + copies held = copies at the start, for every card.
func _check_pool(session: GameSession, pool: CardPool, spells: bool, when: String) -> void:
	var out: Dictionary = {}
	for player: PlayerState in session.alive_players():
		var shown: Array[StringName] = player.shop_spells if spells else player.shop_units
		for card_id: StringName in shown:
			out[card_id] = CoreUtil.to_int(out.get(card_id, 0)) + 1
		if not spells:
			for card_id: StringName in player.discover_options:
				out[card_id] = CoreUtil.to_int(out.get(card_id, 0)) + 1
		for unit: Unit in player.all_cards():
			if unit.is_spell() == spells:
				out[unit.def.id] = CoreUtil.to_int(out.get(unit.def.id, 0)) + unit.pool_copies
	for card_id: StringName in pool.ids():
		var total: int = pool.copies_left(card_id) + CoreUtil.to_int(out.get(card_id, 0))
		if total != pool.starting_copies(card_id):
			_violate(
				(
					"%s: pool %s has %d copies accounted for, started with %d"
					% [when, card_id, total, pool.starting_copies(card_id)]
				)
			)


func _check_fight(session: GameSession, fight: Dictionary) -> void:
	_fights += 1
	var events: Array = fight["events"]
	var result: Dictionary = fight["result"]
	var where: String = "round %d fight %s" % [session.round_number, fight["players"]]
	if events.is_empty():
		_violate("%s: no events" % where)
		return
	var first: Dictionary = events[0]
	var last: Dictionary = events[events.size() - 1]
	if first["type"] != "combat_start" or last["type"] != "combat_end":
		_violate("%s: log doesn't run from combat_start to combat_end" % where)
		return
	var boards: Array = first["boards"]
	var board_a: Array = boards[0]
	var board_b: Array = boards[1]
	if not board_a.is_empty() and not board_b.is_empty():
		_real_fights += 1
	var reason: String = str(result["reason"])
	_reasons[reason] = CoreUtil.to_int(_reasons.get(reason, 0)) + 1
	if not Combat.REASONS.has(reason):
		_violate("%s: unknown end reason %s" % [where, reason])
	var winner: int = CoreUtil.to_int(result["winner"])
	var damage: int = CoreUtil.to_int(fight["damage"])
	var loser: int = CoreUtil.to_int(fight["loser"])
	if winner < 0 and damage != 0:
		_violate("%s: a tie dealt %d damage" % [where, damage])
	if winner >= 0 and loser >= 0 and (damage < 2 or damage > 13):
		_violate("%s: loss damage %d outside 2-13" % [where, damage])
	var survivors: Array = result["survivors"]
	if winner >= 0:
		var mine: Array = survivors[winner]
		var theirs: Array = survivors[1 - winner]
		if mine.is_empty() or not theirs.is_empty():
			_violate("%s: winner %d but survivors %s" % [where, winner, survivors])
	if _plant == "unlogged_damage":
		events = events.filter(func(e: Dictionary) -> bool: return e["type"] != "damage")
	if _plant == "unplaced_return":
		events = events.filter(func(e: Dictionary) -> bool: return e["type"] != "return")
	_check_replay(events, where)
	var ids: Array = fight["players"]
	for event: Variant in events:
		var entry: Dictionary = event
		var side: int = CoreUtil.to_int(entry.get("side", -1))
		if side >= 0 and CoreUtil.to_int(ids[side]) != Matchmaking.GHOST:
			_ledger(CoreUtil.to_int(ids[side]), entry, true)
		if entry["type"] == "trigger" or entry["type"] == "status":
			var name: String = str(entry.get("mechanic", entry.get("status", "")))
			_fired[name] = CoreUtil.to_int(_fired.get(name, 0)) + 1
		if entry["type"] == "damage" and CoreUtil.to_int(entry["amount"]) <= 0:
			_violate("%s: damage event of %s" % [where, entry["amount"]])


func _check_end(session: GameSession, bots: Array[Bot]) -> void:
	var places: Array[int] = []
	for player: PlayerState in session.players:
		places.append(player.placement)
	places.sort()
	var want: Array[int] = []
	for i: int in session.config.players:
		want.append(i + 1)
	if places != want:
		_violate("game %d: placements %s" % [_game_seed, places])
	for bot: Bot in bots:
		if bot.refused > 0:
			_violate(
				"game %d: a bot's legal action was refused: %s" % [_game_seed, bot.last_refusal]
			)
	for event: Dictionary in session.events:
		var name: String = ""
		if event["type"] == "trigger":
			name = str(event["mechanic"])
		elif event["type"] == "discover_queued":
			name = "discover_queued"  # a second Discover waiting: the pool checks cover it
		if name != "":
			_fired[name] = CoreUtil.to_int(_fired.get(name, 0)) + 1


## Heap and slot events, from the game log or a live side of a fight, into the ledgers.
func _ledger(player_id: int, entry: Dictionary, in_fight: bool) -> void:
	match str(entry["type"]):
		"heap_add":
			_heap_ledger[player_id] = CoreUtil.to_int(_heap_ledger.get(player_id, 0)) + 1
		"heap_remove":
			var ids: Array = entry["ids"]
			_heap_ledger[player_id] = CoreUtil.to_int(_heap_ledger.get(player_id, 0)) - ids.size()
		"slot":
			if not in_fight or CoreUtil.to_bool(entry["permanent"]):
				var change: int = (
					CoreUtil.to_int(entry["attack"]) + CoreUtil.to_int(entry["health"])
				)
				_slot_ledger[player_id] = CoreUtil.to_int(_slot_ledger.get(player_id, 0)) + change


## Heaps and slots hold exactly what their events say; every heap entry is a real unit card.
func _check_ledgers(session: GameSession) -> void:
	for i: int in range(_events_seen, session.events.size()):
		var entry: Dictionary = session.events[i]
		if entry.has("player"):
			_ledger(CoreUtil.to_int(entry["player"]), entry, false)
	_events_seen = session.events.size()
	for player: PlayerState in session.alive_players():
		var where: String = "round %d p%d" % [session.round_number, player.id]
		var entries: int = 0
		for key: Variant in player.heaps:
			var heap: CardHeap = player.heaps[key]
			entries += heap.size()
			for entry: Dictionary in heap.entries:
				var card_id := StringName(str(entry["id"]))
				if not session.library.has(card_id) or session.library.get_card(card_id).is_spell():
					_violate("%s: heap holds %s, not a unit card" % [where, card_id])
		if entries != CoreUtil.to_int(_heap_ledger.get(player.id, 0)):
			_violate(
				(
					"%s: heap has %d entries, events account for %d"
					% [where, entries, CoreUtil.to_int(_heap_ledger.get(player.id, 0))]
				)
			)
		var slot_total: int = 0
		for slot: SlotState in player.slots:
			slot_total += slot.attack + slot.health
		if slot_total != CoreUtil.to_int(_slot_ledger.get(player.id, 0)):
			_violate(
				(
					"%s: slot buffs total %d, events account for %d"
					% [where, slot_total, CoreUtil.to_int(_slot_ledger.get(player.id, 0))]
				)
			)


## The fight log can be replayed: every unit an event names was placed first (combat_start,
## summon, reserve or return), so a screen can draw it; and every unit that dies was last shown
## at 0 Health or was destroyed, so no Health change (an aura lost, a buff) went unlogged.
func _check_replay(events: Array, where: String) -> void:
	var health: Dictionary = {}
	var destroyed: Dictionary = {}
	var start: Dictionary = events[0]
	for board: Variant in start["boards"]:
		for unit: Variant in board:
			var shown: Dictionary = unit
			health[shown["uid"]] = shown["health"]
	var placed: Dictionary = health.duplicate()
	for event: Variant in events:
		var entry: Dictionary = event
		var kind: String = str(entry["type"])
		if PLACING.has(kind):
			placed[entry["uid"]] = true
		elif CoreUtil.to_int(entry.get("uid", -1)) >= 0 and not placed.has(entry["uid"]):
			_violate(
				"%s: %s names unit %s before a screen could place it" % [where, kind, entry["uid"]]
			)
			placed[entry["uid"]] = true
		match kind:
			"damage", "buff", "stats", "summon", "return", "reserve":
				health[entry["uid"]] = entry["health"]
			"destroy":
				destroyed[entry["uid"]] = true
			"death":
				var shown_alive: bool = CoreUtil.to_int(health.get(entry["uid"], 1)) > 0
				if shown_alive and not destroyed.has(entry["uid"]):
					var mine: Array = events.filter(
						func(e: Dictionary) -> bool: return e.get("uid", -2) == entry["uid"]
					)
					_violate(
						(
							"%s: unit %s died while the log showed it alive: %s"
							% [where, entry["uid"], mine.slice(-4)]
						)
					)


func _violate(text: String) -> void:
	_violations.append("seed %d: %s" % [_game_seed, text])


func _report(games: int, millis: int) -> void:
	print(
		(
			"soak: %d games, %d rounds, %d actions, %d fights (%d with units on both sides), %.1f s"
			% [games, _rounds, _actions, _fights, _real_fights, millis / 1000.0]
		)
	)
	print("soak: end reasons %s" % _reasons)
	var names: Array = _fired.keys()
	names.sort()
	var parts: PackedStringArray = []
	for name: Variant in names:
		parts.append("%s %d" % [name, _fired[name]])
	print("soak: fired %s" % ", ".join(parts))
	for i: int in mini(_violations.size(), MAX_VIOLATIONS_SHOWN):
		print("soak: VIOLATION %s" % _violations[i])
	print("soak: violations %d" % _violations.size())
