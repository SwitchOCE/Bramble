class_name Rng
extends RefCounted
## The core's own hash and random generator (prototype lesson 7: own the generator, not just the
## hash). FNV-1a 32-bit names a stream; xoshiro128** draws from it. Every step stays inside
## 32 bits (multiplications are split into 16-bit halves), so GDScript's 64-bit ints never
## overflow and a seed gives the same numbers on any engine version.
## Each purpose gets its own stream: Rng.derive(game_seed, "shop:3").

const MASK: int = 0xFFFFFFFF
const FNV_OFFSET: int = 0x811C9DC5
const FNV_PRIME: int = 0x01000193

var _s: PackedInt64Array = PackedInt64Array([0, 0, 0, 0])


func _init(seed_value: int = 0) -> void:
	var state: int = seed_value & MASK
	for word: int in 4:
		state = (state + 0x9E3779B9) & MASK
		var z: int = state
		z = mul32(z ^ (z >> 16), 0x85EBCA6B)
		z = mul32(z ^ (z >> 13), 0xC2B2AE35)
		_s[word] = z ^ (z >> 16)
	if _s[0] == 0 and _s[1] == 0 and _s[2] == 0 and _s[3] == 0:
		_s[0] = 1


## A stream for one purpose: the same seed and label always give the same numbers.
static func derive(seed_value: int, label: String) -> Rng:
	return Rng.new(hash32("%d|%s" % [seed_value, label]))


## FNV-1a over the UTF-8 bytes of `text`.
static func hash32(text: String) -> int:
	var h: int = FNV_OFFSET
	for byte: int in text.to_utf8_buffer():
		h = mul32(h ^ byte, FNV_PRIME)
	return h


## (a * b) mod 2^32 without leaving 48 bits.
static func mul32(a: int, b: int) -> int:
	a &= MASK
	b &= MASK
	var low: int = a * (b & 0xFFFF)
	var high: int = ((a * (b >> 16)) & 0xFFFF) << 16
	return (low + high) & MASK


static func _rotl(x: int, k: int) -> int:
	return ((x << k) | (x >> (32 - k))) & MASK


## The next 32-bit output, 0 to 2^32 - 1.
func next_u32() -> int:
	var result: int = mul32(_rotl(mul32(_s[1], 5), 7), 9)
	var t: int = (_s[1] << 9) & MASK
	_s[2] ^= _s[0]
	_s[3] ^= _s[1]
	_s[1] ^= _s[2]
	_s[0] ^= _s[3]
	_s[2] ^= t
	_s[3] = _rotl(_s[3], 11)
	return result


## Uniform in [low, high], without modulo bias.
func range_int(low: int, high: int) -> int:
	if high <= low:
		return low
	var bound: int = high - low + 1
	var limit: int = (MASK + 1) - ((MASK + 1) % bound)
	var roll: int = next_u32()
	while roll >= limit:
		roll = next_u32()
	return low + roll % bound


## Uniform index into a list of `size` items; -1 for an empty list.
func index(size: int) -> int:
	if size <= 0:
		return -1
	return range_int(0, size - 1)


## Fisher-Yates in place.
func shuffle(items: Array) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j: int = range_int(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap
