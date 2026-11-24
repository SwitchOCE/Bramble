extends Node
## How long late fights take, today and under the best proposal and its options, without filming
## (docs/workstreams/fight-animation-24-nov/research/fight-length.md). Fights come from the league
## bots' ghost runs: two runs' recorded boards for the same round, fought by the rules core exactly
## as an async game fights a ghost (GameSession._fight), side 0 live as the player's.
##
##   godot --headless res://tests/screens/feel/fight_compare/fight_length.tscn -- \
##     field=/data/third-run/field-fa1d51ec out=/data/fight-anim-work/fight-length [pairs=80]
##     [seed=2411] [rounds=8,9,10,11,12] [labels=red,blue] [variants=all|best]
##
## It writes <out>/fights/<name>.json (the spec, enough to fight it again: run IDs, round, fight
## seed; plus the log) for every fight with seven units a side, and <out>/lengths.json: per fight,
## today's and each variant's frames to the result, the time by kind and every attack cycle.
## fight_length.py summarises it. A spec also plays on the fight screen for filming:
## "fight": "spec:<path>" in a fight_compare scenario.
## Today: each FightReplay step held as FightScreen holds it at 60 fps (its _wait loop).
## Best: best_timeline.gd's schedule (frame of the result, and its spans).
## Exploratory (ideation/fight-animation): nothing here reaches the game.

const TIMELINE: GDScript = preload("res://tests/screens/feel/fight_compare/best_timeline.gd")
const BEST_REPLAY: GDScript = preload("res://tests/screens/feel/fight_compare/best_replay.gd")
const TREATMENT: GDScript = preload("res://tests/screens/feel/fight_compare/fight_treatment.gd")
const BASE_PATH: String = "res://tests/screens/fixtures/fight_start.json"
const DAMAGE: int = 7
const FPS: float = 60.0
## Each variant: a name and best_timeline.gd's options. CB7's options other than best run
## without rule 7 (as in the CB7 clips). What-ifs, not contested branches: R7 (rule 7's numbers,
## best_timeline.gd SPEEDUPS) and GROUP (up to N single beats in a row start together).
const VARIANTS: Array[Array] = [
	["best", {}],
	["best_no7", {"CB7": "best_no7"}],
	["CB1-today", {"CB1": "today"}],
	["CB1-a", {"CB1": "a"}],
	["CB1-b", {"CB1": "b"}],
	["CB1-c", {"CB1": "c"}],
	["CB5-b", {"CB5": "b"}],
	["CB5-c", {"CB5": "c"}],
	["CB5-bg", {"CB5": "bg"}],
	["CB6-b", {"CB6": "b"}],
	["CB6-a", {"CB6": "a"}],
	["CB6-bg", {"CB6": "bg"}],
	["CB7-bg", {"CB7": "bg"}],
	["CB7-a", {"CB7": "a"}],
	["CB7-b", {"CB7": "b"}],
	["CB7-c", {"CB7": "c"}],
	["CB8-b", {"CB8": "b"}],
	["CB8-c", {"CB8": "c"}],
	["CB8-d", {"CB8": "d"}],
	["R7-x2", {"R7": "x2"}],
	["R7-early", {"R7": "early"}],
	["R7-early_x2", {"R7": "early_x2"}],
	["G2", {"GROUP": 2}],
	["G3", {"GROUP": 3}],
	["G3-R7-early_x2", {"GROUP": 3, "R7": "early_x2"}],
]

var _content: GameContent
var _store: GhostStore
var _base: Dictionary
var _place: Callable
var _probe: FightScreen


