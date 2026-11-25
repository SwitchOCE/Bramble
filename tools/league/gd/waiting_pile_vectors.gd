extends SceneTree
## Generate the recruit checkpoints checked by bramble-engine/tests/waiting_pile.rs.

const CASES := "res://tools/league/bramble-engine/tests/fixtures/waiting_pile_cases.json"
const PROBE := &"waiting_proof"


class Probe:
	extends Mechanic

	func on_sold(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
		ctx.buff(ctx.player.hand[0], 1, 0, true, unit)

	func on_any_sold(ctx: RecruitContext, unit: Unit, _sold: Unit, _params: MechanicParams) -> void:
		ctx.give_card(&"sp_seek", unit)

	func on_recruited(
		ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams
	) -> void:
		if unit.def.id == &"quartermaster":
			for card: Unit in ctx.player.hand:
				if not card.is_spell():
					ctx.give_keyword(card, &"pigeon_reserve", unit)
		else:
			ctx.buff(unit, ctx.player.board[0].attack(), 0, true, unit)


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1 or not args[0].begins_with("out="):
		printerr("waiting_pile_vectors: expected out=<path>")
		quit(2)
		return
	var cases: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CASES))
	var content: GameContent = GameContent.load_default()
	assert(content.errors.is_empty(), str(content.errors))
	assert(content.registry.register(PROBE, Probe.new()))
	var out := FileAccess.open(args[0].trim_prefix("out="), FileAccess.WRITE)
	assert(out != null)
	var count: int = 0
	for name: String in cases:
		var rows: Array = _case(content.new_session(42), CoreUtil.to_array(cases[name]))
		for i: int in rows.size():
			var row: Dictionary = rows[i]
			row["case"] = name
			row["step"] = i
			out.store_line(JSON.stringify(row))
			count += 1
	out.close()
	print("waiting_pile_vectors: %d cases, %d checkpoints" % [cases.size(), count])
	quit(0)


func _case(game: GameSession, steps: Array) -> Array:
	game.start_round()
	var p: PlayerState = game.player(0)
	p.gold = 20
	game.events.clear()
	var out: Array = []
	for step: Array in steps:
		var result: Variant = _step(game, p, step)
		out.append(
			{
				"result": result,
				"hash": RecordState.state_hash(game),
				"events": JSON.stringify(game.events).sha256_text(),
				"waiting": p.waiting_pile.size(),
				"joins":
				(
					game
					. events
					. filter(func(e: Dictionary) -> bool: return e.type == "waiting_join")
					. size()
				),
				"choices": p.recruit_choices.size(),
			}
		)
		game.events.clear()
	return out


func _step(game: GameSession, p: PlayerState, step: Array) -> Variant:
	var arg: Variant = step[1] if step.size() > 1 else null
	var index: int = CoreUtil.to_int(step[2]) if step.size() > 2 else -1
	match str(step[0]):
		"board", "hand":
			var name: String = str(arg)
			var def: UnitDef = game.library.get_card(StringName(name.trim_suffix("*")))
			var copies: int = maxi(1, index) if step[0] == "hand" else 1
			for _i: int in copies:
				var unit: Unit = game.new_unit(def, name.ends_with("*"))
				if step.size() > 3:
					unit.grant(game.registry, StringName(str(step[3])))
				if step[0] == "hand":
					p.hand.append(unit)
				else:
					p.place(unit, index)
		"give":
			var ctx := RecruitContext.new(game, game.recruit, p)
			var source: Unit = p.board[index] if index >= 0 else null
			var ids: Array[int] = []
			for _i: int in CoreUtil.to_int(step[3]) if step.size() > 3 else 1:
				ids.append(ctx.give_card(StringName(str(arg)), source).uid)
			return ids
		"grant_waiting":
			var last: Unit = p.waiting_pile[-1]
			last.grant(game.registry, StringName(str(arg)))
		"offer":
			p.discover_options = [StringName(str(arg))]
		"shop_unit":
			p.shop_units[0] = StringName(str(arg))
		"shop_spell":
			p.shop_spells[0] = StringName(str(arg))
		"worked":
			p.board[CoreUtil.to_int(arg)].worked_this_turn = true
		"gold":
			p.gold = CoreUtil.to_int(arg)
		"act":
			var action: Dictionary = CoreUtil.to_dict(arg).duplicate()
			if index >= 0:
				action["target"] = p.board[index].uid
			elif index < -1:
				action["target"] = p.hand[-index - 2].uid
			return game.act(0, action)
		"legal":
			if str(arg) == "all":
				return JSON.stringify(game.legal_actions(0)).sha256_text()
			return game.legal_actions(0).filter(
				func(a: Dictionary) -> bool: return a.type in ["pick", "recruit_target"]
			)
		"bot":
			var action: Dictionary = SimpleBot.new(Rng.derive(42, "proof")).choose(game, p)
			return {"action": action, "result": game.act(0, action)}
		"settle":
			game.recruit._settle(p)
		"auras":
			game.recruit.refresh_auras(p)
		"attack":
			return [p.board[0].attack(), p.hand[CoreUtil.to_int(arg)].stats.perm_attack]
		"start":
			game.start_round()
		"end":
			game.end_turn(0)
		"stamp":
			var unit: Unit = p.waiting_pile[0]
			unit.worked_this_turn = true
			unit.turn_counters[&"proof"] = 1
			unit.stats.turn_attack = 3
		"restore":
			var payload: Dictionary = RecordState.fight_players(game)[0]
			var owner: PlayerState = game.player(1)
			FightSnapshot.restore_player(payload, owner, game, GhostRun.UID_STRIDE)
			var restored: Array = FightSnapshot.units(owner.waiting_pile)
			var old: Dictionary = payload.duplicate()
			old.erase("waiting_pile")
			FightSnapshot.restore_player(old, owner, game, GhostRun.UID_STRIDE)
			return {
				"saved": payload["waiting_pile"],
				"restored": restored,
				"cleared": owner.waiting_pile.is_empty()
			}
		"retire":
			game._retire(p, 8)
		_:
			assert(false, "unknown step %s" % str(step))
	return null
