extends RefCounted
## Keep historical gameplay replays exact while allowing Ring snapshots and one UI wording edit.
## frozen_replay_proof.py proves the archived raw fixtures before using this projection.

const FROZEN_PASS := "Pass X: your last unit, other than this, gains X"
const CURRENT_PASS := "Pass X: your rightmost unit, other than this, gains X."


static func gameplay(value: Variant) -> Variant:
	if value is Array:
		var items: Array = value
		return items.map(gameplay)
	if value is Dictionary:
		var original: Dictionary = value
		var out: Dictionary = {}
		for key: Variant in original:
			if (
				str(original.get("type", "")) == "ring_dance"
				and key in ["moved_count", "from_ring", "to_ring"]
			):
				continue
			if key == "keyword_text" and original.has("uid") and original.has("def_id"):
				var entries: Array = original[key]
				out[key] = entries.map(_historical_reminder)
			else:
				out[key] = gameplay(original[key])
		return out
	return value


static func _historical_reminder(value: Variant) -> Variant:
	var projected: Variant = gameplay(value)
	if projected is Dictionary:
		var entry: Dictionary = projected
		# Exact snapshot reminder alias only: every other text and field stays compared.
		if entry.get("keyword") == "Pass" and entry.get("text") == CURRENT_PASS:
			entry["text"] = FROZEN_PASS
	return projected