func _ready() -> void:
	var options: Dictionary = {
		"field": "/data/third-run/field-fa1d51ec",
		"out": "/data/fight-anim-work/fight-length",
		"pairs": "80",
		"seed": "2411",
		"rounds": "8,9,10,11,12",
		"labels": "red,blue",
		"variants": "all",
		"fights": "field",
	}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		if not options.has(key) or not arg.contains("="):
			printerr("fight_length: unknown argument %s" % arg)
			get_tree().quit(2)
			return
		options[key] = arg.substr(key.length() + 1)
	_content = GameContent.load_default()
	_store = GhostStore.new(str(options["field"]))
	_base = base_state()
	_probe = probe()
	_place = _probe.unit_xy
	print("fight_length: rules %s" % str(RecordBuild.identity()["rules_hash"]).left(8))
	if str(options["fights"]) == "compare":
		_measure_fixtures()
		_probe.free()
		get_tree().quit(0)
		return
	var out: String = str(options["out"])
	DirAccess.make_dir_recursive_absolute(out.path_join("fights"))
	var specs: Array[Dictionary] = _pick(options)
	var all: bool = str(options["variants"]) == "all"
	var rows: Array = []
	var started: int = Time.get_ticks_msec()
	for spec: Dictionary in specs:
		var events: Array = fight_from_spec(_content, _store, spec).events
		var saved: Dictionary = spec.duplicate()
		saved["events"] = events
		_write(out.path_join("fights/%s.json" % spec["name"]), saved)
		rows.append(measure(spec, events, all))
	_write(
		out.path_join("lengths.json"),
		{"options": options, "rules_hash": RecordBuild.identity()["rules_hash"], "fights": rows}
	)
	print(
		(
			"fight_length: %d fights measured in %d s -> %s"
			% [rows.size(), (Time.get_ticks_msec() - started) / 1000.0, out]
		)
	)
	_probe.free()
	get_tree().quit(0)


## fights=compare: the comparison fight and CB7's fight, whose films are measured
## (README.md beside this file), so the headless count can be checked against real frames.
func _measure_fixtures() -> void:
	var compare: GDScript = load("res://tests/screens/feel/fight_compare/fight_compare.gd")
	for which: String in ["", "cb7"]:
		var combat: Combat = compare.call("fight_named", _content, which)
		var label: String = which if which != "" else "comparison"
		var row: Dictionary = measure({"name": label}, combat.events, true)
		var today_row: Dictionary = row["today"]
		var line: PackedStringArray = [
			"%s: today %d/%d" % [label, today_row["result"], today_row["total"]]
		]
		var variants: Dictionary = row["variants"]
		for variant: String in variants:
			var got: Dictionary = variants[variant]
			line.append("%s %d/%d" % [variant, got["result"], got["total"]])
		print("fight_length: " + ", ".join(line))


## The fights to measure: for each round, `pairs` random pairs of runs that were still playing
## at that round (last_turn >= round), kept when both boards have seven units.
func _pick(options: Dictionary) -> Array[Dictionary]:
	var labels: PackedStringArray = str(options["labels"]).split(",")
	var infos: Array[Dictionary] = []
	for info: Dictionary in _store.find({}):
		if labels.has(str(info.get("label", ""))):
			infos.append(info)
	var pick_seed: int = str(options["seed"]).to_int()
	var rng := RandomNumberGenerator.new()
	rng.seed = pick_seed
	var out: Array[Dictionary] = []
	var tried: int = 0
	for text: String in str(options["rounds"]).split(","):
		var round_number: int = text.to_int()
		var alive: Array[Dictionary] = []
		for info: Dictionary in infos:
			if CoreUtil.to_int(info["last_turn"]) >= round_number:
				alive.append(info)
		var kept: int = 0
		for k: int in str(options["pairs"]).to_int():
			var a: Dictionary = alive[rng.randi_range(0, alive.size() - 1)]
			var b: Dictionary = alive[rng.randi_range(0, alive.size() - 1)]
			if a["id"] == b["id"]:
				continue
			tried += 1
			var spec: Dictionary = {
				"name": "r%02d-%03d" % [round_number, k],
				"field": _store.directory,
				"round": round_number,
				"runs": [a["id"], b["id"]],
				"labels": [a["label"], b["label"]],
				"fight_seed": Rng.hash32("%d|fight|%d|%d" % [pick_seed, round_number, k]),
			}
			var combat: Combat = fight_from_spec(_content, _store, spec)
			if combat == null:
				continue
			var sizes: Array = _board_sizes(combat.events)
			if sizes != [7, 7]:
				continue
			kept += 1
			out.append(spec)
		print("fight_length: round %d: %d full-board fights" % [round_number, kept])
	print("fight_length: %d pairs tried, %d kept" % [tried, out.size()])
	return out


