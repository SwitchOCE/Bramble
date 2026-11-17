class_name Matchmaking
extends RefCounted
## Round pairings (2.3). While everyone is alive, a round-robin from a seeded order, so each
## player meets every opponent once before meeting anyone again (2.3.1). After the first
## elimination, the pairing with the fewest repeats of the last 3 rounds' opponents, from every
## possible pairing (2.3.2); ties are broken at random. An odd player out fights the ghost
## (2.1.2), id GHOST.

const GHOST: int = -1
const AVOID_ROUNDS: int = 3


## 2.3.1 round `index` (0-based) of the circle-method round-robin over `order` (even size).
static func round_robin(order: Array[int], index: int) -> Array:
	var count: int = order.size()
	var rest: Array[int] = order.slice(1)
	var shift: int = index % maxi(1, rest.size())
	var turned: Array[int] = rest.slice(rest.size() - shift) + rest.slice(0, rest.size() - shift)
	var circle: Array[int] = [order[0]]
	circle.append_array(turned)
	var pairs: Array = []
	@warning_ignore("integer_division")
	var half: int = count / 2
	for i: int in half:
		pairs.append(_pair(circle[i], circle[count - 1 - i]))
	return _sorted(pairs)


## 2.3.2: the least-repeating pairing of `ids` (living players, plus the ghost when odd).
static func avoiding(ids: Array[int], history: Dictionary, rng: Rng) -> Array:
	var people: Array[int] = ids.duplicate()
	if people.size() % 2 == 1:
		people.append(GHOST)
	var all: Array = []
	_matchings(people, [], all)
	var best: Array = []
	var best_cost: int = -1
	for matching: Variant in all:
		var pairs: Array = matching
		var cost: int = _repeats(pairs, history)
		if best_cost < 0 or cost < best_cost:
			best_cost = cost
			best = [pairs]
		elif cost == best_cost:
			best.append(pairs)
	if best.is_empty():
		return []
	var chosen: Array = best[rng.index(best.size())]
	return _sorted(chosen)


static func _matchings(people: Array[int], partial: Array, out: Array) -> void:
	if people.is_empty():
		out.append(partial.duplicate())
		return
	var first: int = people[0]
	for i: int in range(1, people.size()):
		var rest: Array[int] = people.duplicate()
		var other: int = rest[i]
		rest.remove_at(i)
		rest.remove_at(0)
		partial.append(_pair(first, other))
		_matchings(rest, partial, out)
		partial.pop_back()


## history: player id -> Array[int] of past opponents, latest last.
static func _repeats(pairs: Array, history: Dictionary) -> int:
	var cost: int = 0
	for value: Variant in pairs:
		var pair: Array = value
		var a: int = CoreUtil.to_int(pair[0])
		var b: int = CoreUtil.to_int(pair[1])
		for who: int in [a, b]:
			var other: int = b if who == a else a
			var past: Array = history.get(who, [])
			if past.slice(maxi(0, past.size() - AVOID_ROUNDS)).has(other):
				cost += 1
	return cost


## A pair is [a, b] with the ghost last, otherwise the lower id first.
static func _pair(a: int, b: int) -> Array:
	if a == GHOST or (b != GHOST and b < a):
		return [b, a]
	return [a, b]


static func _sorted(pairs: Array) -> Array:
	var out: Array = pairs.duplicate()
	out.sort_custom(func(x: Array, y: Array) -> bool: return _key(x) < _key(y))
	return out


static func _key(pair: Array) -> int:
	return CoreUtil.to_int(pair[0])
