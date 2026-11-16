extends RefCounted
## Neutral test mechanics, one per capability the tribes need from the interface. They are not
## content and name no tribe: each proves that a kind of card can be written as data plus a small
## script without touching the engine. tests/core/data/bridge_units.json puts them on cards;
## the soak plays them.

## The heap every player's sales feed, for the heap mechanics below.
const HEAP: StringName = &"heap"


static func register(registry: MechanicRegistry) -> void:
	registry.register(&"medal_after_fight", MedalAfterFight.new())
	registry.register(&"fury_gain", FuryGain.new())
	registry.register(&"outnumbered_aura", OutnumberedAura.new())
	registry.register(&"pile_on", PileOn.new())
	registry.register(&"drill_slot", DrillSlot.new())
	registry.register(&"order_slot", OrderSlot.new())
	registry.register(&"heap_on_sale", HeapOnSale.new())
	registry.register(&"bury", Bury.new())
	registry.register(&"grow", Grow.new())
	registry.register(&"seed_heap", SeedHeap.new())
	registry.register(&"root", Root.new())
	registry.register(&"tide_on_death", TideOnDeath.new())
	registry.register(&"tide_rider", TideRider.new())
	registry.register(&"death_twice", DeathTwice.new())
	registry.register(&"charge", Charge.new())
	registry.register(&"back_row_raider", BackRowRaider.new())
	registry.register(&"swarm_spawn", SwarmSpawn.new())
	registry.register(&"step_up", StepUp.new())
	registry.register(&"lend_keyword", LendKeyword.new())
	registry.register(&"eat", Eat.new())
	registry.register(&"greet", Greet.new())
	registry.register(&"plate", Plate.new())
	registry.register(&"first_strike", FirstStrike.new())
	registry.register(&"slot_gift", SlotGift.new())


## Bridge, lasting unit state: after each fight, a medal (two if it survived), and +1/+1 for
## good per medal earned.
class MedalAfterFight:
	extends Mechanic

	func after_fight(
		ctx: RecruitContext, unit: Unit, report: FightReport, _params: MechanicParams
	) -> void:
		if unit == null or not ctx.trigger(unit, &"medal_after_fight"):
			return
		var medals: int = 2 if report.survived(unit) else 1
		ctx.add_unit_counter(unit, &"medal", medals, unit)
		ctx.buff(unit, medals, medals, true, unit)


## Bridge, permanent write-back from a fight: whenever this attacks while outnumbered, +1/+1
## for good.
class FuryGain:
	extends Mechanic

	func on_attack(
		combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
	) -> void:
		var outnumbered: bool = combat.units(1 - unit.side).size() > combat.units(unit.side).size()
		if outnumbered and combat.trigger(unit, &"fury_gain"):
			combat.buff(unit, 1, 1, unit, true)


## An aura that sees the fight: +amount Attack to itself while outnumbered.
class OutnumberedAura:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"amount": MechanicParams.Kind.NUMBER}

	func has_aura() -> bool:
		return true

	func aura(
		view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
	) -> Vector2i:
		if source_slot == target_slot and view.outnumbered():
			return Vector2i(params.num(&"amount"), 0)
		return Vector2i.ZERO


## Attack listener: when an adjacent friend attacks, this hits the defender first.
class PileOn:
	extends Mechanic

	func on_friendly_attack(
		combat: Combat,
		unit: CombatUnit,
		attacker: CombatUnit,
		defender: CombatUnit,
		_params: MechanicParams
	) -> void:
		if unit == null or not combat.geometry.adjacent(unit.slot).has(attacker.slot):
			return
		if combat.trigger(unit, &"pile_on"):
			combat.hit(unit, defender)