## The fight a spec names, from the rules core: run A's board (side 0, live, as the player's)
## against run B's, as GameSession._fight fights them. Null when a run doesn't load.
static func fight_from_spec(content: GameContent, store: GhostStore, spec: Dictionary) -> Combat:
	var round_number: int = CoreUtil.to_int(spec["round"])
	var session: GameSession = content.new_session(CoreUtil.to_int(spec["fight_seed"]))
	var owners: Array[PlayerState] = []
	var runs: Array = spec["runs"]
	for side: int in 2:
		var fetched: Dictionary = store.fetch(str(runs[side]), content.library, content.registry)
		if not CoreUtil.to_bool(fetched.get("ok", false)):
			printerr("fight_length: %s" % fetched.get("message", "run did not load"))
			return null
		var run: GhostRun = fetched["run"]
		var seat: PlayerState = session.player(side + 1)
		FightSnapshot.restore_player(
			run.payload_for_round(round_number), seat, session, (side + 1) * GhostRun.UID_STRIDE
		)
		owners.append(seat)
	var combat: Combat = Combat.create(
		session.geometry,
		session.config,
		session.registry,
		session.library,
		CoreUtil.to_int(spec["fight_seed"])
	)
	combat.run(
		[owners[0].board, owners[1].board],
		[owners[0].id, owners[1].id],
		[owners[0], owners[1]],
		[true, false],
		[owners[0].hand, owners[1].hand]
	)
	return combat


## A spec file (fights/<name>.json) as a fight, for fight_compare.gd's "spec:" fights.
static func fight_from_file(content: GameContent, path: String) -> Combat:
	var spec: Dictionary = CoreUtil.to_dict(JSON.parse_string(FileAccess.get_file_as_string(path)))
	return fight_from_spec(content, GhostStore.new(str(spec["field"])), spec)


static func base_state() -> Dictionary:
	var base: Dictionary = GlassScreen.load_state(BASE_PATH)
	base.erase("boards")
	base["slots"] = [[], []]
	return base


## A fight screen never shown, for where each unit stands (as best.gd).
static func probe() -> FightScreen:
	var screen: FightScreen = FightScreen.new()
	screen.state = {"you_side": 0}
	screen._g = GlassPieces.fight_geom()
	return screen


## One fight: today, and best with each variant (or best and best_no7 only).
func measure(spec: Dictionary, events: Array, all: bool) -> Dictionary:
	var catalog: Dictionary = {}
	ViewAdapter.add_fight_cards(_content, events, catalog)
	var row: Dictionary = spec.duplicate()
	row.merge(_counts(events))
	var today_replay: FightReplay = FightReplay.build(_base, events, catalog, DAMAGE)
	row["today"] = today(today_replay, _names(events))
	var made: Dictionary = {}
	var variants: Dictionary = {}
	for variant: Array in VARIANTS:
		var variant_name: String = variant[0]
		if not all and variant_name not in ["best", "best_no7"]:
			continue
		var chosen: Dictionary = variant[1]
		var played: Array = TIMELINE.call("reorder", events, chosen)
		var key: String = JSON.stringify([chosen.get("CB4", ""), chosen.get("CB8", "")])
		if not made.has(key):
			var replay: FightReplay = TREATMENT.call(
				"replay_with", BEST_REPLAY, _base, played, catalog, DAMAGE
			)
			made[key] = replay.get("snaps")
		var timeline: RefCounted = TIMELINE.new(chosen)
		timeline.call("build", played, made[key], _place)
		variants[variant_name] = best(timeline, _names(played))
	row["variants"] = variants
	return row


