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
// Source: src/content/pigeon/mechanics/flying_ace.gd
// Flying Ace (with pigeon_sortie): after this kills, earn `medals` Medals for each unit its own
// damage killed, on the fight unit and the real one at once, kept if it dies in the same
// exchange. Decorated: Cleave, given to itself as an aura that follows the Medal count.

use crate::content::pigeon::lib::medals::Medals;
#[derive(Clone, Default)]
pub struct FlyingAce;
pub type FlyingAceRef = Rc<RefCell<FlyingAce>>;
impl ToState for FlyingAce {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for FlyingAce {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("medals", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_kill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        _victim: &CombatUnitRef,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/flying_ace.gd:on_kill")
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/flying_ace.gd:aura_keywords")
    }
}
