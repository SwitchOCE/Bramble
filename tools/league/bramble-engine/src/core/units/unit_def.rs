//! Mirrors src/core/units/unit_def.gd.
use crate::core::mechanics::mechanic_spec::MechanicSpecRef;
use crate::{Array, ToState, Variant};
use std::{cell::RefCell, rc::Rc};
pub type UnitDefRef = Rc<RefCell<UnitDef>>;
#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
#[repr(i64)]
pub enum Kind {
    #[default]
    Unit = 0,
    Spell = 1,
}
impl Kind {
    pub const UNIT: Self = Self::Unit;
    pub const SPELL: Self = Self::Spell;
}
impl ToState for Kind {
    fn to_state(&self) -> Variant {
        Variant::Int(*self as i64)
    }
}
pub struct UnitDef {
    pub id: String,
    pub name: String,
    pub kind: Kind,
    pub tier: i64,
    pub attack: i64,
    pub health: i64,
    pub types: Array<String>,
    pub tribes: Array<String>,
    pub keywords: Array<String>,
    pub mechanics: Array<MechanicSpecRef>,
    pub token: bool,
    pub combines: bool,
    pub cost: i64,
    pub offered: bool,
    pub text: String,
    pub golden_text: String,
    pub reminders: Array<String>,
}
impl Default for UnitDef {
    fn default() -> Self {
        Self {
            id: String::new(),
            name: String::new(),
            kind: Kind::Unit,
            tier: 1,
            attack: 0,
            health: 1,
            types: Array::new(),
            tribes: Array::new(),
            keywords: Array::new(),
            mechanics: Array::new(),
            token: false,
            combines: true,
            cost: 0,
            offered: true,
            text: String::new(),
            golden_text: String::new(),
            reminders: Array::new(),
        }
    }
}
impl UnitDef {
    pub fn is_spell(&self) -> bool {
        self.kind == Kind::Spell
    }
    pub fn in_pool(&self) -> bool {
        !self.token && self.offered
    }
    pub fn has_tribe(&self, tribe: &str) -> bool {
        self.tribes
            .borrow()
            .iter()
            .any(|t| t == tribe || t == "All")
    }
    pub fn fields(&self) -> Variant {
        crate::state_dict! {"id"=>&self.id,"name"=>&self.name,"kind"=>&self.kind,"tier"=>&self.tier,"attack"=>&self.attack,"health"=>&self.health,"types"=>&self.types,"tribes"=>&self.tribes,"keywords"=>&self.keywords,"mechanics"=>&self.mechanics,"token"=>&self.token,"combines"=>&self.combines,"cost"=>&self.cost,"offered"=>&self.offered,"text"=>&self.text,"golden_text"=>&self.golden_text,"reminders"=>&self.reminders}
    }
}
impl ToState for UnitDef {
    fn to_state(&self) -> Variant {
        self.id.to_state()
    }
    fn script_state(&self) -> Variant {
        self.fields()
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "id",
            "name",
            "kind",
            "tier",
            "attack",
            "health",
            "types",
            "tribes",
            "keywords",
            "mechanics",
            "token",
            "combines",
            "cost",
            "offered",
            "text",
            "golden_text",
            "reminders",
        ]
    }
}
