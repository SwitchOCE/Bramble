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
    fn aura_parts(&self) -> u8 {
        AURA_GRANTS
    }
    fn aura_grants(
        &self,
        view: &mut AuraContext,
        source_slot: i64,
        target_slot: i64,
        params: &MechanicParamsRef,
    ) -> Array<Dictionary> {
        if source_slot < 0 {
            return Array::new();
        }
        for slot in 0..source_slot {
            if Self::_has(view.def_at(slot).as_ref(), KEEPER) {
                return Array::new();
            }
        }
        let target = view.def_at(target_slot);
        if !BadgerRules::is_knight(target.as_ref())
            || Self::_has(
                target.as_ref(),
                crate::content::badger::lib::badger_rules::GRUDGE,
            )
        {
            return Array::new();
        }
        let raw = Dictionary::new();
        raw.insert(
            "mechanic",
            Variant::from(crate::content::badger::lib::badger_rules::GRUDGE),
        );
        raw.insert("grudge", Variant::Int(params.borrow().num("grudge")));
        Array::from([raw])
    }
}
impl GrudgeKeeper {
    pub fn _has(def: Option<&UnitDefRef>, mechanic_id: &str) -> bool {
        let Some(def) = def else {
            return false;
        };
        let mechanics = def.borrow().mechanics.clone();
        let mut i = 0;
        while i < mechanics.len() {
            if mechanics.get(i).unwrap().borrow().id == mechanic_id {
                return true;
            }
            i += 1;
        }
        false
    }
}
