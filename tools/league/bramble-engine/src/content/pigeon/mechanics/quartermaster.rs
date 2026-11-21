//! Mirrors src/content/pigeon/mechanics/quartermaster.gd.
use crate::core::mechanics::mechanic::Mechanic;
use crate::core::mechanics::mechanic_params::Kind;
use crate::core::{
    combat::{combat::Combat, combat_unit::CombatUnitRef},
    mechanics::mechanic::{Q_RESERVE_LIMIT, Target},
    mechanics::mechanic_params::MechanicParamsRef,
    recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext},
    units::unit::UnitRef,
};
use crate::{Dictionary, ToState, Variant};
use std::rc::Rc;

pub struct Quartermaster;

impl ToState for Quartermaster {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::new())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}

impl Quartermaster {
    fn _reserve_targets(params: &MechanicParamsRef) -> i64 {
        params.borrow().num("reserve_targets")
    }
}

impl Mechanic for Quartermaster {
    fn param_kinds(&self) -> Dictionary {
        crate::state_dict! { "amount" => &(Kind::Number as i64), "reserve_targets" => &(Kind::Number as i64) }.as_dict()
    }

    fn text_params(&self, params: &MechanicParamsRef) -> Dictionary {
        let count = Self::_reserve_targets(params);
        let words = if count == 1 {
            "a unit".into()
        } else {
            format!("{count} units")
        };
        crate::state_dict! {"reserve_units" => &words}.as_dict()
    }

    fn recruit_target(&self, _params: &MechanicParamsRef) -> Target {
        Target::HandUnit
    }
    fn accepts_recruit_target(&self, unit: &UnitRef, source: Option<&UnitRef>) -> bool {
        !source.is_some_and(|source| Rc::ptr_eq(unit, source))
            && !unit.borrow().has_mechanic("pigeon_reserve")
    }
    fn on_recruited(
        &self,
        ctx: &mut RecruitContext,
        unit: &UnitRef,
        target: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) {
        let limit = Self::_reserve_targets(params);
        if limit <= 0 {
            return;
        }
        // Put the explicit Recruit target first.
        let mut candidates = ctx.player.as_ref().unwrap().borrow().hand.to_vec();
        if let Some(target) = target
            && let Some(index) = candidates.iter().position(|card| Rc::ptr_eq(card, target))
        {
            let selected = candidates.remove(index);
            candidates.insert(0, selected);
        }
        let mut given = 0;
        for card in candidates {
            if card.borrow().is_spell() || !self.accepts_recruit_target(&card, Some(unit)) {
                continue;
            }
            if given == 0 && !ctx.trigger(Some(unit), "pigeon_quartermaster") {
                return;
            }
            ctx.give_keyword(&card, "pigeon_reserve", Some(unit));
            given += 1;
            if given == limit {
                return;
            }
        }
    }
    fn side_query(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        params: &MechanicParamsRef,
    ) -> i64 {
        if unit.is_some() && query == Q_RESERVE_LIMIT {
            return value.wrapping_add(params.borrow().num("amount"));
        }
        value
    }

    fn modify_int(
        &self,
        query: &str,
        value: i64,
        _player: Option<&PlayerStateRef>,
        _unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) -> i64 {
        if query == Q_RESERVE_LIMIT {
            return value.wrapping_add(params.borrow().num("amount"));
        }
        value
    }
}
