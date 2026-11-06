extends Node
## The game's sound effects. Screens call the static `Sfx.play("buy")`; one instance, owned by the
## App, holds the players. Without an instance (a screen tested alone) a call does nothing audible.
## Sounds are made by tools/audio/make_sfx.py; a name here is a file assets/audio/<name>.wav.
## Headless runs use Godot's Dummy audio driver, so nothing here needs a sound card.

const Settings := preload("res://src/ui/settings.gd")

const FOLDER: String = "res://assets/audio/%s.wav"
const EFFECTS_BUS: StringName = &"Effects"
const VOICES: int = 8
const SOUNDS: PackedStringArray = [
	"tap",
	"place",
	"buy",
	"sell",
	"refresh",
	"freeze",
	"tier_up",
	"gold",
	"acorns_combine",
	"triple",
	"discover",
	"hero_power",
	"turn_end",
	"attack",
	"hit_small",
	"hit_medium",
	"hit_big",
	"death",
	"summon",
	"keyword",
	"ring",
	"win",
	"loss",
	"squeak_ooze",
	"squeak_fairy",
]
## Pitch moves by up to this share each play, so repeats don't grate. Tuned phrases move less.
const PITCH_SPREAD: float = 0.05
const PHRASE_SPREAD: float = 0.012
const PHRASES: PackedStringArray = ["tier_up", "triple", "discover", "win", "loss", "ring"]
## The least time between two plays of a sound, in real time: fights at ×4 must not machine-gun.
const DEFAULT_GAP_MS: int = 40
const GAP_MS: Dictionary[String, int] = {
	"attack": 300,
	"hit_small": 200,
	"hit_medium": 200,
	"hit_big": 200,
	"death": 150,
	"summon": 250,
	"keyword": 300,
	"ring": 300,
	"squeak_ooze": 500,
	"squeak_fairy": 500,
}
## Fight sounds share this budget per second. At ×1 a fight never reaches it.
const BUDGET_PER_SECOND: int = 5
const BUDGETED: PackedStringArray = [
	"attack", "hit_small", "hit_medium", "hit_big", "summon", "keyword", "ring"
]
const TRIBE_VOICES: Dictionary[String, String] = {
	"Oozes": "squeak_ooze",
	"Fairies": "squeak_fairy",
}

## Tests turn this on to read what was asked for, before any rate limit.
static var logging: bool = false
static var requests: PackedStringArray = []
static var _instance: Node = null
static var _last_played: Dictionary[String, int] = {}
static var _budget_times: Array[int] = []

var _voices: Array[AudioStreamPlayer] = []
var _streams: Dictionary[String, AudioStream] = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_voice: int = 0


func _init() -> void:
	_rng.randomize()
	for i: int in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = EFFECTS_BUS
		add_child(voice)
		_voices.append(voice)


func _enter_tree() -> void:
	_instance = self
	apply_volumes()


func _exit_tree() -> void:
	if _instance == self:
		_instance = null


static func play(sound: String) -> void:
	if not SOUNDS.has(sound):
		push_error("Sfx: no sound named '%s'" % sound)
		return
	if logging:
		requests.append(sound)
	if allowed(sound, Time.get_ticks_msec()) and _instance != null:
		_instance.call("_start", sound)


## The button click, for connecting straight to a `pressed` signal.
static func tap() -> void:
	play("tap")


## An ooze or fairy says something when played or attacking.
static func play_voice(tribes: Array) -> void:
	var voice: String = voice_for(tribes)
	if not voice.is_empty():
		play(voice)


static func voice_for(tribes: Array) -> String:
	for tribe: Variant in tribes:
		var voice: String = TRIBE_VOICES.get(str(tribe), "")
		if not voice.is_empty():
			return voice
	return ""


## Stops what's ringing, bar the click of the button that asked (Skip).
static func silence() -> void:
	if _instance != null:
		_instance.call("_stop_all_but_tap")


## The rate limit: may `sound` start at `now_ms`? If so, it counts as started.
static func allowed(sound: String, now_ms: int) -> bool:
	var gap: int = GAP_MS.get(sound, DEFAULT_GAP_MS)
	if _last_played.has(sound) and now_ms - _last_played[sound] < gap:
		return false
	if BUDGETED.has(sound):
		_budget_times = _budget_times.filter(func(at: int) -> bool: return now_ms - at < 1000)
		if _budget_times.size() >= BUDGET_PER_SECOND:
			return false
		_budget_times.append(now_ms)
	_last_played[sound] = now_ms
	return true


## Forgets recent plays and logged requests (tests).
static func reset_limits() -> void:
	_last_played.clear()
	_budget_times.clear()
	requests.clear()


## Sets the buses from Settings. A volume is a 0..1 slider: squared, so it feels even to the ear.
static func apply_volumes() -> void:
	var effects: int = AudioServer.get_bus_index(EFFECTS_BUS)
	if effects < 0:
		AudioServer.add_bus()
		effects = AudioServer.bus_count - 1
		AudioServer.set_bus_name(effects, EFFECTS_BUS)
		AudioServer.set_bus_send(effects, &"Master")
	_set_bus(0, Settings.master_volume)
	_set_bus(effects, Settings.effects_volume)


static func _set_bus(bus: int, volume: float) -> void:
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, 2.0 * linear_to_db(maxf(volume, 0.001)))


func _start(sound: String) -> void:
	if not _streams.has(sound):
		_streams[sound] = load(FOLDER % sound)
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	var spread: float = PHRASE_SPREAD if PHRASES.has(sound) else PITCH_SPREAD
	voice.stream = _streams[sound]
	voice.pitch_scale = _rng.randf_range(1.0 - spread, 1.0 + spread)
	voice.play()


func _stop_all_but_tap() -> void:
	var click: AudioStream = _streams.get("tap")
	for voice: AudioStreamPlayer in _voices:
		if voice.stream != click:
			voice.stop()
