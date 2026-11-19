pub mod aura_context;
pub mod card_heap;
pub mod fight_report;
pub mod slot_state;

#[cfg(test)]
mod tests {
    use crate::{ToState, Variant};
    use std::collections::BTreeSet;
    fn check<T: ToState + Default>() {
        let Variant::Dictionary(state) = T::default().to_state() else {
            panic!("state must be an object")
        };
        let actual: BTreeSet<String> = state.borrow().keys().cloned().collect();
        let expected: BTreeSet<String> = T::field_names()
            .iter()
            .map(|field| field.to_string())
            .collect();
        assert_eq!(actual, expected);
    }
    #[test]
    fn all_owned_state_fields_are_serialized() {
        check::<crate::core::combat::combat::Combat>();
        check::<crate::core::combat::combat_unit::CombatUnit>();
        check::<crate::core::combat::fight_arrivals::FightArrivals>();
        check::<crate::core::combat::fight_auras::FightAuras>();
        check::<crate::core::combat::fight_deaths::FightDeaths>();
        check::<crate::core::combat::fight_side::FightSide>();
        check::<crate::core::board::board_geometry::BoardGeometry>();
        check::<crate::core::board::selectors::Selectors>();
        check::<super::aura_context::AuraContext>();
        check::<super::card_heap::CardHeap>();
        check::<super::fight_report::FightReport>();
        check::<super::slot_state::SlotState>();
        check::<crate::core::units::unit::Unit>();
        check::<crate::core::units::stat_block::StatBlock>();
        check::<crate::core::units::unit_text::UnitText>();
    }
    #[test]
    fn combat_constructor_helpers_point_to_the_same_owner() {
        let combat = crate::core::combat::combat::Combat::new();
        let arrivals = combat.borrow().arrivals.as_ref().unwrap().clone();
        let owner = arrivals.borrow()._combat().unwrap();
        assert!(std::rc::Rc::ptr_eq(&combat, &owner));
        assert!(!combat.borrow().to_state().as_dict().is_empty());
    }
}
