extends RefCounted
## Display-only bell forecast, read from card mechanics. Own marks precede loans; makers and
## lenders compete in reading order, as they do in combat. This never changes a recruit board.

const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const Data := preload("res://src/ui/view_data.gd")
var _library: UnitLibrary = UnitLibrary.load_dir()


## A recruit tile's current combat preview. Only units presently beside it lend Bitter;
## neither hand/held units nor the other row contribute. Never changes the core state.
func recruit_unit(board: Array, slot: int) -> Dictionary:
	var view: Dictionary = Data.entry(board, slot).duplicate(true)
	if view.is_empty():
		return view
	var printed: int = _number(view, "bitter", "n")
	var borrowed: int = 0
	for neighbour: int in BoardGeometry.adjacent(slot):
		var source: Dictionary = Data.entry(board, neighbour)
		if not source.is_empty() and Data.b(source, "alive", true):
			borrowed += _number(source, "bog_aura", "bitter")
	if printed + borrowed > 0:
		view["recruit_bitter"] = printed + borrowed
		view["recruit_bitter_printed"] = printed
		view["recruit_bitter_borrowed"] = borrowed
		var keywords: Array = Data.a(view, "keywords")
		if not keywords.has("Bitter"):
			keywords.append("Bitter")
		view["keywords"] = keywords
	if not _mechanic(view, "kiss").is_empty():
		view["recruit_kisses"] = Data.i(Data.d(view, "counters"), "kisses")
	return view


func _number(view: Dictionary, id: String, key: String) -> int:
	var mechanic: Dictionary = _mechanic(view, id)
	var params: Dictionary = MechanicRegistry.params_for(mechanic, Data.b(view, "golden"))
	return Data.i(params, key)


func forecast(boards: Array) -> Dictionary:
	var patches: Array[Dictionary] = []
	var marks: Array[Dictionary] = []
	for side: int in 2:
		var friends: Array = boards[side]
		var enemies: Array = boards[1 - side]
		var bogged: Dictionary = {}
		var marked: Dictionary = {}
		for slot: int in mini(friends.size(), 7):
			if not friends[slot] is Dictionary:
				continue
			var mire: Dictionary = _mechanic(Data.entry(friends, slot), "mire")
			var has_mire: bool = not mire.is_empty()
			for neighbour: int in BoardGeometry.adjacent(slot):
				if neighbour < friends.size() and friends[neighbour] is Dictionary:
					has_mire = (
						has_mire
						or Data.b(_mechanic(Data.entry(friends, neighbour), "bog_aura"), "mire")
					)
			if has_mire:
				var slots: Array[int] = [slot]
				if Data.b(mire, "spread"):
					slots.append_array(BoardGeometry.adjacent(slot))
				for target: int in slots:
					if not bogged.has(target):
						bogged[target] = true
						patches.append(
							{
								"side": 1 - side,
								"slot": target,
								"from_side": side,
								"from_slot": slot,
								"live": true
							}
						)
			if not _mechanic(Data.entry(friends, slot), "quarry").is_empty():
				_mark(marks, marked, enemies, side, slot, slot)
		for lender: int in mini(friends.size(), 7):
			if not friends[lender] is Dictionary:
				continue
			var loan: Dictionary = _mechanic(Data.entry(friends, lender), "lend_quarry")
			if loan.is_empty():
				continue
			var selected: Array[int] = BoardGeometry.adjacent(lender)
			if Data.s(loan, "select") == "neighbours":
				selected = BoardGeometry.neighbours(lender)
			elif Data.s(loan, "select") == "friendly":
				selected = [0, 1, 2, 3, 4, 5, 6]
			for slot: int in selected:
				if slot < friends.size() and friends[slot] is Dictionary and not marked.has(slot):
					_mark(
						marks,
						marked,
						enemies,
						side,
						slot,
						slot if Data.b(loan, "own_across") else lender
					)
	return {"patches": patches, "quarries": marks}


func _mechanic(view: Dictionary, id: String) -> Dictionary:
	var definition: Dictionary = _library.get_unit(Data.s(view, "def_id"))
	for entry: Variant in Data.a(definition, "mechanics"):
		var mechanic: Dictionary = entry
		if Data.s(mechanic, "id") == id:
			return mechanic
	return {}


func _mark(
	marks: Array[Dictionary],
	marked: Dictionary,
	enemies: Array,
	side: int,
	hunter: int,
	target: int
) -> void:
	if target >= enemies.size() or not enemies[target] is Dictionary:
		return
	if Data.s(Data.entry(enemies, target), "def_id") == "nest_egg":
		return
	marked[hunter] = true
	marks.append({"side": 1 - side, "slot": target, "from_side": side, "from_slot": hunter})


static func playback(model: CombatModel) -> Dictionary:
	var patches: Array[Dictionary] = []
	var marks: Array[Dictionary] = []
	for patch: Dictionary in model.bog_patches.values():
		var maker: Dictionary = model.unit(Data.i(patch, "maker"))
		var side: int = Data.i(patch, "side")
		patches.append(
			{
				"side": side,
				"slot": Data.i(patch, "slot"),
				"from_side": Data.i(maker, "side"),
				"from_slot": Data.i(maker, "slot"),
				"live":
				(
					Data.b(maker, "alive")
					and Data.i(maker, "side") != side
					and not Data.b(patch, "broken")
				)
			}
		)
	for unit: Dictionary in model.units.values():
		var target: Dictionary = model.unit(Data.i(unit, "quarry"))
		if Data.b(unit, "alive") and Data.b(target, "alive"):
			marks.append(
				{
					"side": Data.i(target, "side"),
					"slot": Data.i(target, "slot"),
					"from_side": Data.i(unit, "side"),
					"from_slot": Data.i(unit, "slot")
				}
			)
	return {"patches": patches, "quarries": marks}
