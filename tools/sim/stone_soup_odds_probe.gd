extends SceneTree
## Read-only observer probe of the exact 32 original routes through R6. No policy changes.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const BASE: String = "res://build/neutrals/soup-confirm.line-metrics.jsonl"
var _session: GameSession
var _seed: int
var _engine: int
var _offers: Array = []
var _events: Array = []
var _draws: Array = []
var _seen: Dictionary = {}
var _parity: Dictionary = {}
var _checked: int = 0


class ObservedPool:
	extends UnitPool
	var observer: Callable
	var weighted: bool = false

	func draw_by_odds(odds: Array, max_tier: int, rng: RandomNumberGenerator) -> String:
		var weight: int = 0
		for tier: int in range(1, mini(max_tier, odds.size()) + 1):
			if _left_by_tier[tier - 1] > 0:
				weight += CoreUtil.to_int(odds[tier - 1])
		var q: float = (
			float(CoreUtil.to_int(odds[0])) / weight
			if not odds.is_empty() and weight > 0 and _left_by_tier[0] > 0
			else 0.0
		)
		var before: Dictionary = {
			"kind": "tier_weighted",
			"tier1_weight": q,
			"soup_left": copies_left("stone_soup"),
			"tier1_left": eligible_copies(1)
		}
		weighted = true
		var result: String = super.draw_by_odds(odds, max_tier, rng)
		weighted = false
		observer.call(rng, max_tier, before, result)
		return result

	func draw(max_tier: int, rng: RandomNumberGenerator, min_tier: int = 1) -> String:
		var before: Dictionary = {
			"kind": "uniform_copies",
			"tier1_weight":
			(
				float(eligible_copies(1)) / maxi(1, eligible_copies(max_tier, min_tier))
				if min_tier <= 1
				else 0.0
			),
			"soup_left": copies_left("stone_soup"),
			"tier1_left": eligible_copies(1)
		}
		var result: String = super.draw(max_tier, rng, min_tier)
		if not weighted:
			observer.call(rng, max_tier, before, result)
		return result


func _initialize() -> void:
	var options: Dictionary = {"metrics": BASE, "out": "build/neutrals/soup-odds-probe.json"}
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		assert(parts.size() == 2 and options.has(parts[0]))
		options[parts[0]] = parts[1]
	var file: FileAccess = FileAccess.open(str(options["metrics"]), FileAccess.READ)
	assert(file != null)
	var records: Array = []
	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges() != "":
			records.append(JSON.parse_string(line))
	assert(records.size() == 32)
	var library: UnitLibrary = UnitLibrary.load_dir()
	for record: Dictionary in records:
		_seed = CoreUtil.to_int(record["seed"])
		_parity.clear()
		_seen.clear()
		var seating: Array = ["line_oozes_engine", "line_oozes_tempo"]
		for _seat: int in 6:
			seating.append("hard:varied")
		var seating_rng := RandomNumberGenerator.new()
		seating_rng.seed = ("wave2b|Oozes|%d" % _seed).hash()
		BenchSuites._shuffle(seating, seating_rng)
		_engine = seating.find("line_oozes_engine")
		for row: Dictionary in record["pre_start"]:
			if CoreUtil.to_int(row["round"]) <= 6:
				_parity["%d:%d" % [row["round"], row["seat"]]] = row
		var config: GameConfig = GameConfig.full_game()
		config.set_value("human_bot", seating[0])
		config.set_value("bots", seating.slice(1))
		_session = GameSession.new()
		_session._seed = _seed
		_session._config = config
		_session._library = ScaleOverlay.library_for(library, config)
		_session._bot_factory = BenchSuites.create_bot
		_session._setup()
		var original: UnitPool = _session._pool
		var pool := ObservedPool.new()
		pool._copies = original._copies.duplicate(true)
		pool._tiers = original._tiers.duplicate(true)
		pool._tribes = original._tribes.duplicate(true)
		pool._by_tier = original._by_tier.duplicate(true)
		pool._left_by_tier = original._left_by_tier.duplicate()
		pool._order = original._order.duplicate()
		pool.observer = _draw
		_session._pool = pool
		_session._rules.pool = pool
		_session._rules.shop_observer = _shop
		_session.fight_capture_observer = _capture
		for player: PlayerState in _session._players:
			player.log_observer = _event.bind(player.id)
		assert(_session._hero_offer.is_empty())
		_session._start_round()
		while not _session.is_over() and _session._round <= 6:
			_session.end_turn()
		assert(_parity.is_empty(), "missing original pre-start board")
		print("soup odds parity seed=%d passed" % _seed)
	var output: FileAccess = FileAccess.open(str(options["out"]), FileAccess.WRITE)
	assert(output != null)
	(
		output
		. store_string(
			(
				(
					JSON
					. stringify(
						{
							"version": 1,
							"source_metrics": options["metrics"],
							"source_metrics_sha256": FileAccess.get_sha256(str(options["metrics"])),
							"parity_boards_checked": _checked,
							"offers": _offers,
							"events": _events,
							"draws": _draws,
							"hazard_definition":
							(
								"Exact conditional probability given the realized pre-draw pool and shop tier; "
								+ "full-history products are path references, not ex-ante policy probabilities."
							)
						},
						"",
						true,
						true
					)
				)
				+ "\n"
			)
		)
	)
	_session = null
	quit(0)


