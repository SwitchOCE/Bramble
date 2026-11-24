extends Control
## The comparison fight for fight animation treatments (README.md beside this file): one fixed
## fight on shipped tribe cards with their art, the same every run, played by the real fight screen
## with the treatment the scenario names ("treatment": "today"). Every drawn frame it logs each
## card's centre, scale, turn and opacity, and marks step changes, contact, bursts, numbers
## changing and sound cues. Filmed with tools/feel/film, it writes <out>.cards.csv and
## <out>.markers.csv beside the film; the report holds the attacks and moments by frame.

const CoreKit := preload("res://tests/core/core_kit.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")
const BASE_PATH: String = "res://tests/screens/fixtures/fight_start.json"
const SESSION_SEED: int = 7
const FIGHT_SEED: int = 22
## What the loser takes, as the result shows it (the fixture's, not a game's).
const DAMAGE: int = 7
## Your board (side 0, the lower one) and the opponent's (side 1): {slot: card id}. Slots 0-3 are
## the front row, 4-6 the back row.
const YOU: Dictionary = {
	0: "sentry",
	1: "horde-runner",
	2: "green-recruit",
	3: "old-brock",
	4: "sentry",
	5: "horde-runner",
	6: "private",
}
const THEM: Dictionary = {0: "prophet-of-the-dust", 1: "nettle-sprout", 2: "orchard-stripper"}
## The moments the fight is built to hold, by attack (0 = the fight's first attack).
const MOMENTS: Array[Dictionary] = [
	{"moment": "a", "attack": 0, "what": "plain attack straight across"},
	{"moment": "b", "attack": 1, "what": "plain attack on a diagonal target"},
	{"moment": "c", "attack": 2, "what": "Thorns hits the attacker before the exchange"},
	{"moment": "d", "attack": 4, "what": "Thorns kills the attacker; its death summons a Hopper"},
	{
		"moment": "e",
		"attack": 5,
		"what": "a kill whose death hits all; Old Brock triggers six times"
	},
]
## A second, short fixed fight, for CB7 only ("fight": "cb7" in a scenario): your first Gleaner
## kills the Orchard Stripper, whose death deals 5 to all of yours; five die together and the two
## Gleaners left trigger ten times, all on King Speck. Two Health values are set for the fixture
## (CB7_HEALTH): the Stripper dies to the first hit, and King Speck takes all ten hits.
const CB7_YOU: Dictionary = {
	0: "gleaner",
	1: "gleaner",
	2: "gleaner",
	3: "hopper",
	4: "hopper",
	5: "hopper",
	6: "hopper",
}
const CB7_THEM: Dictionary = {0: "orchard-stripper", 1: "king-speck"}
const CB7_HEALTH: Dictionary = {0: 1, 1: 60}
const CB7_SEED: int = 2
const CB7_MOMENTS: Array[Dictionary] = [
	{"moment": "f", "attack": 0, "what": "two Gleaners trigger ten times on King Speck"},
]
## How close (px) to its nearest point an attacker counts as in contact.
const CONTACT_SLACK: float = 0.5
## x, y: the card's centre in film pixels; rotation in degrees; attack, health: the numbers shown;
## scale_y: the scale along the card's own length (scale is across it); keystone: its leading
## edge's width over its trailing edge's (tip.gdshader, 1 when flat) and lead, which edge leads
## (1 top, -1 bottom).
const CARD_COLUMNS: String = (
	"frame,t,step,key,card_id,side,slot,x,y,"
	+ "scale,rotation,alpha,attack,health,state,scale_y,keystone,lead"
)
const MARKER_COLUMNS: String = "frame,t,step,marker,key,detail"

var treatment_name: String = ""
## Which fixed fight: "" (the comparison fight) or "cb7".
var fight_name: String = ""
var screen: FightScreen
var combat: Combat
var replay: FightReplay
var treatment: RefCounted
var elapsed: float = 0.0
var result_at: float = -1.0
var finished_at: float = -1.0

