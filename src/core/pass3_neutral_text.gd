class_name Pass3NeutralText
extends RefCounted
## Native neutral faces and parameters resolve from the same sweep values.

const PARAMETERS: Dictionary = {
	"charcoal_burner": {"cap": "burner_cap", "above": "burner_above", "share": "burner_share"},
	"click_beetle": {"repeats": "click_repeats", "golden_repeats": "golden_click_repeats"},
	"whirligig_beetle":
	{
		"health_share": "whirligig_health_share",
		"golden_health_share": "golden_whirligig_health_share"
	},
}
const DETAILS: Dictionary = {
	"charcoal_burner":
	(
		"Reads each recipient's own base plus permanent body stats; excludes Rings, auras and standing "
		+ "tribe bonuses. Each share rounds down once after multiplying by the total gold burned. "
		+ "Golden increases only the gold burned."
	),
	"click_beetle":
	(
		"Only the strongest Click Beetle counts. Every Bird landing replays its When played effects "
		+ "before its once-only homecoming growth. Playing the returned Bird from hand "
		+ "repeats them again. "
		+ "Extra triggers cannot repeat multiplication or advance a countdown."
	),
	"ballooning_spider":
	"Only while this lives. Behind means the back-row slots directly behind this.",
	"whirligig_beetle":
	(
		"F1 swaps with B1, F2 with B2, F3 with B3; F4 stays. A pair stays if either unit would gain "
		+ "Ring Attack or Health. Only actually moved enemies lose Health, rounded down to at least 1. "
		+ "Health loss is not damage and does not consume Shield."
	),
	"shieldbug":
	"Gives Shield to the friendly units directly behind this. Golden changes its body only.",
}


static func is_native(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "pass3_neutral":
			return true
	return false


static func configure(card: Dictionary, config: GameConfig) -> void:
	if not is_native(card):
		return
	card["pass3_rates"] = Pass3Rates.resolved(config)
	card.erase(MechanicRegistry.COMPILED_KEY)
	var id: String = str(card["id"])
	for entry: Dictionary in card["mechanics"]:
		if str(entry.get("id", "")) != "pass3_neutral":
			continue
		var mapping: Dictionary = PARAMETERS.get(id, {})
		for field: String in mapping:
			entry[field] = Pass3Rates.value(config, "neutrals_" + str(mapping[field]))
		if id == "charcoal_burner" and not config.get_bool("card_size_caps"):
			entry["cap"] = BoardUnit.STAT_CLAMP
	for golden: bool in [false, true]:
		card["golden_text" if golden else "text"] = face(card, config, golden)
		card["golden_details" if golden else "details"] = str(DETAILS.get(id, ""))


static func face(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	match str(card.get("id", "")):
		"charcoal_burner":
			var cap: int = Pass3Rates.integer(config, "neutrals_burner_cap") * (2 if golden else 1)
			var amount: String = "up to %d of " % cap if config.get_bool("card_size_caps") else ""
			return (
				"End of Turn: burn %syour gold above %d. The units behind this gain %s of their stats per gold."
				% [
					amount,
					Pass3Rates.integer(config, "neutrals_burner_above"),
					Pass3Text._fraction(Pass3Rates.number(config, "neutrals_burner_share"))
				]
			)
		"click_beetle":
			var repeats: int = Pass3Rates.integer(
				config, "neutrals_golden_click_repeats" if golden else "neutrals_click_repeats"
			)
			return "Your When played effects trigger%s." % Pass3Text._repeat(repeats)
		"ballooning_spider":
			return "The units behind this have Swoop."
		"whirligig_beetle":
			return (
				(
					"Start of Combat: swap enemy rows without improving Rings. "
					+ "Each enemy moved loses %s of its Health."
				)
				% Pass3Text._fraction(
					Pass3Rates.number(
						config,
						(
							"neutrals_golden_whirligig_health_share"
							if golden
							else "neutrals_whirligig_health_share"
						)
					)
				)
			)
		"shieldbug":
			return "Start of Combat: give the units behind this Shield."
	return ""
