class_name UnitDef
extends RefCounted
## One card as data: a unit, a token (Created only, never in the pool, 5.3.6) or a Tavern
## spell (6.1.5). Its keywords and effects are mechanic ids with typed parameters (MechanicSpec).

enum Kind { UNIT, SPELL }

var id: StringName = &""
var name: String = ""
var kind: Kind = Kind.UNIT
var tier: int = 1
var attack: int = 0
var health: int = 1
## 5.2.1 the type line, e.g. ["Owl", "Warrior"]. 5.2.2 which types are tribes is open; this
## track's lobby filter reads `tribes`.
var types: PackedStringArray = []
var tribes: PackedStringArray = []
## Keywords are mechanics with no parameters (taunt, reborn...). Kept apart for display.
var keywords: Array[StringName] = []
## Every mechanic on the card, keywords included, in card order.
var mechanics: Array[MechanicSpec] = []
## True for a token: Created only, never drawn (glossary "Token").
var token: bool = false
## 4.2.5 a spell's listed cost. Units cost by tier (4.2.1).
var cost: int = 0
## Set by the library for spells that the shop never offers (the Triple Reward).
var offered: bool = true
var text: String = ""


func is_spell() -> bool:
	return kind == Kind.SPELL


func in_pool() -> bool:
	return not token and offered


func has_tribe(tribe: String) -> bool:
	return tribes.has(tribe) or tribes.has("All")
