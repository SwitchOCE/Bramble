extends Control
## Reproducible states for briefs 1, 3 and 4; the matching reference page stays untouched.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")


func _ready() -> void:
	var screen: RecruitScreen = SCREEN.instantiate()
	screen.state = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	if OS.get_environment("BRAMBLE_SHOP_POOR") == "1":
		screen.state["gold"] = 1
	add_child(screen)
	if OS.get_environment("BRAMBLE_SHOP_SELL") == "1":
		RecruitShop.show_sell(screen, 3, true)


func feel_report() -> Dictionary:
	var screen: RecruitScreen = get_child(0)
	return RecruitDuplicates.marks(screen.state)
