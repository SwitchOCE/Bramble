#![allow(unused_imports, unused_variables)]
use crate::core::combat::fight_side::FightSide;
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
// Source: src/content/locust/mechanics/molt.gd
// Molt: the first time this dies each fight, it returns as a plain copy with 1 Health, then
// gains +2/+2 permanently (the copy and the recruit-board unit). Through the core's return
// protocol: counted in charges (printed Molt is one a fight, Skin-shedder adds locust_molt_extra
// for this fight), kept in fight counts so they carry across any return, and shown as uses left.
// A plain return (RETURN_PLAIN): with Root as well, Root comes first when the Compost can pay
// (ruling 17), decided by return priority.
// After any return (this Molt's, or Root's first): a Molt given this fight (Skin-shedder) is not
// on the returned unit (a plain copy, or the recruit-board unit), so it is given again while a
// charge is left.
pub const GROWTH: i64 = 2;
use crate::content::locust::lib::locust::{self as names, Locust};
#[derive(Clone, Default)]
pub struct Molt;
pub type MoltRef = Rc<RefCell<Molt>>;
impl ToState for Molt {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Molt {
    fn return_offer(
        &self,
        _combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _params: &MechanicParamsRef,
    ) -> i64 {
        if Locust::molt_left(unit) > 0 {
            1
        } else {
            0
        }
    }
    fn pay_return(
        &self,
        combat: &mut Combat,
        gone: &CombatUnitRef,
        back: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        back.borrow_mut().add_fight_count(names::MOLT_USED, 1);
        combat.buff(Some(back), GROWTH, GROWTH, Some(gone), true);
        let left = Locust::molt_left(Some(back));
        combat.show_uses(Some(back), names::MOLT, left, Some(gone));
        if left <= 0 {
            combat.show_status(Some(back), names::MOLT, false, Some(gone));
        }
    }
    fn on_returned(
        &self,
        combat: &mut Combat,
        gone: &CombatUnitRef,
        back: &CombatUnitRef,
        _params: &MechanicParamsRef,
    ) {
        if Locust::molt_left(Some(back)) > 0 && !back.borrow().has_mechanic(names::MOLT) {
            let side_index = back.borrow().side;
            let side = combat.bridge(side_index);
            FightSide::give_keyword(&side, combat, Some(back), names::MOLT, false, Some(gone));
        }
    }
}
