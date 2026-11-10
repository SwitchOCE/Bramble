extends GutTest
## Ownership drives categories even when distinct roles print identical text.

const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")
const GoldPlaque := preload("res://src/ui/widgets/gold_plaque.gd")


func _category(node: Node) -> String:
	return str(Capture.classify_text_node(node)["category"])


func test_identical_digits_are_classified_by_owner_and_field() -> void:
	var card := CardView.new()
	add_child_autofree(card)
	card.show_unit(
		{"def_id": "field_vole", "name": "Vole", "attack": 4, "health": 4}, CardView.Mode.BOARD
	)
	var attack: Label = card.get("_attack_label")
	assert_eq(_category(attack), "unit_stats")
	attack.text = "End turn"
	assert_eq(_category(attack), "unit_stats", "changing its ink cannot change its owner role")
	var ordinary := Label.new()
	ordinary.text = "4"
	add_child_autofree(ordinary)
	assert_eq(_category(ordinary), "other")
	var action := Button.new()
	action.text = "4"
	add_child_autofree(action)
	assert_eq(_category(action), "costs_and_controls")
	var gold := GoldPlaque.new()
	add_child_autofree(gold)
	gold.show_gold(4)
	var amount: Label = gold.get("_value")
	assert_eq(_category(amount), "costs_and_controls")


func test_hero_health_and_egg_stats_keep_their_distinct_roles() -> void:
	var hero := LobbyPlaque.new({"name": "Pipkin", "health": 4, "tier": 4, "alive": true}, false)
	add_child_autofree(hero)
	var hip: Control = hero.get("_hip")
	var health: Node = hip.get_child(0)
	assert_eq(_category(health), "hero_health")
	var knot: Control = hero.get("_knot")
	assert_eq(_category(knot.get_child(0)), "other", "opponent tier is state, not a price")
	var board := BoardView.new()
	add_child_autofree(board)
	board.configure("board", 209, true)
	var marks: Node = board.get("_marks")
	var eggs: Array = marks.get("_egg_attack")
	var egg_attack: Node = eggs[0]
	assert_eq(_category(egg_attack), "unit_stats")


func test_missing_art_and_four_confusable_portraits_count_as_fallback_names() -> void:
	for id: String in [
		"no_individual_portrait", "young_brock", "old_brock", "sable", "mistress_russet"
	]:
		var card := CardView.new()
		add_child_autofree(card)
		card.show_unit(
			{"def_id": id, "name": "Name", "attack": 4, "health": 4}, CardView.Mode.BOARD
		)
		var name_label: Label = card.get("_name_label")
		assert_eq(_category(name_label), "fallback_names", id)
		var report: Dictionary = Capture.label_breakdown(card)
		var counts: Dictionary = report["counts"]
		var sum: int = 0
		for category: String in Capture.LABEL_CATEGORIES:
			sum += CoreUtil.to_int(counts[category])
		assert_eq(sum, Capture.text_nodes(card).size(), "classification never filters raw nodes")