## Today's length: each step held for its hold, counted as FightScreen counts it (one 1/60 s
## frame at a time, the step changing on the frame its wait reaches 0). Steps by kind: start,
## attack (lunge, return home, the exchange's splash), trigger (a trigger's step, and its
## splashes and changes), change (numbers changing with no trigger: auras), death, summon, end.
static func today(replay: FightReplay, names: Dictionary) -> Dictionary:
	var kinds: Dictionary = {}
	var frame: int = 0
	var starts: Array[int] = []
	var last_lunge: Dictionary = {}
	var cycles: Array[Dictionary] = []
	var result: int = 0
	for i: int in replay.steps.size():
		var step: Dictionary = replay.steps[i]
		var hold: float = step["hold"]
		var frames: int = held(hold)
		var state: Dictionary = step["state"]
		var moment: Dictionary = state.get("moment", {})
		var lunge: Dictionary = CoreUtil.to_dict(moment.get("lunge", {})).duplicate()
		lunge.erase("waiting")
		if not lunge.is_empty() and lunge != last_lunge:
			starts.append(frame)
			cycles.append({"from": frame, "attacker": _card_at(state, lunge, names)})
		last_lunge = lunge
		var kind: String = _today_kind(i, replay.steps.size(), step, moment)
		if i == replay.steps.size() - 1:
			result = frame
			kind = "result"
		kinds[kind] = CoreUtil.to_int(kinds.get(kind, 0)) + frames
		frame += frames
	for k: int in cycles.size():
		var to: int = CoreUtil.to_int(cycles[k + 1]["from"]) if k + 1 < cycles.size() else result
		cycles[k]["frames"] = to - CoreUtil.to_int(cycles[k]["from"])
	return {"result": result, "total": frame, "kinds": kinds, "cycles": cycles}


## Frames a step is shown for: FightScreen._process subtracts delta (1/60 s) from its wait each
## frame and moves on once the wait is 0 or less.
static func held(hold: float) -> int:
	var wait: float = hold
	var frames: int = 0
	while wait > 0.0:
		wait -= 1.0 / FPS
		frames += 1
	return maxi(frames, 1)


static func _today_kind(i: int, count: int, step: Dictionary, moment: Dictionary) -> String:
	if i == 0:
		return "start"
	var kind: String = str(step.get("kind", ""))
	var triggered: bool = moment.has("trigger")
	match kind:
		"trigger":
			return "trigger"
		"splash", "change":
			if triggered:
				return "trigger"
			return "attack" if kind == "splash" else "change"
		"death":
			return "death"
		"summon":
			return "summon"
	return "end" if i == count - 1 else "attack"


## Best's length: frames to the result (the queue's end + 24) and the whole film (+ 90), every
## frame of it by what is on screen: attack (an attacker's lift, its least hold, strike and
## return), else trigger (a beat, to the next), death (a fall), summon (an arrival), else start
## (before the first lift), end (after the last thing, to the result) or wait (an attacker
## raised longer than its least hold with nothing else playing; a number being read).
static func best(timeline: RefCounted, names: Dictionary) -> Dictionary:
	var end_frame: int = CoreUtil.to_int(timeline.get("end_frame"))
	var result: int = end_frame - CoreUtil.to_int(TIMELINE.END_HOLD)
	var label: PackedStringArray = []
	label.resize(result)
	label.fill("")
	var windup: Dictionary = TIMELINE.WINDUPS[timeline.call("pick", "CB1")]
	var least: int = CoreUtil.to_int(windup["lift"]) + CoreUtil.to_int(windup["hold"])
	var attacks: Array = timeline.get("attacks")
	var cycles: Array[Dictionary] = []
	var sped: int = 0
	for value: Variant in attacks:
		var attack: Dictionary = value
		var lift: int = CoreUtil.to_int(attack["lift"])
		var launch: int = CoreUtil.to_int(attack["launch"])
		var raised: int = lift + least
		if launch >= 0:
			raised = mini(raised, launch)
			_mark(label, launch, CoreUtil.to_int(attack["home"]), "attack")
		_mark(label, lift, raised, "attack")
		var next: int = CoreUtil.to_int(attack["next_lift"])
		var to: int = next if next >= 0 else result
		var key: String = str(attack["attacker"])
		(
			cycles
			. append(
				{
					"from": lift,
					"frames": to - lift,
					"attacker": names.get(key.trim_prefix("u").to_int(), key),
					"queue":
					CoreUtil.to_int(attack["queue_end"]) - CoreUtil.to_int(attack["queue_from"]),
				}
			)
		)
		if attack.get("speedup", false):
			sped += 1
	for kind: String in ["trigger", "death", "summon"]:
		for value: Variant in timeline.get("spans"):
			var span: Dictionary = value
			if str(span["kind"]) == kind:
				_mark(label, CoreUtil.to_int(span["from"]), CoreUtil.to_int(span["to"]), kind)
	var first: int = result
	if not attacks.is_empty():
		first = CoreUtil.to_int(CoreUtil.to_dict(attacks[0])["lift"])
	var busy_end: int = 0
	for n: int in result:
		if label[n] != "":
			busy_end = n + 1
	var kinds: Dictionary = {}
	for n: int in result:
		var kind: String = label[n]
		if kind == "":
			kind = "start" if n < first else ("end" if n >= busy_end else "wait")
		kinds[kind] = CoreUtil.to_int(kinds.get(kind, 0)) + 1
	kinds["result"] = end_frame - result
	var notes: PackedStringArray = timeline.get("notes")
	return {
		"result": result,
		"total": end_frame,
		"kinds": kinds,
		"cycles": cycles,
		"sped_attacks": sped,
		"notes": notes.size(),
	}


