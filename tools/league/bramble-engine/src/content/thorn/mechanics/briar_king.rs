#![allow(unused_imports, unused_variables)]
use crate::content::thorn::lib::compost_rules::BRIAR;
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
// Source: src/content/thorn/mechanics/briar_king.gd
// Your other front-row Briars have Grow N (Briar King): an aura on Briars in F1 to F4, not this
// unit, adding to any Grow they have.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct BriarKing;
pub type BriarKingRef = Rc<RefCell<BriarKing>>;
impl ToState for BriarKing {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for BriarKing {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("amount", Variant::Int(Kind::Number as i64));
        out
    }
    fn has_aura(&self) -> bool {
        true
    }
    fn aura_grants(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> Array<Dictionary> {
        if source_slot < 0
            || target_slot == source_slot
            || !view
                .geometry
                .as_ref()
                .unwrap()
                .borrow()
                .is_front(target_slot)
        {
            return Array::new();
        }
        let target = view.def_at(target_slot);
        if target.is_none() || !target.unwrap().borrow().has_tribe(BRIAR) {
            return Array::new();
        }
        let grant = Dictionary::new();
        grant.insert("mechanic", Variant::String("thorn_grow".into()));
        grant.insert("amount", Variant::Int(params.borrow().num("amount")));
        Array::from([grant])
    }
}
