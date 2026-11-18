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
// Source: src/content/mouse/mechanics/captain.gd
// Thimble Captain: whenever a neighbour attacks, summon a Cousin (golden: 2) nearest the
// Captain. Not on its own attacks. A Cousin that lands next to the attacker piles on in this
// same attack (the core lets a unit that arrives while friends hear an attack hear it too).

use crate::content::mouse::lib::mouse_rules::MouseRules;
#[derive(Clone, Default)]
pub struct Captain;
pub type CaptainRef = Rc<RefCell<Captain>>;
impl ToState for Captain {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for Captain {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("count", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_friendly_attack(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        attacker: &CombatUnitRef,
        _defender: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/mouse/mechanics/captain.gd:on_friendly_attack")
    }
}
