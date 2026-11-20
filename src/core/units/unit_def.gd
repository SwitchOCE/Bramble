class_name UnitDef
extends RefCounted
## One card as data: a unit, a token (Created only) or a Tavern
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
## Printed keywords (usually unparameterized), kept apart for display.
var keywords: Array[StringName] = []
## Every mechanic on the card, keywords included, in card order.
var mechanics: Array[MechanicSpec] = []
## True for a token: Created only, never drawn (glossary "Token").
var token: bool = false
## False for a card that never combines into a golden (7.3.1), from card data "combines".
var combines: bool = true
## 4.2.5 a spell's listed cost. Units cost by tier (4.2.1).
var cost: int = 0
## Set by the library for spells that the shop never offers (the Triple Reward).
var offered: bool = true
var text: String = ""
## The text a golden copy shows, from card data "golden_text", when its golden effect is not
## the plain text with doubled numbers ("triple"); "" means use `text`.
var golden_text: String = ""
## Extra reminder lines the card shows (card data "reminders": ["Only one pays each fight."]).
var reminders: PackedStringArray = []


func is_spell() -> bool:
	return kind == Kind.SPELL


func can_be_drawn() -> bool:
	return not token and offered


func has_tribe(tribe: String) -> bool:
	return tribes.has(tribe) or tribes.has("All")
