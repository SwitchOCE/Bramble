//! Port of `src/core/rules/game_config.gd`.
// 2.1.1
// 2.2.5 (no heroes on this track: everyone starts at the default)
// 4.1.1: 5 on turn 1, +2 a turn until 15, then +1 a turn, no ceiling.
// 4.4.2-4.4.3: 1 gold for the first 10 paid refreshes, then +1 every 5.
// 4.5.1
// 4.6.1-4.6.2: base cost to upgrade to tiers 2..6.
// 4.6.3, 4.6.6: the per-turn drop grows by 1 a turn up to this.
// 5.1.2: copies per unit and per Tavern spell, by tier 1..7 (spells 1..6).
// 6.1.1
// 6.2.1
// 7.1.1
// 8.1.2
// 10.1.1, 10.1.3: small loss = round + 1 up to 10; a big loss deals 3 more.
// 9.10.1-9.10.3
// 1.2.4
// 2.1.3
use crate::core::util::core_util::CoreUtil;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type GameConfigRef = Rc<RefCell<GameConfig>>;
#[derive(Clone)]
pub struct GameConfig {
    pub players: i64,
    pub starting_health: i64,
    pub starting_armor: i64,
    pub income_first: i64,
    pub income_fast_step: i64,
    pub income_fast_until: i64,
    pub income_slow_step: i64,
    pub refresh_base_cost: i64,
    pub refresh_first_step_after: i64,
    pub refresh_step_length: i64,
    pub freeze_toggles_per_turn: i64,
    pub max_tier: i64,
    pub upgrade_costs: Array<i64>,
    pub discount_step_cap: i64,
    pub unit_copies_by_tier: Array<i64>,
    pub spell_copies_by_tier: Array<i64>,
    pub shop_units: i64,
    pub shop_spells: i64,
    pub discover_options: i64,
    pub hand_limit: i64,
    pub front_slots: i64,
    pub back_slots: i64,
    pub loss_round_offset: i64,
    pub loss_cap: i64,
    pub big_loss_extra: i64,
    pub attack_limit: i64,
    pub combat_trigger_limit: i64,
    pub action_trigger_limit: i64,
    pub return_limit: i64,
    pub stat_max: i64,
    pub round_limit: i64,
}
impl Default for GameConfig {
    fn default() -> Self {
        Self {
            players: 8,
            starting_health: 40,
            starting_armor: 0,
            income_first: 5,
            income_fast_step: 2,
            income_fast_until: 15,
            income_slow_step: 1,
            refresh_base_cost: 1,
            refresh_first_step_after: 10,
            refresh_step_length: 5,
            freeze_toggles_per_turn: 5,
            max_tier: 6,
            upgrade_costs: Array::from(vec![8, 12, 16, 19, 26]),
            discount_step_cap: 5,
            unit_copies_by_tier: Array::from(vec![15, 15, 13, 11, 9, 7, 5]),
            spell_copies_by_tier: Array::from(vec![5, 7, 9, 11, 9, 7]),
            shop_units: 5,
            shop_spells: 2,
            discover_options: 3,
            hand_limit: 7,
            front_slots: 4,
            back_slots: 3,
            loss_round_offset: 1,
            loss_cap: 10,
            big_loss_extra: 3,
            attack_limit: 200,
            combat_trigger_limit: 10000,
            action_trigger_limit: 1000,
            return_limit: 5,
            stat_max: 1000000000,
            round_limit: 50,
        }
    }
}
impl GameConfig {
    pub fn new() -> Self {
        Self::default()
    }
    /// Format 2 records require every saved script field; extra keys are ignored, as in Godot.
    pub fn from_dict(saved: &Dictionary) -> Result<Self, String> {
        let saved = saved.borrow();
        for key in Self::field_names() {
            if !saved.contains_key(*key) {
                return Err(format!("missing config {key}"));
            }
        }
        Ok(Self {
            players: CoreUtil::to_int(&saved["players"]),
            starting_health: CoreUtil::to_int(&saved["starting_health"]),
            starting_armor: CoreUtil::to_int(&saved["starting_armor"]),
            income_first: CoreUtil::to_int(&saved["income_first"]),
            income_fast_step: CoreUtil::to_int(&saved["income_fast_step"]),
            income_fast_until: CoreUtil::to_int(&saved["income_fast_until"]),
            income_slow_step: CoreUtil::to_int(&saved["income_slow_step"]),
            refresh_base_cost: CoreUtil::to_int(&saved["refresh_base_cost"]),
            refresh_first_step_after: CoreUtil::to_int(&saved["refresh_first_step_after"]),
            refresh_step_length: CoreUtil::to_int(&saved["refresh_step_length"]),
            freeze_toggles_per_turn: CoreUtil::to_int(&saved["freeze_toggles_per_turn"]),
            max_tier: CoreUtil::to_int(&saved["max_tier"]),
            upgrade_costs: Array::from(
                CoreUtil::to_array(&saved["upgrade_costs"])
                    .borrow()
                    .iter()
                    .map(CoreUtil::to_int)
                    .collect::<Vec<_>>(),
            ),
            discount_step_cap: CoreUtil::to_int(&saved["discount_step_cap"]),
            unit_copies_by_tier: Array::from(
                CoreUtil::to_array(&saved["unit_copies_by_tier"])
                    .borrow()
                    .iter()
                    .map(CoreUtil::to_int)
                    .collect::<Vec<_>>(),
            ),
            spell_copies_by_tier: Array::from(
                CoreUtil::to_array(&saved["spell_copies_by_tier"])
                    .borrow()
                    .iter()
                    .map(CoreUtil::to_int)
                    .collect::<Vec<_>>(),
            ),
            shop_units: CoreUtil::to_int(&saved["shop_units"]),
            shop_spells: CoreUtil::to_int(&saved["shop_spells"]),
            discover_options: CoreUtil::to_int(&saved["discover_options"]),
            hand_limit: CoreUtil::to_int(&saved["hand_limit"]),
            front_slots: CoreUtil::to_int(&saved["front_slots"]),
            back_slots: CoreUtil::to_int(&saved["back_slots"]),
            loss_round_offset: CoreUtil::to_int(&saved["loss_round_offset"]),
            loss_cap: CoreUtil::to_int(&saved["loss_cap"]),
            big_loss_extra: CoreUtil::to_int(&saved["big_loss_extra"]),
            attack_limit: CoreUtil::to_int(&saved["attack_limit"]),
            combat_trigger_limit: CoreUtil::to_int(&saved["combat_trigger_limit"]),
            action_trigger_limit: CoreUtil::to_int(&saved["action_trigger_limit"]),
            return_limit: CoreUtil::to_int(&saved["return_limit"]),
            stat_max: CoreUtil::to_int(&saved["stat_max"]),
            round_limit: CoreUtil::to_int(&saved["round_limit"]),
        })
    }
    pub fn to_dict(&self) -> Dictionary {
        match self.to_state() {
            Variant::Dictionary(value) => value,
            _ => unreachable!(),
        }
    }
    pub fn copies_for(&self, tier: i64, spell: bool) -> i64 {
        let table = if spell {
            &self.spell_copies_by_tier
        } else {
            &self.unit_copies_by_tier
        };
        let table = table.borrow();
        if tier < 1 || tier > table.len() as i64 {
            return 0;
        }
        table[tier as usize - 1]
    }
}
impl ToState for GameConfig {
    fn to_state(&self) -> Variant {
        crate::state_dict! {
            "players" => &self.players,
            "starting_health" => &self.starting_health,
            "starting_armor" => &self.starting_armor,
            "income_first" => &self.income_first,
            "income_fast_step" => &self.income_fast_step,
            "income_fast_until" => &self.income_fast_until,
            "income_slow_step" => &self.income_slow_step,
            "refresh_base_cost" => &self.refresh_base_cost,
            "refresh_first_step_after" => &self.refresh_first_step_after,
            "refresh_step_length" => &self.refresh_step_length,
            "freeze_toggles_per_turn" => &self.freeze_toggles_per_turn,
            "max_tier" => &self.max_tier,
            "upgrade_costs" => &self.upgrade_costs,
            "discount_step_cap" => &self.discount_step_cap,
            "unit_copies_by_tier" => &self.unit_copies_by_tier,
            "spell_copies_by_tier" => &self.spell_copies_by_tier,
            "shop_units" => &self.shop_units,
            "shop_spells" => &self.shop_spells,
            "discover_options" => &self.discover_options,
            "hand_limit" => &self.hand_limit,
            "front_slots" => &self.front_slots,
            "back_slots" => &self.back_slots,
            "loss_round_offset" => &self.loss_round_offset,
            "loss_cap" => &self.loss_cap,
            "big_loss_extra" => &self.big_loss_extra,
            "attack_limit" => &self.attack_limit,
            "combat_trigger_limit" => &self.combat_trigger_limit,
            "action_trigger_limit" => &self.action_trigger_limit,
            "return_limit" => &self.return_limit,
            "stat_max" => &self.stat_max,
            "round_limit" => &self.round_limit,
        }
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "players",
            "starting_health",
            "starting_armor",
            "income_first",
            "income_fast_step",
            "income_fast_until",
            "income_slow_step",
            "refresh_base_cost",
            "refresh_first_step_after",
            "refresh_step_length",
            "freeze_toggles_per_turn",
            "max_tier",
            "upgrade_costs",
            "discount_step_cap",
            "unit_copies_by_tier",
            "spell_copies_by_tier",
            "shop_units",
            "shop_spells",
            "discover_options",
            "hand_limit",
            "front_slots",
            "back_slots",
            "loss_round_offset",
            "loss_cap",
            "big_loss_extra",
            "attack_limit",
            "combat_trigger_limit",
            "action_trigger_limit",
            "return_limit",
            "stat_max",
            "round_limit",
        ]
    }
}
