#![allow(unused_imports, unused_variables)]
use crate::core::combat::{combat::Combat, combat_unit::CombatUnitRef};
use crate::core::mechanics::{
    bound_mechanic::BoundMechanicRef,
    mechanic::*,
    mechanic_params::{Kind, MechanicParamsRef},
};
use crate::core::recruit::{player_state::PlayerStateRef, recruit_context::RecruitContext};
use crate::core::state::{aura_context::AuraContext, fight_report::FightReportRef};
use crate::core::units::{unit::UnitRef, unit_def::UnitDefRef};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
// Source: src/content/locust/mechanics/mother.gd
// Mother of Thousands. Whenever you summon Hoppers, summon (1 + `extra`) times as many: twice,
// three times on a golden. Two don't add up (the biggest applies). In a fight it must be on
// the board; in the shop, on the recruit board.

use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct Mother;
pub type MotherRef = Rc<RefCell<Mother>>;
impl ToState for Mother {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Mother {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("extra", Variant::Int(Kind::Number as i64));
        out
    }
    fn side_query(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        query: &str,
        value: i64,
        params: &MechanicParamsRef,
    ) -> i64 {
        if unit.is_some() && query == names::Q_HOPPER_TIMES {
            return value.max(1 + params.borrow().num("extra"));
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
        if query == names::Q_HOPPER_TIMES {
            value.max(1 + params.borrow().num("extra"))
        } else {
            value
        }
    }
}
