class_name GameFlow
extends RefCounted
## One game against ghosts. The human recruits in seat 0. The other seats bring their
## recorded boards to each fight, and the lobby finishes even if the human is eliminated.

const HUMAN: int = 0
## STAND-IN player names and portraits: the mock-ups' eight, not decided characters.
const PLAYERS: Array[Dictionary] = [
	{"name": "Dame Farthing", "portrait": "dame_farthing"},
	{"name": "Brother Bracken", "portrait": "brother_bracken"},
	{"name": "March Hare", "portrait": "march_hare"},
	{"name": "Pipkin", "portrait": "pipkin"},
	{"name": "Dame Hoolet", "portrait": "dame_hoolet"},
	{"name": "Hob Mumblecrust", "portrait": "hob_mumblecrust"},
	{"name": "Little King Wren", "portrait": "little_king_wren"},
	{"name": "Old Mother Mousewife", "portrait": "old_mother_mousewife"},
]

var content: GameContent
var session: GameSession
## The human's fight in the last finish_round, or {} when they had none:
##   events (the fight log), you_side, opponent (a player id or Matchmaking.GHOST),
##   damage, loser, result, before: {you: view, opponent: view} snapshot before the fight.
var last_fight: Dictionary = {}
## The seed used by the matchmaker and the rules.
var game_seed: int = 0
## The round the human went out in, 0 while they are in.
var out_round: int = 0
var _store: GhostStore


## Select from the shipped field. The caller owns the IDs already used in the app session.
static func pick_opponents(store: GhostStore, seed_value: int, exclude: Dictionary) -> Dictionary:
	var matchmaker := LocalMatchmaker.new()
	var rules_hash: String = RecordBuild.identity()["rules_hash"]
	var band: Dictionary = {"kinds": ["bot"], "shipped_only": true, "index_only": true}
	var rng: Rng = Rng.derive(seed_value, "ghost_matchmaking")
	var pick: Dictionary = matchmaker.pick(store, rules_hash, band, exclude, rng)
	if pick["ok"] or not store.error.is_empty():
		return pick
	var field: Array[Dictionary] = store.find(band)
	if (
		not field.is_empty()
		and not field.any(func(row: Dictionary) -> bool: return row["rules_hash"] == rules_hash)
	):
		return {
			"ok": false,
			"message":
			(
				"ghost field rules hash %s differs from the game's %s"
				% [field[0]["rules_hash"], rules_hash]
			),
		}
	if not exclude.is_empty() and matchmaker.pick(store, rules_hash, band, {}, rng)["ok"]:
		pick["exhausted"] = true
	return pick


## Match and load seats 1–7. An empty lobby filter gives the human every tribe.
static func create(
	game_content: GameContent, seed_value: int, store: GhostStore, exclude: Dictionary = {}
) -> Dictionary:
	var pick: Dictionary = pick_opponents(store, seed_value, exclude)
	if not pick["ok"]:
		return pick
	var rules_hash: String = RecordBuild.identity()["rules_hash"]
	var runs: Dictionary[int, GhostRun] = {}
	for id: String in pick["ids"]:
		var loaded: Dictionary = store.fetch(id, game_content.library, game_content.registry)
		if not loaded["ok"]:
			return loaded
		var info: Dictionary = loaded["info"]
		if info["kind"] != "bot" or info["rules_hash"] != rules_hash:
			return {"ok": false, "message": "ineligible ghost run %s" % id}
		runs[runs.size() + 1] = loaded["run"]
	var flow := GameFlow.new()
	flow.content = game_content
	flow.game_seed = seed_value
	flow.session = game_content.new_async_session(seed_value, runs)
	flow._store = store
	if flow.session == null:
		return {"ok": false, "message": "cannot seat ghost runs"}
	return {"ok": true, "flow": flow}


## Save the human's run after the lobby has settled every placement.
func save_player_run() -> String:
	if _store == null or not session.over:
		return ""
	var cut: Dictionary = GhostRunWriter.cut(
		session.record, Time.get_datetime_string_from_system(true) + "Z", "local", "local", _store
	)
	if not cut["ok"]:
		push_warning("Could not save player ghost: %s" % cut["message"])
		return ""
	var bytes: PackedByteArray = cut["bytes"]
	var id: String = _store.add(bytes)
	if id.is_empty():
		push_warning("Could not save player ghost: %s" % _store.error)
	return id


