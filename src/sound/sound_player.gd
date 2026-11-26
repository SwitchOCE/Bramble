class_name SoundPlayer
extends Node
## The game's sound, as the autoload `Sound`. It plays the cues in Neon's table
## (assets/audio/cues.json; how they are meant to be used: docs/workstreams/sound/audio-spec.md),
## on its own bus with a limiter, at the player's volume (GameSettings).
##
## Sound must never change a fight: this reads only what the screens show, never the rules core,
## and its random source is its own. Per cue the table gives the takes, loudness, pitch range,
## gain jitter, how many may sound at once (max_voices) and the shortest gap between two starts
## (min_gap_s). A take is never the same as the one before it, nor one already used in the same
## step. A cue the table doesn't have yet stays silent: Neon's set grows in batches, so this is
## normal and not warned about; with keep_log on it is logged as dropped "missing".

const TABLE_PATH: String = "res://assets/audio/cues.json"
const BUS: StringName = &"Sfx"
## The limiter is a safety net for many hits at once, not the mix.
const LIMIT_CEILING_DB: float = -1.0
const VOICES: int = 16

## Every cue asked for, while keep_log is on: {cue, file, at_ms, gain_db, pitch, dropped}.
## dropped is "" when it played, else why not (missing, voices, gap, busy).
var heard: Array[Dictionary] = []
var keep_log: bool = false
var table: Dictionary = {}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _players: Array[AudioStreamPlayer] = []
## player -> cue name it is playing
var _playing_cue: Dictionary = {}
var _streams: Dictionary = {}
var _last_take: Dictionary = {}
var _last_start_ms: Dictionary = {}
var _step_takes: Dictionary = {}
## [{at_ms, cue, gain_db}] waiting for their stagger
var _queued: Array[Dictionary] = []


func _ready() -> void:
	# the pause panel plays a hit at the new volume while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	load_table(TABLE_PATH)
	_ensure_bus()
	for i: int in VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		player.bus = BUS
		add_child(player)
		_players.append(player)
	apply_settings()


## Reads the table; an unreadable one leaves every cue silent (and says so once).
func load_table(path: String) -> void:
	table = {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if parsed is Dictionary:
		table = parsed
	else:
		push_warning("sound: could not read %s; no sound" % path)


## The player's volume and mute from GameSettings, applied to the sound bus.
func apply_settings() -> void:
	var bus: int = AudioServer.get_bus_index(BUS)
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(GameSettings.volume(), 0.0001)))
	AudioServer.set_bus_mute(bus, GameSettings.muted() or GameSettings.volume() <= 0.0)


## The fight screen calls this as it shows each step.
func fight_step(step: Dictionary, before: Dictionary = {}) -> void:
	_step_takes.clear()
	for cue: Dictionary in SoundCues.for_fight_step(step, table, before):
		play(str(cue["cue"]), _num(cue["delay_s"]), _num(cue["gain_db"]))


## The fight screen calls this as each moment of a fight's schedule comes (FightTimeline cues).
func fight_cue(cue: Dictionary) -> void:
	_step_takes.clear()
	for each: Dictionary in SoundCues.for_fight_cue(cue, table):
		play(str(each["cue"]), _num(each["delay_s"]), _num(each["gain_db"]))


## Plays a cue now, or after delay_s, with gain_db on top of the table's loudness.
func play(cue: String, delay_s: float = 0.0, gain_db: float = 0.0) -> void:
	if delay_s > 0.0:
		var at_ms: int = Time.get_ticks_msec() + int(delay_s * 1000.0)
		_queued.append({"at_ms": at_ms, "cue": cue, "gain_db": gain_db})
		return
	_start(cue, gain_db)


func _process(_delta: float) -> void:
	if _queued.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var due: Array[Dictionary] = []
	for item: Dictionary in _queued:
		if CoreUtil.to_int(item["at_ms"]) <= now:
			due.append(item)
	for item: Dictionary in due:
		_queued.erase(item)
		_start(str(item["cue"]), _num(item["gain_db"]))


func _start(cue: String, gain_db: float) -> void:
	var entry: Dictionary = {"cue": cue, "file": "", "at_ms": Time.get_ticks_msec(), "dropped": ""}
	var cues: Dictionary = CoreUtil.to_dict(table.get("cues", {}))
	var spec: Dictionary = CoreUtil.to_dict(cues.get(cue, {}))
	var files: Array = CoreUtil.to_array(spec.get("files", []))
	if files.is_empty():
		_note(entry, "missing")
		return
	var now: int = Time.get_ticks_msec()
	var gap_ms: int = int(_num(spec.get("min_gap_s", 0.0)) * 1000.0)
	if _last_start_ms.has(cue) and now - CoreUtil.to_int(_last_start_ms[cue]) < gap_ms:
		_note(entry, "gap")
		return
	if _voices_of(cue) >= maxi(1, CoreUtil.to_int(spec.get("max_voices", 4))):
		_note(entry, "voices")
		return
	var player: AudioStreamPlayer = _free_player()
	if player == null:
		_note(entry, "busy")
		return
	var file: String = _pick(cue, files)
	var stream: AudioStream = _stream(file)
	if stream == null:
		_note(entry, "missing")
		return
	var pitch_range: Array = CoreUtil.to_array(spec.get("pitch", [1.0, 1.0]))
	var pitch: float = 1.0
	if pitch_range.size() == 2:
		pitch = _rng.randf_range(_num(pitch_range[0]), _num(pitch_range[1]))
	var jitter: float = _num(spec.get("gain_jitter_db", 0.0))
	var db: float = _num(spec.get("volume_db", 0.0)) + gain_db + _rng.randf_range(-jitter, jitter)
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = db
	player.play()
	_playing_cue[player] = cue
	_last_start_ms[cue] = now
	entry["file"] = file
	entry["gain_db"] = db
	entry["pitch"] = pitch
	_note(entry, "")


func _note(entry: Dictionary, dropped: String) -> void:
	entry["dropped"] = dropped
	if keep_log:
		heard.append(entry)


## A take: never the one before it, nor (while others are left) one already used in this step.
func _pick(cue: String, files: Array) -> String:
	var choices: Array[String] = []
	for value: Variant in files:
		var take: String = str(value)
		if take != str(_last_take.get(cue, "")) and not _step_takes.has(take):
			choices.append(take)
	if choices.is_empty():
		# every take used in this step: still not the one before
		for value: Variant in files:
			if str(value) != str(_last_take.get(cue, "")) or files.size() == 1:
				choices.append(str(value))
	var file: String = choices[_rng.randi_range(0, choices.size() - 1)]
	_last_take[cue] = file
	_step_takes[file] = true
	return file


func _stream(file: String) -> AudioStream:
	if not _streams.has(file):
		var loaded: Resource = load(file) if ResourceLoader.exists(file) else null
		_streams[file] = loaded as AudioStream
	var stream: AudioStream = _streams[file]
	return stream


func _voices_of(cue: String) -> int:
	var count: int = 0
	for player: AudioStreamPlayer in _players:
		if player.playing and str(_playing_cue.get(player, "")) == cue:
			count += 1
	return count


func _free_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player
	return null


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	AudioServer.add_bus()
	var bus: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, BUS)
	AudioServer.set_bus_send(bus, &"Master")
	var limiter: AudioEffectHardLimiter = AudioEffectHardLimiter.new()
	limiter.ceiling_db = LIMIT_CEILING_DB
	AudioServer.add_bus_effect(bus, limiter)


static func _num(value: Variant) -> float:
	if value is float:
		return value
	if value is int:
		return float(CoreUtil.to_int(value))
	return 0.0
