extends Mechanic
## A plain return in charges (the locusts' Molt, through the return protocol): one charge a
## fight plus any test_molt_extra given this fight; back as a plain copy with 1 Health, then
## +{amount}/+{amount} permanently. Charges are a per-fight limit (fight_count), so the core
## carries them across a return (SHARED-RULES 21); the screen sees what is left (show_uses).

const USED: StringName = &"test_molt_used"
const EXTRA: StringName = &"test_molt_extra"


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func return_offer(_combat: Combat, unit: CombatUnit, _params: MechanicParams) -> int:
	return 1 if left(unit) > 0 else 0


func pay_return(combat: Combat, gone: CombatUnit, back: CombatUnit, params: MechanicParams) -> void:
	back.add_fight_count(USED)
	var amount: int = params.num(&"amount")
	combat.buff(back, amount, amount, gone, true)
	combat.show_uses(back, USED, left(back), gone)


static func left(unit: CombatUnit) -> int:
	return 1 + unit.fight_count(EXTRA) - unit.fight_count(USED)