var _card_rows: PackedStringArray = []
var _marker_rows: PackedStringArray = []
## frame -> {key: centre in film pixels}
var _centres: Dictionary = {}
var _frames: Array[int] = []
var _burst_frames: Array[int] = []
var _frame_steps: Dictionary = {}
var _step_frames: Dictionary = {}
var _attacks: Array[Dictionary] = []
var _node_keys: Dictionary = {}
var _numbers: Dictionary = {}
var _present: Dictionary = {}
var _last_step: int = -1
var _last_splashes: Array = []
var _heard: int = 0
var _kept_log: bool = false
var _uids: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func feel_setup(scenario: Dictionary) -> void:
	var options: Dictionary = scenario.get("options", {})
	start(str(scenario.get("treatment", "today")), options, str(scenario.get("fight", "")))


## Builds the fight, the treatment's replay and screen, and starts playing. options: the
## scenario's "options", for a treatment with configure(options) (best.gd's contested branches).
func start(chosen: String, options: Dictionary = {}, which: String = "") -> void:
	treatment_name = chosen
	fight_name = which
	treatment = Treatments.make(chosen)
	if treatment == null:
		push_error("fight_compare: no treatment '%s' in treatments.gd" % chosen)
		return
	if treatment.has_method("configure"):
		treatment.call("configure", options)
	var content: GameContent = GameContent.load_default()
	combat = fight_named(content, which)
	var base: Dictionary = GlassScreen.load_state(BASE_PATH)
	base.erase("boards")
	base["slots"] = [[], []]
	var catalog: Dictionary = {}
	ViewAdapter.add_fight_cards(content, combat.events, catalog)
	replay = treatment.call("make_replay", base, combat.events, catalog, DAMAGE)
	_find_attacks()
	screen = SCREEN.instantiate()
	screen.set_script(treatment.call("screen_script"))
	screen.set("treatment", treatment)
	screen.state = (replay.steps[0] as Dictionary)["state"]
	add_child(screen)
	screen.result_shown.connect(func() -> void: result_at = elapsed)
	screen.playback_finished.connect(func() -> void: finished_at = elapsed)
	# the cues as the sound player starts them (sound_player.gd); put back as found on exit
	_kept_log = Sound.keep_log
	Sound.keep_log = true
	_heard = Sound.heard.size()
	if not RenderingServer.frame_pre_draw.is_connected(_log_frame):
		RenderingServer.frame_pre_draw.connect(_log_frame)
	screen.play(replay)


## The fixed fight a scenario names: "cb7" is CB7's second fight; else the comparison fight.
static func fight_named(content: GameContent, which: String) -> Combat:
	if which != "cb7":
		return fight(content)
	var game: GameSession = content.new_session(SESSION_SEED)
	var them: Array[Unit] = CoreKit.board(game, CB7_THEM)
	for slot: Variant in CB7_HEALTH:
		them[_i(slot)].stats.set_health = _i(CB7_HEALTH[slot])
	return CoreKit.fight(game, CoreKit.board(game, CB7_YOU), them, CB7_SEED)


## The comparison fight from the rules core: the same log every run.
static func fight(content: GameContent) -> Combat:
	var game: GameSession = content.new_session(SESSION_SEED)
	return CoreKit.fight(game, CoreKit.board(game, YOU), CoreKit.board(game, THEM), FIGHT_SEED)


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_log_frame):
		RenderingServer.frame_pre_draw.disconnect(_log_frame)
		Sound.keep_log = _kept_log


func _process(delta: float) -> void:
	if screen != null:
		elapsed += delta


## Each step that starts an attack: a lunge unlike the one before (a pile-on's waiting lunge and
## its later lunge are one attack).
func _find_attacks() -> void:
	var last: Dictionary = {}
	for i: int in replay.steps.size():
		var state: Dictionary = replay.steps[i]["state"]
		var moment: Dictionary = state.get("moment", {})
		var shown: Dictionary = moment.get("lunge", {})
		var lunge: Dictionary = shown.duplicate()
		lunge.erase("waiting")
		if lunge.is_empty() or lunge == last:
			last = lunge
			continue
		last = lunge
		var attacker: Dictionary = _unit_at(state, _i(lunge["side"]), _i(lunge["slot"]))
		var target: Dictionary = _unit_at(state, _i(lunge["target_side"]), _i(lunge["target_slot"]))
		(
			_attacks
			. append(
				{
					"attack": _attacks.size(),
					"step": i,
					"attacker": "u%d" % _i(attacker.get("uid", -1)),
					"attacker_card": str(attacker.get("id", "")),
					"target": "u%d" % _i(target.get("uid", -1)),
					"target_card": str(target.get("id", "")),
					"from": [_i(lunge["side"]), _i(lunge["slot"])],
					"to": [_i(lunge["target_side"]), _i(lunge["target_slot"])],
				}
			)
		)


