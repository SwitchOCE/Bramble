class_name Matchmaking
extends RefCounted
## Round pairings (SPEC section 9 pick for 2.1.5 / 2.3): random from the seed, avoiding each
## player's last 3 opponents where possible; an odd player out fights the ghost (2.1.2), id -1.

const GHOST: int = -1
const ATTEMPTS: int = 40


## `players` are the living players. Returns pairs [a, b] with a < b, or [a, GHOST].
static func pair(players: Array[PlayerState], rng: RandomNumberGenerator) -> Array:
	var best: Array = []
	var best_repeats: int = -1
	for _attempt: int in ATTEMPTS:
		var order: Array[PlayerState] = players.duplicate()
		for i: int in range(order.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, i)
			var swap: PlayerState = order[i]
			order[i] = order[j]
			order[j] = swap
		var pairs: Array = []
		var repeats: int = 0
		var index: int = 0
		while index < order.size():
			var a: PlayerState = order[index]
			if index + 1 >= order.size():
				pairs.append([a.id, GHOST])
				repeats += 1 if a.recent_opponents.has(GHOST) else 0
				break
			var b: PlayerState = order[index + 1]
			pairs.append([mini(a.id, b.id), maxi(a.id, b.id)])
			repeats += 1 if a.recent_opponents.has(b.id) else 0
			index += 2
		if best_repeats < 0 or repeats < best_repeats:
			best = pairs
			best_repeats = repeats
		if best_repeats == 0:
			break
	best.sort_custom(
		func(x: Array, y: Array) -> bool: return CoreUtil.to_int(x[0]) < CoreUtil.to_int(y[0])
	)
	return best