func start_round() -> void:
	last_fight = {}
	session.start_round()


func act(action: Dictionary) -> String:
	return session.act(HUMAN, action)


func human() -> PlayerState:
	return session.player(HUMAN)


func human_alive() -> bool:
	return human().alive


func is_over() -> bool:
	return session.over


## The human's turn is over. All pairs fight, and the human's fight is kept for the screen.
func finish_round() -> Dictionary:
	last_fight = {}
	if not human_alive():
		session.finish_round()
		return last_fight
	if not human().turn_ended:
		session.end_turn(HUMAN)
	var opponent: int = session.opponent_of(HUMAN)
	var opponent_seat: int = session.ghost_of if opponent == Matchmaking.GHOST else opponent
	var opponent_state: PlayerState = _opponent_state(opponent)
	var before: Dictionary = {"you": session.view_for(HUMAN), "opponent": opponent_view(opponent)}
	var sources: Dictionary = {}
	_add_sources(sources, human())
	var is_run: bool = session.runs.has(opponent)
	if not is_run:
		_add_sources(sources, opponent_state)
	var fights: Array[Dictionary] = session.finish_round()
	if not human_alive():
		out_round = session.round_number
	if is_run:
		# The core loads the run's board during finish_round. Combat leaves run boards intact.
		var loaded: Dictionary = opponent_state.view()
		loaded["health"] = before["opponent"]["health"]
		before["opponent"] = loaded
		_add_sources(sources, opponent_state)
	before["sources"] = sources
	for fight: Dictionary in fights:
		var pair: Array = fight["players"]
		if not pair.has(HUMAN):
			continue
		last_fight = {
			"events": fight["events"],
			"you_side": pair.find(HUMAN),
			"opponent": opponent,
			"opponent_seat": opponent_seat,
			"damage": CoreUtil.to_int(fight["damage"]),
			"loser": CoreUtil.to_int(fight["loser"]),
			"result": fight["result"],
			"before": before,
		}
	return last_fight


## After the human is out, play the remaining rounds to settle all eight places.
func play_out() -> void:
	while not play_out_round():
		pass


## One round after the human is out. True once the game is over.
func play_out_round() -> bool:
	session.keep_fight_events = false
	if session.over:
		return true
	session.start_round()
	session.finish_round()
	return session.over


## The opponent's state in this lobby, including its simulated health.
func opponent_view(opponent: int) -> Dictionary:
	var each: PlayerState = _opponent_state(opponent)
	return each.view() if each != null else {}


func opponent_health(opponent: int) -> int:
	var each: PlayerState = _opponent_state(opponent)
	return maxi(0, each.health) if each != null else 0


func _opponent_state(opponent: int) -> PlayerState:
	if opponent == Matchmaking.GHOST:
		return session.ghost_player
	if opponent >= 0 and opponent < session.players.size():
		return session.player(opponent)
	return null


## A seat's stand-in name; the ghost is named after the player it copies.
func name_of(seat: int) -> String:
	if seat == Matchmaking.GHOST:
		return "Ghost of %s" % name_of(session.ghost_of) if session.ghost_of >= 0 else "Ghost"
	if seat < 0 or seat >= PLAYERS.size():
		return ""
	return str(PLAYERS[seat]["name"])


func portrait_of(seat: int) -> String:
	if seat == Matchmaking.GHOST:
		return portrait_of(session.ghost_of) if session.ghost_of >= 0 else ""
	if seat < 0 or seat >= PLAYERS.size():
		return ""
	return str(PLAYERS[seat]["portrait"])


## Every seat's place once the game is over: [{seat, name, portrait, place}], best first.
func standings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for each: PlayerState in session.players:
		(
			out
			. append(
				{
					"seat": each.id,
					"name": name_of(each.id),
					"portrait": portrait_of(each.id),
					"place": each.placement,
					"health": each.health,
					"you": each.id == HUMAN,
				}
			)
		)
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x["place"] < y["place"])
	return out


## Where each board unit's numbers come from before the fight (ViewAdapter.stat_sources), by
## recruit uid, for the fight's hover: {uid: [line]}.
func _add_sources(out: Dictionary, each: PlayerState) -> void:
	if each == null:
		return
	for unit: Unit in each.board_units():
		var lines: Array = ViewAdapter.stat_sources(content, session, each, unit)
		if not lines.is_empty():
			out[unit.uid] = lines
