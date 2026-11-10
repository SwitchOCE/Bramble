extends "res://tests/ui/shots/declutter_b2_frames.gd"
## The declared test-only Committee variant uses the real Committee's individual portrait.
## Rules, event records, numbers and fixed-step sampling remain the parent's exact fixture.


func _views(player: PlayerState) -> Array:
	var views: Array = super._views(player)
	for value: Variant in views:
		if value is Dictionary:
			var view: Dictionary = value
			if str(view.get("def_id", "")) == "declutter_test_committee":
				view["portrait_id"] = "standing_committee"
	return views
