class_name GhostRun
extends RefCounted
## A validated format-1 run. The ID hashes the input bytes, including whitespace.
# gdlint: disable=max-returns
# Each validation failure reports the field that prevented loading the run.

const FORMAT: int = 1
const UID_STRIDE: int = 1_000_000
const _MAX_JSON_INT: int = 9_007_199_254_740_991
const _SOURCE_KINDS: PackedStringArray = ["bot", "player", "internal", "tester", "test_realm"]
const _END_REASONS: PackedStringArray = ["eliminated", "won", "round_limit", "unfinished"]

var id: String:
	get:
		return _id

var last_turn: int:
	get:
		return _payloads.size()

var _id: String
var _payloads: Dictionary = {}


## Returns {"ok": true, "run": GhostRun} or {"ok": false, "message": String}.
static func read(
	path: String, library: UnitLibrary = null, registry: MechanicRegistry = null
) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("cannot open run file %s" % path)
	var length: int = file.get_length()
	var bytes: PackedByteArray = file.get_buffer(length)
	if bytes.size() != length:
		return _failure("cannot read all bytes of run file %s" % path)
	return parse(bytes, library, registry)


## Pass the library and registry to also check references against the destination game.
static func parse(
	bytes: PackedByteArray, library: UnitLibrary = null, registry: MechanicRegistry = null
) -> Dictionary:
	var parser := JSON.new()
	var decoded: String = bytes.get_string_from_utf8()
	if decoded.to_utf8_buffer() != bytes:
		return _failure("run file must be UTF-8")
	if parser.parse(decoded) != OK:
		return _failure(
			(
				"invalid run JSON at line %d: %s"
				% [parser.get_error_line() + 1, parser.get_error_message()]
			)
		)
	if not parser.data is Dictionary:
		return _failure("run file must contain one JSON object")
	var data: Dictionary = parser.data
	var problem: String = _header_problem(data, library)
	if problem != "":
		return _failure(problem)
	var run := GhostRun.new()
	problem = run._read_turns(data, library, registry)
	if problem != "":
		return _failure(problem)
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		hasher.update(bytes)
	run._id = hasher.finish().hex_encode()
	var source: Dictionary = data["source"]
	var info: Dictionary = {
		"id": run.id,
		"rules_hash": data["rules"]["rules_hash"],
		"kind": source["kind"],
		"label": source["label"],
		"placement": CoreUtil.to_int(data["placement"]),
		"last_turn": run.last_turn,
		"made": data["made"],
		"record_sha256": source["record_sha256"],
		"seat": CoreUtil.to_int(source["seat"]),
		"ended": data["ended"],
	}
	return {"ok": true, "run": run, "info": info}


## Rounds are one-based. A finished run supplies its last saved board.
func turn_for_round(round_number: int) -> int:
	return clampi(round_number, 0, last_turn)


func payload_for_round(round_number: int) -> Dictionary:
	var payload: Dictionary = _payloads.get(turn_for_round(round_number), {})
	return payload.duplicate(true)


func reason_for_round(round_number: int) -> String:
	if round_number < 1 or last_turn == 0:
		return ""
	return "same_turn" if round_number <= last_turn else "run_ended"


func _read_turns(data: Dictionary, library: UnitLibrary, registry: MechanicRegistry) -> String:
	var final_turn: int = CoreUtil.to_int(data["last_turn"])
	var seat: int = CoreUtil.to_int(data["source"]["seat"])
	var cards: Dictionary = data["cards"]
	var held_cards: Dictionary = {}
	for raw: Variant in data["turns"]:
		var turn: Dictionary = CoreUtil.to_dict(raw)
		if not _integer(turn.get("turn"), 1, final_turn):
			return "turns entries require a turn number in 1..%d" % final_turn
		var number: int = CoreUtil.to_int(turn["turn"])
		if _payloads.has(number):
			return "duplicate turn %d" % number
		var problem: String = _turn_problem(turn, seat, held_cards, library, registry)
		if problem != "":
			return "turn %d: %s" % [number, problem]
		_payloads[number] = turn["payload"]
	if _payloads.size() != final_turn:
		for number: int in range(1, _payloads.size() + 2):
			if not _payloads.has(number):
				return "missing turn %d (expected every turn in 1..%d)" % [number, final_turn]
	for number: int in range(1, final_turn + 1):
		if CoreUtil.to_int(data["turns"][number - 1]["turn"]) != number:
			return "turns must be ordered, starting at turn 1"
	for card_id: String in held_cards:
		if not cards.has(card_id):
			return "cards is missing fingerprint for %s" % card_id
	for card_id: String in cards:
		if not held_cards.has(card_id):
			return "cards lists %s, which never appears on the board or in hand" % card_id
	return ""


