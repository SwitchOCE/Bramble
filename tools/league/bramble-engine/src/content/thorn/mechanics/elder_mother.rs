#![allow(unused_imports, unused_variables)]
use crate::content::thorn::lib::compost_rules::{ELDER_PER, HEAP};
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
// Source: src/content/thorn/mechanics/elder_mother.gd
// Start of fight: Summon copies of the N highest-tier units in your Compost, with +M/+M for each
// unit in it (Elder Mother; main pass). Each copy goes to the empty slot nearest this unit; with
// no room it waits in the core's one line of waiting summons and lands after a round of deaths.
// On arrival it gains +M/+M for each Compost entry, used ones included (the standing Compost
// mechanic gives it, so it still lands bigger after the Elder Mother has died). The entries stay,
// marked used for this fight (FightSide.heap_use_highest). Copies don't run Start of fight
// effects.

use crate::content::thorn::lib::compost_rules::CompostRules as Compost;
#[derive(Clone, Default)]
pub struct ElderMother;
pub type ElderMotherRef = Rc<RefCell<ElderMother>>;
impl ToState for ElderMother {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl Mechanic for ElderMother {
    fn param_kinds(&self) -> Dictionary {
        let out = Dictionary::new();
        out.insert("copies", Variant::Int(Kind::Number as i64));
        out.insert("per", Variant::Int(Kind::Number as i64));
        out
    }
    fn on_start_of_combat(
        &self,
        combat: &mut Combat,
        unit: Option<&CombatUnitRef>,
        params: &MechanicParamsRef,
    ) {
        let unit = unit.unwrap();
        let index = unit.borrow().side;
        let side = combat.bridge(index);
        if side.borrow_mut().heap_unused(combat, HEAP) <= 0
            || !combat.trigger(Some(unit), "thorn_elder_mother")
        {
            return;
        }
        let payload = Dictionary::new();
        payload.insert(ELDER_PER, Variant::Int(params.borrow().num("per")));
        let copies = params.borrow().num("copies");
        for _i in 0..copies {
            let entry = FightSide::heap_use_highest(&side, combat, HEAP, Some(unit));
            if entry.is_empty() {
                return;
            }
            let (index, slot) = {
                let u = unit.borrow();
                (u.side, u.slot)
            };
            combat.summon(
                index,
                &entry.get("id").as_text(),
                slot,
                false,
                Some(unit),
                true,
                &payload,
                false,
            );
        }
    }
}
