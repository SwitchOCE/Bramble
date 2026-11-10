class_name Pass3HedgerowText
extends RefCounted
## Hedgerow faces and native parameters resolve from the same preset and overrides.

const PARAMETERS: Dictionary = {
	"mr_crumb": {"pass": "crumb_pass", "sell_share": "crumb_sell_share"},
	"sleeping_partner": {"period": "partner_period", "acorns": "partner_acorns"},
	"mrs_clover": {"share": "clover_share"},
	"mr_pym": {"pass": "pym_pass"},
	"mrs_mallow": {"multiplier": "mallow_multiplier", "targets": "mallow_targets"},
	"dr_urchin": {"hunker_targets": "urchin_hunker_targets"},
	"sergeant_at_conkers":
	{"throws": "sergeant_throws", "share_per_gold": "sergeant_share_per_gold"},
	"alderman_dozey":
	{
		"period": "dozey_period",
		"multiplier": "dozey_wake_multiplier",
		"golden_multiplier": "golden_dozey_wake_multiplier",
		"food_per_gold": "dozey_food_per_gold"
	},
	"beadle_warrenby": {"pass": "beadle_pass"},
	"honorary_treasurer": {"per_gold": "treasurer_per_gold"},
	"goodman_hayward": {"per_gold": "hayward_per_gold"},
	"standing_committee": {"share": "committee_share"},
	"squire_lollop": {"share": "lollop_share"},
	"old_mother_mast": {"gold_step": "mast_gold_step", "limit": "mast_cap"}
}
const DETAILS: Dictionary = {
	"mr_crumb":
	(
		"Sold stats include its own permanent gains, excluding standing tribe "
		+ "bonuses. Pass targets your last other unit."
	),
	"sleeping_partner":
	(
		"Touching means the unbroken zigzag run through this, including this. Only "
		+ "Hedgerow folk count. Moving or tripling restarts the wait. Extra triggers "
		+ "do not advance it."
	),
	"mrs_clover":
	(
		"Only Hedgerow summons count. Shares round down. Recruit summons keep the "
		+ "gain; combat summons keep it for the fight."
	),
	"mr_pym": "Combining three Acorns counts as getting a Stash.",
	"mrs_mallow":
	(
		"Smallest means Attack plus Health; ties use zigzag order. Can pick this. "
		+ "Shy units are skipped. Targets are selected before any gain; extra "
		+ "triggers cannot repeat multiplication."
	),
	"dr_urchin":
	(
		"Protects your last other Hedgerow unit in zigzag order while this lives. "
		+ "Recalculates as units die; excludes this unit."
	),
	"sergeant_at_conkers":
	(
		"Spends the smallest Larder item for each throw. Losses round down, to at "
		+ "least 0 Attack and 1 Health. With no enemy across, keep the item. Golden "
		+ "throws resolve separately."
	),
	"alderman_dozey":
	(
		"Feeding rounds up. Wakes after all other End of Turn effects; includes "
		+ "standing tribe bonuses, excludes auras and fight buffs. Moving or tripling"
		+ " restarts the wait. Extra triggers do not advance or repeat a wake."
	),
	"beadle_warrenby":
	"Only real Acorns count; combining makes a Stash, not an Acorn. No trigger limit.",
	"honorary_treasurer":
	(
		"Larder means your held Acorns, Stashes and Great Hoards and the gold they "
		+ "are worth. Gains are permanent."
	),
	"goodman_hayward":
	(
		"Cashing or feeding a Larder item both count. Uncapped standing tribe bonus"
		+ " applies to Hedgerow folk now and later, shown on shop offers and kept when bought. Units "
		+ "summoned in fights do not get it."
	),
	"standing_committee":
	(
		"Touching means the unbroken zigzag run through this, including this. Read "
		+ "its smallest Hedgerow unit once before gains. Shares round down and are "
		+ "permanent."
	),
	"squire_lollop":
	(
		"Biggest means Attack plus Health; ties use reading order. Read once before "
		+ "gains. Shares round down and are permanent. Only touching Hedgerow folk "
		+ "gain; your biggest never gains."
	),
	"old_mother_mast":
	(
		"Larder gold is read before this payout. Each copy pays separately. Up to "
		+ "the displayed number per turn; the rate overlay can remove this loop "
		+ "limit."
	)
}