static func _header_problem(data: Dictionary, library: UnitLibrary) -> String:
	if not _integer(data.get("format"), FORMAT, FORMAT):
		return "expected run format %d" % FORMAT
	if not data.get("rules") is Dictionary:
		return "rules must be an object"
	var rules: Dictionary = data["rules"]
	if not _hex(rules.get("rules_hash"), 64):
		return "rules.rules_hash must be a SHA-256 hex string"
	for key: String in ["version", "revision", "engine"]:
		if not rules.get(key) is String:
			return "rules.%s must be text" % key
	if not data.get("patch") is String:
		return "patch must be text"
	for key: String in ["content", "tribes"]:
		if not _strings(data.get(key)):
			return "%s must be an array of strings" % key
	if not data.get("source") is Dictionary:
		return "source must be an object"
	var problem: String = _source_problem(CoreUtil.to_dict(data["source"]))
	if problem != "":
		return problem
	if not _text(data.get("made")):
		return "made must be nonempty text"
	if not _integer(data.get("placement"), 0, 8):
		return "placement must be an integer in 0..8"
	if not _text(data.get("ended")) or not _END_REASONS.has(str(data["ended"])):
		return "ended must be eliminated, won, round_limit or unfinished"
	if not _integer(data.get("last_turn"), 1):
		return "last_turn must be a positive integer"
	if not data.get("turns") is Array or not data.get("cards") is Dictionary:
		return "turns must be an array and cards must be an object"
	var cards: Dictionary = data["cards"]
	for card_id: String in cards:
		if not _text(card_id) or not _hex(cards[card_id], 16):
			return "cards requires card ids and 16-digit hex fingerprints"
		if library != null and not library.has(StringName(card_id)):
			return "unknown card '%s' in cards" % card_id
	return ""


static func _source_problem(source: Dictionary) -> String:
	if not _text(source.get("kind")) or not _SOURCE_KINDS.has(str(source["kind"])):
		return "source.kind must be bot, player, internal, tester or test_realm"
	for key: String in ["label", "player"]:
		if not source.get(key) is String:
			return "source.%s must be text" % key
	var rating: Variant = source.get("rating")
	if not source.has("rating") or (rating != null and not _number(rating)):
		return "source.rating must be a number or null"
	if not _hex(source.get("record_sha256"), 64):
		return "source.record_sha256 must be a SHA-256 hex string"
	if source.get("record_mode") not in ["live", "async"]:
		return "source.record_mode must be live or async"
	var seed_text: Variant = source.get("game_seed")
	if not seed_text is String or str(str(seed_text).to_int()) != seed_text:
		return "source.game_seed must be canonical signed int64 decimal text"
	if not _integer(source.get("seat"), 0, 7):
		return "source.seat must be in 0..7"
	return ""


static func _turn_problem(
	turn: Dictionary,
	seat: int,
	held_cards: Dictionary,
	library: UnitLibrary,
	registry: MechanicRegistry
) -> String:
	if not _integer(turn.get("tier"), 1, 6):
		return "tier must be in 1..6"
	for key: String in ["health", "armor", "gold"]:
		if not _integer(turn.get(key), 0):
			return "%s must be a nonnegative integer" % key
	if not turn.get("acts") is Array:
		return "acts must be an array"
	for raw: Variant in turn["acts"]:
		var act: Dictionary = CoreUtil.to_dict(raw)
		if not act.get("action") is Dictionary or not act.get("result") is String:
			return "acts entries require an action object and a result string"
	if not turn.get("payload") is Dictionary:
		return "payload must be an object"
	var payload: Dictionary = turn["payload"]
	var tier: int = CoreUtil.to_int(turn["tier"])
	if not _integer(payload.get("id"), seat, seat) or not _integer(payload.get("tier"), tier, tier):
		return "payload id and tier must match the source seat and turn tier"
	return _payload_problem(payload, held_cards, library, registry)


