extends Mechanic
## 11.2.4 Reborn (example keyword): the first time this unit dies in a combat, it returns with
## 1 Health as a fresh copy (9.8.2) and can't return again that combat. Through the return
## protocol, as a plain return (a Molt or Root on the same unit is asked the same way).


func return_offer(_combat: Combat, unit: CombatUnit, _params: MechanicParams) -> int:
	return 1 if unit.returns == 0 else 0


func pay_return(combat: Combat, gone: CombatUnit, back: CombatUnit, _params: MechanicParams) -> void:
	combat.show_status(back, &"reborn", false, gone)
