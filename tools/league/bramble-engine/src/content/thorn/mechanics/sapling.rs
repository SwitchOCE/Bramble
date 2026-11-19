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
// Source: src/content/thorn/mechanics/sapling.gd
// After this returns, gain +N/+N permanently (Blackthorn Sapling): after any return of this unit,
// Root or a Molt, on the returned unit in the fight and on the recruit board.

#[derive(Clone, Default)]
pub struct Sapling;
pub type SaplingRef = Rc<RefCell<Sapling>>;
impl ToState for Sapling {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Sapling {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_returned(
        &self,
        combat: &mut Combat,
        _gone: &CombatUnitRef,
        back: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        if back.borrow().gone || !combat.trigger(Some(back), "thorn_sapling") {
            return;
        }
        let amount = params.borrow().num("amount");
        combat.buff(Some(back), amount, amount, Some(back), true);
    }
}
