//! Typed conversions from `src/core/util/core_util.gd`.
use crate::{Array, Dictionary, ToState, Variant};

pub struct CoreUtil;

impl CoreUtil {
    pub fn to_int(value: &Variant) -> i64 {
        match value {
            Variant::Int(whole) => *whole,
            Variant::Float(number) => number.round() as i64,
            Variant::Bool(flag) => i64::from(*flag),
            _ => 0,
        }
    }

    pub fn to_bool(value: &Variant) -> bool {
        match value {
            Variant::Bool(flag) => *flag,
            _ => Self::to_int(value) != 0,
        }
    }

    pub fn to_text(value: &Variant) -> String {
        match value {
            Variant::String(text) => text.clone(),
            _ => String::new(),
        }
    }

    pub fn to_array(value: &Variant) -> Array<Variant> {
        match value { Variant::Array(list) => list.clone(), _ => Array::new() }
    }

    pub fn to_dict(value: &Variant) -> Dictionary {
        match value { Variant::Dictionary(map) => map.clone(), _ => Dictionary::new() }
    }

    /// Integer division rounded up, for positive divisors.
    pub fn ceil_div(numerator: i64, divisor: i64) -> i64 {
        numerator.wrapping_add(divisor).wrapping_sub(1) / divisor
    }
}

impl ToState for CoreUtil {
    fn to_state(&self) -> Variant { crate::state_dict! {} }
    fn field_names() -> &'static [&'static str] { &[] }
}