static func _unit_at(state: Dictionary, side: int, slot: int) -> Dictionary:
	var boards: Array = state.get("boards", [[], []])
	var row: Array = boards[side]
	return row[slot] if slot < row.size() and row[slot] is Dictionary else {}


# ---- the per-frame log ----


func _log_frame() -> void:
	if screen == null or screen._cards == null:
		return
	var frame: int = Engine.get_frames_drawn()
	var step: int = mini(screen._step, replay.steps.size() - 1)
	_frames.append(frame)
	_frame_steps[frame] = step
	if step != _last_step:
		_last_step = step
		_step_frames[step] = frame
		var held: Dictionary = replay.steps[step]
		_mark(frame, step, "step", "", "%s %s" % [str(held["kind"]), str(held["hold"])])
		for attack: Dictionary in _attacks:
			if _i(attack["step"]) == step:
				_mark(
					frame,
					step,
					"attack_start",
					str(attack["attacker"]),
					"attack %d" % attack["attack"]
				)
	_log_cards(frame, step)
	_log_bursts(frame, step)
	while _heard < Sound.heard.size():
		var cue: Dictionary = Sound.heard[_heard]
		_heard += 1
		var dropped: String = str(cue.get("dropped", ""))
		_mark(
			frame, step, "sound", "", str(cue["cue"]) + (" dropped:" + dropped if dropped else "")
		)


func _log_cards(frame: int, step: int) -> void:
	for key: Variant in screen._keeper._kept:
		var entry: Dictionary = screen._keeper._kept[key]
		var kept: Control = entry["node"]
		_node_keys[kept.get_instance_id()] = str(key)
	_note_places(step)
	var centres: Dictionary = {}
	var seen: Dictionary = {}
	for child: Node in screen._cards.get_children():
		if not child is Control:
			continue
		var card: Control = child
		var key: String = _node_keys.get(card.get_instance_id(), "?%d" % card.get_instance_id())
		seen[key] = true
		var centre: Vector2 = card.get_global_transform_with_canvas() * (card.size / 2.0)
		centres[key] = centre
		var numbers: Vector2i = Vector2i(-1, -1)
		if card is GlassCard:
			numbers = Vector2i((card as GlassCard).attack, (card as GlassCard).health)
		var where: Array = _uids.get(key, ["", -1, -1])
		if not _present.has(key):
			_present[key] = true
			_mark(frame, step, "card_in", key, str(where[0]))
		if _numbers.has(key) and _numbers[key] != numbers:
			var was: Vector2i = _numbers[key]
			_mark(
				frame, step, "numbers", key, "%d/%d -> %d/%d" % [was.x, was.y, numbers.x, numbers.y]
			)
		_numbers[key] = numbers
		var leaving: bool = screen._keeper._fading.has(card)
		var tip: Vector2 = _tip_of(card)
		(
			_card_rows
			. append(
				(
					"%d,%.4f,%d,%s,%s,%d,%d,%.2f,%.2f,%.4f,%.2f,%.3f,%d,%d,%s,%.4f,%.4f,%d"
					% [
						frame,
						frame / 60.0,
						step,
						key,
						where[0],
						where[1],
						where[2],
						centre.x,
						centre.y,
						card.scale.x,
						card.rotation_degrees,
						card.modulate.a,
						numbers.x,
						numbers.y,
						"leaving" if leaving else "kept",
						card.scale.y,
						tip.x,
						roundi(tip.y),
					]
				)
			)
		)
	for key: Variant in _present.keys():
		if not seen.has(key):
			_present.erase(key)
			_mark(frame, step, "card_out", str(key), "")
	_centres[frame] = centres


