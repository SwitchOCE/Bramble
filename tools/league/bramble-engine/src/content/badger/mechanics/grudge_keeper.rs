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
// Source: src/content/badger/mechanics/grudge_keeper.gd
// Grudge-keeper: your Knights have Grudge N. Paid by badger_grudge_pay (the biggest keeper, once
// for each Knight); this aura shows it on the Knights with no Grudge of their own, from the first
// keeper in reading order.
pub const KEEPER: &str = "badger_grudge_keeper";
use crate::content::badger::lib::badger_rules::BadgerRules;
#[derive(Clone, Default)]
pub struct GrudgeKeeper;
pub type GrudgeKeeperRef = Rc<RefCell<GrudgeKeeper>>;
impl ToState for GrudgeKeeper {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for GrudgeKeeper {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("grudge", Variant::Int(Kind::Number as i64));
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
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/grudge_keeper.gd:aura_grants")
    }
}
impl GrudgeKeeper {
    pub fn _has(def: Option<&UnitDefRef>, mechanic_id: &str) -> bool {
        // TODO(port mechanics)
        todo!("port src/content/badger/mechanics/grudge_keeper.gd:_has")
    }
}
