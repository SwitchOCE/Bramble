extends Mechanic
## Standing, hidden: Grudge after each fight, win or lose, alive or dead. Each unit on the board
## gains +N Health, and +N/+N more for each unit it was outnumbered by: +N x count Attack and
## +N x (count + 1) Health. N is the biggest of its own Grudge and, for a Knight, the biggest
## Grudge-keeper's on the board. Never twice for one unit. A pass 1 proposal (19 Nov) gave it
## the Health floor; it paid nothing at count 0.

const BadgerRules := preload("res://src/content/badger/lib/badger_rules.gd")
const KEEPER: StringName = &"badger_grudge_keeper"


func after_fight(
	ctx: RecruitContext, unit: Unit, report: FightReport, _params: MechanicParams
) -> void:
	if unit != null:
		return
	var count: int = maxi(0, report.outnumbered_by)
	var board: Array[Unit] = ctx.player.board_units()
	var keeper: int = 0
	for each: Unit in board:
		keeper = maxi(keeper, _biggest(each, KEEPER))
	for each: Unit in board:
		var grudge: int = _biggest(each, BadgerRules.GRUDGE)
		if BadgerRules.is_knight(each.def):
			grudge = maxi(grudge, keeper)
		if grudge <= 0 or not ctx.trigger(each, BadgerRules.GRUDGE):
			continue
		ctx.buff(each, grudge * count, grudge * (count + 1), true, each)


## The biggest `grudge` among the unit's own mechanics with this id. Aura copies aren't
## counted: the Grudge a keeper shows on a Knight is read from the keeper itself.
static func _biggest(unit: Unit, mechanic_id: StringName) -> int:
	var best: int = 0
	for bound: BoundMechanic in unit.mechanics:
		if bound.id == mechanic_id:
			best = maxi(best, bound.params.num(&"grudge"))
	return best
