extends GutTest
## The core's own hash and generator (prototype lesson 7) and the board geometry (chapter 8).
## The pinned numbers come from a Python copy of FNV-1a and xoshiro128**, so an engine upgrade
## can't change seeds silently.

@warning_ignore_start("unsafe_call_argument")


func test_fnv1a_matches_reference() -> void:
	assert_eq(Rng.hash32("hello"), 0x4F9F2CAB)
	assert_eq(Rng.hash32("7|shop:3"), 1827940353)


func test_xoshiro_matches_reference() -> void:
	var rng := Rng.new(12345)
	assert_eq(
		[rng.next_u32(), rng.next_u32(), rng.next_u32(), rng.next_u32()],
		[518667457, 440444462, 4232892992, 3757857622]
	)
	var derived: Rng = Rng.derive(7, "shop:3")
	assert_eq(derived.next_u32(), 2820041589)


func test_streams_are_independent_and_repeatable() -> void:
	var a: Rng = Rng.derive(1, "shop:0")
	var b: Rng = Rng.derive(1, "shop:0")
	var c: Rng = Rng.derive(1, "shop:1")
	var first: int = a.next_u32()
	assert_eq(first, b.next_u32(), "same seed and label, same numbers")
	assert_ne(first, c.next_u32(), "another label, another stream")


func test_range_int_stays_in_bounds() -> void:
	var rng := Rng.new(99)
	var seen: Dictionary = {}
	for _i: int in 500:
		var roll: int = rng.range_int(3, 6)
		seen[roll] = true
		assert_between(roll, 3, 6)
	assert_eq(seen.size(), 4, "every value comes up")


func test_8_2_relations_table() -> void:
	var g: BoardGeometry = BoardGeometry.standard()
	assert_eq(Array(g.labels), ["F1", "F2", "F3", "F4", "B1", "B2", "B3"])
	assert_eq(g.adjacent(0), [1] as Array[int])
	assert_eq(g.adjacent(1), [0, 2] as Array[int])
	assert_eq(g.adjacent(5), [4, 6] as Array[int])
	assert_eq(g.behind(0), [4] as Array[int])
	assert_eq(g.behind(1), [4, 5] as Array[int])
	assert_eq(g.behind(3), [6] as Array[int])
	assert_eq(g.in_front_of(4), [0, 1] as Array[int])
	assert_eq(g.in_front_of(6), [2, 3] as Array[int])
	assert_eq(g.neighbours(1), [0, 2, 4, 5] as Array[int], "8.2.3 up to 4")
	assert_eq(g.across(5), 5, "8.2.6 same label")


func test_8_4_2_summon_order_table() -> void:
	var g: BoardGeometry = BoardGeometry.standard()
	var want: Array = [
		[1, 2, 3, 4, 5, 6],
		[2, 0, 3, 5, 4, 6],
		[3, 1, 0, 6, 5, 4],
		[2, 1, 0, 6, 5, 4],
		[5, 6, 1, 0, 2, 3],
		[6, 4, 2, 1, 3, 0],
		[5, 4, 3, 2, 1, 0],
	]
	for slot: int in 7:
		assert_eq(Array(g.summon_order(slot)), want[slot], "from %s" % g.label(slot))


func test_8_4_1_dead_units_slot_first_then_8_4_5_full_board_fails() -> void:
	var g: BoardGeometry = BoardGeometry.standard()
	var occupied: Array[bool] = [true, false, false, false, false, false, false]
	occupied[2] = false
	assert_eq(g.summon_slot(occupied, 2, true), 2, "own slot when empty")
	assert_eq(g.summon_slot(occupied, 0, false), 1, "nearest from F1")
	assert_eq(g.summon_slot(occupied, -1, false), 1, "8.4.3 no source: first empty")
	var full: Array[bool] = [true, true, true, true, true, true, true]
	assert_eq(g.summon_slot(full, 3, true), -1)


func test_geometry_is_instance_data() -> void:
	var g: BoardGeometry = BoardGeometry.standard(3, 2)
	assert_eq(g.slot_count, 5)
	assert_eq(g.in_front_of(3), [0, 1] as Array[int], "a 3-2 board builds its own tables")


func test_selectors_skip_empty_slots() -> void:
	var g: BoardGeometry = BoardGeometry.standard()
	var occupied: Array[bool] = [true, false, true, false, true, true, false]
	assert_eq(Selectors.slots(g, 1, occupied, "adjacent"), [0, 2] as Array[int])
	assert_eq(Selectors.slots(g, 0, occupied, "adjacent"), [] as Array[int], "8.2.2 no skipping")
	assert_eq(Selectors.slots(g, 4, occupied, "in_front"), [0] as Array[int])
	assert_eq(Selectors.slots(g, 0, occupied, "others"), [2, 4, 5] as Array[int])
