//! Port of `src/core/rules/rules.gd`.
use crate::core::recruit::player_state::PlayerStateRef;
use crate::core::rules::game_config::GameConfigRef;
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::core::util::core_util::CoreUtil;
use crate::{Array, ToState, Variant};
use std::{cell::RefCell, rc::Rc};

pub type RulesRef = Rc<RefCell<Rules>>;
pub struct Rules {
    pub config: GameConfigRef,
}
impl Rules {
    pub const INCOME: &'static str = "income";
    pub const UNIT_PRICE: &'static str = "unit_price";
    pub const SPELL_PRICE: &'static str = "spell_price";
    pub const SELL_VALUE: &'static str = "sell_value";
    pub const REFRESH_COST: &'static str = "refresh_cost";
    pub const UPGRADE_COST: &'static str = "upgrade_cost";
    pub const HAND_LIMIT: &'static str = "hand_limit";
    pub const SHOP_UNITS: &'static str = "shop_units";
    pub const SHOP_SPELLS: &'static str = "shop_spells";
    pub const FREEZE_LIMIT: &'static str = "freeze_limit";
    pub const DISCOVER_OPTIONS: &'static str = "discover_options";
    pub const TRIPLE_REWARD_TIER: &'static str = "triple_reward_tier";
    pub const LOSS_DAMAGE: &'static str = "loss_damage";