static func _mark(label: PackedStringArray, from: int, to: int, kind: String) -> void:
	for n: int in range(maxi(from, 0), mini(to, label.size())):
		if label[n] == "":
			label[n] = kind


## uid -> card id, from every event that names both.
static func _names(events: Array) -> Dictionary:
	var out: Dictionary = {}
	for value: Variant in events:
		var event: Dictionary = value
		if event.has("uid") and event.has("id"):
			out[CoreUtil.to_int(event["uid"])] = str(event["id"])
		for side: Variant in event.get("boards", []):
			for unit: Variant in side:
				if unit is Dictionary:
					var shown: Dictionary = unit
					out[CoreUtil.to_int(shown.get("uid", -1))] = str(shown.get("id", ""))
	return out


static func _card_at(state: Dictionary, lunge: Dictionary, names: Dictionary) -> String:
	var boards: Array = state.get("boards", [[], []])
	var row: Array = boards[CoreUtil.to_int(lunge["side"])]
	var unit: Variant = row[CoreUtil.to_int(lunge["slot"])]
	if unit is Dictionary:
		var shown: Dictionary = unit
		return str(names.get(CoreUtil.to_int(shown.get("uid", -1)), shown.get("id", "")))
	return ""


static func _board_sizes(events: Array) -> Array:
	for value: Variant in events:
		var event: Dictionary = value
		if str(event.get("type", "")) == "combat_start":
			var sizes: Array = []
			for side: Variant in event.get("boards", []):
				var count: int = 0
				for unit: Variant in side:
					if unit is Dictionary:
						count += 1
				sizes.append(count)
			return sizes
	return []


## How busy a fight is: attacks, triggers, deaths, summons, damage events and all events.
static func _counts(events: Array) -> Dictionary:
	var out: Dictionary = {"attacks": 0, "triggers": 0, "deaths": 0, "summons": 0, "damages": 0}
	var types: Dictionary = {
		"attack": "attacks",
		"trigger": "triggers",
		"death": "deaths",
		"summon": "summons",
		"reserve": "summons",
		"return": "summons",
		"damage": "damages",
	}
	for value: Variant in events:
		var event: Dictionary = value
		var kind: String = str(event.get("type", ""))
		if types.has(kind):
			out[types[kind]] = CoreUtil.to_int(out[types[kind]]) + 1
	out["events"] = events.size()
	out["winner"] = -1
	for value: Variant in events:
		var event: Dictionary = value
		if str(event.get("type", "")) == "combat_end":
			out["winner"] = CoreUtil.to_int(event.get("winner", -1))
	return out


static func _write(path: String, data: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("fight_length: cannot write %s" % path)
		return
	file.store_string(JSON.stringify(data, " "))