## Slot effects: at the end of your turn, this slot gets +1/+1 for good.
class DrillSlot:
	extends Mechanic

	func on_end_of_turn(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
		if unit != null and ctx.trigger(unit, &"drill_slot"):
			ctx.slot_buff(unit.slot, 1, 1, unit)


## An ability with a slot target and a gold cost: pay 1, a slot gets +2/+2 and is a guard
## post (gives Taunt).
class OrderSlot:
	extends Mechanic

	func has_ability() -> bool:
		return true

	func ability_cost(_params: MechanicParams) -> int:
		return 1

	func ability_target(_params: MechanicParams) -> Target:
		return Target.SLOT

	func on_ability(
		ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams
	) -> void:
		if ctx.trigger(unit, &"order_slot"):
			ctx.slot_buff(ctx.target_index, 2, 2, unit, &"taunt")


## Standing (no unit): every Bought copy sold goes into the heap.
class HeapOnSale:
	extends Mechanic

	func on_any_sold(ctx: RecruitContext, _unit: Unit, sold: Unit, _params: MechanicParams) -> void:
		for _copy: int in sold.bought_copies:
			ctx.heap_add(HEAP, sold.def.id, null)


## An ability on a shop card: once a turn, a shop unit goes into the heap.
class Bury:
	extends Mechanic

	func has_ability() -> bool:
		return true

	func ability_target(_params: MechanicParams) -> Target:
		return Target.SHOP_UNIT

	func on_ability(
		ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams
	) -> void:
		if not ctx.trigger(unit, &"bury"):
			return
		var card_id: StringName = ctx.take_from_shop(ctx.target_index, unit)
		if card_id != &"":
			ctx.heap_add(HEAP, card_id, unit)


## Start of Combat, reading the real heap: +amount/+amount for each entry, this fight.
class Grow:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"amount": MechanicParams.Kind.NUMBER}

	func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
		var size: int = combat.bridge(unit.side).heap(HEAP).size()
		if size > 0 and combat.trigger(unit, &"grow"):
			var amount: int = params.num(&"amount") * size
			combat.buff(unit, amount, amount, unit)


## A death in the fight adds to the real heap: a copy of this card goes in.
class SeedHeap:
	extends Mechanic

	func on_death(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
		if combat.trigger(unit, &"seed_heap"):
			combat.bridge(unit.side).heap_add(HEAP, unit.def.id, unit.def.tier, unit)


## A return that costs: once a fight, if `cost` entries can be spent, it comes back with 1
## Health and spends them.
class Root:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"cost": MechanicParams.Kind.THRESHOLD}

	func return_health(
		combat: Combat, unit: CombatUnit, health: int, params: MechanicParams
	) -> int:
		if unit.returns > 0 or combat.bridge(unit.side).heap(HEAP).size() < params.num(&"cost"):
			return health
		return maxi(health, 1)

	func on_returned(
		combat: Combat, gone: CombatUnit, _back: CombatUnit, params: MechanicParams
	) -> void:
		combat.bridge(gone.side).heap_spend(HEAP, params.num(&"cost"), gone)


