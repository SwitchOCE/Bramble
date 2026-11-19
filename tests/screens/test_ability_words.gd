extends GutTest
## An Active's hover says nothing when it can be used, and the core's reason when it can't.

const CARD: Dictionary = {
	"name": "Lance Corporal", "text": "{cost}: Give the slots in front of this +2/+2."
}


func test_a_ready_active_has_no_state_line() -> void:
	var words: Dictionary = RecruitButtons.ability_words(
		CARD, {"id": "x", "why": "", "poor": false}
	)
	assert_eq(str(words["kind_line"]), "")
	assert_eq(str(words["name"]), "Lance Corporal")


func test_a_blocked_active_says_why() -> void:
	for pair: Array in [
		["can't be used from here", "Can't be used from here"],
		["nothing to target", "Nothing to target"],
		["already used this turn", "Already used this turn"],
		["not enough gold", "Not enough gold"],
	]:
		var words: Dictionary = RecruitButtons.ability_words(CARD, {"id": "x", "why": str(pair[0])})
		assert_eq(str(words["kind_line"]), str(pair[1]))
