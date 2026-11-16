extends SceneTree
## Rough timings of the core's hot paths (legal actions, a fight), for tuning the soak.
## Usage: godot --headless -s res://tools/checks/bench_core.gd


func _initialize() -> void:
	var registry: MechanicRegistry = MechanicRegistry.with_built_ins()
	var library: UnitLibrary = UnitLibrary.from_file(
		"res://tests/core/data/neutral_units.json", registry
	)
	var session: GameSession = GameSession.create(5, library, registry)
	var bots: Array[Bot] = []
	for id: int in session.config.players:
		bots.append(SimpleBot.new(Rng.derive(5, "bot:%d" % id)))
	for _round: int in 8:
		session.start_round()
		for player: PlayerState in session.alive_players():
			bots[player.id].take_turn(session, player.id)
		session.finish_round()
	session.start_round()
	var start: int = Time.get_ticks_usec()
	for _i: int in 1000:
		session.legal_actions(0)
	print("bench: legal_actions %.3f ms" % ((Time.get_ticks_usec() - start) / 1000000.0))
	start = Time.get_ticks_usec()
	for _i: int in 1000:
		bots[0].choose(session, session.player(0))
	print("bench: SimpleBot.choose %.3f ms" % ((Time.get_ticks_usec() - start) / 1000000.0))
	start = Time.get_ticks_usec()
	var events: int = 0
	for i: int in 200:
		var combat: Combat = Combat.create(session.geometry, session.config, registry, library, i)
		combat.run([session.player(0).board, session.player(1).board], [0, 1])
		events += combat.events.size()
	print(
		(
			"bench: fight %.3f ms, %.0f events each"
			% [(Time.get_ticks_usec() - start) / 200000.0, events / 200.0]
		)
	)
	quit(0)