## (keystone, lead) of a card drawn tipped by tip.gdshader (best_screen.gd), else (1, 0).
static func _tip_of(card: Control) -> Vector2:
	var mat: ShaderMaterial = card.material as ShaderMaterial
	if mat == null or mat.get_shader_parameter("keystone") == null:
		return Vector2(1.0, 0.0)
	return Vector2(
		GlassPieces.as_float(mat.get_shader_parameter("keystone")),
		GlassPieces.as_float(mat.get_shader_parameter("lead"))
	)


## Which card each key is and where it stands, from the step's state.
func _note_places(step: int) -> void:
	var state: Dictionary = replay.steps[step]["state"]
	var boards: Array = state.get("boards", [[], []])
	for side: int in boards.size():
		var row: Array = boards[side]
		for slot: int in row.size():
			if row[slot] is Dictionary:
				var unit: Dictionary = row[slot]
				_uids["u%d" % _i(unit.get("uid", -1))] = [str(unit.get("id", "")), side, slot]


## A burst is shown when the screen's splashes change to a new set (its impact).
func _log_bursts(frame: int, step: int) -> void:
	var splashes: Array = screen._shown_splashes
	if splashes != _last_splashes and not splashes.is_empty():
		var parts: PackedStringArray = []
		for splash: Dictionary in splashes:
			var amount: String = "0" if splash.get("blocked", false) else str(splash["amount"])
			parts.append("%d:%d:%s" % [_i(splash["side"]), _i(splash["slot"]), amount])
		_mark(frame, step, "burst", "", " ".join(parts))
		_burst_frames.append(frame)
	_last_splashes = splashes.duplicate(true)
	for child: Node in screen._front.get_children():
		if child is Control and String(child.name).begins_with("Hit"):
			var hit: Control = child
			var centre: Vector2 = hit.get_global_transform_with_canvas() * (hit.size / 2.0)
			(
				_card_rows
				. append(
					(
						"%d,%.4f,%d,%s,burst,-1,-1,%.2f,%.2f,%.4f,%.2f,%.3f,-1,-1,burst,%.4f,1.0000,0"
						% [
							frame,
							frame / 60.0,
							step,
							String(hit.name),
							centre.x,
							centre.y,
							hit.scale.x,
							hit.rotation_degrees,
							hit.modulate.a,
							hit.scale.y,
						]
					)
				)
			)


func _mark(frame: int, step: int, marker: String, key: String, detail: String) -> void:
	_marker_rows.append(
		"%d,%.4f,%d,%s,%s,%s" % [frame, frame / 60.0, step, marker, key, detail.replace(",", ";")]
	)


# ---- the report ----


## Per attack: the frames it starts, makes contact (the attacker nearest its target), first
## shows a burst after contact and ends (the next attack starts).
func attack_frames() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n: int in _attacks.size():
		var attack: Dictionary = _attacks[n].duplicate()
		var first: int = _i(_step_frames.get(_i(attack["step"]), -1))
		var last: int = _frames.back() if not _frames.is_empty() else -1
		if n + 1 < _attacks.size():
			last = _i(_step_frames.get(_i(_attacks[n + 1]["step"]), last + 1)) - 1
		attack["start_frame"] = first
		attack["end_frame"] = last
		var contact: int = _contact(str(attack["attacker"]), str(attack["target"]), first, last)
		attack["contact_frame"] = contact
		attack["burst_frame"] = -1
		for frame: int in _burst_frames:
			if frame >= maxi(first, contact) and frame <= last:
				attack["burst_frame"] = frame
				break
		out.append(attack)
	return out


func _contact(attacker: String, target: String, first: int, last: int) -> int:
	if first < 0:
		return -1
	var target_at: Vector2 = Vector2.INF
	var distances: Dictionary = {}
	for frame: int in range(first, last + 1):
		var centres: Dictionary = _centres.get(frame, {})
		# the target where it stood as the attack began: its own lift or recoil is not contact
		if centres.has(target) and target_at == Vector2.INF:
			target_at = centres[target]
		if centres.has(attacker) and target_at != Vector2.INF:
			var at: Vector2 = centres[attacker]
			distances[frame] = at.distance_to(target_at)
	if distances.is_empty():
		return -1
	var nearest: float = INF
	for frame: Variant in distances:
		nearest = minf(nearest, GlassPieces.as_float(distances[frame]))
	var from: float = GlassPieces.as_float(distances.values()[0])
	if nearest > from - 5.0:
		return -1
	for frame: int in range(first, last + 1):
		if distances.has(frame) and distances[frame] <= nearest + CONTACT_SLACK:
			return frame
	return -1


