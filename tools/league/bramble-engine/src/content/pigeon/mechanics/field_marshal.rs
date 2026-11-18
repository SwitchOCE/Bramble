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
// Source: src/content/pigeon/mechanics/field_marshal.gd
// Field Marshal: an aura while this is on the board. Each Medal on a friendly Pigeon gives
// `extra`/`extra` more (borrowed), so a Medal is worth +4/+4, or +6/+6 from a golden; the
// Medal's own +2/+2 stays the unit's. And friendly Decorated Pigeons have Stiff Upper Lip.

use crate::content::pigeon::lib::medals::Medals;
#[derive(Clone, Default)]
pub struct FieldMarshal;
pub type FieldMarshalRef = Rc<RefCell<FieldMarshal>>;
impl ToState for FieldMarshal {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for FieldMarshal {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("extra", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> (i64, i64) {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/field_marshal.gd:aura")
    }
    fn aura_keywords(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        _params: &MechanicParamsRef,
    ) -> Array<String> {
        // TODO(port mechanics)
        todo!("port src/content/pigeon/mechanics/field_marshal.gd:aura_keywords")
    }
}
