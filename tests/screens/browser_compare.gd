extends Control
## Screenshot fixtures only: real screen, printed content, and the approved page's pinned hovers.

@export_enum("start", "all", "mice", "spells", "game") var which: String = "all"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if which == "start":
		add_child(StartScreen.new())
		return
	if which == "game":
		var recruit: Control = (
			(load("res://tests/screens/shop_review.tscn") as PackedScene).instantiate()
		)
		add_child(recruit)
		recruit.process_mode = Node.PROCESS_MODE_DISABLED
	var browser: CardBrowser = CardBrowser.new()
	browser.in_game = which == "game"
	browser.spells = which == "spells"
	browser.tribe = "mouse" if which == "mice" else ""
	browser.tier = 5 if which == "mice" else 0
	browser.pinned_hover = (
		{
			"all": "hedge-knight",
			"mice": "master-of-engines",
			"spells": "sp_seek",
			"game": "brock-cub"
		}
		. get(which, "")
	)
	add_child(browser)
