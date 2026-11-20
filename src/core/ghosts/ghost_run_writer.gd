class_name GhostRunWriter
extends RefCounted
## Cut the live player at seat 0 from a finished GameRecord, in Rust's wire order.
## Replay recovers pre-fight health, armor and gold, which the recorded payload omits.


## Returns {ok, bytes, id} or {ok, message}. The store supplies the recorded opponents for replay.
static func cut(
	record: GameRecord, made: String, player: String, label: String, store: GhostStore = null
) -> Dictionary:
	if record == null or record.path.is_empty() or record.error != "":
		return _failure("no saved game record")
	if made.is_empty():
		return _failure("missing made time")
	var file: FileAccess = FileAccess.open(record.path, FileAccess.READ)
	if file == null:
		return _failure("cannot open record %s" % record.path)
	var length: int = file.get_length()
	var bytes: PackedByteArray = file.get_buffer(length)
	file.close()
	if bytes.is_empty() or bytes.size() != length:
		return _failure("cannot read record %s" % record.path)
	var decoded: Dictionary = RecordReplay.decode(bytes)
	if not decoded["ok"]:
		return decoded
	var entries: Array[Dictionary] = decoded["entries"]
	var capture := SeatCapture.new()
	var replay: Dictionary = RecordReplay.rebuild(entries, store, capture.observe)
	if not replay["ok"]:
		return replay
	if not replay["complete"]:
		return _failure("game record is unfinished")
	var session: GameSession = replay["session"]
	return _encode(
		entries[0],
		GhostRun.sha256(bytes),
		capture.turns,
		session,
		{
			"made": made,
			"player": player,
			"label": label,
		}
	)


static func _encode(
	header: Dictionary,
	record_id: String,
	turns: Array[Dictionary],
	game: GameSession,
	metadata: Dictionary
) -> Dictionary:
	var recipe: Dictionary = header["recipe"]
	var content: Array[String] = []
	var card_data: Dictionary = {}
	for card: Dictionary in UnitLibrary.SYSTEM_CARDS:
		card_data[card["id"]] = card
	for path: String in recipe["paths"]:
		var folder: String = RecordReplay.content_folder(path)
		content.append(folder.replace("\\", "/").trim_suffix("/").get_file())
		var file: String = folder.path_join("units.json")
		if FileAccess.file_exists(file) and not _load_cards(file, card_data):
			return _failure("cannot load card data from %s" % file)
	if recipe["kind"] == "game" and not _load_cards(GameContent.STAND_IN_PATH, card_data):
		return _failure("cannot load stand-in card data")

	var cards: Dictionary = {}
	for turn: Dictionary in turns:
		var payload: Dictionary = turn["payload"]
		for group: String in ["board", "hand"]:
			for unit: Variant in payload[group]:
				if unit == null or cards.has(unit["def"]):
					continue
				var id: String = unit["def"]
				if not card_data.has(id):
					return _failure("missing card data for %s" % id)
				cards[id] = (
					GhostJson.encode(RecordState.value(card_data[id]), true).sha256_text().left(16)
				)
	cards.sort()
	var player: PlayerState = game.player(0)
	var ended: String = "eliminated"
	if player.alive:
		ended = "round_limit" if game.alive_players().size() > 1 else "won"
	var source: Dictionary = {
		"kind": "player",
		"label": metadata["label"],
		"player": metadata["player"],
		"rating": null,
		"record_sha256": record_id,
		"record_mode": header["mode"],
		"game_seed": header["seed"],
		"seat": 0,
	}
	var run: Dictionary = {
		"format": GhostRun.FORMAT,
		"rules": header["build"],
		"patch": "",
		"content": content,
		"tribes": recipe["tribes"],
		"source": source,
		"made": metadata["made"],
		"placement": player.placement,
		"last_turn": turns.size(),
		"ended": ended,
		"cards": cards,
		"turns": turns,
	}
	var bytes: PackedByteArray = GhostJson.encode(run).to_utf8_buffer()
	var parsed: Dictionary = GhostRun.parse(bytes)
	if not parsed["ok"]:
		return parsed
	var info: Dictionary = parsed["info"]
	return {"ok": true, "bytes": bytes, "id": info["id"]}


static func _load_cards(path: String, cards: Dictionary) -> bool:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return false
	var data: Dictionary = CoreUtil.to_dict(json.data)
	if not data.get("cards") is Array:
		return false
	for card: Dictionary in data["cards"]:
		if not card.get("id") is String:
			return false
		if not cards.has(card["id"]):
			cards[card["id"]] = card
	return true


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}


class SeatCapture:
	var turns: Array[Dictionary] = []
	var _acts: Array[Dictionary] = []

	func observe(entry: Dictionary, game: GameSession) -> void:
		if entry["op"] == "act" and entry["player"] == 0:
			_acts.append({"action": RecordState.value(entry["action"]), "result": entry["result"]})
		elif entry["op"] == "fight_boards":
			for payload: Dictionary in entry["players"]:
				if payload["id"] == 0:
					var player: PlayerState = game.player(0)
					(
						turns
						. append(
							{
								"turn": game.round_number,
								"tier": player.tier,
								"health": player.health,
								"armor": player.armor,
								"gold": player.gold,
								"acts": _acts,
								"payload": RecordState.value(payload),
							}
						)
					)
					_acts = []
					break
