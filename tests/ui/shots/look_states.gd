extends RefCounted
## Playable look-tool fixtures. They stage real state; player actions use normal game rules.

const CorePort := preload("res://src/ui/adapter/core_port.gd")


static func last_fight(port: CorePort) -> void:
	var session: GameSession = port.session
	session._round = 14
	session._pairings = [[0, 1]]
	session._bots.clear()
	for player: PlayerState in session._players:
		player.alive = player.id < 2
		player.placement = 0 if player.alive else player.id + 1
		player.round_number = 14
		player.board.fill(null)
		player.hand.clear()
		player.items.clear()
		player.away.clear()
		player.pending.clear()
	var human: PlayerState = session._players[0]
	human.health = 1
	human.last_stand_used = true
	human.gold = 0
	var opponent: PlayerState = session._players[1]
	opponent.health = 40
	opponent.board[0] = RecruitUnit.make(
		port.library.get_unit("field_vole"), session._rules.new_iid()
	)
	opponent.board[0].add_permanent(20, 20)
	human.scout = session._scout_of(1)
