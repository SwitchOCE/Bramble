class_name ScaleLeverText
extends RefCounted
## Dial values are rendered into the private card definitions at game construction.


static func configure(card: Dictionary, config: GameConfig) -> void:
	match str(card.get("id", "")):
		"scale_engine":
			var tribe: String = config.get_string("scale_engine_tribe")
			var target: String = "your units" if tribe == "" else "your %s" % tribe
			if config.get_bool("scale_engine_self"):
				target = "this"
			var flat: int = maxi(0, config.get_int("scale_engine_flat"))
			var percent: int = maxi(0, config.get_int("scale_engine_percent"))
			for golden: bool in [false, true]:
				var factor: int = 2 if golden else 1
				var gain: String = (
					"+%d/+%d" % [flat * factor, flat * factor]
					if flat > 0
					else "+%d%% stats" % (percent * factor)
				)
				card["golden_text" if golden else "text"] = (
					"End of Turn: give %s %s permanently." % [target, gain]
				)
		"scale_answer":
			var percent: int = clampi(config.get_int("scale_answer_percent"), 0, 100)
			card["text"] = "Start of Combat: shrink the biggest enemy by %d%%." % percent
			card["golden_text"] = card["text"]
		"scale_doubler":
			card["text"] = "Your End of Turn effects trigger an extra time."
			card["golden_text"] = "Your End of Turn effects trigger 2 extra times."
		"scale_economy":
			card["text"] = "End of Turn: improve income by 1, then get it next turn."
			card["golden_text"] = "End of Turn: improve income by 1, then get 2 times it next turn."
			card["details"] = (
				"Income starts at 0 and stops improving at %d."
				% maxi(0, config.get_int("scale_economy_cap"))
			)
