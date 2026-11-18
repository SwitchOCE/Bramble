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
// Source: src/content/thorn/lib/compost_rules.gd
// The Briars' shared rules (docs/ideation-track-2/tribes/thorn/units.json "rules"), used by the
// thorn mechanics. Not a mechanic: it sits outside mechanics/ so the loader doesn't register it.
// Stateless. The core marks which Compost entries were copied this fight
// (FightSide.heap_use_highest); Root's once a fight is a fight count (root.gd).
// The Compost: one heap on each player for the whole game.
// CombatUnit.state on an Elder Mother copy: +N/+N for each Compost entry when it lands.
// True when `params` belongs to the first bound mechanic with this id on the unit (own text
// first, then aura grants). Keywords that add up (Thorns, Grow) act once, from the first.
// The sum of one parameter over every bound mechanic with this id (Thorns 2 + Thorns 6).
// True when a side has an empty slot for a summon (a dying unit still holds its slot until the
// death check, as the core counts it).
// An Elder Mother copy that just landed gains +N/+N for each Compost entry, once.
// The Briars on a recruit board, in reading order.
pub const HEAP: &str = "thorn_compost";
pub const BRIAR: &str = "Briar";
pub const ELDER_PER: &str = "thorn_elder_per";
#[derive(Clone, Default)]
pub struct CompostRules;
pub type CompostRulesRef = Rc<RefCell<CompostRules>>;
impl ToState for CompostRules {
    fn to_state(&self) -> Variant {
        Variant::Dictionary(Dictionary::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl CompostRules {
    pub fn is_first(
        hooks: &Array<BoundMechanicRef>,
        mechanic_id: &str,
        params: &MechanicParamsRef,
    ) -> bool {
        // TODO(port mechanics)
        todo!("port src/content/thorn/lib/compost_rules.gd:is_first")
    }
    pub fn total(hooks: &Array<BoundMechanicRef>, mechanic_id: &str, param: &str) -> i64 {
        // TODO(port mechanics)
        todo!("port src/content/thorn/lib/compost_rules.gd:total")
    }
    pub fn has_room(combat: &mut Combat, side_index: i64) -> bool {
        // TODO(port mechanics)
        todo!("port src/content/thorn/lib/compost_rules.gd:has_room")
    }
    pub fn elder_bonus(combat: &mut Combat, entered: &CombatUnitRef) {
        // TODO(port mechanics)
        todo!("port src/content/thorn/lib/compost_rules.gd:elder_bonus")
    }
    pub fn briars(player: Option<&PlayerStateRef>) -> Array<UnitRef> {
        // TODO(port mechanics)
        todo!("port src/content/thorn/lib/compost_rules.gd:briars")
    }
}