    pub fn new(game_config: &GameConfigRef) -> Self {
        Self {
            config: game_config.clone(),
        }
    }
    pub fn ask(
        &self,
        query: &str,
        base: i64,
        player: Option<&PlayerStateRef>,
        unit: Option<&UnitRef>,
        used: Option<&Array<UnitRef>>,
    ) -> i64 {
        let mut value = base;
        let contributors = Array::new();
        let sources = if let Some(unit) = unit {
            Array::from([unit.clone()])
        } else if let Some(player) = player {
            player.borrow().board_units()
        } else {
            Array::new()
        };
        for source in sources.iter_live() {
            value = self._unit_layer(&source, query, value, player, Some(&contributors));
        }
        value = self._cap(query, value);
        // Remove earlier weaker modifiers superseded by later ones. Equal backups never
        // entered contributors, so the first applying copy remains the source.
        if contributors.len() > 1 {
            for source in contributors.duplicate().iter_live() {
                let mut without = base;
                for other in contributors.iter_live() {
                    if !Rc::ptr_eq(&other, &source) {
                        without = self._unit_layer(&other, query, without, player, None);
                    }
                }
                if self._cap(query, without) == value {
                    contributors
                        .borrow_mut()
                        .retain(|other| !Rc::ptr_eq(other, &source));
                }
            }
        }
        if let Some(used) = used {
            for source in contributors.iter_live() {
                if !used.borrow().iter().any(|other| Rc::ptr_eq(other, &source)) {
                    used.push(source);
                }
            }
        }
        value
    }
    pub fn _unit_layer(
        &self,
        unit: &UnitRef,
        query: &str,
        mut value: i64,
        player: Option<&PlayerStateRef>,
        used: Option<&Array<UnitRef>>,
    ) -> i64 {
        let mechanics = unit.borrow().mechanics.clone();
        for bound in mechanics.iter_live() {
            let (mechanic, params) = {
                let bound = bound.borrow();
                (
                    bound.mechanic.as_ref().expect("bound mechanic").clone(),
                    bound.params.clone(),
                )
            };
            let next = mechanic.modify_int(query, value, player, Some(unit), &params);
            if let Some(used) = used
                && self._cap(query, next) != self._cap(query, value)
                && !used.borrow().iter().any(|other| Rc::ptr_eq(other, unit))
            {
                used.push(unit.clone());
            }
            value = next;
        }
        value
    }
    // Hard caps: no price, cost or limit below 0 (4.1.5), and the hand holds at least one card.
    pub fn _cap(&self, query: &str, value: i64) -> i64 {
        if query == Self::HAND_LIMIT {
            return value.max(1);
        }
        if query == Self::TRIPLE_REWARD_TIER {
            return value.clamp(1, self.config.borrow().max_tier);
        }
        value.max(0)
    }
    // 4.1.1 income on `turn` (1-based), then 4.1.4's changes through the query.
    pub fn income(&self, player: &PlayerStateRef, turn: i64, used: Option<&Array<UnitRef>>) -> i64 {
        let config = self.config.borrow();
        let mut amount = config.income_first;
        for _step in 1..turn {
            if amount < config.income_fast_until {
                amount = (amount + config.income_fast_step).min(config.income_fast_until);
            } else {
                amount += config.income_slow_step;
            }
        }
        drop(config);
        self.ask(Self::INCOME, amount, Some(player), None, used)
    }
    // 4.2.1 a unit costs its tier + 1.
    pub fn unit_price(
        &self,
        player: &PlayerStateRef,
        def: &UnitDefRef,
        used: Option<&Array<UnitRef>>,
    ) -> i64 {
        self.ask(
            Self::UNIT_PRICE,
            def.borrow().tier + 1,
            Some(player),
            None,
            used,
        )
    }
    // 4.2.5 a Tavern spell costs its listed cost.
    pub fn spell_price(
        &self,
        player: &PlayerStateRef,
        def: &UnitDefRef,
        used: Option<&Array<UnitRef>>,
    ) -> i64 {
        self.ask(
            Self::SPELL_PRICE,
            def.borrow().cost,
            Some(player),
            None,
            used,
        )
    }
    // 4.3.3-4.3.4: half the tier rounded up for each Bought copy; Created copies add nothing.
    pub fn sell_value(&self, player: &PlayerStateRef, unit: &UnitRef) -> i64 {
        let each = CoreUtil::ceil_div(
            unit.borrow().def.as_ref().expect("Unit.def").borrow().tier,
            2,
        );
        let base = each * unit.borrow().bought_copies;
        self.ask(Self::SELL_VALUE, base, Some(player), Some(unit), None)
    }
    // 4.4.2-4.4.3: the cost of the player's next paid refresh this turn.
    pub fn refresh_cost(&self, player: &PlayerStateRef, used: Option<&Array<UnitRef>>) -> i64 {
        let config = self.config.borrow();
        let next_paid = player.borrow().refreshes_paid + 1;
        let mut cost = config.refresh_base_cost;
        if next_paid > config.refresh_first_step_after {
            cost += CoreUtil::ceil_div(
                next_paid - config.refresh_first_step_after,
                config.refresh_step_length,
            );
        }
        drop(config);
        self.ask(Self::REFRESH_COST, cost, Some(player), None, used)
    }
    // Paid refreshes remaining at the current step, including the next one (4.4.2-4.4.5).
    pub fn refreshes_left(&self, player: &PlayerStateRef) -> i64 {
        let paid = player.borrow().refreshes_paid;
        let config = self.config.borrow();
        if paid < config.refresh_first_step_after {
            return config.refresh_first_step_after - paid;
        }
        config.refresh_step_length
            - (paid - config.refresh_first_step_after) % config.refresh_step_length
    }
    // 4.6.2-4.6.6: base cost of the next tier, less the discount for turns waited on this tier.
    // -1 when the player is at the top tier.
    pub fn upgrade_cost(&self, player: &PlayerStateRef, used: Option<&Array<UnitRef>>) -> i64 {
        let player_value = player.borrow();
        let config = self.config.borrow();
        if player_value.tier >= config.max_tier {
            return -1;
        }
        let base = config.upgrade_costs.borrow()[player_value.tier as usize - 1];
        let waited = player_value.turns_waited;
        drop(config);
        drop(player_value);
        self.ask(
            Self::UPGRADE_COST,
            (base - self.waiting_discount(waited)).max(0),
            Some(player),
            None,
            used,
        )
    }
    // 4.6.3, 4.6.6: total discount after `turns` turns waited: 1, 3, 6, 10, 15, then +5 a turn.
    pub fn waiting_discount(&self, turns: i64) -> i64 {
        let mut total = 0;
        for turn in 1..turns + 1 {
            total += turn.min(self.config.borrow().discount_step_cap);
        }
        total
    }
    pub fn hand_limit(&self, player: &PlayerStateRef) -> i64 {
        self.ask(
            Self::HAND_LIMIT,
            self.config.borrow().hand_limit,
            Some(player),
            None,
            None,
        )
    }
    pub fn shop_units(&self, player: &PlayerStateRef) -> i64 {
        self.ask(
            Self::SHOP_UNITS,
            self.config.borrow().shop_units,
            Some(player),
            None,
            None,
        )
    }
    pub fn shop_spells(&self, player: &PlayerStateRef) -> i64 {
        self.ask(
            Self::SHOP_SPELLS,
            self.config.borrow().shop_spells,
            Some(player),
            None,
            None,
        )
    }
    pub fn freeze_limit(&self, player: &PlayerStateRef) -> i64 {
        self.ask(
            Self::FREEZE_LIMIT,
            self.config.borrow().freeze_toggles_per_turn,
            Some(player),
            None,
            None,
        )
    }
    pub fn discover_options(&self, player: &PlayerStateRef) -> i64 {
        self.ask(
            Self::DISCOVER_OPTIONS,
            self.config.borrow().discover_options,
            Some(player),
            None,
            None,
        )
    }
    // 7.3.6: the tier above the player's current tier, or the top tier at the top.
    pub fn triple_reward_tier(&self, player: &PlayerStateRef) -> i64 {
        self.ask(
            Self::TRIPLE_REWARD_TIER,
            (player.borrow().tier + 1).min(self.config.borrow().max_tier),
            Some(player),
            None,
            None,
        )
    }
    // 10.1.1-10.1.3: round + 1 up to 10; a big loss deals 3 more. Asked for the loser.
    pub fn loss_damage(&self, loser: &PlayerStateRef, round_number: i64, big: bool) -> i64 {
        let config = self.config.borrow();
        let mut amount = (round_number + config.loss_round_offset).min(config.loss_cap);
        if big {
            amount += config.big_loss_extra;
        }
        drop(config);
        self.ask(Self::LOSS_DAMAGE, amount, Some(loser), None, None)
    }
}
impl ToState for Rules {
    fn to_state(&self) -> Variant {
        crate::state_dict! { "config" => &self.config }
    }
    fn field_names() -> &'static [&'static str] {
        &["config"]
    }
}
