#![allow(unused_imports, unused_variables)]
use crate::content::thorn::lib::compost_rules::HEAP;
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
// Source: src/content/thorn/mechanics/grow.gd
// Grow N: Start of fight (main pass): gain +N/+N for every 2 units in your Compost, this fight.
// Grow from several sources adds up before the trigger: the first Grow on the unit gains the
// total. Units that arrive later don't Grow (the core runs only units there when it began).

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct Grow;
pub type GrowRef = Rc<RefCell<Grow>>;
impl ToState for Grow {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Grow {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.unwrap();
        let hooks = unit.borrow().hooks();
        if !Compost::is_first(&hooks, "thorn_grow", params) {
            return;
        }
        let index = unit.borrow().side;
        let side = combat.bridge(index);
        let pairs = side.borrow_mut().heap(combat, HEAP).borrow().size() / 2;
        let gain = Compost::total(&hooks, "thorn_grow", "amount") * pairs;
        if gain > 0 && combat.trigger(Some(unit), "thorn_grow") {
            combat.buff(Some(unit), gain, gain, Some(unit), false);
        }
    }
}
