//! Mirrors src/core/content/content_set.gd. Paths retain their Godot spelling in diagnostics.
use crate::core::{
    mechanics::mechanic_registry::{MechanicRegistry, MechanicRegistryRef, content_mechanic},
    rules::game_config::GameConfigRef,
    session::game_session::{GameSession, GameSessionRef},
    units::unit_library::{UnitLibrary, UnitLibraryRef},
    util::core_util::CoreUtil,
};
use crate::{Array, Dictionary, ToState, Variant};
use std::{
    cell::RefCell,
    path::{Path, PathBuf},
    rc::Rc,
};
pub type ContentSetRef = Rc<RefCell<ContentSet>>;
pub struct ContentSet {
    pub record_paths: Array<String>,
    pub registry: MechanicRegistryRef,
    pub library: UnitLibraryRef,
    pub display: Dictionary,
    pub standing: Array<String>,
    pub folders: Array<String>,
    pub errors: Array<String>,
}
/// Resolve res:// without making it an implicit dependency on the working directory.
pub fn resolve(root: &Path, path: &str) -> PathBuf {
    path.strip_prefix("res://")
        .map_or_else(|| PathBuf::from(path), |p| root.join(p))
}
impl ContentSet {
    pub const ROOT: &str = "res://src/content";
    pub const SHARED: &str = "shared";
    pub fn folders_in(root: &Path, only: &Array<String>) -> Array<String> {
        let mut out = Vec::new();
        if let Ok(entries) = std::fs::read_dir(root) {
            for e in entries.flatten() {
                let path = e.path();
                if !path.join("tribe.json").is_file() {
                    continue;
                }
                let name = e.file_name().to_string_lossy().into_owned();
                if only.is_empty() || only.borrow().contains(&name) || name == "shared" {
                    out.push(path.to_string_lossy().into_owned());
                }
            }
        }
        crate::util::godot_sort::sort_by(&mut out, |a, b| a < b);
        out.into()
    }
    pub fn load_folders(repo_root: &Path, paths: &Array<String>) -> ContentSetRef {
        let registry = MechanicRegistry::with_built_ins();
        let library = UnitLibrary::with_system_cards(&registry);
        let core_display=crate::util::godot_json::parse_string(r#"{"slot_buff":{"name":"Slot buff","reminder":"Stays on the slot. Any unit standing there has it.","icon":"slot_buff","hidden":false}}"#).as_dict();
        let mut made = Self {
            record_paths: paths.duplicate(),
            registry,
            library,
            display: core_display,
            standing: Array::new(),
            folders: Array::new(),
            errors: Array::new(),
        };
        for path in paths.borrow().iter() {
            made._load_mechanics(repo_root, path);
        }
        for id in made.standing.borrow().iter() {
            if !made.registry.borrow().has(id) {
                made.errors
                    .push(format!("standing mechanic {id} is not registered"));
            }
        }
        for path in paths.borrow().iter() {
            made._load_cards(repo_root, path);
        }
        made.errors
            .borrow_mut()
            .extend(made.registry.borrow().errors.borrow().iter().cloned());
        made.errors
            .borrow_mut()
            .extend(made.library.borrow().errors.borrow().iter().cloned());
        Rc::new(RefCell::new(made))
    }
    pub fn session(
        &self,
        game_seed: i64,
        config: Option<GameConfigRef>,
        lobby_tribes: &Array<String>,
    ) -> GameSessionRef {
        let made = GameSession::create(
            game_seed,
            &self.library,
            &self.registry,
            config,
            lobby_tribes,
        );
        {
            let mut s = made.borrow_mut();
            s.record_recipe=crate::state_dict!{"kind"=>"core","paths"=>&self.record_paths,"tribes"=>lobby_tribes}.as_dict();
            s.display = self.display.clone();
            for id in self.standing.borrow().iter() {
                s.give_standing(id);
            }
        }
        made
    }
    pub fn _load_mechanics(&mut self, repo_root: &Path, path: &str) {
        let manifest = self._json(repo_root, &format!("{path}/tribe.json"));
        let prefix = CoreUtil::to_text(&manifest.get_or("prefix", "".into()));
        let folder = Path::new(path)
            .file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .into_owned();
        self.folders.push(folder.clone());
        if prefix.is_empty() && folder != Self::SHARED {
            self.errors.push(format!(
                "{path}: tribe.json has no prefix (only the shared folder may have none)"
            ));
        } else if !prefix.is_empty() && self.registry.borrow().prefixes.borrow().contains(&prefix) {
            self.errors.push(format!(
                "{path}: the prefix {prefix} is already used by another folder"
            ));
        } else if !prefix.is_empty() {
            self.registry.borrow().prefixes.push(prefix.clone());
        }
        let own = Array::new();
        let mut files = Vec::new();
        if let Ok(dir) = std::fs::read_dir(resolve(repo_root, &format!("{path}/mechanics"))) {
            for file in dir.flatten() {
                if file.path().is_file() {
                    files.push(file.file_name().to_string_lossy().into_owned());
                }
            }
        }
        crate::util::godot_sort::sort_by(&mut files, |a, b| a < b);
        for file in files {
            let script_file = file.trim_end_matches(".remap");
            if !script_file.ends_with(".gd") {
                continue;
            }
            let stem = script_file.trim_end_matches(".gd");
            let id = format!("{prefix}{stem}");
            let Some(mechanic) = content_mechanic(&folder, stem) else {
                self.errors.push(format!("{path}: mechanics/{script_file} does not extend Mechanic; put helper code in lib/"));
                continue;
            };
            if self.registry.borrow_mut().register(&id, mechanic) && !prefix.is_empty() {
                own.push(id);
            }
        }
        for v in manifest.get("standing").as_array().borrow().iter() {
            self.standing.push(v.as_text());
        }
        let table = if Self::_has(repo_root, path, "display.json") {
            self._json(repo_root, &format!("{path}/display.json"))
        } else {
            Dictionary::new()
        };
        for (key, value) in table.borrow().iter() {
            if self.display.has(key) {
                self.errors
                    .push(format!("{path}: display id {key} is already used"));
            }
            if !key.starts_with(&prefix) {
                self.errors.push(format!(
                    "{path}: display id {key} lacks the prefix {prefix}"
                ));
            }
            self.display.insert(key.clone(), value.clone());
        }
        for name in own.borrow().iter() {
            if !self.display.has(name) {
                self.errors
                    .push(format!("{path}: mechanic {name} has no display entry"));
            }
        }
    }
    pub fn _load_cards(&mut self, repo_root: &Path, path: &str) {
        if Self::_has(repo_root, path, "units.json") {
            let cards = self._json(repo_root, &format!("{path}/units.json"));
            self.library
                .borrow_mut()
                .add_cards(&cards.get("cards").as_array(), &self.registry);
        }
    }
    pub fn _has(repo_root: &Path, path: &str, file: &str) -> bool {
        resolve(repo_root, &format!("{path}/{file}")).is_file()
    }
    pub fn _json(&mut self, repo_root: &Path, file: &str) -> Dictionary {
        let parsed = crate::util::godot_json::parse_string(
            &std::fs::read_to_string(resolve(repo_root, file)).unwrap_or_default(),
        )
        .as_dict();
        if parsed.is_empty() {
            self.errors
                .push(format!("{file} is missing or not a JSON object"));
        }
        parsed
    }
}
impl ToState for ContentSet {
    fn to_state(&self) -> Variant {
        crate::state_dict! {"record_paths"=>&self.record_paths,"registry"=>&self.registry,"library"=>&self.library,"display"=>&self.display,"standing"=>&self.standing,"folders"=>&self.folders,"errors"=>&self.errors}
    }
    fn field_names() -> &'static [&'static str] {
        &[
            "record_paths",
            "registry",
            "library",
            "display",
            "standing",
            "folders",
            "errors",
        ]
    }
}