static func is_native(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "pass3_hedgerow":
			return true
	return false


static func configure(card: Dictionary, config: GameConfig) -> void:
	if not is_native(card):
		return
	card["pass3_rates"] = Pass3Rates.resolved(config)
	card.erase(MechanicRegistry.COMPILED_KEY)
	var id: String = str(card["id"])
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "pass3_hedgerow":
			var mapping: Dictionary = PARAMETERS.get(id, {})
			for param: String in mapping:
				entry[param] = Pass3Rates.value(config, "hedgerow_" + str(mapping[param]))
			if id == "old_mother_mast" and not config.get_bool("card_rate_limits"):
				entry["limit"] = BoardUnit.STAT_CLAMP
		elif str(entry.get("id", "")) == "bristle":
			entry["n"] = Pass3Rates.integer(config, "hedgerow_urchin_bristle")
		elif str(entry.get("id", "")) == "eats_acorns":
			entry["per_gold"] = ceili(Pass3Rates.number(config, "hedgerow_dozey_food_per_gold"))
			entry["gold_step"] = 1
		elif str(entry.get("id", "")) == "effect" and id in ["mrs_burdock", "mrs_sorrel"]:
			for step: Dictionary in MechanicRegistry.steps_of(entry):
				if str(step.get("effect", "")) == "summon":
					step["copies"] = Pass3Rates.integer(
						config,
						(
							"hedgerow_burdock_kits"
							if id == "mrs_burdock"
							else "hedgerow_sorrel_summons"
						)
					)
					step["golden"] = false
	var values: Array = Pass3Rates.value(config, "hedgerow_larder_gold")
	var reminder: String = (
		"Play for gold: Acorn %d, Stash %d, Great Hoard %d. Three make the next size."
		% [CoreUtil.to_int(values[0]), CoreUtil.to_int(values[1]), CoreUtil.to_int(values[2])]
	)
	var overrides: Dictionary = card.get("keyword_text_overrides", {})
	overrides["Acorn"] = reminder
	card["keyword_text_overrides"] = overrides
	if id in ["alderman_dozey", "sleeping_partner"]:
		var period: int = Pass3Rates.integer(
			config, "hedgerow_dozey_period" if id == "alderman_dozey" else "hedgerow_partner_period"
		)
		card["turns_goal"] = period
		card["turns_repeat"] = period
	for golden: bool in [false, true]:
		card["golden_text" if golden else "text"] = face(card, config, golden)
		if DETAILS.has(id):
			card["golden_details" if golden else "details"] = details(card, config, golden)
	# Sorrel's reusable attack effect lends its own face; her native marker never lends.
	if id == "mrs_sorrel":
		card["mechanic_text"] = {
			"0":
			{
				"id": "effect",
				"trigger": "after_attack",
				"text": face(card, config),
				"golden_text": face(card, config, true)
			}
		}


static func face(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	var id: String = str(card.get("id", ""))
	var factor: int = 2 if golden else 1
	match id:
		"mrs_burdock", "mrs_sorrel":
			var count: int = (
				Pass3Rates.integer(
					config,
					"hedgerow_burdock_kits" if id == "mrs_burdock" else "hedgerow_sorrel_summons"
				)
				* factor
			)
			var noun: String = "Kit" if id == "mrs_burdock" else "Shrewlet"
			return (
				"%s: summon %s behind this. Spill."
				% [
					"When played" if id == "mrs_burdock" else "After this attacks",
					"a 1/1 " + noun if count == 1 else Pass3Text._word(count) + " 1/1 " + noun + "s"
				]
			)
		"mr_crumb":
			var amount: int = Pass3Rates.integer(config, "hedgerow_crumb_pass") * factor
			var share: float = Pass3Rates.number(config, "hedgerow_crumb_sell_share") * factor
			return (
				"When played: Pass +%d/+%d. When sold: Pass %s."
				% [
					amount,
					amount,
					"its stats" if is_equal_approx(share, 1.0) else Pass3Text._stats(share, "its")
				]
			)
		"sleeping_partner":
			var count: int = Pass3Rates.integer(config, "hedgerow_partner_acorns") * factor
			return (
				"Every %d turns in this slot: get %s per Hedgerow unit touching this."
				% [
					Pass3Rates.integer(config, "hedgerow_partner_period"),
					"an Acorn" if count == 1 else Pass3Text._word(count) + " Acorns"
				]
			)
		"mrs_clover":
			return (
				"After you summon a Hedgerow unit: give it %s."
				% Pass3Text._stats(
					Pass3Rates.number(config, "hedgerow_clover_share") * factor, "this unit's"
				)
			)
		"mr_pym", "beadle_warrenby":
			var amount: int = (
				Pass3Rates.integer(
					config, "hedgerow_pym_pass" if id == "mr_pym" else "hedgerow_beadle_pass"
				)
				* factor
			)
			return (
				"After you get %s: Pass +%d/+%d."
				% ["a Stash" if id == "mr_pym" else "an Acorn", amount, amount]
			)
		"mrs_mallow":
			var targets: int = Pass3Rates.integer(config, "hedgerow_mallow_targets") * factor
			var multiple: float = Pass3Rates.number(config, "hedgerow_mallow_multiplier")
			var noun: String = (
				"your smallest Hedgerow unit's"
				if targets == 1
				else "your %s smallest Hedgerow units'" % Pass3Text._word(targets)
			)
			return (
				"End of Turn: %s %s stats%s."
				% [
					Pass3Text._multiply(multiple),
					noun,
					(
						" by " + Pass3Text._n(multiple)
						if Pass3Text._multiply(multiple) == "multiply"
						else ""
					)
				]
			)
		"dr_urchin":
			var count: int = Pass3Rates.integer(config, "hedgerow_urchin_hunker_targets") * factor
			return (
				"Bristle %d. Your last %sother Hedgerow %s Hunker."
				% [
					Pass3Rates.integer(config, "hedgerow_urchin_bristle") * factor,
					"" if count == 1 else Pass3Text._word(count) + " ",
					"unit has" if count == 1 else "units have"
				]
			)
		"sergeant_at_conkers":
			var count: int = Pass3Rates.integer(config, "hedgerow_sergeant_throws") * factor
			return (
				"Start of Combat: throw your %ssmallest Larder %s across. That enemy loses %s per gold."
				% [
					"" if count == 1 else Pass3Text._word(count) + " ",
					"item" if count == 1 else "items",
					Pass3Text._stats(
						Pass3Rates.number(config, "hedgerow_sergeant_share_per_gold"), "its"
					)
				]
			)
		"alderman_dozey":
			var food: String = Pass3Text._n(
				Pass3Rates.number(config, "hedgerow_dozey_food_per_gold") * factor
			)
			var multiple: float = Pass3Rates.number(
				config,
				(
					"hedgerow_golden_dozey_wake_multiplier"
					if golden
					else "hedgerow_dozey_wake_multiplier"
				)
			)
			return (
				"Larder items played on this: +%s/+%s per gold. Every %d turns in this slot: %s its stats%s."
				% [
					food,
					food,
					Pass3Rates.integer(config, "hedgerow_dozey_period"),
					Pass3Text._multiply(multiple),
					(
						" by " + Pass3Text._n(multiple)
						if Pass3Text._multiply(multiple) == "multiply"
						else ""
					)
				]
			)
		"honorary_treasurer", "goodman_hayward":
			var amount: String = Pass3Text._n(
				(
					Pass3Rates.number(
						config,
						(
							"hedgerow_treasurer_per_gold"
							if id == "honorary_treasurer"
							else "hedgerow_hayward_per_gold"
						)
					)
					* factor
				)
			)
			return (
				"End of Turn: gain +%s/+%s per gold in your Larder." % [amount, amount]
				if id == "honorary_treasurer"
				else (
					"After you play a Larder item: your Hedgerow folk have +%s/+%s per gold this game."
					% [amount, amount]
				)
			)
		"standing_committee":
			return (
				"End of Turn: Hedgerow folk touching this gain %s."
				% Pass3Text._stats(
					Pass3Rates.number(config, "hedgerow_committee_share") * factor,
					"the smallest one's"
				)
			)
		"squire_lollop":
			return (
				"Start of Turn: Hedgerow folk touching this, except your biggest, gain %s."
				% Pass3Text._stats(
					Pass3Rates.number(config, "hedgerow_lollop_share") * factor, "its"
				)
			)
		"old_mother_mast":
			if not config.get_bool("card_rate_limits"):
				return (
					"Start of Turn: get %s per %d gold in your Larder."
					% [
						"an Acorn" if factor == 1 else "two Acorns",
						Pass3Rates.integer(config, "hedgerow_mast_gold_step")
					]
				)
			return (
				"Start of Turn: get %s per %d gold in your Larder. Up to %d."
				% [
					"an Acorn" if factor == 1 else "two Acorns",
					Pass3Rates.integer(config, "hedgerow_mast_gold_step"),
					Pass3Rates.integer(config, "hedgerow_mast_cap") * factor
				]
			)
	return ""


static func details(card: Dictionary, _config: GameConfig, _golden: bool = false) -> String:
	return str(DETAILS.get(str(card.get("id", "")), ""))


## The Larder value dial controls both the held value and the gold paid on play.
static func configure_larder_item(card: Dictionary, config: GameConfig) -> bool:
	var ids: Array[String] = ["acorn", "stash", "great_hoard"]
	var index: int = ids.find(str(card.get("id", "")))
	if index < 0 or not config.get_bool("pass3_content"):
		return false
	var resolved: Variant = Pass3Rates.value(config, "hedgerow_larder_gold")
	# Archived captures can predate this dial; leave their item definitions untouched.
	if not resolved is Array:
		return false
	var values: Array = resolved
	if values.size() != 3:
		return false
	var amount: int = CoreUtil.to_int(values[index])
	card["gold_value"] = amount
	var effect: Dictionary = card.get("do", {})
	effect["amount"] = amount
	card["do"] = effect
	card["text"] = "Play for %d gold." % amount
	if index < 2:
		card["text"] += " Three combine into a %s." % ("Stash" if index == 0 else "Great Hoard")
	var reminder: String = (
		"Play for gold: Acorn %d, Stash %d, Great Hoard %d. Three make the next size."
		% [CoreUtil.to_int(values[0]), CoreUtil.to_int(values[1]), CoreUtil.to_int(values[2])]
	)
	var overrides: Dictionary = card.get("keyword_text_overrides", {})
	overrides["Acorn"] = reminder
	card["keyword_text_overrides"] = overrides
	for entry: Dictionary in card.get("keyword_text", []):
		if str(entry.get("keyword", "")) == "Acorn":
			entry["text"] = reminder
	return true
