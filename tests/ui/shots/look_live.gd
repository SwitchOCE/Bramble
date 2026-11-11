extends "res://tests/ui/shots/screenshot.gd"
## Uses the existing shot builders, but leaves their App alive for real mouse/keyboard input.

const LookStates := preload("res://tests/ui/shots/look_states.gd")


func _run(screen_name: String, window_size: Vector2i, out_path: String) -> void:
	if screen_name not in ["last_fight", "combat_end", "combat_start"]:
		await super._run(screen_name, window_size, out_path)
		return
	await process_frame
	var app: App = App.new()
	root.add_child(app)
	_bot_game(app, BOT_ROUNDS)
	if screen_name == "last_fight":
		LookStates.last_fight(app.port as CorePort)
		app.show_recruit()
	else:
		app.show_game_combat()
		var combat: CombatScreen = app.current as CombatScreen
		combat.auto_return = false
		if screen_name == "combat_end":
			combat.skip_to_end()
		else:
			while combat.next_index < combat.events.size():
				var event: Dictionary = Data.entry(combat.events, combat.next_index)
				combat.call("_play_event", event, false)
				combat.next_index += 1
				if Data.s(event, "type") == "combat_start":
					break
		combat.call("_set_playing", false)
	await _shoot(window_size, out_path)


func _play_until(combat: CombatScreen, index: int) -> void:
	await super._play_until(combat, index)
	combat.call("_set_playing", false)


func _shoot(_window_size: Vector2i, ready_path: String) -> void:
	for i: int in 20:
		await process_frame
	var app: App = root.get_child(root.get_child_count() - 1) as App
	# Staging uses a human bot to build the board. Give that seat back to the live player.
	if app.port is CorePort:
		var port: CorePort = app.port as CorePort
		if port.session != null:
			port.session._bots.erase(0)
	var ready: FileAccess = FileAccess.open(ready_path, FileAccess.WRITE)
	ready.store_string("ready")
	ready.close()
	print("look: ready")
