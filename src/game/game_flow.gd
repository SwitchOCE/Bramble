class_name GameFlow
extends RefCounted
## One game against bots, headless: the human in seat 0, a FlowBot (SimpleBot plus abilities and
## spending spare gold) in each other seat. It owns the GameSession and moves it through the round
## (src/core/README.md, "Phase order"):
##   start_round: the core's start of turn for everyone
##   act: the human's actions, passed to the core unchanged; returns the core's refusal or ""
##   finish_round: the bots take their turns, both views of the human's fight are snapshot,
##     every pair fights, eliminations; returns the human's fight
##   play_out: once the human is out, the bots play the game to its end, so all eight places
##     are known
## No turn timer in this build: the human's turn lasts until they end it.

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
## seat -> Bot; the human's seat holds null.
var bots: Array[Bot] = []
## The human's fight in the last finish_round, or {} when they had none:
##   events (the fight log), you_side, opponent (a player id or Matchmaking.GHOST),
##   damage, loser, after (after_fight's events), before: {you: view, opponent: view} snapshot
##   before the fight.
var last_fight: Dictionary = {}
## The game's seed, so a game can be replayed (`-- --seed N`).
var game_seed: int = 0
## The round the human went out in, 0 while they are in.
var out_round: int = 0


## `tribe_ids`: the tribe folders in the lobby (GameContent.tribe_ids); empty means all.
static func create(
	game_content: GameContent, seed_value: int, tribe_ids: PackedStringArray = []
) -> GameFlow:
	var flow := GameFlow.new()
	flow.content = game_content
	flow.game_seed = seed_value
	var lobby: PackedStringArray = game_content.lobby_names(tribe_ids)
	flow.session = game_content.new_session(seed_value, lobby)
	for seat: int in flow.session.players.size():
		if seat == HUMAN:
			flow.bots.append(null)
		else:
			flow.bots.append(FlowBot.new(Rng.derive(seed_value, "bot:%d" % seat)))
	return flow


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


## The human's turn is over (End turn, or a scripted player): the bots play, then every fight.
func finish_round() -> Dictionary:
	_bots_take_turns()
	var opponent: int = session.opponent_of(HUMAN)
	var before: Dictionary = {}
	if human_alive():
		before = {"you": session.view_for(HUMAN), "opponent": opponent_view(opponent)}
	var was_alive: bool = human_alive()
	var fights: Array[Dictionary] = session.finish_round()
	if was_alive and not human_alive():
		out_round = session.round_number
	last_fight = {}
	for fight: Dictionary in fights:
		var pair: Array = fight["players"]
		if not pair.has(HUMAN):
			continue
		last_fight = {
			"events": fight["events"],
			"you_side": pair.find(HUMAN),
			"opponent": opponent,
			"damage": CoreUtil.to_int(fight["damage"]),
			"loser": CoreUtil.to_int(fight["loser"]),
			"result": fight["result"],
			# what after_fight changed on the real boards (game log events); the next recruit
			# view shows the result, no screen shows the changes one by one yet
			"after": fight.get("after", []),
			"before": before,
		}
	return last_fight


## After the human is out: the bots play on until the game ends (2.1.3 caps it at round 50).
func play_out() -> void:
	session.keep_fight_events = false
	while not session.over:
		session.start_round()
		_bots_take_turns()
		session.finish_round()


## What the screens show of an opponent: a player's view, or the ghost's board and tier.
func opponent_view(opponent: int) -> Dictionary:
	if opponent == Matchmaking.GHOST:
		var ghost: PlayerState = session.ghost_player
		var out: Dictionary = ghost.view() if ghost != null else {}
		out["ghost"] = true
		return out
	if opponent < 0:
		return {}
	return session.view_for(opponent)


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


func _bots_take_turns() -> void:
	for seat: int in bots.size():
		var bot: Bot = bots[seat]
		var each: PlayerState = session.player(seat)
		if bot != null and each.alive and not each.turn_ended:
			bot.take_turn(session, seat)
