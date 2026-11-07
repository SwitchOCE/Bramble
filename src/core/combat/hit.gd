class_name Hit
extends RefCounted
## One damage event in the making (9.6.3): who hits whom for how much, and how it was modified.

const ATTACK: String = "attack"
const THORNS: String = "thorns"
const EFFECT: String = "effect"

var owner_side: int = -1
var source: CombatUnit
var target: CombatUnit
var raw: int = 0
var amount: int = 0
var kind: String = ATTACK
var strike: int = 1
## True when the target is the defender of the attack this hit belongs to (Hunker).
var on_defender: bool = false
var modifiers: Array[String] = []


static func make(
	from: CombatUnit, to: CombatUnit, damage: int, hit_kind: String, strike_number: int = 1
) -> Hit:
	var hit := Hit.new()
	hit.owner_side = from.side if from != null else -1
	hit.source = from
	hit.target = to
	hit.raw = damage
	hit.amount = damage
	hit.kind = hit_kind
	hit.strike = strike_number
	return hit


## Peck: Attack split as evenly as possible, larger parts first.
static func split(attack: int, parts: int) -> Array[int]:
	var out: Array[int] = []
	@warning_ignore("integer_division")
	var base: int = attack / parts
	var extra: int = attack % parts
	for index: int in parts:
		out.append(base + (1 if index < extra else 0))
	return out