static func _payload_problem(
	payload: Dictionary, held_cards: Dictionary, library: UnitLibrary, registry: MechanicRegistry
) -> String:
	for key: String in ["board", "hand", "slots", "standing"]:
		if not payload.get(key) is Array:
			return "payload.%s must be an array" % key
	var board: Array = payload["board"]
	var slots: Array = payload["slots"]
	var hand: Array = payload["hand"]
	if board.size() != 7 or slots.size() != 7 or hand.size() > 7:
		return "payload requires 7 board slots, 7 slot states and at most 7 hand cards"
	var seen: Dictionary = {}
	for key: String in ["board", "hand"]:
		for unit: Variant in payload[key]:
			if key == "board" and unit == null:
				continue
			var unit_problem: String = _unit_problem(unit, seen, library, registry, key == "board")
			if unit_problem != "":
				return "payload.%s: %s" % [key, unit_problem]
			held_cards[unit["def"]] = true
	for raw: Variant in slots:
		var slot: Dictionary = CoreUtil.to_dict(raw)
		if not _integer(slot.get("renown"), -_MAX_JSON_INT) or not _strings(slot.get("keywords")):
			return "payload.slots entries require integral renown and an array of keyword ids"
		if registry != null:
			for keyword: String in slot["keywords"]:
				var mechanic_id := StringName(keyword)
				if not registry.has(mechanic_id) or not registry.kinds_of(mechanic_id).is_empty():
					return "payload.slots: invalid keyword '%s'" % keyword
	if not _integers(payload.get("counters")):
		return "payload.counters must be an integer dictionary"
	var problem: String = _heaps_problem(payload.get("heaps"), library)
	if problem != "":
		return problem
	for effect: Variant in payload["standing"]:
		problem = _standing_problem(effect, registry)
		if problem != "":
			return problem
	return ""


static func _unit_problem(
	value: Variant,
	seen: Dictionary,
	library: UnitLibrary,
	registry: MechanicRegistry,
	on_board: bool
) -> String:
	var raw: Dictionary = CoreUtil.to_dict(value)
	if not _text(raw.get("def")) or not raw.get("golden") is bool:
		return "unit requires a card id (def) and boolean golden"
	if not _integer(raw.get("uid"), 1):
		return "unit uid must be a positive integer"
	var uid: int = CoreUtil.to_int(raw["uid"])
	if uid >= UID_STRIDE:
		return "unit uid %d must be below %d" % [uid, UID_STRIDE]
	if seen.has(uid):
		return "duplicate unit uid %d" % uid
	seen[uid] = true
	if library != null:
		var card: UnitDef = library.get_card(StringName(str(raw["def"])))
		if card == null:
			return "unknown card '%s'" % raw["def"]
		if on_board and card.is_spell():
			return "spell '%s' cannot be on the board" % raw["def"]
	if not _integer(raw.get("copies", 1), 1) or not _integer(raw.get("bought_copies", 0), 0):
		return "unit copies must be positive and bought_copies must be nonnegative integers"
	for key: String in ["stats", "counters", "turn_counters"]:
		if not _integers(raw.get(key, {})):
			return "unit %s must be an integer dictionary" % key
	for layer: String in raw.get("stats", {}):
		if not FightSnapshot.LAYERS.has(layer):
			return "unknown stat layer '%s'" % layer
	for key: String in ["grants", "aura_grants"]:
		var problem: String = _grants_problem(raw.get(key, []), registry)
		if problem != "":
			return "unit %s: %s" % [key, problem]
	return ""


static func _grants_problem(raw: Variant, registry: MechanicRegistry) -> String:
	if not raw is Array:
		return "must be an array"
	for entry: Variant in raw:
		var grant: Array = CoreUtil.to_array(entry)
		if grant.size() not in [1, 2] or not _text(grant[0]):
			return "entries require a mechanic id and optional parameter object"
		if grant.size() == 2 and not grant[1] is Dictionary:
			return "parameters must be an object"
		var params: Dictionary = grant[1] if grant.size() == 2 else {}
		for value: Variant in params.values():
			if not value is String and not _integer(value, -_MAX_JSON_INT):
				return "parameter values must be text or integers"
		if registry != null and registry.bind_given(StringName(str(grant[0])), params) == null:
			return "unknown mechanic or invalid parameters for '%s'" % grant[0]
	return ""


static func _heaps_problem(raw: Variant, library: UnitLibrary) -> String:
	if not raw is Dictionary:
		return "payload.heaps must be an object"
	for key: String in raw:
		var heap: Dictionary = CoreUtil.to_dict(raw[key])
		if not _integer(heap.get("_next_n"), 1) or not heap.get("entries") is Array:
			return "payload.heaps.%s requires positive _next_n and an entries array" % key
		var previous: int = 0
		for value: Variant in heap["entries"]:
			var entry: Dictionary = CoreUtil.to_dict(value)
			if not _text(entry.get("id")) or not _integer(entry.get("tier"), 1, 7):
				return "payload.heaps.%s entry requires a card id and tier in 1..7" % key
			if not _integer(entry.get("n"), previous + 1, CoreUtil.to_int(heap["_next_n"]) - 1):
				return "payload.heaps.%s entries must have increasing n below _next_n" % key
			previous = CoreUtil.to_int(entry["n"])
			if library != null:
				var card: UnitDef = library.get_card(StringName(str(entry["id"])))
				if card == null:
					return "payload.heaps.%s: unknown card '%s'" % [key, entry["id"]]
				if card.is_spell() or entry["tier"] != card.tier:
					return (
						"payload.heaps.%s: '%s' must be a unit with the saved tier"
						% [key, entry["id"]]
					)
	return ""


static func _standing_problem(raw: Variant, registry: MechanicRegistry) -> String:
	var effect: Dictionary = CoreUtil.to_dict(raw)
	if (
		not _text(effect.get("id"))
		or not effect.get("granted") is bool
		or not effect.get("params") is Dictionary
	):
		return "payload.standing entries require a mechanic id, granted boolean and params object"
	var params: Dictionary = effect["params"]
	if not params.get("golden") is bool or not params.get("_texts") is Dictionary:
		return "payload.standing params require a golden boolean and a _texts object"
	var texts: Dictionary = params["_texts"]
	for value: Variant in texts.values():
		if not value is String:
			return "payload.standing _texts values must be strings"
	for key: String in ["_ints", "_kinds", "_golden_ints"]:
		if not _integers(params.get(key)):
			return "payload.standing params.%s must be an integer dictionary" % key
	if registry != null and not registry.has(StringName(str(effect["id"]))):
		return "payload.standing: unknown mechanic '%s'" % effect["id"]
	return ""


static func _integers(raw: Variant) -> bool:
	if not raw is Dictionary:
		return false
	var fields: Dictionary = raw
	for value: Variant in fields.values():
		if not _integer(value, -_MAX_JSON_INT):
			return false
	return true


static func _strings(raw: Variant) -> bool:
	if not raw is Array:
		return false
	for value: Variant in raw:
		if not value is String:
			return false
	return true


static func _integer(raw: Variant, low: int, high: int = _MAX_JSON_INT) -> bool:
	return _number(raw) and raw == floor(raw) and raw >= low and raw <= high


static func _number(raw: Variant) -> bool:
	if raw is int:
		return true
	if not raw is float:
		return false
	var number: float = raw
	return is_finite(number)


static func _text(raw: Variant) -> bool:
	return raw is String and not str(raw).is_empty()


static func _hex(raw: Variant, length: int) -> bool:
	if not raw is String:
		return false
	var digits: String = raw
	if digits.length() != length:
		return false
	for index: int in length:
		if not "0123456789abcdef".contains(digits[index]):
			return false
	return true


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
