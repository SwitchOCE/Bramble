//! Mirrors src/core/records/record_build.gd (source checkout fingerprint).
use crate::{Array, Dictionary, ToState, Variant};
use sha2::{Digest, Sha256};
use std::path::Path;
#[derive(Default)]
pub struct RecordBuild {
    pub _identity: Dictionary,
}
impl RecordBuild {
    pub fn identity(repo_root: &Path) -> Dictionary {
        let files = Array::new();
        Self::_collect(repo_root, "res://src/core", &files);
        Self::_collect(repo_root, "res://src/content", &files);
        files.push("res://src/game/game_content.gd".into());
        files.push("res://src/game/data/stand_in_units.json".into());
        crate::util::godot_sort::sort_by(&mut files.borrow_mut(), |a, b| a < b);
        let mut parts = Vec::new();
        for path in files.borrow().iter() {
            let bytes = std::fs::read(crate::core::content::content_set::resolve(repo_root, path))
                .unwrap_or_default();
            parts.push(format!("{path}:{:x}", Sha256::digest(bytes)));
        }
        let project = std::fs::read_to_string(repo_root.join("project.godot")).unwrap_or_default();
        let setting = |key: &str, default: &str| {
            project
                .lines()
                .find_map(|l| {
                    l.strip_prefix(&format!("{key}=\""))
                        .and_then(|v| v.strip_suffix('"'))
                        .map(str::to_owned)
                })
                .unwrap_or_else(|| default.into())
        };
        crate::state_dict!{"version"=>&setting("config/version",""),"revision"=>&setting("config/build","workspace"),"engine"=>"4.7.2.stable.official.ed1daf0bf","rules_hash"=>&format!("{:x}",Sha256::digest(parts.join("\n").as_bytes()))}.as_dict()
    }
    pub fn _collect(repo_root: &Path, path: &str, files: &Array<String>) {
        let Ok(dir) =
            std::fs::read_dir(crate::core::content::content_set::resolve(repo_root, path))
        else {
            return;
        };
        for file in dir.flatten() {
            let name = file.file_name().to_string_lossy().into_owned();
            let child = format!("{path}/{name}");
            if file.path().is_dir() {
                Self::_collect(repo_root, &child, files);
            } else {
                let name = name.trim_end_matches(".remap");
                if name.ends_with(".gd") || name.ends_with(".json") {
                    files.push(format!("{path}/{name}"));
                }
            }
        }
    }
}
// Static variables do not carry PROPERTY_USAGE_SCRIPT_VARIABLE on an instance.
impl ToState for RecordBuild {
    fn to_state(&self) -> Variant {
        crate::state_dict! {}
    }
}