## A player number raised in a fight that lasts the game: +1 "tide" when this dies.
class TideOnDeath:
	extends Mechanic

	func on_death(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
		if combat.trigger(unit, &"tide_on_death"):
			combat.bridge(unit.side).add_counter(&"tide", 1, unit)


## An aura that reads a player number: this has +tide Attack, in both phases.
class TideRider:
	extends Mechanic

	func has_aura() -> bool:
		return true

	func aura(
		view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
	) -> Vector2i:
		return Vector2i(view.counter(&"tide"), 0) if source_slot == target_slot else Vector2i.ZERO


## A side rule: your death effects resolve twice.
class DeathTwice:
	extends Mechanic

	func side_query(
		_combat: Combat, unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
	) -> int:
		if unit != null and query == Q_DEATH_EFFECT_TIMES:
			return maxi(value, 2)
		return value


## 9.4.12 Start of Combat: this attacks immediately.
class Charge:
	extends Mechanic

	func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
		if combat.trigger(unit, &"charge"):
			combat.attack_now(unit)


## 9.5.7 attacks the enemy back row while it has units.
class BackRowRaider:
	extends Mechanic

	func combat_query(
		_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
	) -> int:
		return ROW_BACK if query == Q_TARGET_ROW else value


## Waiting summons: when this dies, `count` Sprouts that wait for empty slots. In the Recruit
## Phase (eaten), one Sprout on the recruit board.
class SwarmSpawn:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"count": MechanicParams.Kind.NUMBER}

	func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
		if not combat.trigger(unit, &"swarm_spawn"):
			return
		for _i: int in params.num(&"count"):
			combat.summon(unit.side, &"tk_sprout", unit.slot, true, unit, true)

	func on_recruit_death(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
		if ctx.trigger(unit, &"swarm_spawn"):
			ctx.summon(&"tk_sprout", -1)


## 9.7.2 step 3 and 9.4.9: after a friend in front of this dies, this steps into its slot.
class StepUp:
	extends Mechanic

	func after_friendly_death(
		combat: Combat, unit: CombatUnit, dead: CombatUnit, _params: MechanicParams
	) -> void:
		if unit == null or not combat.geometry.in_front_of(unit.slot).has(dead.slot):
			return
		if combat.unit_at(unit.side, dead.slot) == null and combat.trigger(unit, &"step_up"):
			combat.move_unit(unit, dead.slot)


## An aura that gives a keyword: adjacent units have `keyword`.
class LendKeyword:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"keyword": MechanicParams.Kind.TEXT}

	func has_aura() -> bool:
		return true

	func aura_keywords(
		view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
	) -> Array[StringName]:
		var out: Array[StringName] = []
		if source_slot >= 0 and view.geometry.adjacent(source_slot).has(target_slot):
			out.append(StringName(params.text(&"keyword")))
		return out


## Any sale: this gains the sold unit's stats for good, and the sold unit's death effects
## resolve in the Recruit Phase.
class Eat:
	extends Mechanic

	func on_any_sold(ctx: RecruitContext, unit: Unit, sold: Unit, _params: MechanicParams) -> void:
		if unit == null or sold.is_spell() or not ctx.trigger(unit, &"eat"):
			return
		ctx.buff(unit, sold.attack(), sold.health(), true, unit)
		ctx.run_death_effects(sold)


## Entering a board, both phases: a friend that enters gets +1 Attack (this turn / fight).
class Greet:
	extends Mechanic

	func on_board_enter(
		ctx: RecruitContext, unit: Unit, entered: Unit, _params: MechanicParams
	) -> void:
		if unit != null and entered != unit and ctx.trigger(unit, &"greet"):
			ctx.buff(entered, 1, 0, false, unit)

	func on_fight_enter(
		combat: Combat, unit: CombatUnit, entered: CombatUnit, _params: MechanicParams
	) -> void:
		if unit == null or entered == unit or entered.side != unit.side:
			return
		if combat.trigger(unit, &"greet"):
			combat.buff(entered, 1, 0, unit)


## Damage from attacks is reduced by `amount`, to no less than 1.
class Plate:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"amount": MechanicParams.Kind.NUMBER}

	func absorb_damage(
		_combat: Combat, _unit: CombatUnit, amount: int, from_attack: bool, params: MechanicParams
	) -> int:
		if not from_attack or amount <= 0:
			return amount
		return maxi(1, amount - params.num(&"amount"))


## Strikes first: a defender this kills doesn't strike back.
class FirstStrike:
	extends Mechanic

	func combat_query(
		_unit: CombatUnit, query: StringName, value: int, _params: MechanicParams
	) -> int:
		return 1 if query == Q_STRIKES_FIRST else value


## A spell aimed at a board slot: that slot gets +amount/+amount.
class SlotGift:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"amount": MechanicParams.Kind.NUMBER}

	func play_target(_params: MechanicParams) -> Target:
		return Target.SLOT

	func on_played(ctx: RecruitContext, unit: Unit, _target: Unit, params: MechanicParams) -> void:
		if ctx.trigger(unit, &"slot_gift"):
			ctx.slot_buff(ctx.target_index, params.num(&"amount"), params.num(&"amount"), unit)
