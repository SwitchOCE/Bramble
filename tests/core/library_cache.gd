class_name TestLibraries
extends RefCounted
## Test-only: builds each unit library once a run and hands each caller a deep copy (test-suite plan
## step 4, 5a). A copy (about 4 ms) is far cheaper than a parse (about 75 ms), the frozen legacy
## library (about 190 ms) or a configured overlay (about 125 ms, built twice per kit), and callers
## may still register or edit cards freely.
## A parse reads the effect schema for keyword reminders and the pass-3 rates for card text, so a
## cached library is only reused while the same schema is loaded (field_frozen_content.gd swaps it)
## and the rates are unchanged; otherwise it is built afresh. Tests of the parse itself still call
## UnitLibrary.load_dir().
## The cached masters are never handed out, so no game compiles mechanics into them.

static var _cache: Dictionary = {}


## A fresh copy of `UnitLibrary.load_dir()`.
static func current() -> UnitLibrary:
	return cached("current", UnitLibrary.load_dir)


## A fresh copy of what `builder` returns, built once a run per key (the legacy libraries use this).
static func cached(key: String, builder: Callable) -> UnitLibrary:
	return copy(_master(key, builder))


## A fresh copy of what ScaleOverlay.library_for(<base>, config) returns, where base is current()
## or LegacyWave1.library(). RecruitRules.create and UnitPool.create return it as it is, since it
## carries the overlay's key; if the config changes first, they rebuild from its copied source as
## before. Runs Pass3Birds.detect_pool first, as RecruitRules.create does, so the key is the one
## it sees.
static func configured(config: GameConfig, legacy_base: bool = false) -> UnitLibrary:
	var base_key: String = "wave1:true" if legacy_base else "current"
	var base: UnitLibrary = _master(
		base_key, LegacyWave1.build.bind(true) if legacy_base else UnitLibrary.load_dir
	)
	if ReferenceQuilboar.request_error(config) != "":
		# A refused reference request: hand over the plain base and let the real calls refuse it.
		return copy(base)
	var probe := RecruitRules.new()
	probe.library = base
	probe.config = config
	Pass3Birds.detect_pool(probe)
	# Keyed by this base build too: if the base is rebuilt, its overlays are as well.
	var key: String = "%s|%d|%s" % [base_key, base.get_instance_id(), ScaleOverlay._key(config)]
	var overlaid: UnitLibrary = _master(key, ScaleOverlay.library_for.bind(base, config))
	if not overlaid.has_meta("scale_overlay_key"):
		# This config needs no overlay: library_for returns the base as it is.
		return copy(base)
	var out: UnitLibrary = copy(overlaid)
	# Every overlay mark (its key, reference_quilboar), with the source as a copy of its own.
	for meta: StringName in overlaid.get_meta_list():
		out.set_meta(meta, overlaid.get_meta(meta))
	out.set_meta("scale_overlay_source", copy(base))
	return out


## The cached library for `key`, built once while the schema stays the same. Never handed out.
static func _master(key: String, builder: Callable) -> UnitLibrary:
	var entry: Dictionary = _cache.get(key, {})
	var inputs: int = _inputs()
	if (
		entry.is_empty()
		or not is_same(entry["schema"], EffectSchema.data())
		or entry["inputs"] != inputs
	):
		var built: UnitLibrary = builder.call()
		entry = {"schema": EffectSchema.data(), "inputs": inputs, "library": built}
		_cache[key] = entry
	var library: UnitLibrary = entry["library"]
	return library


## The authored rates the parse writes into card text; tests edit them in place.
static func _inputs() -> int:
	Pass3Rates.defaults()
	return str([Pass3Rates._defaults, Pass3Rates._presets, Pass3Rates._default_preset]).hash()


## A deep copy: no dictionary is shared with the source. Metadata isn't copied.
static func copy(source: UnitLibrary) -> UnitLibrary:
	var out := UnitLibrary.new()
	for unit: Dictionary in source._units:
		var dup: Dictionary = unit.duplicate(true)
		out._units.append(dup)
		out._by_id[dup["id"]] = dup
	out._errors = source._errors.duplicate()
	out._cards = source._cards.duplicate(true)
	out._heroes = source._heroes.duplicate(true)
	return out
