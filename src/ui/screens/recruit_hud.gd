extends RefCounted
## Populate the recruit economy and lobby from one state snapshot.

const RecruitLayout := preload("res://src/ui/screens/recruit_layout.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const Data := preload("res://src/ui/view_data.gd")


static func populate(ui: RecruitLayout) -> bool:
	var state: Dictionary = ui.state
	ui._gold.show_gold(Data.i(state, "gold", 0))
	ui._gold.show_income(
		RecruitView.income_note(state),
		Data.i(state, "gold_next_turn") - Data.i(state, "debt_payment")
	)
	ui._tier_label.text = "TIER %d" % Data.i(state, "tier", 1)
	ui._round_label.text = "Turn %d" % Data.i(state, "round", 1)
	var tier_cost: Variant = state.get("tier_up_cost")
	if tier_cost == null:
		ui._tier_button.set_face("", "tier")
		ui._tier_button.disabled = true
	else:
		ui._tier_button.set_face("", "tier", Data.as_int(tier_cost))
		ui._tier_button.disabled = false
	var refresh_cost: int = Data.i(state, "refresh_cost", 1)
	ui._refresh_button.set_face("", "refresh", refresh_cost)
	ui._kin_button.set_face("", "refresh", 2)
	ui._kin_button.tooltip_text = (
		"2 gold, once a turn: refresh with at least two units sharing your tribes. "
		+ "Nests count as Birds."
	)
	ui._kin_button.disabled = not Data.b(state, "can_ask_for_kin")
	var frozen: bool = Data.b(state, "frozen", false)
	ui._freeze_button.set_face("", "freeze")
	ui._freeze_button.tooltip_text = "Unfreeze" if frozen else "Freeze"
	ui._tier_button.tooltip_text = "Tier up"
	ui._refresh_button.tooltip_text = "Refresh · %d gold" % refresh_cost
	ui._end_button.set_face("End turn")
	ui._lobby.show_standings(
		Data.a(state, "standings"),
		Data.i(state, "next_opponent_id", -2),
		Data.i(RecruitView.ghost_owner(state), "player_id", -9)
	)
	ui._tribes.show_bonuses(Data.a(state, "lobby_tribes"), Data.d(state, "tribe_bonuses"))
	ui._tribes.show_engine(state)
	return frozen
