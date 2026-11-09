extends BotEval
## Measurement arm: ignore authored buy/keep scores, including text_value's keep hint.
## Fallback text value is TEXT_PER_TIER * tier; live mechanic/stat evaluation still applies.


func _hint_number(card_def: Dictionary, key: String, fallback: float) -> float:
	if key in ["buy", "keep"]:
		return fallback
	return super._hint_number(card_def, key, fallback)
