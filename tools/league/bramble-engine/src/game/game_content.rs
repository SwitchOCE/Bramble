#![allow(unused_variables)]
//! Rules-affecting portions of src/game/game_content.gd; presentation helpers are explicit TODOs.
use crate::core::{
    content::content_set::{ContentSet, resolve},
    ghosts::ghost_run::RunsBySeat,
    mechanics::mechanic_registry::MechanicRegistryRef,
    session::game_session::{GameSession, GameSessionRef},
    units::unit_library::UnitLibraryRef,
};
use crate::{Array, Dictionary, ToState, Variant};
use std::{cell::RefCell, path::Path, rc::Rc};
pub type GameContentRef = Rc<RefCell<GameContent>>;
pub struct GameContent {
    pub record_paths: Array<String>,
    pub registry: MechanicRegistryRef,
    pub library: UnitLibraryRef,
    pub tribes: Array<Dictionary>,
    pub standing: Array<String>,
    pub display: Dictionary,
    pub errors: Array<String>,
    pub stand_ins: bool,
    pub _art: Dictionary,
    pub _standing_tribe: Dictionary,
    pub _folder_of: Dictionary,
    pub _card_reminders: Dictionary,
}
impl GameContent {
    pub const STAND_IN_PATH: &str = "res://src/game/data/stand_in_units.json";
    pub fn load_default(repo_root: &Path) -> GameContentRef {
        let paths = ContentSet::folders_in(&repo_root.join("src/content"), &Array::new());
        Self::load_folders(repo_root, &paths)
    }
    pub fn load_folders(repo_root: &Path, paths: &Array<String>) -> GameContentRef {
        let loaded = ContentSet::load_folders(repo_root, paths);
        let l = loaded.borrow();
        let mut c = Self {
            record_paths: paths.duplicate(),
            registry: l.registry.clone(),
            library: l.library.clone(),
            tribes: Array::new(),
            standing: l.standing.duplicate(),
            display: l.display.duplicate(),
            errors: l.errors.duplicate(),
            stand_ins: false,
            _art: Dictionary::new(),
            _standing_tribe: Dictionary::new(),
            _folder_of: Dictionary::new(),
            _card_reminders: Dictionary::new(),
        };
        drop(l);
        for path in paths.borrow().iter() {
            c._read_folder(repo_root, path);
        }
        let stand_in = Self::_json(repo_root, Self::STAND_IN_PATH)
            .get("cards")
            .as_array();
        let wanted = Array::new();
        c.stand_ins = c.tribes.is_empty();
        let tribe_spells = !c.library.borrow().drawable_cards(true).is_empty();
        for raw in stand_in.borrow().iter() {
            let card = raw.as_dict();
            let spell = card.get_or("kind", "unit".into()).as_text() == "spell";
            if c.stand_ins || (spell && !tribe_spells) {
                wanted.push(Variant::Dictionary(card.clone()));
                c._art.insert(
                    card.get_or("id", "".into()).as_text(),
                    card.get_or("art", "".into()),
                );
            }
        }
        let before = c.library.borrow().errors.len();
        c.library.borrow_mut().add_cards(&wanted, &c.registry);
        c.errors
            .borrow_mut()
            .extend(c.library.borrow().errors.borrow()[before..].iter().cloned());
        Rc::new(RefCell::new(c))
    }
    /// Starts an async lobby with a live seat 0 and validated runs in seats 1–7.
    pub fn new_async_session(
        &self,
        seed: i64,
        runs_by_seat: RunsBySeat,
        lobby_tribes: &Array<String>,
    ) -> Result<GameSessionRef, &'static str> {
        if runs_by_seat.len() != 7 {
            return Err("async games need seven run seats");
        }
        let game = self.new_session(seed, lobby_tribes);
        game.borrow_mut().set_runs(runs_by_seat)?;
        Ok(game)
    }

    pub fn new_session(&self, game_seed: i64, lobby_tribes: &Array<String>) -> GameSessionRef {
        let made =
            GameSession::create(game_seed, &self.library, &self.registry, None, lobby_tribes);
        {
            let mut game = made.borrow_mut();
            game.record_recipe=crate::state_dict!{"kind"=>"game","paths"=>&self.record_paths,"tribes"=>lobby_tribes}.as_dict();
            game.display = self.display.clone();
            for id in self.standing_for(lobby_tribes).borrow().iter() {
                game.give_standing(id);
            }
        }
        made
    }
    pub fn standing_for(&self, lobby_tribes: &Array<String>) -> Array<String> {
        let out = Array::new();
        for id in self.standing.borrow().iter() {
            let tribe = self._standing_tribe.get_or(id, "".into()).as_text();
            if lobby_tribes.is_empty() || tribe.is_empty() || lobby_tribes.borrow().contains(&tribe)
            {
                out.push(id.clone());
            }
        }
        out
    }
    pub fn tribe_ids(&self) -> Array<String> {
        self.tribes
            .borrow()
            .iter()
            .map(|t| t.get("folder").as_text())
            .collect()
    }
    pub fn tribe_name(&self, tribe_id: &str) -> String {
        self.tribes
            .borrow()
            .iter()
            .find(|t| t.get("folder").as_text() == tribe_id)
            .map(|t| t.get("name").as_text())
            .unwrap_or_default()
    }
    pub fn lobby_names(&self, ids: &Array<String>) -> Array<String> {
        ids.borrow()
            .iter()
            .map(|id| self.tribe_name(id))
            .filter(|s| !s.is_empty())
            .collect()
    }
    pub fn text_for(&self, card_id: &str) -> String {
        if card_id == "triple_reward" {
            "Discover a unit from the tier above yours.".into()
        } else {
            String::new()
        }
    }
    pub fn mechanics_of(&self, card_id: &str) -> Array<Variant> {
        let out = Array::new();
        let Some(c) = self.library.borrow().get_card(card_id) else {
            return out;
        };
        for id in c.borrow().keywords.borrow().iter() {
            let v = Variant::from(id.clone());
            if !out.borrow().contains(&v) {
                out.push(v);
            }
        }
        for spec in c.borrow().mechanics.borrow().iter() {
            let v = Variant::from(spec.borrow().id.clone());
            if !out.borrow().contains(&v) {
                out.push(v);
            }
        }
        out
    }
    pub fn reminders_for(&self, card_id: &str, text: &str) -> Array<Variant> {
        todo!("port src/game/game_content.gd:reminders_for")
    }
    pub fn _token_ids(&self) -> Array<String> {
        self.library
            .borrow()
            .ids()
            .borrow()
            .iter()
            .filter(|id| {
                self.library
                    .borrow()
                    .get_card(id)
                    .is_some_and(|c| c.borrow().token)
            })
            .cloned()
            .collect()
    }
    pub fn _names(text: &str, card_name: &str) -> bool {
        todo!("port src/game/game_content.gd:_names")
    }
    pub fn folder_of(&self, card_id: &str) -> String {
        self._folder_of.get_or(card_id, "".into()).as_text()
    }
    pub fn art_for(&self, card_id: &str) -> String {
        todo!("port src/game/game_content.gd:art_for")
    }
    pub fn display_name(&self, key: &str) -> String {
        todo!("port src/game/game_content.gd:display_name")
    }
    pub fn reminder(&self, key: &str) -> String {
        self.display
            .get(key)
            .as_dict()
            .get_or("reminder", "".into())
            .as_text()
    }
    pub fn icon(&self, key: &str) -> String {
        self.display
            .get(key)
            .as_dict()
            .get_or("icon", "".into())
            .as_text()
    }
    pub fn display_table(&self) -> Dictionary {
        todo!("port src/game/game_content.gd:display_table")
    }
    pub fn _read_folder(&mut self, repo_root: &Path, path: &str) {
        let manifest = Self::_json(repo_root, &format!("{path}/tribe.json"));
        let folder = Path::new(path)
            .file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .into_owned();
        let counts: Dictionary<i64> = Dictionary::new();
        for raw in Self::_json(repo_root, &format!("{path}/units.json"))
            .get("cards")
            .as_array()
            .borrow()
            .iter()
        {
            let card = raw.as_dict();
            let id = card.get_or("id", "".into()).as_text();
            self._folder_of.insert(id.clone(), folder.clone().into());
            let lines = card.get("reminders").as_array();
            if !lines.is_empty() {
                self._card_reminders.insert(id, Variant::Array(lines));
            }
            for tribe in card.get("tribes").as_array().borrow().iter() {
                let name = tribe.as_text();
                let n = counts.borrow().get(&name).copied().unwrap_or(0) + 1;
                counts.borrow_mut().insert(name, n);
            }
        }
        if manifest.get_or("prefix", "".into()).as_text().is_empty() {
            return;
        }
        let mut named = String::new();
        for (name, count) in counts.borrow().iter() {
            if named.is_empty() || *count > *counts.borrow().get(&named).unwrap_or(&0) {
                named = name.clone();
            }
        }
        if named.is_empty() {
            named = folder
                .split('_')
                .map(|s| {
                    let mut ch = s.chars();
                    ch.next().map_or(String::new(), |c| {
                        c.to_uppercase().to_string() + ch.as_str()
                    })
                })
                .collect::<Vec<_>>()
                .join(" ");
        }
        self.tribes
            .push(crate::state_dict! {"folder"=>&folder,"name"=>&named}.as_dict());
        for standing in manifest.get("standing").as_array().borrow().iter() {
            self._standing_tribe
                .insert(standing.as_text(), named.clone().into());
        }
    }
    pub fn _json(repo_root: &Path, file: &str) -> Dictionary {
        crate::util::godot_json::parse_string(
            &std::fs::read_to_string(resolve(repo_root, file)).unwrap_or_default(),
        )
        .as_dict()
    }
}
impl ToState for GameContent {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"record_paths"=>&self.record_paths,"registry"=>&self.registry,"library"=>&self.library,"tribes"=>&self.tribes,"standing"=>&self.standing,"display"=>&self.display,"errors"=>&self.errors,"stand_ins"=>&self.stand_ins,"_art"=>&self._art,"_standing_tribe"=>&self._standing_tribe,"_folder_of"=>&self._folder_of,"_card_reminders"=>&self._card_reminders}
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "record_paths",
            "registry",
            "library",
            "tribes",
            "standing",
            "display",
            "errors",
            "stand_ins",
            "_art",
            "_standing_tribe",
            "_folder_of",
            "_card_reminders",
        ]
    }
}
