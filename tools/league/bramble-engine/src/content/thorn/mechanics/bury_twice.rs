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
// Source: src/content/thorn/mechanics/bury_twice.gd
// "Your Bury effects happen twice" (Old Mother Midden: `times` 2, a golden 3 through card data's
// golden override). One unit is still buried and one entry added. Two Middens don't add up: the
// biggest applies.

use crate::content::thorn::lib::bury_base::BuryBase;
#[derive(Clone, Default)]
pub struct BuryTwice;
pub type BuryTwiceRef = Rc<RefCell<BuryTwice>>;
impl ToState for BuryTwice {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for BuryTwice {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("times", Variant::Int(Kind::Number as i64));
        out
    }
    fn modify_int(
        &self,
        query: &str,
        value: i64,
        _player: Option<&PlayerStateRef>,
        _unit: Option<&UnitRef>,
        params: &MechanicParamsRef,
    ) -> i64 {
        if query != crate::content::thorn::lib::bury_base::Q_BURY_TIMES {
            return value;
        }
        value.max(params.borrow().num("times"))
    }
}
