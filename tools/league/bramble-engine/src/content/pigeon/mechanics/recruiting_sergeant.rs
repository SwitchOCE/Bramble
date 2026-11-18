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
// Source: src/content/pigeon/mechanics/recruiting_sergeant.gd
// Recruiting Sergeant: when a slot in front of this is empty in a fight, summon a Private there
// (`limit` a fight). Checked in the Start of fight set-up pass and after each round of deaths
// (after Reserve units and waiting summons, SHARED-RULES 6), the Guard post first. A golden
// Sergeant summons golden Privates (4/4), still `limit` a fight. The limit is a fight count, so
// it carries across a return (SHARED-RULES 21); the screen sees what is left (`uses`).
pub const SUMMONED: &str = "pigeon_sergeant_privates";
pub const PRIVATE: &str = "private";
use crate::content::pigeon::mechanics::guard_post::GuardPost;
#[derive(Clone, Default)]
pub struct RecruitingSergeant;
pub type RecruitingSergeantRef = Rc<RefCell<RecruitingSergeant>>;
impl ToState for RecruitingSergeant {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for RecruitingSergeant {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("limit", Variant::Int(Kind::Threshold as i64));
        out
    }
    fn start_of_combat_priority(&self, _params: &MechanicParamsRef) -> i64 {
        SOC_SETUP
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/recruiting_sergeant.gd:on_start_of_combat")
    }
    fn after_death_round(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/recruiting_sergeant.gd:after_death_round")
    }
}
impl RecruitingSergeant {
    pub fn _fill(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/recruiting_sergeant.gd:_fill")
    }
}
