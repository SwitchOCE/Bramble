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
// Source: src/content/thorn/mechanics/old_stump.gd
// When this dies, summon a copy of the highest-tier unit in your Compost (Old Stump; a golden:
// the 2 highest). A plain, non-golden copy for this fight, into this unit's slot first. The
// entry stays in the Compost, marked used for this fight (FightSide.heap_use_highest), so each
// entry comes out once a fight. With nothing left to copy, or no room, nothing happens and no
// entry is marked. In the shop (eaten) it does nothing.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct OldStump;
pub type OldStumpRef = Rc<RefCell<OldStump>>;
impl ToState for OldStump {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for OldStump {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("copies", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_death_effect(&self) -> bool {
        true
    }
    fn on_death(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        // TODO(port mechanics)
        todo!("port src/content/thorn/mechanics/old_stump.gd:on_death")
    }
}