func feel_report() -> Dictionary:
	var attacks: Array[Dictionary] = attack_frames()
	var moments: Array[Dictionary] = []
	var cb7: bool = fight_name == "cb7"
	for moment: Dictionary in CB7_MOMENTS if cb7 else MOMENTS:
		var held: Dictionary = moment.duplicate()
		var n: int = _i(moment["attack"])
		if n < attacks.size():
			var attack: Dictionary = attacks[n]
			held["attacker"] = attack["attacker_card"]
			held["target"] = attack["target_card"]
			for field: String in ["start_frame", "contact_frame", "burst_frame", "end_frame"]:
				held[field] = attack[field]
				held[field.replace("_frame", "_s")] = snappedf(_i(attack[field]) / 60.0, 0.01)
		moments.append(held)
	var planned: float = 0.0
	for step: Dictionary in replay.steps:
		planned += GlassPieces.as_float(step["hold"])
	var files: Dictionary = _write_logs()
	var plan: Variant = treatment.call("plan") if treatment.has_method("plan") else {}
	return {
		"treatment": treatment_name,
		"plan": plan,
		"fight": fight_name if cb7 else "comparison",
		"you": CB7_YOU if cb7 else YOU,
		"them": CB7_THEM if cb7 else THEM,
		"fight_seed": CB7_SEED if cb7 else FIGHT_SEED,
		"events": combat.events.size(),
		"steps": replay.steps.size(),
		"planned_seconds": planned,
		"result_at": result_at,
		"finished_at": finished_at,
		"first_frame": _frames[0] if not _frames.is_empty() else -1,
		"core_matches": _core_matches(),
		"attacks": attacks,
		"moments": moments,
		"files": files,
	}


## The board on screen at the end equals the core's result.
func _core_matches() -> bool:
	for side: int in 2:
		var core: Array[Dictionary] = []
		for unit: CombatUnit in combat.units(side):
			core.append(
				{
					"slot": unit.slot,
					"uid": unit.uid,
					"attack": unit.attack(),
					"health": unit.health()
				}
			)
		core.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["slot"] < b["slot"])
		if replay.summary(side) != core:
			return false
	return true


## The logs beside the film: <out>.cards.csv and <out>.markers.csv, when filmed.
func _write_logs() -> Dictionary:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3 or not args[2].ends_with(".report.json"):
		return {}
	var stem: String = args[2].trim_suffix(".report.json")
	var out: Dictionary = {"cards": stem + ".cards.csv", "markers": stem + ".markers.csv"}
	for contact: Dictionary in attack_frames():
		if _i(contact["contact_frame"]) >= 0:
			_mark(
				_i(contact["contact_frame"]),
				_i(_frame_steps.get(_i(contact["contact_frame"]), -1)),
				"contact",
				str(contact["attacker"]),
				"attack %d" % contact["attack"]
			)
	_save(str(out["cards"]), CARD_COLUMNS, _card_rows)
	var markers: Array = Array(_marker_rows)
	# by frame, keeping the order they were marked in within a frame
	var order: Dictionary = {}
	for i: int in markers.size():
		order[markers[i]] = i
	markers.sort_custom(
		func(a: String, b: String) -> bool:
			var fa: int = a.get_slice(",", 0).to_int()
			var fb: int = b.get_slice(",", 0).to_int()
			return fa < fb if fa != fb else _i(order[a]) < _i(order[b])
	)
	_save(str(out["markers"]), MARKER_COLUMNS, PackedStringArray(markers))
	return out


static func _save(path: String, header: String, rows: PackedStringArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_line(header)
	for row: String in rows:
		file.store_line(row)
	file.close()


static func _i(value: Variant) -> int:
	return CoreUtil.to_int(value)
