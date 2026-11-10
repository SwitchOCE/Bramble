extends "res://tests/ui/shots/screenshot.gd"
## Uses the existing shot builders, but leaves their App alive for real mouse/keyboard input.


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