func _draw(rng: RandomNumberGenerator, tier: int, before: Dictionary, drawn: String) -> void:
	for player: PlayerState in _session._players:
		if player.shop_rng != rng or player.round_number > 6:
			continue
		before.merge(
			{
				"seed": _seed,
				"seat": player.id,
				"engine": player.id == _engine,
				"round": player.round_number,
				"shop_tier": tier,
				"drawn": drawn
			}
		)
		var other_held: int = 0
		for other: PlayerState in _session._players:
			if other.id == player.id:
				continue
			for unit: RecruitUnit in other.owned_units():
				if unit.pool_id() == "stone_soup":
					other_held += unit.pool_copies
		before["other_seats_owned_soup_copies"] = other_held
		before["hazard"] = (
			CoreUtil.to_float(before["tier1_weight"])
			* CoreUtil.to_int(before["soup_left"])
			/ maxi(1, CoreUtil.to_int(before["tier1_left"]))
		)
		_draws.append(before)
		return


func _shop(player: PlayerState) -> void:
	if player.round_number > 6:
		return
	for unit: RecruitUnit in player.shop:
		var key: String = "%d:%d" % [player.id, unit.iid]
		if _seen.has(key):
			continue
		_seen[key] = true
		_offers.append(
			{
				"seed": _seed,
				"seat": player.id,
				"engine": player.id == _engine,
				"round": player.round_number,
				"tier": player.tier,
				"iid": unit.iid,
				"card": unit.def_id(),
				"gold": player.gold,
				"frozen": player.frozen,
				"board": player.board_specs(),
				"shop": _shop_cards(player)
			}
		)


static func _shop_cards(player: PlayerState) -> Array:
	var cards: Array = []
	for unit: RecruitUnit in player.shop:
		cards.append({"card": unit.def_id(), "iid": unit.iid})
	return cards


func _event(kind: String, fields: Dictionary, seat: int) -> void:
	var player: PlayerState = _session._players[seat]
	if player.round_number > 6 or player.id != _engine:
		return
	_events.append(
		{
			"seed": _seed,
			"seat": player.id,
			"round": player.round_number,
			"type": kind,
			"fields": fields.duplicate(true),
			"gold_after": player.gold,
			"tier": player.tier,
			"board": player.board_specs(),
			"shop": _shop_cards(player)
		}
	)


func _capture(input: Dictionary, result: Dictionary, combat: Combat) -> void:
	if CoreUtil.to_int(input["round"]) > 6:
		return
	var captured: Dictionary = FightCapture.record(input, result, _session._library, combat)
	for side: int in 2:
		var seat: int = CoreUtil.to_int(input["player_ids"][side])
		if seat < 0:
			continue
		var key: String = "%d:%d" % [input["round"], seat]
		var expected: Dictionary = _parity[key]
		var snapshot: Dictionary = captured["combat_start"][side]
		var cards: Array = []
		for unit: Dictionary in snapshot["units"]:
			if CoreUtil.to_bool(unit.get("active", false)):
				cards.append(str(unit["def_id"]))
		assert(
			CoreUtil.to_int(snapshot["active_stats"]) == CoreUtil.to_int(expected["active_stats"]),
			"stat parity failed"
		)
		assert(
			FightCapture.canonical(cards) == FightCapture.canonical(expected["cards"]),
			"card parity failed"
		)
		_parity.erase(key)
		_checked += 1
