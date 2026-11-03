extends GutTest
## The 4-3 brick of rulebook chapter 8: the relations table (8.2) and summon placement (8.4).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const F1: int = 0
const F2: int = 1
const F3: int = 2
const F4: int = 3
const B1: int = 4
const B2: int = 5
const B3: int = 6


func test_rows_8_2_7() -> void:
	for slot: int in [F1, F2, F3, F4]:
		assert_true(BoardGeometry.is_front(slot), "slot %d is front" % slot)
	for slot: int in [B1, B2, B3]:
		assert_true(BoardGeometry.is_back(slot), "slot %d is back" % slot)


func test_adjacent_8_2_2() -> void:
	assert_eq(BoardGeometry.adjacent(F1), [F2] as Array[int], "F1")
	assert_eq(BoardGeometry.adjacent(F3), [F2, F4] as Array[int], "F3")
	assert_eq(BoardGeometry.adjacent(B2), [B1, B3] as Array[int], "B2")
	assert_eq(BoardGeometry.adjacent(B3), [B2] as Array[int], "B3")


func test_in_front_and_behind_8_2_1() -> void:
	assert_eq(BoardGeometry.in_front_of(B1), [F1, F2] as Array[int], "B1")
	assert_eq(BoardGeometry.in_front_of(B3), [F3, F4] as Array[int], "B3")
	assert_eq(BoardGeometry.in_front_of(F2), [] as Array[int], "front slots have none")
	assert_eq(BoardGeometry.behind(F1), [B1] as Array[int], "F1")
	assert_eq(BoardGeometry.behind(F2), [B1, B2] as Array[int], "F2")
	assert_eq(BoardGeometry.behind(F4), [B3] as Array[int], "F4")


func test_neighbours_8_2_3() -> void:
	assert_eq(BoardGeometry.neighbours(F2), [F1, F3, B1, B2] as Array[int], "F2")
	assert_eq(BoardGeometry.neighbours(B1), [F1, F2, B2] as Array[int], "B1")


func test_across_8_2_6() -> void:
	assert_eq(BoardGeometry.across(B1), B1, "B1 faces B1")


func test_summon_order_table_8_4_2() -> void:
	var expected: Dictionary = {
		F1: [F2, F3, F4, B1, B2, B3],
		F2: [F3, F1, F4, B2, B1, B3],
		F3: [F4, F2, F1, B3, B2, B1],
		F4: [F3, F2, F1, B3, B2, B1],
		B1: [B2, B3, F2, F1, F3, F4],
		B2: [B3, B1, F3, F2, F4, F1],
		B3: [B2, B1, F4, F3, F2, F1],
	}
	for source: int in expected:
		var occupied: Array[bool] = _occupied([source])
		var order: Array = []
		for _step: int in 6:
			var slot: int = BoardGeometry.summon_slot(occupied, source, false)
			order.append(slot)
			occupied[slot] = true
		assert_eq(order, expected[source], "order from %s" % BoardGeometry.LABELS[source])


func test_own_slot_first_8_4_1() -> void:
	var occupied: Array[bool] = _occupied([F1, F2])
	assert_eq(BoardGeometry.summon_slot(occupied, F3, true), F3, "the dying unit's empty slot")
	occupied[F3] = true
	assert_eq(BoardGeometry.summon_slot(occupied, F3, true), F4, "then the nearest empty slot")


func test_no_source_goes_to_first_empty_8_4_3() -> void:
	assert_eq(BoardGeometry.summon_slot(_occupied([F1, F2]), -1, false), F3, "reading order")


func test_full_board_loses_the_summon_8_4_5() -> void:
	var occupied: Array[bool] = _occupied([F1, F2, F3, F4, B1, B2, B3])
	assert_eq(BoardGeometry.summon_slot(occupied, F2, true), -1, "no slot")


func _occupied(slots: Array[int]) -> Array[bool]:
	var out: Array[bool] = []
	out.resize(BoardGeometry.SLOTS)
	for slot: int in slots:
		out[slot] = true
	return out
