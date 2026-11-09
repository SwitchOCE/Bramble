extends GutTest
# Planted failure for the gate's verdict check. Never merged.


func test_planted_failure() -> void:
	assert_eq(1, 2, "planted failing test")
