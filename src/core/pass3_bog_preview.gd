class_name Pass3BogPreview
extends RefCounted
## A non-random estimate from the recorded scout, never a simulated future opponent.


static func attach(player: PlayerState, board: Array, config: GameConfig) -> void:
	var recorded: Array = player.scout.get("views", [])
	var enemy: Array = recorded.duplicate(true)
	if enemy.is_empty():
		return
	var patches: Dictionary = {}
	var reserved: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		var source: RecruitUnit = player.board[slot]
		if source == null:
			continue
		var count: int = (
			Pass3Bog.factor(source, "lantern") * Pass3Rates.integer(config, "bog_lantern_lures")
		)
		for _index: int in count:
			var target: int = _biggest(enemy, [], reserved)
			if target >= 0:
				reserved.append(target)
				patches[target] = slot
	for slot: int in BoardGeometry.SLOTS:
		if player.board[slot] == null or Pass3Bog.factor(player.board[slot], "jenny") <= 0:
			continue
		var target: int = _biggest(enemy, BoardGeometry.row_of(slot), reserved)
		if target >= 0 and target != slot:
			var swap: Variant = enemy[slot]
			enemy[slot] = enemy[target]
			enemy[target] = swap
	for slot: int in BoardGeometry.SLOTS:
		var source: RecruitUnit = player.board[slot]
		if source == null:
			continue
		if source.has_mechanic_id("mire") or Pass3Bog.loan_factor(player, slot, config) > 0:
			if not patches.has(slot):
				patches[slot] = slot
		if source.def_id() == "prima_donna":
			var remaining: int = Pass3Rates.integer(config, "bog_prima_donna_patches") - 1
			for adjacent: int in BoardGeometry.adjacent(slot):
				if remaining > 0 and not patches.has(adjacent):
					patches[adjacent] = slot
				remaining -= 1
	for slot: int in board.size():
		if board[slot] == null:
			continue
		var keep: float = Pass3Bog.soak_keep(player, slot, config)
		if keep <= 0:
			continue
		var preview: Array[Dictionary] = []
		for target: int in patches:
			if patches[target] != slot or target >= enemy.size() or enemy[target] == null:
				continue
			var foe: Dictionary = enemy[target]
			var attack: int = CoreUtil.to_int(foe.get("attack", 0))
			var raw: float = attack * Pass3Rates.number(config, "bog_bitter_share")
			var bite: int = (
				ceili(raw) if Pass3Rates.enabled(config, "bog_bitter_round_up") else floori(raw)
			)
			bite = mini(maxi(0, bite), maxi(0, attack - 1))
			preview.append(
				{
					"slot": target,
					"name": str(foe.get("name", "Enemy")),
					"attack": attack,
					"drink": floori(bite * keep)
				}
			)
		board[slot]["soak_preview"] = preview


static func _biggest(enemy: Array, row: Array, excluded: Array[int]) -> int:
	var best: int = -1
	var score: int = -1
	for slot: int in enemy.size():
		if enemy[slot] == null or excluded.has(slot) or (not row.is_empty() and not row.has(slot)):
			continue
		var unit: Dictionary = enemy[slot]
		var size: int = (
			CoreUtil.to_int(unit.get("attack", 0)) + CoreUtil.to_int(unit.get("health", 0))
		)
		if size > score:
			best = slot
			score = size
	return best
