//! Typed mechanic parameters. NUMBER doubles when golden; THRESHOLD never does (7.3.5).
use crate::core::util::core_util::CoreUtil;
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, rc::Rc};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(i64)]
pub enum Kind {
    Number = 0,
    Threshold = 1,
    Text = 2,
}
impl Kind {
    pub const NUMBER: Self = Self::Number;
    pub const THRESHOLD: Self = Self::Threshold;
    pub const TEXT: Self = Self::Text;
}
impl ToState for Kind {
    fn to_state(&self) -> Variant {
        Variant::Int(*self as i64)
    }
}

#[derive(Clone, Debug, Default)]
pub struct MechanicParams {
    pub golden: bool,
    pub _ints: Dictionary<i64>,
    pub _texts: Dictionary<String>,
    pub _kinds: Dictionary<i64>,
    pub _golden_ints: Dictionary<i64>,
}
pub type MechanicParamsRef = Rc<RefCell<MechanicParams>>;
impl MechanicParams {
    pub fn new() -> MechanicParamsRef {
        Rc::new(RefCell::new(Self::default()))
    }
    pub fn parse(
        raw: &Dictionary,
        kinds: &Dictionary,
        where_: &str,
        errors: &Array<String>,
    ) -> Option<MechanicParamsRef> {
        let params = Self::new();
        let mut ok = true;
        let raw = if raw.has("golden") {
            let raw = raw.duplicate();
            let overrides = CoreUtil::to_dict(&raw.get("golden"));
            raw.erase("golden");
            for (key, value) in overrides.borrow().iter() {
                let known = kinds.has(key);
                if !known || CoreUtil::to_int(&kinds.get(key)) != Kind::Number as i64 {
                    errors.push(format!(
                        "{where_}: golden '{key}' is not a NUMBER parameter"
                    ));
                    ok = false;
                } else if !matches!(value, Variant::Int(_) | Variant::Float(_)) {
                    errors.push(format!("{where_}: golden '{key}' must be a number"));
                    ok = false;
                } else {
                    params
                        .borrow()
                        ._golden_ints
                        .borrow_mut()
                        .insert(key.clone(), CoreUtil::to_int(value));
                }
            }
            raw
        } else {
            raw.clone()
        };
        for key in raw.borrow().keys() {
            if !kinds.has(key) {
                errors.push(format!("{where_}: unknown parameter '{key}'"));
                ok = false;
            }
        }
        for (key, kind) in kinds.borrow().iter() {
            let kind = CoreUtil::to_int(kind);
            params
                .borrow()
                ._kinds
                .borrow_mut()
                .insert(key.clone(), kind);
            if !raw.has(key) {
                errors.push(format!("{where_}: missing parameter '{key}'"));
                ok = false;
                continue;
            }
            let value = raw.get(key);
            if kind == Kind::Text as i64 {
                if !matches!(value, Variant::String(_)) {
                    errors.push(format!("{where_}: '{key}' must be text"));
                    ok = false;
                }
                params
                    .borrow()
                    ._texts
                    .borrow_mut()
                    .insert(key.clone(), CoreUtil::to_text(&value));
            } else {
                if !matches!(value, Variant::Int(_) | Variant::Float(_)) {
                    errors.push(format!("{where_}: '{key}' must be a number"));
                    ok = false;
                }
                params
                    .borrow()
                    ._ints
                    .borrow_mut()
                    .insert(key.clone(), CoreUtil::to_int(&value));
            }
        }
        if ok { Some(params) } else { None }
    }
    /// The same dictionary objects are intentionally shared, as in GDScript's assignment (7.3.5).
    pub fn with_golden(&self, is_golden: bool) -> MechanicParamsRef {
        Rc::new(RefCell::new(Self {
            golden: is_golden,
            _ints: self._ints.clone(),
            _texts: self._texts.clone(),
            _kinds: self._kinds.clone(),
            _golden_ints: self._golden_ints.clone(),
        }))
    }
    pub fn num(&self, param: &str) -> i64 {
        let value = self._ints.borrow().get(param).copied().unwrap_or(0);
        if self.golden
            && self._kinds.borrow().get(param).copied().unwrap_or(-1) == Kind::Number as i64
        {
            if let Some(value) = self._golden_ints.borrow().get(param) {
                return *value;
            }
            return value.wrapping_mul(2);
        }
        value
    }
    pub fn text(&self, param: &str) -> String {
        self._texts.borrow().get(param).cloned().unwrap_or_default()
    }
    pub fn to_dict(&self) -> Dictionary {
        let out = Dictionary::new();
        for key in self._ints.borrow().keys() {
            out.insert(key, Variant::Int(self.num(key)));
        }
        for (key, value) in self._texts.borrow().iter() {
            out.insert(key, Variant::String(value.clone()));
        }
        out
    }
}
impl ToState for MechanicParams {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"golden"=>&self.golden,"_ints"=>&self._ints,"_texts"=>&self._texts,"_kinds"=>&self._kinds,"_golden_ints"=>&self._golden_ints}
    }
    fn field_names() -> &'static [&'static str] {
        &["golden", "_ints", "_texts", "_kinds", "_golden_ints"]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn golden_numbers_override_and_thresholds_preserve_aliases() {
        let kinds = Dictionary::new();
        kinds.insert("amount", Variant::Int(Kind::Number as i64));
        kinds.insert("every", Variant::Int(Kind::Threshold as i64));
        kinds.insert("card", Variant::Int(Kind::Text as i64));
        let raw = Dictionary::new();
        raw.insert("amount", Variant::Float(4.0));
        raw.insert("every", Variant::Float(3.0));
        raw.insert("card", Variant::from("hopper"));
        let golden = Dictionary::new();
        golden.insert("amount", Variant::Float(6.0));
        raw.insert("golden", Variant::Dictionary(golden));
        let errors = Array::new();
        let plain = MechanicParams::parse(&raw, &kinds, "fixture", &errors).unwrap();
        let golden = plain.borrow().with_golden(true);
        assert!(errors.is_empty());
        assert_eq!(plain.borrow().num("amount"), 4);
        assert_eq!(golden.borrow().num("amount"), 6);
        assert_eq!(golden.borrow().num("every"), 3);
        assert_eq!(golden.borrow().text("card"), "hopper");
        plain.borrow()._ints.borrow_mut().insert("every".into(), 9);
        assert_eq!(
            golden.borrow().num("every"),
            9,
            "with_golden aliases the original dictionaries"
        );
        assert_eq!(
            CoreUtil::to_int(&golden.borrow().to_dict().get("amount")),
            6
        );
    }
    #[test]
    fn parse_reports_all_errors_in_source_order() {
        let kinds = Dictionary::new();
        kinds.insert("amount", Variant::Int(0));
        kinds.insert("every", Variant::Int(1));
        let raw = Dictionary::new();
        raw.insert("extra", Variant::Bool(true));
        raw.insert("amount", Variant::from("bad"));
        let overrides = Dictionary::new();
        overrides.insert("every", Variant::Int(7));
        raw.insert("golden", Variant::Dictionary(overrides));
        let errors = Array::new();
        assert!(MechanicParams::parse(&raw, &kinds, "fixture", &errors).is_none());
        assert_eq!(
            errors.to_vec(),
            vec![
                "fixture: golden 'every' is not a NUMBER parameter",
                "fixture: unknown parameter 'extra'",
                "fixture: 'amount' must be a number",
                "fixture: missing parameter 'every'"
            ]
        );
    }
}
