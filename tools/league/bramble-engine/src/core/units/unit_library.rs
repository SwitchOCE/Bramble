//! Mirrors src/core/units/unit_library.gd. Card numbers are read from repository data.
use super::unit_def::{Kind, UnitDef, UnitDefRef};
use crate::core::{
    mechanics::{
        mechanic_params::MechanicParams, mechanic_registry::MechanicRegistryRef,
        mechanic_spec::MechanicSpec,
    },
    util::core_util::CoreUtil,
};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, path::Path, rc::Rc};
pub type UnitLibraryRef = Rc<RefCell<UnitLibrary>>;
#[derive(Default)]
pub struct UnitLibrary {
    pub errors: Array<String>,
    pub _cards: Dictionary<UnitDefRef>,
    pub _order: Array<String>,
}
impl UnitLibrary {
    pub const TRIPLE_REWARD_ID: &str = "triple_reward";
    /// SYSTEM_CARDS in unit_library.gd, as JSON text. The ghost cutter fingerprints these entries.
    pub const SYSTEM_CARDS: &str = r#"[{"id":"triple_reward","name":"Triple Reward","kind":"spell","tier":1,"cost":0,"offered":false,"effects":[{"mechanic":"triple_reward"}]}]"#;
    pub fn with_system_cards(registry: &MechanicRegistryRef) -> UnitLibraryRef {
        let out = Rc::new(RefCell::new(Self::default()));
        // 7.3.6: the core's own spell is the only card definition embedded in the source.
        let cards = crate::util::godot_json::parse_string(Self::SYSTEM_CARDS).as_array();
        out.borrow_mut().add_cards(&cards, registry);
        out
    }
    pub fn from_file(
        repo_root: &Path,
        path: &str,
        registry: &MechanicRegistryRef,
    ) -> UnitLibraryRef {
        let out = Self::with_system_cards(registry);
        let actual = crate::core::content::content_set::resolve(repo_root, path);
        if !actual.is_file() {
            out.borrow().errors.push(format!("no card file at {path}"));
            return out;
        }
        let root = crate::util::godot_json::parse_string(
            &std::fs::read_to_string(actual).unwrap_or_default(),
        )
        .as_dict();
        if root.is_empty() {
            out.borrow()
                .errors
                .push(format!("{path} is not a JSON object"));
            return out;
        }
        out.borrow_mut()
            .add_cards(&root.get("cards").as_array(), registry);
        out
    }
    pub fn add_cards(&mut self, raw_cards: &Array<Variant>, registry: &MechanicRegistryRef) {
        for raw in raw_cards.borrow().iter() {
            let Some(card) = self._parse(&raw.as_dict(), registry) else {
                continue;
            };
            let id = card.borrow().id.clone();
            if self._cards.borrow().contains_key(&id) {
                self.errors.push(format!("duplicate card id {id}"));
                continue;
            }
            self._cards.borrow_mut().insert(id.clone(), card);
            self._order.push(id);
        }
    }
    pub fn _parse(
        &mut self,
        raw: &Dictionary,
        registry: &MechanicRegistryRef,
    ) -> Option<UnitDefRef> {
        let card = Rc::new(RefCell::new(UnitDef::default()));
        {
            let mut c = card.borrow_mut();
            c.id = CoreUtil::to_text(&raw.get_or("id", "".into()));
            if c.id.is_empty() {
                self.errors.push("a card has no id".into());
                return None;
            }
            c.name = CoreUtil::to_text(&raw.get_or("name", c.id.clone().into()));
            c.kind = if raw.get_or("kind", "unit".into()) == Variant::from("spell") {
                Kind::Spell
            } else {
                Kind::Unit
            };
            c.tier = CoreUtil::to_int(&raw.get_or("tier", 1.into()));
            c.attack = CoreUtil::to_int(&raw.get_or("attack", 0.into()));
            c.health = CoreUtil::to_int(&raw.get_or("health", 1.into()));
            c.token = CoreUtil::to_bool(&raw.get_or("token", false.into()));
            c.combines = CoreUtil::to_bool(&raw.get_or("combines", true.into()));
            c.cost = CoreUtil::to_int(&raw.get_or("cost", 0.into()));
            c.offered = CoreUtil::to_bool(&raw.get_or("offered", true.into()));
            c.text = CoreUtil::to_text(&raw.get_or("text", "".into()));
            c.golden_text = CoreUtil::to_text(&raw.get_or("golden_text", "".into()));
            for line in raw.get("reminders").as_array().borrow().iter() {
                c.reminders.push(line.as_text());
            }
            for name in raw.get("types").as_array().borrow().iter() {
                c.types.push(name.as_text());
            }
            for tribe in raw.get("tribes").as_array().borrow().iter() {
                c.tribes.push(tribe.as_text());
            }
        }
        let mut ok = {
            let c = card.borrow();
            (1..=7).contains(&c.tier) && (c.health >= 1 || c.is_spell())
        };
        if !ok {
            self.errors.push(format!(
                "{}: tier must be 1-7 and Health at least 1",
                card.borrow().id
            ));
        }
        for keyword in raw.get("keywords").as_array().borrow().iter() {
            let params = CoreUtil::to_dict(keyword).duplicate();
            let id = params.get_or("mechanic", keyword.clone()).as_text();
            params.erase("mechanic");
            card.borrow().keywords.push(id.clone());
            ok = self._add_mechanic(&card, &id, &params, registry) && ok;
        }
        for effect in raw.get("effects").as_array().borrow().iter() {
            let params = effect.as_dict().duplicate();
            let id = CoreUtil::to_text(&params.get_or("mechanic", "".into()));
            params.erase("mechanic");
            ok = self._add_mechanic(&card, &id, &params, registry) && ok;
        }
        ok.then_some(card)
    }
    pub fn _add_mechanic(
        &mut self,
        card: &UnitDefRef,
        mechanic_id: &str,
        raw: &Dictionary,
        registry: &MechanicRegistryRef,
    ) -> bool {
        let where_ = format!("{}/{mechanic_id}", card.borrow().id);
        if !registry.borrow().has(mechanic_id) {
            self.errors.push(format!("{where_}: no such mechanic"));
            return false;
        }
        let kinds = registry.borrow().kinds_of(mechanic_id);
        let Some(params) = MechanicParams::parse(raw, &kinds, &where_, &self.errors) else {
            return false;
        };
        card.borrow()
            .mechanics
            .push(MechanicSpec::new(mechanic_id, Some(params)));
        true
    }
    pub fn has(&self, card_id: &str) -> bool {
        self._cards.borrow().contains_key(card_id)
    }
    pub fn get_card(&self, card_id: &str) -> Option<UnitDefRef> {
        self._cards.borrow().get(card_id).cloned()
    }
    pub fn ids(&self) -> Array<String> {
        self._order.duplicate()
    }
    // The drawable cards of one kind, in library order.
    pub fn drawable_cards(&self, spells: bool) -> Array<UnitDefRef> {
        self._order
            .borrow()
            .iter()
            .filter_map(|id| self.get_card(id))
            .filter(|c| {
                let c = c.borrow();
                c.can_be_drawn() && c.is_spell() == spells
            })
            .collect()
    }
}
impl ToState for UnitLibrary {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"errors"=>&self.errors,"_cards"=>&self._cards,"_order"=>&self._order}
    }
    fn field_names() -> &'static [&'static str] {
        &["errors", "_cards", "_order"]
    }
}
