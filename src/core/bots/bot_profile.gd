class_name BotProfile
extends RefCounted
## Opt-in bench counters. No RNG, state changes, or clock-dependent decisions.

static var enabled: bool = false
static var totals: Dictionary = {}
static var counts: Dictionary = {}
static var _stack: Array[String] = []
static var _last: int = 0


static func enter(category: String) -> void:
	if not enabled:
		return
	_charge()
	if category in ["setup", "fights"]:
		counts[category] = CoreUtil.to_int(counts.get(category, 0)) + 1
	_stack.append(category)


static func leave() -> void:
	if not enabled:
		return
	_charge()
	_stack.pop_back()


static func measured() -> int:
	var total: int = 0
	for amount: Variant in totals.values():
		total += CoreUtil.to_int(amount)
	return total


static func _charge() -> void:
	var now: int = Time.get_ticks_usec()
	if not _stack.is_empty():
		var key: String = _stack.back()
		totals[key] = CoreUtil.to_int(totals.get(key, 0)) + now - _last
	_last = now
