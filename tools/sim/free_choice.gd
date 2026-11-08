extends BotBrain
## Measurement policy: every tribe has the same zero prior. No named route, unit priority,
## route curve or measured power prior is used. Hard's live board/shop/text values remain;
## actual purchases and commitment spells can make later kin purchases more valuable.


func _choose_build() -> void:
	pinned_strategy = ""
	value.strategy = {}
