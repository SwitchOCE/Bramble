#![allow(unused_imports, unused_variables)]
//! Skeleton port of `src/core/units/unit_text.gd`; gameplay TODO bodies belong to the later port workers.
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    rc::{Rc, Weak},
};

use crate::core::mechanics::bound_mechanic::BoundMechanicRef;

use crate::core::units::unit_def::UnitDefRef;

// GDScript rule and contract comments:
// Card text for the screens. 7.3.5: card data writes its numbers as {param} placeholders
// ("Gain +{attack}/+{health}"), and the text is filled from the unit's bound parameters, which
// are already doubled on a golden (NUMBER) or kept (THRESHOLD). So one text serves both.
// The card text a unit shows: its card's golden_text on a golden copy when the card has one,
// else its text; either filled from the bound parameters.
// `text` with each {name} replaced by the first bound mechanic parameter of that name.
// [{"mechanic": id, ...parameters}] for the unit's own text, golden numbers applied.
// One number per parameter for each mechanic with numbers the unit has, across its printed text,
// what it was given and what auras grant it ({mechanic: {param: n}}), combined as the mechanic
// combines grants (Mechanic.grant_combine: Fury adds up, Root's cost takes the lowest). A screen
// shows "Fury 3" from it without knowing the mechanic.
pub type UnitTextRef = Rc<RefCell<UnitText>>;
pub struct UnitText {}
impl Default for UnitText {
    fn default() -> Self {
        Self {}
    }
}
impl ToState for UnitText {
    fn to_state(&self) -> Variant {
        Variant::dictionary(Default::default())
    }
    fn field_names() -> &'static [&'static str] {
        &[]
    }
}
impl UnitText {
    pub fn text_of(card: &UnitDefRef, mechanics: &Array<BoundMechanicRef>, golden: bool) -> String {
        let card = card.borrow();
        let raw = if golden && !card.golden_text.is_empty() {
            &card.golden_text
        } else {
            &card.text
        };
        Self::fill(raw, mechanics)
    }
    pub fn fill(text: &str, mechanics: &Array<BoundMechanicRef>) -> String {
        if !text.contains('{') {
            return text.to_string();
        }
        let mut out = text.to_string();
        for bound in mechanics.borrow().iter() {
            let values = bound.borrow().params.borrow().to_dict();
            for (key, value) in values.borrow().iter() {
                out = out.replace(&format!("{{{key}}}"), &value.as_text());
            }
        }
        out
    }
    pub fn effects_view(mechanics: &Array<BoundMechanicRef>) -> Array<Variant> {
        let out = Array::new();
        for bound in mechanics.borrow().iter() {
            let bound = bound.borrow();
            let values = bound.params.borrow().to_dict();
            if values.is_empty() {
                continue;
            }
            let entry = Dictionary::new();
            entry.insert("mechanic", Variant::String(bound.id.clone()));
            for (key, value) in values.borrow().iter() {
                entry.insert(key.clone(), value.clone());
            }
            out.push(Variant::Dictionary(entry));
        }
        out
    }
    pub fn totals_view(hooks: &Array<BoundMechanicRef>) -> Dictionary {
        let out = Dictionary::new();
        for bound in hooks.borrow().iter() {
            let bound = bound.borrow();
            let values = bound.params.borrow().to_dict();
            let entry = out.get(&bound.id).as_dict();
            for (key, value) in values.borrow().iter() {
                let Variant::Int(now) = value else {
                    continue;
                };
                let combined = if entry.has(key) {
                    let how = bound
                        .mechanic
                        .as_ref()
                        .expect("bound mechanic")
                        .grant_combine(key);
                    crate::core::mechanics::mechanic::combine(how, entry.get(key).as_i64(), *now)
                } else {
                    *now
                };
                entry.insert(key.clone(), Variant::Int(combined));
            }
            if !entry.is_empty() {
                out.insert(bound.id.clone(), Variant::Dictionary(entry));
            }
        }
        out
    }
    pub fn counters_view(counters: &Dictionary) -> Dictionary {
        counters.duplicate()
    }
    pub fn new() -> Self {
        Self::default()
    }
}
